@TestOn('vm')
library;

import 'dart:io';

import 'package:path/path.dart';
import 'package:process_run/shell.dart';
import 'package:test/test.dart';

var _topDir = join('.dart_tool', 'dev_build', 'test', 'run_ci_cleanup');

/// Run `run_ci` on [path] (no format nor analyze).
Future<void> _runCi(String path, String args) async {
  await Shell(verbose: false).run(
    '${shellArgument(Platform.resolvedExecutable)} run'
    ' ${shellArgument(join('bin', 'run_ci.dart'))}'
    ' --no-recursive --no-format --no-analyze $args ${shellArgument(path)}',
  );
}

void main() {
  test('run_ci cleanup', () async {
    // No dependencies (an offline pub get) and no tests, the build step is
    // on: the setup creates build/, the cleanup script tells if it still
    // exists.
    var path = join(_topDir, 'package');
    if (Directory(path).existsSync()) {
      await Directory(path).delete(recursive: true);
    }
    await Directory(join(path, 'tool')).create(recursive: true);
    await File(join(path, 'pubspec.yaml')).writeAsString('''
name: run_ci_cleanup_package
environment:
  sdk: ^3.12.0
''');
    await File(join(path, 'tool', 'dev_build_setup.dart')).writeAsString('''
import 'dart:io';

void main() {
  File('build/output.txt')
    ..createSync(recursive: true)
    ..writeAsStringSync('built');
}
''');
    await File(join(path, 'tool', 'dev_build_cleanup.dart')).writeAsString('''
import 'dart:io';

void main() {
  File('cleanup.txt').writeAsStringSync('build: \${Directory('build').existsSync()}');
}
''');
    var buildDir = Directory(join(path, 'build'));
    var cleanupFile = File(join(path, 'cleanup.txt'));

    // build/ created by the run: deleted after the cleanup script.
    await _runCi(path, '');
    expect(cleanupFile.readAsStringSync(), 'build: true');
    expect(buildDir.existsSync(), isFalse);

    // --no-cleanup: no cleanup script, build/ kept.
    await cleanupFile.delete();
    await _runCi(path, '--no-cleanup');
    expect(cleanupFile.existsSync(), isFalse);
    expect(File(join(buildDir.path, 'output.txt')).existsSync(), isTrue);

    // build/ existing before the run: kept.
    await _runCi(path, '');
    expect(cleanupFile.readAsStringSync(), 'build: true');
    expect(File(join(buildDir.path, 'output.txt')).existsSync(), isTrue);
  }, timeout: const Timeout(Duration(minutes: 4)));
}
