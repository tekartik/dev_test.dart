/// Test presenters and helpers to drive a dev_build menu through its agent
/// (`menuAgent`), on any platform.
library;

import 'dart:async';

import 'package:dev_build/menu/menu_agent.dart';
import 'package:dev_build/src/menu/dev_menu.dart'; // ignore: implementation_imports
import 'package:dev_build/src/menu/menu_manager.dart'; // ignore: implementation_imports
import 'package:dev_build/src/menu/menu_presenter.dart'; // ignore: implementation_imports
import 'package:test/test.dart';

/// A presenter processing the lines like the console does (prompt answer,
/// item key or shortcut, command handler), set as the menu presenter with a
/// new menu manager.
class MenuLineTestPresenter extends Object
    with MenuPresenterMixin
    implements MenuPresenter, MenuLineProcessor {
  /// Set as the menu presenter.
  MenuLineTestPresenter() {
    menuPresenter = this;
    menuManager = null;
  }

  /// The lines written.
  final written = <String>[];
  Completer<String>? _prompt;

  @override
  void presentMenu(DevMenu menu) {}

  @override
  Future<String> prompt(Object? message) =>
      (_prompt = Completer<String>()).future;

  @override
  void write(Object message) => writeln(message);

  @override
  void writeln(Object message) {
    written.add('$message');
    // Like the web and flutter presenters: the agent must not record it
    // twice.
    // ignore: avoid_print
    print('[presenter] $message');
  }

  @override
  Future<void> processLine(String line) async {
    final prompt = _prompt;
    if (prompt != null) {
      _prompt = null;
      prompt.complete(line);
      return;
    }
    final menu = menuManager.activeMenu!;
    final item = menu.byCmd(line);
    if (item != null) {
      try {
        await menuManager.runItem(item);
      } catch (_) {
        // Reported by the runner
      }
    } else {
      await menu.command?.fn(line);
    }
  }
}

/// A presenter without [MenuLineProcessor], its prompts never answered,
/// set as the menu presenter with a new menu manager.
class MenuBasicTestPresenter extends Object
    with MenuPresenterMixin
    implements MenuPresenter {
  /// Set as the menu presenter.
  MenuBasicTestPresenter() {
    menuPresenter = this;
    menuManager = null;
  }

  @override
  void presentMenu(DevMenu menu) {}

  @override
  Future<String> prompt(Object? message) => Completer<String>().future;

  @override
  void write(Object message) {}
}

/// Runs the agent command [name], expects it ok and returns its result.
Future<Map<String, Object?>> menuAgentRunOk(
  String name, [
  Map<String, Object?>? args,
]) async {
  final response = await menuAgent.run(name, args);
  expect(response['ok'], isTrue, reason: '$response');
  return (response['result'] as Map).cast<String, Object?>();
}

/// Runs the agent command [name], expects it failing and returns its error.
Future<String> menuAgentRunError(
  String name, [
  Map<String, Object?>? args,
]) async {
  final response = await menuAgent.run(name, args);
  expect(response['ok'], isFalse, reason: '$response');
  return response['error'] as String;
}

/// The items of a `menu` state as `key name`, ` >` added for a sub menu.
List<String> menuAgentStateItems(Map<String, Object?> state) => [
  for (final item in (state['items'] as List).cast<Map>())
    '${item['key']} ${item['name']}${item['menu'] == true ? ' >' : ''}',
];

/// Polls the `menu` state until [until] is true (at most [timeout]).
Future<Map<String, Object?>> menuAgentWaitState(
  bool Function(Map<String, Object?> state) until, {
  Map<String, Object?>? args,
  Duration timeout = const Duration(seconds: 10),
}) async {
  final stopwatch = Stopwatch()..start();
  while (true) {
    final state = await menuAgentRunOk('menu', args);
    if (until(state) || stopwatch.elapsed > timeout) {
      return state;
    }
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
}
