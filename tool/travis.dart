// @dart=2.9
import 'package:process_run/shell.dart';

import 'run_ci.dart';

Future main() async {
  var shell = Shell();
  var nnbdEnabled = dartVersion > minNnbdVersion;
  if (nnbdEnabled) {
    for (var dir in ['dev_test']) {
      shell = shell.pushd(dir);
      await shell.run('''

pub get
dart tool/travis.dart

    ''');
      shell = shell.popd();
    }
  }
}
