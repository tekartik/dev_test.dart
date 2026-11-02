import 'package:dev_build/build_support.dart';
import 'package:dev_build/src/dart_install.dart'
    show parseDartInstalledOutLines;
import 'package:pub_semver/pub_semver.dart';
import 'package:test/test.dart';

/// `dart installed --all` output (Dart 3.13), names changed.
const _dartInstalledAllOutput = '''
dev_build 1.1.9 (not active)
dev_build 1.1.12 (not active)
dev_build 1.1.16 (not active)
dev_build 1.1.15 (not active)
dev_build 1.1.10 (not active)
hooks_tool 1.0.0 from "/home/user/src/exp/hooks_tool/./." at 2026-10-29 00:08:54.143310
jaspr_cli 0.23.5
my_tools 1.0.154 from Git repository "git@github.com:example/tools.dart.git" at "4c7f13da"
adb_app 0.1.0 from "/home/user/src/android_tools/packages/adb_app/." at 2026-10-29 00:12:31.674960
fire_app 0.1.0+1 from "/home/user/src/tools_flutter/packages/fire_app/." at 2026-10-29 00:12:50.176024
agent_mcp 0.2.0 from Git repository "https://github.com/example/common_utils.dart" at "682da018"
console_test_app 1.0.0 from "/home/user/src/sqflite/packages/console_test_app/." at 2026-10-29 00:12:53.090340
dart_mcp_server 1.1.2 (not active)
dart_mcp_server 1.1.3 (not active)
dart_mcp_server 1.2.0 (not active)
dart_mcp_server 1.2.2 (not active)
dart_mcp_server 1.2.1 (not active)
dart_mcp_server 1.1.1 (not active)
skills 1.0.1 (not active)
pubviz 6.1.0 (not active)
cognitive_complexity 0.2.3+2 (not active)
global_tool 1.0.0 from "/home/user/src/exp/global_tool/." at 2026-10-29 00:12:54.891216
github_app 0.1.0+1 from "/home/user/src/tools_flutter/packages/github_app/." at 2026-10-29 00:13:11.141879
tools_app 1.0.0+1 from "/home/user/src/tools_flutter/packages/tools_app/." at 2026-10-29 00:13:44.774434
asset_app 0.1.0+1 from "/home/user/src/tools_flutter/packages/asset_app" at 2026-10-29 00:14:16.097824
webdev 4.0.3
ai_tool 0.1.0 from "/home/user/src/ai/ai_tool/." at 2026-10-29 00:14:50.122847
''';

void main() {
  group('DartInstalledCliPackage', () {
    test('hosted', () {
      var package = DartInstalledCliPackage.fromLine('webdev 4.0.3')!;
      expect(package.name, 'webdev');
      expect(package.version, Version(4, 0, 3));
      expect(package.source, DartInstalledCliPackage.sourceHosted);
      expect(package.active, isTrue);
      expect(package.sourceValue, isNull);
      expect(package.toString(), 'webdev 4.0.3');
    });
    test('git', () {
      var package = DartInstalledCliPackage.fromLine(
        'my_tools 1.0.154 from Git repository '
        '"git@github.com:example/tools.dart.git" at "4c7f13da"',
      )!;
      expect(package.name, 'my_tools');
      expect(package.version, Version(1, 0, 154));
      expect(package.source, DartInstalledCliPackage.sourceGit);
      expect(package.gitUrl, 'git@github.com:example/tools.dart.git');
      expect(package.gitRef, '4c7f13da');
      expect(package.active, isTrue);
      expect(
        package.toString(),
        'my_tools 1.0.154 git git@github.com:example/tools.dart.git',
      );
    });
    test('path', () {
      var package = DartInstalledCliPackage.fromLine(
        'hooks_tool 1.0.0 from "/home/user/src/exp/hooks_tool/./." '
        'at 2026-10-29 00:08:54.143310',
      )!;
      expect(package.source, DartInstalledCliPackage.sourcePath);
      expect(package.path, '/home/user/src/exp/hooks_tool/./.');
      expect(package.lastModified, '2026-10-29 00:08:54.143310');
      expect(package.active, isTrue);
    });
    test('not active', () {
      var package = DartInstalledCliPackage.fromLine(
        'cognitive_complexity 0.2.3+2 (not active)',
      )!;
      expect(package.version, Version(0, 2, 3, build: '2'));
      expect(package.source, DartInstalledCliPackage.sourceHosted);
      expect(package.status, 'not active');
      expect(package.active, isFalse);
      expect(package.toString(), 'cognitive_complexity 0.2.3+2 (not active)');
      // Parentheses in the path.
      var path = DartInstalledCliPackage.fromLine(
        'x 1.0.0 from "/p (1)" at 2026-09-28 17:06:49.116900 (not active)',
      )!;
      expect(path.path, '/p (1)');
      expect(path.active, isFalse);
    });
    test('unknown / invalid', () {
      expect(
        DartInstalledCliPackage.fromLine(
          'x 1.0.0 from an unknown source "sdk"',
        )!.source,
        DartInstalledCliPackage.sourceUnknown,
      );
      expect(DartInstalledCliPackage.fromLine(''), isNull);
      expect(
        DartInstalledCliPackage.fromLine('No Dart CLI tools installed.'),
        isNull,
      );
      expect(DartInstalledCliPackage.fromLine('x notaversion'), isNull);
      expect(DartInstalledCliPackage.fromLine('x 1.0.0 from nowhere'), isNull);
    });
    test('parseDartInstalledCliPackages', () {
      var packages = parseDartInstalledCliPackages(
        _dartInstalledAllOutput.split('\n'),
      );
      expect(packages, hasLength(27));
      var active = packages.where((package) => package.active).toList();
      expect(active.map((package) => package.name), [
        'hooks_tool',
        'jaspr_cli',
        'my_tools',
        'adb_app',
        'fire_app',
        'agent_mcp',
        'console_test_app',
        'global_tool',
        'github_app',
        'tools_app',
        'asset_app',
        'webdev',
        'ai_tool',
      ]);
      expect(
        packages
            .where((package) => package.name == 'dart_mcp_server')
            .map((package) => package.version.toString()),
        ['1.1.2', '1.1.3', '1.2.0', '1.2.2', '1.2.1', '1.1.1'],
      );
      Iterable<String> sourceNames(String source) => packages
          .where((package) => package.source == source)
          .map((package) => package.name);
      expect(sourceNames(DartInstalledCliPackage.sourceGit), [
        'my_tools',
        'agent_mcp',
      ]);
      expect(sourceNames(DartInstalledCliPackage.sourcePath), hasLength(9));
      expect(
        packages.firstWhere((package) => package.name == 'asset_app').path,
        '/home/user/src/tools_flutter/packages/asset_app',
      );

      // Active only, as the existing parser.
      expect(parseDartInstalledOutLines(_dartInstalledAllOutput.split('\n')), {
        for (var package in active) package.name: package.version,
      });
    });
  });
}
