@TestOn('vm')
library;

import 'package:dev_build/package.dart';
// ignore: unused_import
import 'package:dev_build/src/dev_utils.dart';
import 'package:dev_build/src/version.dart';
import 'package:path/path.dart';
import 'package:process_run/shell_run.dart';
import 'package:test/test.dart';

var rootProjectPath = '..';

class _RunCiBinContext {
  final Shell shell;

  _RunCiBinContext(this.shell);
}

var compiledRunCiExeFuture = DartPackageIo('.').compiledExe(
  script: join('bin', 'run_ci.dart'),
  minVersion: packageVersion,
  verbose: false, // devWarning(true),
);

void main() {
  group('bin', () {
    group('run_ci', () {
      Future<_RunCiBinContext> setupDartScriptShell() async {
        return _RunCiBinContext(
          Shell(
            environment:
                ShellEnvironment()
                  ..aliases['run_ci'] =
                      'dart run ${join('bin', 'run_ci.dart')}',
          ),
        );
      }

      Future<_RunCiBinContext> setupCompiledScriptShell() async {
        var compiledRunCiExe = await compiledRunCiExeFuture;
        return _RunCiBinContext(
          Shell(
            environment:
                ShellEnvironment()..aliases['run_ci'] = compiledRunCiExe.path,
          ),
        );
      }

      void runCiGroup(
        String name,
        Future<_RunCiBinContext> Function() runCiSetupAll,
      ) {
        late _RunCiBinContext context;
        late Shell shell;
        setUpAll(() async {
          context = await runCiSetupAll();
          shell = context.shell;
        });
        group(name, () {
          test('root_no_action', () async {
            await shell.run(
              'run_ci --print-path --no-vm-test --no-browser-test --no-node-test'
              ' --no-format --no-analyze'
              ' $rootProjectPath',
            );
          });
          test('root_no_package', () async {
            try {
              // Should fail for dev_test
              await shell.run('run_ci --offline --pub-get --no-override ..');
            } on ShellException catch (e) {
              /// Github actions return 255...
              expect(e.result!.exitCode, anyOf(1, 255));
            }

            // No offline needed for dev_test!
            await shell.run('run_ci --pub-get --no-override ..');

            try {
              await shell.run('run_ci --offline --pub-get .. --no-recursive');
              fail('should fail');
            } on ShellException catch (e) {
              expect(e.result!.exitCode, 1);
            }
          });
          test('root_info', () async {
            await shell.run('run_ci --no-run-ci --prj-info $rootProjectPath');
          });
        });
      }

      runCiGroup('run_ci.dart', setupDartScriptShell);
      runCiGroup('run_ci.exe', setupCompiledScriptShell);
    });
  });
}
