@TestOn('vm')
library;

import 'dart:io';

import 'package:dev_build/build_support.dart';
import 'package:dev_build/src/mixin/package.dart'
    show analysisOptionsSupportsNnbdExperiment;
//import 'package:dev_build/src/package/package.dart';
import 'package:path/path.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

void main() {
  group('package', () {
    test('pubspec', () async {
      var pubspecMap = await pathGetPubspecYamlMap('.');
      expect(pubspecYamlGetPackageName(pubspecMap), 'dev_build');
      expect(pubspecYamlGetVersion(pubspecMap), greaterThan(Version(1, 0, 0)));
      expect(
        pubspecYamlGetVersionOrNull(pubspecMap),
        pubspecYamlGetVersion(pubspecMap),
      );
      expect(
        pubspecYamlHasAnyDependencies(pubspecMap, ['build_node_compilers']),
        isFalse,
      );
      expect(
        pubspecYamlHasAnyDependencies(pubspecMap, ['build_web_compilers']),
        isFalse,
      );
      expect(pubspecYamlHasAnyDependencies(pubspecMap, ['lints']), isTrue);
      expect(pubspecYamlSupportsFlutter(pubspecMap), isFalse);
      expect(pubspecYamlSupportsWeb(pubspecMap), isFalse);
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
      expect(VersionBoundaries.parse('0.0.1').toMinMaxString(), '0.0.1');
      expect(VersionBoundaries.parse('0.0.1').toShortString(), '0.0.1');
      expect(VersionBoundaries.parse('^0.0.1').toString(), '^0.0.1');
      expect(VersionBoundaries.parse('^0.0.1').toShortString(), '^0.0.1');
      expect(
        VersionBoundaries.parse('^0.0.1').toMinMaxString(),
        '>=0.0.1 <0.0.2',
      );
      expect(VersionBoundaries.parse('^0.1.2').toString(), '^0.1.2');
      expect(
        VersionBoundaries.parse('^0.1.2').toMinMaxString(),
        '>=0.1.2 <0.2.0',
      );
      expect(VersionBoundaries.parse('^1.2.3').toString(), '^1.2.3');
      expect(
        VersionBoundaries.parse('^1.2.3').toMinMaxString(),
        '>=1.2.3 <2.0.0',
      );
      expect(VersionBoundaries.parse('^1.2.3-4').toString(), '^1.2.3-4');
      expect(
        VersionBoundaries.parse('^1.2.3-4').toMinMaxString(),
        '>=1.2.3-4 <2.0.0',
      );

      boundaries = VersionBoundaries.parse('>1.0.0');
      expect(boundaries.matches(Version(1, 1, 0)), isTrue);
      expect(boundaries.matches(Version(2, 1, 0)), isTrue);
      expect(boundaries.matches(Version(1, 0, 0)), isFalse);
      boundaries = VersionBoundaries.parse('<=3.0.0');
      expect(boundaries.matches(Version(3, 0, 0)), isTrue);
      expect(boundaries.matches(Version(3, 0, 1)), isFalse);

      expect(
        VersionBoundaries.tryParse(''),
        const VersionBoundaries(null, null),
      );
      expect(
        VersionBoundaries.tryParse('dummy'),
        const VersionBoundaries(null, null),
      );

      expect(const VersionBoundaries(null, null).toString(), '');
      expect(VersionBoundaries.parse('>=1.0.0').toYamlString(), "'>=1.0.0'");
      expect(VersionBoundaries.parse('1.0.0').toYamlString(), '1.0.0');
      expect(VersionBoundaries.parse('^1.0.0').toYamlString(), '^1.0.0');
      expect(
        VersionBoundaries.parse('>=1.0.0 <2.1.0').toYamlString(),
        "'>=1.0.0 <2.1.0'",
      );

      expect(
        VersionBoundaries.versions(
          Version(1, 1, 2),
          Version(1, 3, 2),
        ).toString(),
        '>=1.1.2 <1.3.2',
      );
      expect(
        VersionBoundaries.versions(
          Version(1, 1, 2),
          Version(2, 0, 0),
        ).toString(),
        '^1.1.2',
      );
      expect(
        VersionBoundaries.versions(Version(1, 1, 2), null).toString(),
        '>=1.1.2',
      );
      expect(
        VersionBoundaries.versions(null, Version(1, 1, 2)).toString(),
        '<1.1.2',
      );
      expect(
        Version(1, 0, 0).lowerBoundary,
        VersionBoundary(Version(1, 0, 0), true),
      );
      expect(
        Version(1, 0, 0).upperBoundary,
        VersionBoundary(Version(1, 0, 0), false),
      );
    });

    test('pubspecYamlHasAnyDependencies', () {
      expect(
        pubspecYamlHasAnyDependencies(
          {
            'dependencies': {'test': '>=1'},
          },
          ['test'],
        ),
        isTrue,
      );
      expect(
        pubspecYamlHasAnyDependencies(
          {
            'dependencies': {'test': '>=1'},
          },
          ['other_test'],
        ),
        isFalse,
      );
      expect(
        pubspecYamlHasAnyDependencies(
          {
            'dependencies': {'test': null},
          },
          ['test'],
        ),
        isTrue,
      );
      expect(
        pubspecYamlHasAnyDependencies(
          {
            'dev_dependencies': {'test': '>=1'},
          },
          ['test'],
        ),
        isTrue,
      );
      expect(
        pubspecYamlHasAnyDependencies(
          {
            'dependency_overrides': {'test': '>=1'},
          },
          ['test'],
        ),
        isTrue,
      );
      expect(
        pubspecYamlHasAnyDependencies(
          {
            'dependencies': {'test': null},
          },
          ['direct:test'],
        ),
        isTrue,
      );
      expect(
        pubspecYamlHasAnyDependencies(
          {
            'dev_dependencies': {'test': null},
          },
          ['direct:test', 'override:test'],
        ),
        isFalse,
      );
      expect(
        pubspecYamlHasAnyDependencies(
          {
            'dev_dependencies': {'test': null},
          },
          ['dev:test'],
        ),
        isTrue,
      );
      expect(
        pubspecYamlHasAnyDependencies(
          {
            'dependency_overrides': {'test': null},
          },
          ['override:test'],
        ),
        isTrue,
      );
    });

    test('pubspecYamlGetDependenciesPackageName', () {
      var yaml = <String, Object?>{
        'dependencies': {'test1': null},
        'dev_dependencies': {'test2': null},
        'dependency_overrides': {'test3': null},
      };
      var deps = pubspecYamlGetDependenciesPackageName(yaml);

      /// Check non nullable
      expect(deps.length, 1);
      expect(deps, ['test1']);
      expect(
        pubspecYamlGetDependenciesPackageName(
          yaml,
          kind: PubDependencyKind.dev,
        ),
        ['test2'],
      );
      expect(
        pubspecYamlGetDependenciesPackageName(
          yaml,
          kind: PubDependencyKind.override,
        ),
        ['test3'],
      );
      yaml = {
        'dependencies': 'dummy',
        'dev_dependencies': ['dummy'],
      };
      expect(pubspecYamlGetDependenciesPackageName(yaml), isEmpty);
      expect(
        pubspecYamlGetDependenciesPackageName(
          yaml,
          kind: PubDependencyKind.dev,
        ),
        isEmpty,
      );
      expect(
        pubspecYamlGetDependenciesPackageName(
          yaml,
          kind: PubDependencyKind.dev,
        ),
        isEmpty,
      );
    });

    group('package_config.json', () {
      test('pathGetPackageConfigMap', () async {
        var map = await pathGetPackageConfigMap('.');
        var packages = packageConfigGetPackages(map);
        expect(packages, contains('process_run'));
        expect(packages, isNot(contains('sqflite')));
        var devTestPath = pathPackageConfigMapGetPackagePath(
          '.',
          map,
          'dev_build',
        )!;
        var devTestPath2 = await pathGetResolvedPackagePath('.', 'dev_build');

        expect(devTestPath, normalize(absolute('.')));
        expect(devTestPath2, normalize(absolute('.')));
        var processRunPath = pathPackageConfigMapGetPackagePath(
          '.',
          map,
          'process_run',
        )!;
        var processRunPath2 = await pathGetResolvedPackagePath(
          '.',
          'process_run',
        );
        expect(processRunPath, contains('process_run'));
        expect(processRunPath2, contains('process_run'));
        var processRunPubspecYaml = await pathGetPubspecYamlMap(processRunPath);
        expect(processRunPubspecYaml['name'], 'process_run');
        expect(pathPackageConfigMapGetPackagePath('.', map, '_dummy'), isNull);

        expect(File(join(devTestPath, 'pubspec.yaml')).existsSync(), isTrue);
        expect(File(join(processRunPath, 'pubspec.yaml')).existsSync(), isTrue);
      });
    });
  });
}
