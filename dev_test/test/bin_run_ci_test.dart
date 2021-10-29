@TestOn('vm')
library dev_test.test.bin_run_ci_test;

import 'package:path/path.dart';
import 'package:process_run/shell_run.dart';
import 'package:test/test.dart';

var rootProjectPath = '..';
void main() {
  group('bin', () {
    group('run_ci', () {
      test('root_no_package', () async {
        var shell = Shell(
            environment: ShellEnvironment()
              ..aliases['run_ci'] = 'dart run ${join('bin', 'run_ci.dart')}');
        await shell.run('run_ci --offline --pub-get --no-override ..');
        try {
          await shell.run('run_ci --offline --pub-get .. --no-recursive');
          fail('should fail');
        } on ShellException catch (e) {
          expect(e.result!.exitCode, 1);
        }
      });
      test('root_info', () async {
        var shell = Shell(
            environment: ShellEnvironment()
              ..aliases['run_ci'] = 'dart run ${join('bin', 'run_ci.dart')}');
        await shell.run('run_ci --no-run-ci --prj-info $rootProjectPath');
      });
    });
  });
}
