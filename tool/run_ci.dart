import 'package:process_run/shell.dart';

Future main() async {
  var shell = Shell();

  for (var dir in ['dev_test']) {
    shell = shell.pushd(dir);
    await shell.run('''

pub get
dart tool/run_ci.dart

    ''');
    shell = shell.popd();
  }
}
