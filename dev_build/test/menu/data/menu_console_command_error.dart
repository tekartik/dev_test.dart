import 'package:dev_build/menu/menu_io.dart';

/// Menu whose command handler throws, run by menu_io_console_test.dart.
void main(List<String> arguments) {
  mainMenuConsole(arguments, () {
    command((line) {
      throw StateError('command failed $line');
    });
    item('ok', () {
      write('item ran');
    });
  });
}
