@TestOn('vm')
library dev_test.test.package_test;

import 'dart:io';

import 'package:dev_test/package.dart';
import 'package:dev_test/src/build_support.dart';
import 'package:dev_test/src/mixin/package.dart';
import 'package:dev_test/src/package/recursive_pub_path.dart';
import 'package:dev_test/src/run_ci.dart';
import 'package:dev_test/test.dart';
import 'package:path/path.dart';
import 'package:process_run/cmd_run.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:yaml/yaml.dart';

void main() {
  group('package', () {
    test('pubspec', () async {
      var pubspecMap = await pathGetPubspecYamlMap('.');
      expect(
          pubspecYamlHasAnyDependencies(pubspecMap, ['build_node_compilers']),
          isFalse);
      expect(pubspecYamlHasAnyDependencies(pubspecMap, ['build_web_compilers']),
          isTrue);
      expect(pubspecYamlHasAnyDependencies(pubspecMap, ['lints']), isTrue);
      expect(pubspecYamlSupportsFlutter(pubspecMap), isFalse);
      expect(pubspecYamlSupportsWeb(pubspecMap), isTrue);
      expect(pubspecYamlSupportsNode(pubspecMap), isFalse);
    });

    Map<String, Object?>? parseMap(String text) {
      return (loadYaml(text) as Map?)?.cast<String, Object?>();
    }

    test('pubspec supports', () {
      var pubspecMap = parseMap('''
dependencies:
  flutter:
      ''')!;
      expect(pubspecYamlSupportsFlutter(pubspecMap), isTrue);
      expect(pubspecYamlSupportsWeb(pubspecMap), isFalse);
      expect(pubspecYamlSupportsNode(pubspecMap), isFalse);

      pubspecMap = parseMap('''
dev_dependencies:
  build_web_compilers:
      ''')!;
      expect(pubspecYamlSupportsFlutter(pubspecMap), isFalse);
      expect(pubspecYamlSupportsWeb(pubspecMap), isTrue);
      expect(pubspecYamlSupportsNode(pubspecMap), isFalse);

      pubspecMap = parseMap('''
dev_dependencies:
  build_node_compilers:
      ''')!;
      expect(pubspecYamlSupportsFlutter(pubspecMap), isFalse);
      expect(pubspecYamlSupportsWeb(pubspecMap), isFalse);
      expect(pubspecYamlSupportsNode(pubspecMap), isTrue);
    });

    test('analysisOptions supports', () {
      var map = parseMap('');
      expect(analysisOptionsSupportsNnbdExperiment(map), isFalse);
      map = parseMap('''
analyzer:
  enable-experiment:
    - non-nullable
      ''');
      expect(analysisOptionsSupportsNnbdExperiment(map), isTrue);

      map = parseMap('''
analyzer:
  enable-experiment:
    - other
      ''');
      expect(analysisOptionsSupportsNnbdExperiment(map), isFalse);

      map = parseMap('''
analyzer:
  enable-experiment:
    other:
      ''');
      expect(analysisOptionsSupportsNnbdExperiment(map), isFalse);
    });

    test('boundaries', () {
      var map = parseMap('''
environment:
  sdk: '>=2.8.0 <3.0.0'
      ''');
      var boundaries = pubspecYamlGetSdkBoundaries(map)!;

      expect(boundaries.matches(Version(2, 8, 0)), isTrue);
      expect(boundaries.matchesMin(Version(2, 8, 0)), isTrue);
      expect(boundaries.matchesMax(Version(2, 8, 0)), isTrue);
      expect(boundaries.matches(Version(2, 9, 0)), isTrue);
      expect(boundaries.matchesMin(Version(2, 9, 0)), isTrue);
      expect(boundaries.matchesMax(Version(2, 9, 0)), isTrue);
      expect(boundaries.matches(Version(3, 0, 0)), isFalse);
      expect(boundaries.matchesMin(Version(3, 0, 0)), isTrue);
      expect(boundaries.matchesMax(Version(3, 0, 0)), isFalse);
      expect(boundaries.matchesMax(Version(2, 8, 0, pre: 'dev')), isTrue);
      expect(boundaries.matches(Version(2, 8, 0, pre: 'dev')), isFalse);
      expect(boundaries.matchesMin(Version(2, 8, 0, pre: 'dev')), isFalse);
      expect(boundaries.matchesMin(Version(3, 0, 0)), isTrue);

      expect(VersionBoundaries.parse('0.0.1').toString(), '0.0.1');
      expect(VersionBoundaries.parse('^0.0.1').toString(), '>=0.0.1 <0.0.2');
      expect(VersionBoundaries.parse('^0.1.2').toString(), '>=0.1.2 <0.2.0');
      expect(VersionBoundaries.parse('^1.2.3').toString(), '>=1.2.3 <2.0.0');

      boundaries = VersionBoundaries.parse('>1.0.0');
      expect(boundaries.matches(Version(1, 1, 0)), isTrue);
      expect(boundaries.matches(Version(2, 1, 0)), isTrue);
      expect(boundaries.matches(Version(1, 0, 0)), isFalse);
      boundaries = VersionBoundaries.parse('<=3.0.0');
      expect(boundaries.matches(Version(3, 0, 0)), isTrue);
      expect(boundaries.matches(Version(3, 0, 1)), isFalse);

      expect(VersionBoundaries.tryParse(''), VersionBoundaries(null, null));
      expect(
          VersionBoundaries.tryParse('dummy'), VersionBoundaries(null, null));
    });

    test('pubspecYamlHasAnyDependencies', () {
      expect(
          pubspecYamlHasAnyDependencies({
            'dependencies': {'test': '>=1'}
          }, [
            'test'
          ]),
          isTrue);
      expect(
          pubspecYamlHasAnyDependencies({
            'dependencies': {'test': '>=1'}
          }, [
            'other_test'
          ]),
          isFalse);
      expect(
          pubspecYamlHasAnyDependencies({
            'dependencies': {'test': null}
          }, [
            'test'
          ]),
          isTrue);
      expect(
          pubspecYamlHasAnyDependencies({
            'dev_dependencies': {'test': '>=1'}
          }, [
            'test'
          ]),
          isTrue);
      expect(
          pubspecYamlHasAnyDependencies({
            'dependency_overrides': {'test': '>=1'}
          }, [
            'test'
          ]),
          isTrue);
    });

    test('posixNormalize', () async {
      expect(posixNormalize('.'), '.');
      expect(posixNormalize('..'), '..');
      expect(posixNormalize('.\\'), '.');
      expect(posixNormalize('..\\'), '..');
      expect(posixNormalize('.\\a'), 'a');
      expect(posixNormalize('./a'), 'a');
      expect(posixNormalize('..\\a'), '../a');
      expect(posixNormalize('../a'), '../a');
    });

    test('recursivePubPath', () async {
      var repoSupportEntry = join('..', 'repo_support');
      var devTestEntry = join('..', 'dev_test');
      expect(await recursivePubPath(['.', '..']), ['.', repoSupportEntry]);
      expect(await recursivePubPath(['..', '.']), ['.', repoSupportEntry]);
      expect(await recursivePubPath(['..']), [devTestEntry, repoSupportEntry]);

      expect(await recursivePubPath(['.']), ['.']);
    });

    test('recursivePubPath ignore build', () async {
      // Somehow on node, build contains pubspec.yaml at its root and should be ignored
      // try to reproduce here
      var outDir = join('.dart_tool', 'dev_test', 'test', 'recursive_test');
      var file = File(join(outDir, 'build', 'pubspec.yaml'));
      await file.parent.create(recursive: true);
      await file.writeAsString('name: dummy');

      expect(await recursivePubPath([outDir]), []);
    });

    test('check isPubPackageRoot', () async {
      // Check dart version boundaries
      var outDir =
          join('.dart_tool', 'dev_test', 'test', 'is_pub_package_root');
      var file = File(join(outDir, 'pubspec.yaml'));
      await file.parent.create(recursive: true);
      await file.writeAsString('''
      environment:
        sdk: '>=$dartVersion'
      ''');
      expect(await recursivePubPath([outDir]), [outDir]);

      await file.writeAsString('''
      environment:
        sdk: '>$dartVersion'
      ''');
      expect(await recursivePubPath([outDir]), []);

      await file.writeAsString('''
      environment:
        sdk: '<=$dartVersion'
      ''');
      expect(await recursivePubPath([outDir]), [outDir]);

      await file.writeAsString('''
      environment:
        sdk: '<$dartVersion'
      ''');
      expect(await recursivePubPath([outDir]), []);
    });

    test('filterTopLevelDartDirs', () async {
      expect(
          await filterTopLevelDartDirs(join('..', 'repo_support')), ['tool']);
      expect(await filterTopLevelDartDirs('.'),
          ['bin', 'example', 'lib', 'test', 'tool']);
    });

    test('recursiveActions', () async {
      var list = <String>[];
      await recursiveActions(['.'], action: (src) {
        list.add(src);
      });
      expect(list, ['.']);

      list = <String>[];
      await recursiveActions(['..'], action: (src) {
        list.add(src);
      });
      expect(list, [join('..', 'dev_test'), join('..', 'repo_support')]);
      list = <String>[];
      await recursiveActions(['.', '..'], action: (src) {
        list.add(src);
      });
      expect(list, ['.', join('..', 'repo_support')]);
    });

    test('packageRunCi', () async {
      await packageRunCi('..', noTest: true);
    });

    test('analyze no dart code', () async {
      // Somehow on node, build contains pubspec.yaml at its root and should be ignored
      // try to reproduce here
      var outDir =
          join('.dart_tool', 'dev_test', 'test', 'analyze_no_dart_code_test');
      var file = File(join(outDir, 'pubspec.yaml'));
      await file.parent.create(recursive: true);
      await file.writeAsString('''
name: no_dart_code
environment:
  sdk: '>=2.12.0 <3.0.0'
''');

      await packageRunCi(outDir,
          options: PackageRunCiOptions(analyzeOnly: true, offline: true));
    });
    test('analyze no flutter code', () async {
      // Somehow on node, build contains pubspec.yaml at its root and should be ignored
      // try to reproduce here
      var outDir = join('.dart_tool', 'dev_test', 'test',
          'analyze_no_flutter_code_test', 'sub');
      var file = File(join(outDir, 'pubspec.yaml'));
      await file.parent.create(recursive: true);
      await file.writeAsString('''
name: no_dart_code
environment:
  sdk: '>=2.12.0 <3.0.0'
dependencies:
  flutter:
    sdk: flutter
''');

      // Make it handles sub dir too
      await packageRunCi(dirname(outDir),
          options: PackageRunCiOptions(
              analyzeOnly: true,
              formatOnly: true,
              offline: true,
              recursive: true));
      await packageRunCi(outDir,
          options: PackageRunCiOptions(analyzeOnly: true, offline: true));
    });

    group('package_config.json', () {
      test('pathGetPackageConfigMap', () async {
        var map = await pathGetPackageConfigMap('.');
        var packages = packageConfigGetPackages(map);
        expect(packages, contains('process_run'));
        expect(packages, isNot(contains('sqflite')));
        var devTestPath =
            pathPackageConfigMapGetPackagePath('.', map, 'dev_test')!;
        expect(devTestPath, '.');
        var processRunPath =
            pathPackageConfigMapGetPackagePath('.', map, 'process_run')!;
        expect(processRunPath, contains('process_run'));
        var processRunPubspecYaml = await pathGetPubspecYamlMap(processRunPath);
        expect(processRunPubspecYaml['name'], 'process_run');
        expect(pathPackageConfigMapGetPackagePath('.', map, '_dummy'), isNull);

        expect(File(join(devTestPath, 'pubspec.yaml')).existsSync(), isTrue);
        expect(File(join(processRunPath, 'pubspec.yaml')).existsSync(), isTrue);
      });
    });
  });
}
