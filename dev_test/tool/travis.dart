import 'package:process_run/shell.dart';

Future main() async {
  var shell = Shell();

  await shell.run('''
# Analyze code
dartanalyzer --fatal-warnings --fatal-infos .
dartfmt -n --set-exit-if-changed .

# Run tests
pub run test -p vm -j 1
pub run test -p chrome -j 1 test/multiplatform
pub run build_runner test -- -p chrome -j 1 test/multiplatform
''');
}
