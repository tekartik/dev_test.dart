@TestOn('vm')
library;

import 'package:dev_build/package.dart';
import 'package:pub_semver/pub_semver.dart';

import 'package:test/test.dart';

void main() {
  group('global_package', () {
    test('hosted', () {
      // pub global activate markdown
      final line = 'markdown 0.9.0';
      var package =
          PubGlobalPackage.fromListLine(line) as PubGlobalHostedPackage;
      expect(package.name, 'markdown');
      expect(package.version, Version(0, 9, 0));
      expect(package.activateArgs, ['markdown']);

      final activatedLine = 'Activated markdown 0.10.0.';
      package =
          PubGlobalPackage.fromActivatedLine(activatedLine, package.name)
              as PubGlobalHostedPackage;
      expect(package.name, 'markdown');
      expect(package.version, Version(0, 10, 0));
      expect(package.activateArgs, ['markdown']);

      expect(
        PubGlobalPackage.fromActivatedLine(activatedLine, 'dummy'),
        isNull,
      );
    });
    test('hosted install', () {
      var package = PubGlobalHostedPackageInstall(
        'test',
        versionBoundaries: VersionBoundaries.versions(
          Version(1, 0, 0),
          Version(2, 1, 0),
        ),
      );
      expect(package.activateArgs, ['test', '>=1.0.0 <2.1.0']);
    });

    test('git', () {
      // pub global activate --source git https://github.com/tekartik/pubglobalupdate.dart
      final line =
          "my_script 0.1.0 from Git repository 'https://github.com/tekartik/my_script.dart'";
      final package =
          PubGlobalPackage.fromListLine(line) as PubGlobalGitPackage;
      expect(package.name, 'my_script');
      expect(package.version, greaterThanOrEqualTo(Version(0, 1, 0)));
      expect(package.source, 'https://github.com/tekartik/my_script.dart');
      expect(package.activateArgs, [
        '--source',
        'git',
        'https://github.com/tekartik/my_script.dart',
      ]);
    });
    test('git install', () {
      var gitUrl = 'https://github.com/tekartik/my_script.dart';
      var gitPath = 'packages/my_package';
      var gitRef = 'main';
      var package = PubGlobalGitPackageInstall('my_script', gitUrl: gitUrl);

      expect(package.activateArgs, ['--source', 'git', gitUrl]);
      package = PubGlobalGitPackageInstall(
        'my_script',
        gitUrl: gitUrl,
        gitPath: gitPath,
      );
      expect(package.activateArgs, [
        '--source',
        'git',
        gitUrl,
        '--git-path',
        gitPath,
      ]);
      package = PubGlobalGitPackageInstall(
        'my_script',
        gitUrl: gitUrl,
        gitRef: gitRef,
      );
      expect(package.activateArgs, [
        '--source',
        'git',
        gitUrl,
        '--git-ref',
        gitRef,
      ]);
      package = PubGlobalGitPackageInstall(
        'my_script',
        gitUrl: gitUrl,
        gitPath: gitPath,
        gitRef: gitRef,
      );
      expect(package.activateArgs, [
        '--source',
        'git',
        gitUrl,
        '--git-path',
        gitPath,
        '--git-ref',
        gitRef,
      ]);
    });
    test('path', () {
      // pub global activate --source path /media/ssd/devx/git/bitbucket.org/alextk/script.dart
      final line = 'my_script 0.1.0 at path "/my_path/my_script.dart"';
      final package =
          PubGlobalPackage.fromListLine(line) as PubGlobalPathPackage;
      expect(package.name, 'my_script');
      expect(package.version, greaterThanOrEqualTo(Version(0, 1, 0)));
      expect(package.source, '/my_path/my_script.dart');
      expect(package.activateArgs, [
        '--source',
        'path',
        '/my_path/my_script.dart',
      ]);
    });

    test('path install', () {
      var package = PubGlobalPathPackageInstall('my_script', path: '/my_path');
      expect(package.name, 'my_script');
      expect(package.source, '/my_path');
      expect(package.activateArgs, ['--source', 'path', '/my_path']);
    });
  });
}
