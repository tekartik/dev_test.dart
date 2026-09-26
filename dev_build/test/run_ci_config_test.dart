@TestOn('vm')
library;

import 'dart:io';

import 'package:dev_build/package.dart';
import 'package:dev_build/src/io/file_utils.dart';
import 'package:dev_build/src/run_ci_config.dart';
import 'package:path/path.dart';
import 'package:process_run/cmd_run.dart';
import 'package:test/test.dart';

void main() {
  group('RunCiConfig', () {
    test('fromYaml', () {
      var config = RunCiConfig.fromYaml('');
      expect(config.include, isNull);
      expect(config.exclude, isNull);
      config = RunCiConfig.fromYaml('''
include:
  - packages
exclude:
  - example
  - packages/legacy
''');
      expect(config.include, ['packages']);
      expect(config.exclude, ['example', 'packages/legacy']);
    });
    test('fromYaml invalid', () {
      expect(() => RunCiConfig.fromYaml('- example'), throwsFormatException);
      expect(
        () => RunCiConfig.fromYaml('exclude: example'),
        throwsFormatException,
      );
      expect(
        () => RunCiConfig.fromYaml('exclude:\n  - 1'),
        throwsFormatException,
      );
    });
  });

  group('runCiRecursivePubPath', () {
    var minPubspecYamlContent =
        'name: dummy\nenvironment:\n  sdk: ^$dartVersion';
    var outDir = join('.dart_tool', 'dev_build', 'test', 'run_ci_config_test');
    var packageA = join(outDir, 'packages', 'a');
    var packageB = join(outDir, 'packages', 'b');
    var exampleC = join(outDir, 'example', 'c');
    var exampleD = join(outDir, 'example', 'd');
    var otherE = join(outDir, 'other', 'e');
    var all = [outDir, exampleC, exampleD, otherE, packageA, packageB];

    Future<void> writeConfig(String dir, String content) async {
      await File(join(dir, runCiConfigFileName)).writeAsString(content);
    }

    Future<List<String>> list([String? dir]) =>
        runCiRecursivePubPath([dir ?? outDir]);

    setUp(() async {
      await Directory(outDir).prepare();
      for (var dir in [outDir, ...all]) {
        var file = File(join(dir, 'pubspec.yaml'));
        await file.parent.create(recursive: true);
        await file.writeAsString(minPubspecYamlContent);
      }
    });

    test('no config', () async {
      expect(await list(), all);
    });
    test('exclude', () async {
      await writeConfig(outDir, 'exclude:\n  - example');
      expect(await list(), [outDir, otherE, packageA, packageB]);
      // Only for run_ci
      expect(await recursivePubPath([outDir]), all);
      // The configs above explicit paths are ignored
      expect(await list(join(outDir, 'example')), [exampleC, exampleD]);
    });
    test('include', () async {
      await writeConfig(outDir, '''
include:
  - packages
  - example/c
exclude:
  - packages/b
''');
      expect(await list(), [outDir, exampleC, packageA]);
    });
    test('nested', () async {
      await writeConfig(outDir, 'exclude:\n  - other');
      await writeConfig(join(outDir, 'example'), 'exclude:\n  - d/');
      expect(await list(), [outDir, exampleC, packageA, packageB]);
    });
    test('exclude itself', () async {
      await writeConfig(join(outDir, 'example'), 'exclude:\n  - .');
      expect(await list(), [outDir, otherE, packageA, packageB]);
      expect(await list(join(outDir, 'example')), isEmpty);
      await writeConfig(packageA, 'exclude:\n  - .');
      expect(await list(), [outDir, otherE, packageB]);
      expect(await list(packageA), isEmpty);
    });
    test('include nothing', () async {
      await writeConfig(outDir, 'include: []');
      expect(await list(), [outDir]);
    });
    test('invalid', () async {
      await writeConfig(outDir, 'exclude: example');
      expect(list, throwsFormatException);
    });
  });
}
