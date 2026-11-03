/// The menu agent in process: on the VM and in Chrome (js and wasm).
library;

import 'dart:async';

import 'package:dev_build/menu/menu.dart';
import 'package:dev_build/menu/menu_agent.dart';
import 'package:tekartik_dev_build_test/menu_agent_testing.dart';
import 'package:test/test.dart';

void main() {
  test('describe', () {
    final commands = menuAgent.describe();
    expect(commands.map((command) => command['name']), ['menu', 'menu_line']);
    for (final command in commands) {
      expect(command['description'], isA<String>());
      expect((command['inputSchema'] as Map)['type'], 'object');
    }
    expect(menuAgentVmCommandsExtension, 'ext.tekartik.agent.commands');
    expect(menuAgentVmRunExtension, 'ext.tekartik.agent.run');
  });

  test('vm register, also harmless on the web', () {
    expect(menuAgentVmRegister(), isTrue);
    // Once
    expect(menuAgentVmRegister(), isTrue);
  });

  test('menu and menu_line', () async {
    final presenter = MenuLineTestPresenter();
    menu('main', () {
      item('hi', () => write('hi'));
      item('print', () {
        // ignore: avoid_print
        print('printed');
      });
      item('crash', () => throw StateError('crash'));
      item('ask', () async {
        write('got ${await prompt('Name?')}');
      });
      item('short', () => write('short'), cmd: 's');
      menu('sub', () {
        item('in sub', () => write('in sub'));
      });
      command((line) => write('command $line'));
    });
    await menuRun();

    var state = await menuAgentRunOk('menu');
    expect(state['path'], isEmpty);
    expect(menuAgentStateItems(state), ['0 main >']);
    expect(state['canBack'], isFalse);
    expect(state['status'], 'ready');
    expect(
      await menuAgentRunError('menu_line', {'line': '-'}),
      'already in the top menu',
    );
    expect(
      await menuAgentRunError('menu_line', {'line': 'x'}),
      contains('unknown item'),
    );
    expect(await menuAgentRunError('menu_line'), contains('line'));
    expect(await menuAgentRunError('unknown'), contains('unknown command'));

    state = await menuAgentRunOk('menu_line', {'line': '0'});
    expect(state['path'], ['main']);
    expect(menuAgentStateItems(state), [
      '0 hi',
      '1 print',
      '2 crash',
      '3 ask',
      's short',
      '5 sub >',
    ]);
    expect(state['canBack'], isTrue);

    state = await menuAgentRunOk('menu_line', {'line': '0'});
    expect(state['output'], ['hi']);
    expect(presenter.written.last, 'hi');

    // Prints of the item, not the ones of the presenter.
    state = await menuAgentRunOk('menu_line', {'line': '1'});
    expect(state['output'], ['printed']);

    state = await menuAgentRunOk('menu_line', {'line': '2'});
    final output = (state['output'] as List).cast<String>();
    expect(output.single, startsWith('ERROR CAUGHT Bad state: crash'));
    expect(state['status'], 'error');

    // A prompt waits for the next line.
    state = await menuAgentRunOk('menu_line', {'line': '3'});
    expect(state['status'], 'input');
    expect(state['prompt'], 'Name?');
    expect(state['output'], ['PROMPT Name?']);
    state = await menuAgentRunOk('menu_line', {'line': 'Alex'});
    expect(state['status'], 'ready');
    expect(state.containsKey('prompt'), isFalse);
    expect(state['output'], ['ANSWER Alex', 'got Alex']);

    state = await menuAgentRunOk('menu_line', {'line': ' s '});
    expect(state['output'], ['short']);
    state = await menuAgentRunOk('menu_line', {'line': 'free text'});
    expect(state['output'], ['command free text']);
    state = await menuAgentRunOk('menu_line', {'line': '?'});
    expect(state['output'], isEmpty);
    expect(state['path'], ['main']);

    state = await menuAgentRunOk('menu_line', {'line': '5'});
    expect(state['path'], ['main', 'sub']);
    state = await menuAgentRunOk('menu_line', {'line': '.'});
    expect(state['path'], ['main']);

    state = await menuAgentRunOk('menu', {'output': 2});
    expect(state['output'], ['short', 'command free text']);
    final next = state['next'] as int;
    state = await menuAgentRunOk('menu', {'since': next - 3});
    expect(state['output'], ['got Alex', 'short', 'command free text']);
    state = await menuAgentRunOk('menu', {'since': 0});
    expect(state['skipped'], isNull);
    expect((state['output'] as List).first, 'hi');
  });

  test('timeout and busy', () async {
    MenuLineTestPresenter();
    final release = Completer<void>();
    item('slow', () async {
      write('start');
      await release.future;
      write('end');
    });
    item('other', () => write('other'));
    await menuRun();

    var state = await menuAgentRunOk('menu_line', {
      'line': '0',
      'timeout': 0.05,
    });
    expect(state['timeout'], isTrue);
    expect(state['status'], 'running');
    expect(state['output'], ['start']);
    final next = state['next'] as int;
    expect(
      await menuAgentRunError('menu_line', {'line': '1'}),
      startsWith('busy'),
    );

    release.complete();
    state = await menuAgentWaitState(
      (state) => state['status'] == 'ready',
      args: {'since': next},
    );
    expect(state['status'], 'ready');
    expect(state['output'], ['end']);
  });

  test('presenter without line processing', () async {
    MenuBasicTestPresenter();
    item('hi', () => write('hi'));
    item('ask', () async {
      write('got ${await prompt()}');
    });
    command((line) => throw StateError('bad $line'));
    await menuRun();

    var state = await menuAgentRunOk('menu_line', {'line': '0'});
    expect(state['output'], ['hi']);
    state = await menuAgentRunOk('menu_line', {'line': 'zz'});
    expect(
      (state['output'] as List).single,
      startsWith('ERROR Bad state: bad zz'),
    );
    state = await menuAgentRunOk('menu_line', {'line': '1'});
    expect(state['status'], 'input');
    expect(state['prompt'], 'Enter text');
    expect(
      await menuAgentRunError('menu_line', {'line': 'x'}),
      contains('cannot answer a prompt'),
    );
  });
}
