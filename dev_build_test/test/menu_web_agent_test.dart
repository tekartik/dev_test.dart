/// A console menu script (menu_io.dart) run in a browser: the console is a
/// no-op there, the default presenter prints, the agent still drives it.
@TestOn('browser')
library;

import 'package:dev_build/menu/menu_agent.dart';
import 'package:dev_build/menu/menu_io.dart';
import 'package:tekartik_dev_build_test/menu_agent_testing.dart';
import 'package:test/test.dart';

void main() {
  test('menu_io script in a browser, driven by the agent', () async {
    // Records the output from the start.
    expect(menuAgent, isNotNull);
    mainMenuConsole([], () {
      item('hi', () => write('hi'));
      item('ask', () async {
        write('got "${await prompt('Name?')}"');
      });
      menu('sub', () {
        item('in sub', () => write('in sub'));
      });
    });
    // The menu runs in a microtask after the declaration.
    var state = await menuAgentWaitState(
      (state) => (state['items'] as List).isNotEmpty,
    );
    expect(menuAgentStateItems(state), ['0 hi', '1 ask', '2 sub >']);

    state = await menuAgentRunOk('menu_line', {'line': '0'});
    expect(state['output'], ['hi']);
    // The default presenter answers a prompt with an empty text.
    state = await menuAgentRunOk('menu_line', {'line': '1'});
    expect(state['output'], ['PROMPT Name?', 'ANSWER ', 'got ""']);
    state = await menuAgentRunOk('menu_line', {'line': '2'});
    expect(state['path'], ['sub']);
    state = await menuAgentRunOk('menu_line', {'line': '-'});
    expect(state['path'], isEmpty);
  });
}
