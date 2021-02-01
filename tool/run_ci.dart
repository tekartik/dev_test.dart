// @dart=2.9
import 'package:process_run/shell.dart';
import 'package:pub_semver/pub_semver.dart';

var minNnbdVersion = Version(2, 12, 0, pre: '0');

Future main() async {
  var shell = Shell();
  var nnbdEnabled = dartVersion > minNnbdVersion;
  if (nnbdEnabled) {
    for (var dir in ['dev_test']) {
      shell = shell.pushd(dir);
      await shell.run('''

pub get
dart tool/run_ci.dart

    ''');
      shell = shell.popd();
    }
  }
}
