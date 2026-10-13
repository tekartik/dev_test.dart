@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';

import 'package:dev_build/src/node_support.dart';
import 'package:path/path.dart';
import 'package:process_run/shell.dart';
import 'package:test/test.dart';

var _topDir = join('.dart_tool', 'dev_build', 'test', 'run_ci_dry_run');

/// Create a package named [name] with a test folder.
Future<String> _createPackage(
  String name, {
  List<String> devDependencies = const [],
  String? dartTestYaml,
  Map<String, String> files = const {},
}) async {
  var path = join(_topDir, name);
  await Directory(path).create(recursive: true);
  await File(join(path, 'pubspec.yaml')).writeAsString('''
name: $name
environment:
  sdk: ^3.12.0
dev_dependencies:
  test: any
${devDependencies.map((dependency) => '  $dependency: any').join('\n')}
''');
  await File(join(path, 'test', 'a_test.dart')).create(recursive: true);
  if (dartTestYaml != null) {
    await File(join(path, 'dart_test.yaml')).writeAsString(dartTestYaml);
  }
  for (var entry in files.entries) {
    await File(
      join(path, entry.key),
    ).create(recursive: true).then((file) => file.writeAsString(entry.value));
  }
  return path;
}

/// Run `run_ci` in dry run mode on [path], returning the printed lines.
Future<String> _runCiDryRun(
  String path,
  String args, {
  Map<String, String>? environment,
}) async {
  var results =
      await Shell(
        verbose: false,
        environment: environment,
        includeParentEnvironment: environment == null,
      ).run(
        '${shellArgument(Platform.resolvedExecutable)} run'
        ' ${shellArgument(join('bin', 'run_ci.dart'))}'
        ' --dry-run --no-pub-get --no-recursive $args ${shellArgument(path)}',
      );
  return results.first.outText;
}

/// The `dart test` lines of [out].
List<String> _dartTestLines(String out) => LineSplitter.split(
  out,
).where((line) => line.startsWith(r'$ dart test')).toList();

void main() {
  var timeout = const Timeout(Duration(minutes: 2));
  group('run_ci dry run', () {
    test('chrome-js-test', () async {
      var path = await _createPackage(
        'chrome_js',
        devDependencies: ['build_web_compilers'],
      );
      // Only chrome, no vm.
      expect(_dartTestLines(await _runCiDryRun(path, '--chrome-js-test')), [
        r'$ dart test --platform chrome',
      ]);
    }, timeout: timeout);

    test('chrome-js-test dart2js only', () async {
      var path = await _createPackage(
        'chrome_js_compilers',
        devDependencies: ['build_web_compilers'],
        dartTestYaml: '''
platforms:
  - vm
  - chrome
compilers:
  - dart2js
  - dart2wasm
''',
      );
      expect(_dartTestLines(await _runCiDryRun(path, '--chrome-js-test')), [
        r'$ dart test --platform chrome --compiler dart2js',
      ]);
    }, timeout: timeout);

    group('node', () {
      late String path;
      setUpAll(() async {
        path = await _createPackage(
          'node_platform',
          dartTestYaml: '''
platforms:
  - vm
  - node
''',
        );
      });

      test('no-node-test', () async {
        expect(_dartTestLines(await _runCiDryRun(path, '--no-node-test')), [
          r'$ dart test --platform vm',
        ]);
      }, timeout: timeout);

      test('node not installed', () async {
        // Only the dart executable in the path and no user env paths.
        var userEnvFile = File(join(_topDir, 'empty_user_env.yaml'));
        await userEnvFile.writeAsString('');
        var environment = <String, String>{
          for (var key in ['HOME', 'PUB_CACHE', 'USERPROFILE', 'APPDATA'])
            if (Platform.environment[key] != null)
              key: Platform.environment[key]!,
          'PATH': dirname(Platform.resolvedExecutable),
          'TEKARTIK_PROCESS_RUN_USER_ENV_FILE_PATH': userEnvFile.absolute.path,
        };
        expect(
          _dartTestLines(
            await _runCiDryRun(path, '--test', environment: environment),
          ),
          [r'$ dart test --platform vm'],
        );
      }, timeout: timeout);
    });

    test('no npm install', () async {
      var path = await _createPackage(
        'npm_install',
        devDependencies: ['build_node_compilers'],
        files: {'package.json': '{}'},
      );
      var out = await _runCiDryRun(path, '--test');
      if (isNpmSupported && isNodeSupportedSync) {
        expect(out, contains(r'$ npm install'));
      }
      // Nothing installed.
      expect(Directory(join(path, 'node_modules')).existsSync(), isFalse);
      expect(File(join(path, 'package-lock.json')).existsSync(), isFalse);
    }, timeout: timeout);

    test('no webdev activation', () async {
      var path = await _createPackage(
        'webdev_build',
        devDependencies: ['build_runner', 'build_web_compilers'],
        files: {join('web', 'index.html'): '<html></html>'},
      );
      var out = await _runCiDryRun(path, '--build');
      // Displayed, not run.
      expect(out, contains('# Activate webdev if needed'));
      expect(out, contains(r'$ dart pub global activate webdev'));
      expect(out, contains(r'$ dart pub global run webdev build'));
    }, timeout: timeout);
  });
}
