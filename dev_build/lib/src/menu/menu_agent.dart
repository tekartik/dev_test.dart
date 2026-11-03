/// Lets an LLM agent read and drive the menu with two json commands, `menu`
/// (the state and the output) and `menu_line` (a line typed by a user),
/// over the VM service ([menuAgentVmRegister]) or any other json transport
/// ([MenuAgent.describe] and [MenuAgent.run]).
///
/// The VM service extensions and the json shapes are the ones of
/// tekartik_app_agent, so its MCP server (`app-agent`) drives a menu as it
/// drives an app, without any dependency between the packages.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'dev_menu.dart';
import 'menu_manager.dart';
import 'menu_presenter.dart';

/// The VM service extension listing the agent commands
/// (`{commands: [{name, description, inputSchema}]}`).
const menuAgentVmCommandsExtension = 'ext.tekartik.agent.commands';

/// The VM service extension running an agent command (params `name` and
/// `args` as json text): `{ok: true, result}` or `{ok: false, error}`.
const menuAgentVmRunExtension = 'ext.tekartik.agent.run';

/// Output entries kept.
const _maxOutputCount = 200;

/// Lines and characters kept of an output entry (a stack trace).
const _maxEntryLines = 40;
const _maxEntryLength = 4000;

const _defaultOutputCount = 20;
const _defaultTimeout = Duration(seconds: 30);
const _backCommands = {'-', '.'};
const _helpCommand = '?';
const _menuCommand = 'menu';
const _lineCommand = 'menu_line';

MenuAgent? _menuAgent;

/// The menu agent, null until [menuAgent] is first used.
MenuAgent? get menuAgentOrNull => _menuAgent;

/// The menu agent, created on first use: it records the output from then
/// on.
MenuAgent get menuAgent => _menuAgent ??= MenuAgent._();

/// An error the agent reads, the result error.
class _AgentError implements Exception {
  _AgentError(this.message);

  final String message;

  @override
  String toString() => message;
}

class _PendingPrompt {
  _PendingPrompt(this.text);

  final String text;

  /// Answered by the agent, the presenter is completing it.
  var answered = false;
}

/// Reads and drives the menu for an LLM agent.
///
/// Lines go through the presenter when it is a [MenuLineProcessor] (the
/// console, the web and flutter presenters), so that its display follows.
class MenuAgent {
  MenuAgent._();

  final _output = <String>[];

  /// The index of the next output entry.
  var _outputEnd = 0;

  /// Inside a presenter write: its prints are not output entries.
  var _writing = 0;

  /// Lines started by the agent and not done.
  var _lineRunning = 0;

  final _prompts = <_PendingPrompt>[];
  Completer<void>? _change;

  /// The commands, as `{name, description, inputSchema}` (a json schema).
  List<Map<String, Object?>> describe() => [
    {
      'name': _menuCommand,
      'description':
          'The state of the dev menu: path (the menu names from the top '
          'menu), items (key to type, name, menu: true for a sub menu), '
          'canBack, status (ready, running, input when a prompt waits for '
          'an answer, error when the last item failed), prompt (the text '
          'of the pending prompt) and output (the lines written, the last '
          '`output` ones or the ones from the `since` cursor); next is the '
          'cursor of the next line, skipped the lines no longer kept.',
      'inputSchema': {
        'type': 'object',
        'properties': {
          'output': {
            'type': 'integer',
            'description':
                'The number of last output lines (default '
                '$_defaultOutputCount).',
          },
          'since': {
            'type': 'integer',
            'description':
                'Returns the output from this cursor (next of a previous '
                'result) instead.',
          },
        },
      },
    },
    {
      'name': _lineCommand,
      'description':
          'Types a line in the dev menu as a user would: an item key (its '
          'number or shortcut) runs the item or enters its sub menu, - goes '
          'back to the parent menu, ? only returns the state, the answer of '
          'a pending prompt, any other line goes to the menu command '
          'handler. Waits until the run is done, a prompt waits for an '
          'answer (status input: answer with menu_line) or timeout seconds '
          '(timeout: true, status running: poll with menu since). Returns '
          'the output written meanwhile (writes, errors with their stack '
          'trace, prompts, prints of the item) and the state as menu does.',
      'inputSchema': {
        'type': 'object',
        'properties': {
          'line': {'type': 'string', 'description': 'The line typed.'},
          'timeout': {
            'type': 'number',
            'description':
                'Seconds to wait for the run (default '
                '${_defaultTimeout.inSeconds}).',
          },
        },
        'required': ['line'],
      },
    },
  ];

  /// Runs the command [name] with [args]: `{ok: true, result}` or `{ok:
  /// false, error}`.
  Future<Map<String, Object?>> run(
    String name, [
    Map<String, Object?>? args,
  ]) async {
    args ??= const <String, Object?>{};
    try {
      final result = switch (name) {
        _menuCommand => _menu(args),
        _lineCommand => await _line(args),
        _ => throw _AgentError(
          'unknown command "$name" ($_menuCommand, $_lineCommand)',
        ),
      };
      return {'ok': true, 'result': result};
    } on _AgentError catch (e) {
      return {'ok': false, 'error': e.message};
    } catch (e) {
      return {'ok': false, 'error': '$e'};
    }
  }

