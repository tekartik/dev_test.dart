import 'package:dev_build/menu/menu_io.dart';
import 'package:dev_build/menu/menu_run_ci.dart';

Future main(List<String> args) async {
  mainMenuConsole(args, () {
    runCiMenu('.');
  });
}
