import 'package:dev_build/menu/menu_io.dart';

/// Menu driven over the VM service by menu_io_agent_test.dart.
void main(List<String> arguments) {
  mainMenuConsole(arguments, () {
    item('hi', () => write('hi'));
    item('ask', () async {
      write('got ${await prompt('Name?')}');
    });
    menu('sub', () {
      item('in sub', () => write('in sub'));
    });
  });
}
