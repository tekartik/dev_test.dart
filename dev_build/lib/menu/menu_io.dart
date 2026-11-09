/// A numbered console menu for a `dart run` script: `mainMenuConsole` then
/// the declarations of `package:dev_build/menu/menu.dart`.
///
/// ```dart
/// import 'package:dev_build/menu/menu_io.dart';
///
/// void main(List<String> arguments) {
///   mainMenuConsole(arguments, () {
///     item('hello', () => write('Hello'));
///   });
/// }
/// ```
///
/// Extra command line arguments run as typed lines (`0 .` runs item 0 then
/// exits), a `prompt` takes the next one first.
library;

export 'package:dev_build/src/menu/io/menu.dart'
    show initMenuConsole, mainMenuConsole;

export 'menu.dart';