  void _add(String text) {
    _output.add(_trimEntry(text));
    _outputEnd++;
    if (_output.length > _maxOutputCount) {
      _output.removeAt(0);
    }
  }

  static String _trimEntry(String text) {
    var lines = text.split('\n');
    if (lines.length > _maxEntryLines) {
      final more = lines.length - _maxEntryLines;
      lines = [...lines.take(_maxEntryLines), '... ($more more lines)'];
      text = lines.join('\n');
    }
    if (text.length > _maxEntryLength) {
      text = '${text.substring(0, _maxEntryLength)}...';
    }
    return text;
  }

  void _notify() {
    final change = _change;
    _change = null;
    change?.complete();
  }

  _PendingPrompt? get _pendingPrompt {
    for (final prompt in _prompts.reversed) {
      if (!prompt.answered) {
        return prompt;
      }
    }
    return null;
  }

  bool get _busy =>
      _lineRunning > 0 || (menuManagerOrNull?.runningCount ?? 0) > 0;

  MenuLineProcessor? get _processor {
    final presenter = menuPresenter;
    return presenter is MenuLineProcessor
        ? presenter as MenuLineProcessor
        : null;
  }

  String get _status {
    if (_pendingPrompt != null) {
      return 'input';
    }
    if (_busy) {
      return 'running';
    }
    if (menuManagerOrNull?.lastRunFailed ?? false) {
      return 'error';
    }
    return 'ready';
  }

  Map<String, Object?> _state() {
    final manager = menuManagerOrNull;
    final menu = manager?.activeMenu;
    return {
      'path': [
        if (manager != null)
          for (final runner in manager.stackMenus)
            if (runner.menu is! RootMenu) runner.menu.name,
      ],
      'items': [
        if (menu != null)
          for (var i = 0; i < menu.length; i++)
            {
              'key': menu[i].cmd ?? '$i',
              'name': menu[i].name,
              if (menu[i] is MenuMenuItem) 'menu': true,
            },
      ],
      'canBack': manager?.canPop() ?? false,
      'status': _status,
      if (_pendingPrompt case final prompt?) 'prompt': prompt.text,
    };
  }

  /// The output from [index], `skipped` set when entries are no longer
  /// kept.
  Map<String, Object?> _outputFrom(int index) {
    final first = _outputEnd - _output.length;
    final skipped = index < first ? first - index : 0;
    if (index < first) {
      index = first;
    }
    return {
      'output': _output.sublist(index - first),
      'next': _outputEnd,
      if (skipped > 0) 'skipped': skipped,
    };
  }

  static int? _intArg(Map<String, Object?> args, String name) {
    final value = args[name];
    if (value == null) {
      return null;
    }
    if (value is num) {
      return value.toInt();
    }
    throw _AgentError('$name must be a number');
  }

  Map<String, Object?> _menu(Map<String, Object?> args) {
    final since = _intArg(args, 'since');
    final count = _intArg(args, 'output') ?? _defaultOutputCount;
    final from =
        since ?? (_outputEnd - (count < 0 ? 0 : count)).clamp(0, _outputEnd);
    return {..._state(), ..._outputFrom(from)};
  }

  Future<Map<String, Object?>> _line(Map<String, Object?> args) async {
    final line = args['line'];
    if (line is! String) {
      throw _AgentError('line (a string) is required');
    }
    final timeoutValue = args['timeout'];
    if (timeoutValue != null && timeoutValue is! num) {
      throw _AgentError('timeout must be a number of seconds');
    }
    final timeout = timeoutValue is num
        ? Duration(milliseconds: (timeoutValue * 1000).round())
        : _defaultTimeout;
    final manager = menuManagerOrNull;
    final menu = manager?.activeMenu;
    if (manager == null || menu == null) {
      throw _AgentError('the menu is not started');
    }
    final start = _outputEnd;
    final prompt = _pendingPrompt;
    if (prompt != null) {
      final processor = _processor;
      if (processor == null) {
        throw _AgentError('this menu presenter cannot answer a prompt');
      }
      prompt.answered = true;
      _start(() => processor.processLine(line));
    } else {
      if (_busy) {
        throw _AgentError(
          'busy, an item is running: poll with $_menuCommand (since)',
        );
      }
      final command = line.trim();
      if (_backCommands.contains(command)) {
        if (!manager.canPop()) {
          throw _AgentError('already in the top menu');
        }
        _start(manager.popMenu);
      } else if (command != _helpCommand) {
        final item = menu.byCmd(command);
        final handler = menu.command;
        if (item == null && handler == null) {
          throw _AgentError(
            'unknown item "$command" (no command handler in this menu), '
            'type a key of items',
          );
        }
        final processor = _processor;
        if (processor != null) {
          _start(() => processor.processLine(command));
        } else if (item != null) {
          _start(() => manager.runItem(item));
        } else {
          _start(() async {
            try {
              await handler!.fn(command);
            } catch (e, st) {
              _add('ERROR $e\n$st');
            }
          });
        }
      }
    }
    final done = await _settle(timeout);
    return {..._state(), ..._outputFrom(start), if (!done) 'timeout': true};
  }

