@TestOn('vm')
import 'dart:convert';

import 'package:dev_build/build_support.dart';
import 'package:dev_build/src/pub_global.dart'
    show
        deactivatePackage,
        extractWebdevVersionFromOutLines,
        isPackageActivated;
import 'package:process_run/shell.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:test/test.dart';

Future<void> main() async {
  group('pub global', () {
    test('deactivate then checkAndActivateWebdev', () async {
      if (await isPackageActivated('webdev', verbose: true)) {
        await deactivatePackage('webdev', verbose: true);
      }
      await checkAndActivateWebdev(verbose: true);
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
          extractWebdevVersionFromOutLines(lines.toList()), Version(3, 2, 0));
      lines = ['3.2.0'];

      expect(
          extractWebdevVersionFromOutLines(lines.toList()), Version(3, 2, 0));
    });
  });
}
