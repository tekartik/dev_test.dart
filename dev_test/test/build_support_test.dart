@TestOn('vm')
import 'dart:io';

import 'package:dev_test/build_support.dart';
import 'package:dev_test/src/run_ci.dart';
import 'package:path/path.dart';
import 'package:process_run/shell_run.dart';
import 'package:test/test.dart';

void main() {
  test('flutter config', () async {
    if (isFlutterSupportedSync) {
      await run('flutter config');
    }
  });
  group('flutter test', () {
    setUpAll(() async {
      await buildInitFlutter();
    });
    var dir =
        join('.dart_tool', 'dev_test', 'raw_flutter_test1', 'test', 'project');
    var _ensureCreated = false;
    var shell = Shell(workingDirectory: dir);
    Future<void> _create() async {
      await flutterCreateProject(
        path: dir,
      );
      await shell.run('flutter config');
    }

    Future<void> _ensureCreate() async {
      if (!_ensureCreated) {
        if (!Directory(dir).existsSync()) {
          await _create();
        }
        _ensureCreated = true;
      }
    }

    Future<void> _iosBuild() async {
      if (buildSupportsIOS) {
        await shell.run('flutter build ios --release --no-codesign');
      }
    }

    Future<void> _androidBuild() async {
      if (buildSupportsAndroid) {
        await shell.run('flutter build apk');
      }
    }

    Future<void> _runCi() async {
      // Allow failure
      try {
        await packageRunCi(dir);
      } catch (e) {
        stderr.writeln('run_ci error $e');
      }
    }

    test('create', () async {
      await _create();
    }, timeout: const Timeout(Duration(minutes: 5)));
    test('run_ci', () async {
      await _ensureCreate();
      await _runCi();
    }, timeout: const Timeout(Duration(minutes: 5)));

    test('build ios', () async {
      await _ensureCreate();
      await _iosBuild();
    }, timeout: const Timeout(Duration(minutes: 5)));

    test('build android', () async {
      await _ensureCreate();
      await _androidBuild();
    }, timeout: const Timeout(Duration(minutes: 5)));
    test('add sqflite', () async {
      await _ensureCreate();
      if (await pathPubspecAddDependency(dir, 'sqflite')) {
        await _iosBuild();
        await _androidBuild();
        await _runCi();
      }
    }, timeout: const Timeout(Duration(minutes: 10)));
  }, skip: !isFlutterSupportedSync || isRunningOnTravis);
  // TODO @alex find a better to know the flutter build status

  group(
    'dart test',
    () {
      setUpAll(() async {
        await buildInitDart();
      });
      var dir =
          join('.dart_tool', 'dev_test', 'raw_dart_test1', 'test', 'project');
      var _ensureCreated = false;
      var shell = Shell(workingDirectory: dir);
      Future<void> _create() async {
        await dartCreateProject(
          path: dir,
        );
      }

      Future<void> _ensureCreate() async {
        if (!_ensureCreated) {
          if (!Directory(dir).existsSync()) {
            await _create();
          }
          _ensureCreated = true;
        }
      }

      Future<void> _runCi() async {
        // Don't allow failure
        try {
          await packageRunCi(dir);
        } catch (e) {
          stderr.writeln('run_ci error $e');
          rethrow;
        }
      }

      test('create', () async {
        await _create();
      }, timeout: const Timeout(Duration(minutes: 5)));
      test('run_ci', () async {
        await _ensureCreate();
        await _runCi();
      }, timeout: const Timeout(Duration(minutes: 5)));

      test('add dev_test', () async {
        await _ensureCreate();
        var readDependencyLines =
            await pathPubspecGetDependencyLines(dir, 'dev_test');
        if (readDependencyLines == ['dev_test:']) {
          return;
        }
        if (await pathPubspecAddDependency(dir, 'dev_test')) {
          expect(
              pubspecYamlHasAnyDependencies(
                  await pathGetPubspecYamlMap(dir), ['dev_test']),
              isTrue);
          await _runCi();
        } else {
          expect(
              pubspecYamlHasAnyDependencies(
                  await pathGetPubspecYamlMap(dir), ['dev_test']),
              isTrue);
        }
      }, timeout: const Timeout(Duration(minutes: 10)));

      test('add dev_test_relative', () async {
        await _ensureCreate();
        var dependencyLines = ['path: ${join('..', '..', '..', '..', '..')}'];

        var readDependencyLines =
            await pathPubspecGetDependencyLines(dir, 'dev_test');
        if (readDependencyLines == dependencyLines) {
          return;
        }
        if (await pathPubspecRemoveDependency(dir, 'dev_test')) {
          await shell.run('dart pub get');
        }
        expect(await pathPubspecGetDependencyLines(dir, 'dev_test'), isNull);
        expect(
            pubspecYamlHasAnyDependencies(
                await pathGetPubspecYamlMap(dir), ['dev_test']),
            isFalse);
        if (await pathPubspecAddDependency(dir, 'dev_test',
            dependencyLines: dependencyLines)) {
          expect(await pathPubspecGetDependencyLines(dir, 'dev_test'),
              dependencyLines);
          expect(
              pubspecYamlHasAnyDependencies(
                  await pathGetPubspecYamlMap(dir), ['dev_test']),
              isTrue);
          await _runCi();
        } else {
          expect(await pathPubspecGetDependencyLines(dir, 'dev_test'),
              dependencyLines);
          expect(
              pubspecYamlHasAnyDependencies(
                  await pathGetPubspecYamlMap(dir), ['dev_test']),
              isTrue);
        }
      },
          timeout: const Timeout(Duration(minutes: 10)),
          skip: 'Temp skip during nnbd migration');
    },
  );
}
