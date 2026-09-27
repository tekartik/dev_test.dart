@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:dev_build/build_support.dart';
import 'package:dev_build/src/pub_global.dart'
    show
        deactivatePackage,
        extractWebdevVersionFromOutLines,
        isPackageActivated;
import 'package:process_run/shell.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:test/test.dart';

/// Prefer dart install (see dart_install_test.dart).
var _runningOnGithub = Platform.environment['GITHUB_ACTIONS'] == 'true';

Future<void> main() async {
  group('pub global', () {
    test('deactivate then checkAndActivateWebdev', () async {
      if (await isPackageActivated('webdev', verbose: true)) {
        await deactivatePackage('webdev', verbose: true);
      }
      await checkAndActivateWebdev(verbose: true);
      await run('dart pub global run webdev --version');
    }, timeout: const Timeout(Duration(minutes: 5)));
    test('deactivate then concurrent checkAndActivateWebdev', () async {
      if (await isPackageActivated('webdev', verbose: true)) {
        await deactivatePackage('webdev', verbose: true);
      }
      // Isolates don't share the activated packages cache, like concurrent
      // test files or run_ci packages.
      var errors = await Future.wait([
        for (var i = 0; i < 3; i++)
          Isolate.run(() async {
            try {
              await checkAndActivateWebdev();
              return null;
            } catch (e) {
              // Shell exceptions are not sendable
              return '$e';
            }
          }),
      ]);
      expect(errors, [null, null, null]);
      await run('dart pub global run webdev --version');
    }, timeout: const Timeout(Duration(minutes: 5)));
    test('checkAndActivateWebdev verbose', () async {
      await checkAndActivateWebdev(verbose: true);
      await run('dart pub global run webdev --version');
    });
    test('checkAndActivateWebdev silent', () async {
      await checkAndActivateWebdev();
    });
    test('checkAndActivatePackage', () async {
      await checkAndActivatePackage('process_run');
    });
    test('extract', () {
      var lines = LineSplitter.split('''
Can't load Kernel binary: Invalid SDK hash.
Building package executable... (1.3s)
Built webdev:webdev.
3.2.0
''');
      expect(
        extractWebdevVersionFromOutLines(lines.toList()),
        Version(3, 2, 0),
      );
      lines = ['3.2.0'];

      expect(
        extractWebdevVersionFromOutLines(lines.toList()),
        Version(3, 2, 0),
      );
    });
  }, skip: _runningOnGithub ? 'Skipped on github, prefer dart install' : false);
}
