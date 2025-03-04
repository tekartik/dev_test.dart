@TestOn('vm')
library;

import 'dart:io';

import 'package:dev_build/build_support.dart';
import 'package:dev_build/package.dart' show packageRunCi;
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
    var dir = join(
      '.dart_tool',
      'dev_build',
      'raw_flutter_test1',
      'test',
      'project',
    );
    var ensureCreated = false;
    var shell = Shell(workingDirectory: dir);
    Future<void> createProject() async {
      await flutterCreateProject(path: dir);
      await shell.run('flutter config');
    }

    Future<void> ensureCreate() async {
      if (!ensureCreated) {
        if (!Directory(dir).existsSync()) {
          await createProject();
        }
        ensureCreated = true;
      }
    }

    Future<void> iosBuild() async {
      if (buildSupportsIOS) {
        await shell.run('flutter build ios --release --no-codesign');
      }
    }

    Future<void> androidBuild() async {
      if (buildSupportsAndroid) {
        await shell.run('flutter build apk');
      }
    }

    Future<void> runCi() async {
      // Allow failure
      try {
        await packageRunCi(dir);
      } catch (e) {
        stderr.writeln('run_ci error $e');
      }
    }

    test('create', () async {
      await createProject();
    }, timeout: const Timeout(Duration(minutes: 5)));
    test('run_ci', () async {
      await ensureCreate();
      await runCi();
    }, timeout: const Timeout(Duration(minutes: 5)));

    test('build ios', () async {
      await ensureCreate();
      await iosBuild();
    }, timeout: const Timeout(Duration(minutes: 5)));

    test('build android', () async {
      await ensureCreate();
      await androidBuild();
    }, timeout: const Timeout(Duration(minutes: 10)));
    test('add sqflite', () async {
      await ensureCreate();
      if (await pathPubspecAddDependency(dir, 'sqflite')) {
        await iosBuild();
        await androidBuild();
        await runCi();
      }
    }, timeout: const Timeout(Duration(minutes: 15)));
  }, skip: !isFlutterSupportedSync);

  group('dart test', () {
    setUpAll(() async {
      await buildInitDart();
    });
    var dir = join(
      '.dart_tool',
      'dev_build',
      'raw_dart_test1',
      'test',
      'project',
    );
    var ensureCreated = false;
    var shell = Shell(workingDirectory: dir);
    Future<void> create() async {
      await dartCreateProject(path: dir);
    }

    Future<void> ensureCreate() async {
      if (!ensureCreated) {
        if (!Directory(dir).existsSync()) {
          await create();
        }
        ensureCreated = true;
      }
    }

    Future<void> runCi() async {
      // Don't allow failure
      try {
        await packageRunCi(dir);
      } catch (e) {
        stderr.writeln('run_ci error $e');
        rethrow;
      }
    }

    test('create', () async {
      await create();
    }, timeout: const Timeout(Duration(minutes: 5)));

    test('createOthers', () async {
      for (var template in [
        dartTemplateWeb,
        dartTemplateConsole,
        dartTemplatePackage,
      ]) {
        await dartCreateProject(path: dir, template: template);
      }
    }, timeout: const Timeout(Duration(minutes: 5)));
    test('run_ci', () async {
      await ensureCreate();
      await runCi();
    }, timeout: const Timeout(Duration(minutes: 5)));

    test(
      'add dev_build',
      () async {
        await ensureCreate();
        var readDependencyLines = await pathPubspecGetDependencyLines(
          dir,
          'dev_build',
        );
        if (readDependencyLines == ['dev_build:']) {
          return;
        }
        if (await pathPubspecAddDependency(dir, 'dev_build')) {
          expect(
            pubspecYamlHasAnyDependencies(await pathGetPubspecYamlMap(dir), [
              'dev_build',
            ]),
            isTrue,
          );
          await runCi();
        } else {
          expect(
            pubspecYamlHasAnyDependencies(await pathGetPubspecYamlMap(dir), [
              'dev_build',
            ]),
            isTrue,
          );
        }
      },
      skip: 'TODO Not a package yet',
      timeout: const Timeout(Duration(minutes: 10)),
    );

    test(
      'add dev_build_relative',
      () async {
        await ensureCreate();
        var dependencyLines = ['path: ${join('..', '..', '..', '..', '..')}'];

        var readDependencyLines = await pathPubspecGetDependencyLines(
          dir,
          'dev_build',
        );
        if (readDependencyLines == dependencyLines) {
          return;
        }
        if (await pathPubspecRemoveDependency(dir, 'dev_build')) {
          await shell.run('dart pub get');
        }
        expect(await pathPubspecGetDependencyLines(dir, 'dev_build'), isNull);
        expect(
          pubspecYamlHasAnyDependencies(await pathGetPubspecYamlMap(dir), [
            'dev_build',
          ]),
          isFalse,
        );
        if (await pathPubspecAddDependency(
          dir,
          'dev_build',
          dependencyLines: dependencyLines,
        )) {
          expect(
            await pathPubspecGetDependencyLines(dir, 'dev_build'),
            dependencyLines,
          );
          expect(
            pubspecYamlHasAnyDependencies(await pathGetPubspecYamlMap(dir), [
              'dev_build',
            ]),
            isTrue,
          );
          await runCi();
        } else {
          expect(
            await pathPubspecGetDependencyLines(dir, 'dev_build'),
            dependencyLines,
          );
          expect(
            pubspecYamlHasAnyDependencies(await pathGetPubspecYamlMap(dir), [
              'dev_build',
            ]),
            isTrue,
          );
        }
      },
      timeout: const Timeout(Duration(minutes: 10)),
      skip: 'Temp skip during nnbd migration',
    );
  });
}