  /// Runs [action] in a zone recording its prints, errors already reported
  /// (by the menu runner or the presenter).
  void _start(Future<void> Function() action) {
    _lineRunning++;
    Future<void> run() async {
      try {
        await action();
      } catch (_) {
        // Reported
      }
    }

    unawaited(
      runZoned(
        run,
        zoneSpecification: ZoneSpecification(
          print: (self, parent, zone, text) {
            if (_writing == 0) {
              _add(text);
            }
            parent.print(zone, text);
          },
        ),
      ).whenComplete(() {
        _lineRunning--;
        _notify();
      }),
    );
  }

  /// Waits until nothing runs or a prompt waits, false on [timeout].
  Future<bool> _settle(Duration timeout) async {
    final stopwatch = Stopwatch()..start();
    // Let what is already done finish first (microtasks): a presenter
    // answering a prompt right away, an answered prompt resuming its item.
    await Future<void>.delayed(Duration.zero);
    while (_pendingPrompt == null && _busy) {
      final remaining = timeout - stopwatch.elapsed;
      if (remaining <= Duration.zero) {
        return false;
      }
      final change = (_change ??= Completer<void>()).future;
      final timer = Completer<void>();
      final timeoutTimer = Timer(remaining, timer.complete);
      try {
        await Future.any([change, timer.future]);
      } finally {
        timeoutTimer.cancel();
      }
    }
    return true;
  }
}

/// Writes [message] on the presenter, recorded by the agent (internal, the
/// menu `writeln` and the runner errors).
void menuWritelnImpl(Object message) {
  final agent = _menuAgent;
  if (agent == null) {
    menuPresenter.writeln(message);
    return;
  }
  agent._add('$message');
  agent._writing++;
  try {
    menuPresenter.writeln(message);
  } finally {
    agent._writing--;
  }
}

/// Prompts on the presenter, the agent sees the pending prompt (internal,
/// the menu `prompt`).
Future<String> menuPromptImpl(Object? message) async {
  final agent = _menuAgent;
  if (agent == null) {
    return await menuPresenter.prompt(message);
  }
  final prompt = _PendingPrompt('${message ?? 'Enter text'}');
  agent._add('PROMPT ${prompt.text}');
  agent._prompts.add(prompt);
  agent._notify();
  try {
    // The prompt display of the presenter is not an item print.
    final Future<String> answerFuture;
    agent._writing++;
    try {
      answerFuture = menuPresenter.prompt(message);
    } finally {
      agent._writing--;
    }
    final answer = await answerFuture;
    agent._add('ANSWER $answer');
    return answer;
  } finally {
    agent._prompts.remove(prompt);
    agent._notify();
  }
}

/// Adds an output entry the presenter wrote on its own, i.e. a command
/// handler error (internal).
void menuAgentOutput(String text) {
  _menuAgent?._add(text);
}

/// A run of the menu manager ended (internal).
void menuAgentRunEnded() {
  _menuAgent?._notify();
}

var _vmRegistered = false;

/// Registers the VM service extensions [menuAgentVmCommandsExtension] and
/// [menuAgentVmRunExtension] of [menuAgent] (once), reachable from the Dart
/// tooling of a debug run (`dart run --enable-vm-service`, `flutter run`):
/// the `app-agent` MCP server (tekartik_app_agent_mcp) `app_connect` then
/// lists `menu` and `menu_line` as tools.
///
/// Returns false when the extensions are already registered by someone
/// else (an app using tekartik_app_agent): its commands are kept.
bool menuAgentVmRegister() {
  if (_vmRegistered) {
    return true;
  }
  final agent = menuAgent;
  try {
    registerExtension(menuAgentVmCommandsExtension, (method, parameters) async {
      return ServiceExtensionResponse.result(
        jsonEncode({'commands': agent.describe()}),
      );
    });
  } on ArgumentError {
    return false;
  }
  registerExtension(menuAgentVmRunExtension, (method, parameters) async {
    final name = parameters['name'];
    if (name == null) {
      return ServiceExtensionResponse.error(
        ServiceExtensionResponse.invalidParams,
        'missing name',
      );
    }
    Map<String, Object?>? args;
    final argsText = parameters['args'];
    if (argsText != null && argsText.isNotEmpty) {
      try {
        args = (jsonDecode(argsText) as Map).cast<String, Object?>();
      } catch (e) {
        return ServiceExtensionResponse.error(
          ServiceExtensionResponse.invalidParams,
          'invalid args $e',
        );
      }
    }
    return ServiceExtensionResponse.result(
      jsonEncode(await agent.run(name, args)),
    );
  });
  _vmRegistered = true;
  return true;
}
