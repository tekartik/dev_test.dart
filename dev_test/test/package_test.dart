@TestOn('vm')
library dev_test.test.package_test;

import 'dart:io';

import 'package:dev_test/src/mixin/package.dart';
import 'package:dev_test/src/package/recursive_pub_path.dart';
import 'package:dev_test/src/run_ci.dart';
import 'package:dev_test/test.dart';
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
      expect(pubspecYamlHasAnyDependencies(pubspecMap, ['pedantic']), isTrue);
      expect(pubspecYamlSupportsFlutter(pubspecMap), isFalse);
      expect(pubspecYamlSupportsWeb(pubspecMap), isTrue);
      expect(pubspecYamlSupportsNode(pubspecMap), isFalse);
    });

    Map<String, dynamic>? parseMap(String text) {
      return (loadYaml(text) as Map?)?.cast<String, dynamic>();
    }

    test('pubspec supports', () {
      var pubspecMap = parseMap('''
dependencies:
  flutter:
      ''');
      expect(pubspecYamlSupportsFlutter(pubspecMap), isTrue);
      expect(pubspecYamlSupportsWeb(pubspecMap), isFalse);
      expect(pubspecYamlSupportsNode(pubspecMap), isFalse);

      pubspecMap = parseMap('''
dev_dependencies:
  build_web_compilers:
      ''');
      expect(pubspecYamlSupportsFlutter(pubspecMap), isFalse);
      expect(pubspecYamlSupportsWeb(pubspecMap), isTrue);
      expect(pubspecYamlSupportsNode(pubspecMap), isFalse);

      pubspecMap = parseMap('''
dev_dependencies:
  build_node_compilers:
      ''');
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
      expect(boundaries.match(Version(2, 8, 0)), isTrue);
      expect(boundaries.match(Version(2, 9, 0)), isTrue);
      expect(boundaries.match(Version(3, 0, 0)), isFalse);
      expect(boundaries.match(Version(2, 8, 0, pre: 'dev')), isFalse);

      expect(VersionBoundaries.tryParse('0.0.1').toString(), '0.0.1');
      expect(VersionBoundaries.tryParse('^0.0.1').toString(), '>=0.0.1 <0.0.2');
      expect(VersionBoundaries.tryParse('^0.1.2').toString(), '>=0.1.2 <0.2.0');
      expect(VersionBoundaries.tryParse('^1.2.3').toString(), '>=1.2.3 <2.0.0');

      boundaries = VersionBoundaries.tryParse('>1.0.0')!;
      expect(boundaries.match(Version(1, 1, 0)), isTrue);
      expect(boundaries.match(Version(2, 1, 0)), isTrue);
      expect(boundaries.match(Version(1, 0, 0)), isFalse);
      boundaries = VersionBoundaries.tryParse('<=3.0.0')!;
      expect(boundaries.match(Version(3, 0, 0)), isTrue);
      expect(boundaries.match(Version(3, 0, 1)), isFalse);
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
      expect(await recursivePubPath(['.', '..']), ['.', '..']);
      expect(await recursivePubPath(['..', '.']), ['.', '..']);
      expect(await recursivePubPath(['..']),
          ['..', Platform.isWindows ? '..\\dev_test' : '../dev_test']);

      expect(await recursivePubPath(['.']), ['.']);
    });

    test('filterTopLevelDartDirs', () async {
      expect(await filterTopLevelDartDirs('..'), ['tool']);
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
      expect(list, ['..', Platform.isWindows ? '..\\dev_test' : '../dev_test']);
      list = <String>[];
      await recursiveActions(['.', '..'], action: (src) {
        list.add(src);
      });
      expect(list, ['.', '..']);
    });
  });
}
