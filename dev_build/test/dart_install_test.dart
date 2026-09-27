@TestOn('vm')
library;

import 'dart:io';

import 'package:dev_build/build_support.dart';
import 'package:dev_build/src/dart_install.dart'
    show
        getDartInstallBinDir,
        getInstalledCliPackageVersion,
        isCliPackageInstalled,
        parseDartInstalledOutLines;
import 'package:path/path.dart';
import 'package:process_run/shell.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:test/test.dart';

/// Run a command with the dart install bin dir in the path (not always the
/// case, i.e. on CI).
Future<void> runInstalled(String command) async {
  var env = ShellEnvironment()..paths.prepend(getDartInstallBinDir());
  await Shell(environment: env).run(command);
}

Future<void> main() async {
  group('dart install', () {
    test('uninstall then checkAndInstallCliWebdev', () async {
      await uninstallCliPackage('webdev', verbose: true);
      expect(await isCliPackageInstalled('webdev'), isFalse);
      await checkAndInstallCliWebdev(verbose: true);
      expect(await isCliPackageInstalled('webdev'), isTrue);
      expect(await getInstalledCliPackageVersion('webdev'), isNotNull);
      expect(
        File(
          join(
            getDartInstallBinDir(),
            Platform.isWindows ? 'webdev.bat' : 'webdev',
          ),
        ).existsSync(),
        isTrue,
      );
      await runInstalled('webdev --version');
    }, timeout: const Timeout(Duration(minutes: 5)));
    test('checkAndInstallCliWebdev verbose', () async {
      await checkAndInstallCliWebdev(verbose: true);
      await runInstalled('webdev --version');
    }, timeout: const Timeout(Duration(minutes: 5)));
    test('checkAndInstallCliWebdev silent', () async {
      await checkAndInstallCliWebdev();
    }, timeout: const Timeout(Duration(minutes: 5)));
    test('checkAndInstallCliPackage/uninstallCliPackage', () async {
      var package = 'process_run';
      var wasInstalled = await isCliPackageInstalled(package);
      try {
        await uninstallCliPackage(package);
        expect(await isCliPackageInstalled(package), isFalse);
        expect(await uninstallCliPackage(package), isFalse);

        expect(await checkAndInstallCliPackage(package), isTrue);
        expect(await isCliPackageInstalled(package), isTrue);
        expect(await checkAndInstallCliPackage(package), isFalse);

        expect(await uninstallCliPackage(package), isTrue);
        expect(await isCliPackageInstalled(package), isFalse);
      } finally {
        if (wasInstalled) {
          await checkAndInstallCliPackage(package);
        }
      }
    }, timeout: const Timeout(Duration(minutes: 5)));
    test('parseDartInstalledOutLines', () {
      expect(
        parseDartInstalledOutLines(['No Dart CLI tools installed.']),
        isEmpty,
      );
      expect(
        parseDartInstalledOutLines([
          'webdev 3.7.1',
          'my_package 0.1.0 from "/path/to/my_package/." at 2026-07-27 13:17:34.711576',
          'other_package 1.1.2 (not active)',
          '',
        ]),
        {'webdev': Version(3, 7, 1), 'my_package': Version(0, 1, 0)},
      );
    });
    test('getDartInstallBinDir', () {
      var dartDataHome = join('my', 'dart');
      expect(
        getDartInstallBinDir(environment: {'DART_DATA_HOME': dartDataHome}),
        join(dartDataHome, 'install', 'bin'),
      );
      expect(isAbsolute(getDartInstallBinDir()), isTrue);
    });
  });
}
