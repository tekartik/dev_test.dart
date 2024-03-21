import 'menu.dart';

export 'menu_stub.dart' if (dart.library.io) 'menu_io.dart'
    show initMenuConsole;

/// Main menu declaration
void mainMenuConsole(List<String> arguments, void Function() declare) {
  initMenuConsole(arguments);
  declare();
}
