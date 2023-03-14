@TestOn('vm')
import 'package:dev_test/build_support.dart';
import 'package:dev_test/src/pub_global.dart'
    show isPackageActivated, deactivatePackage;
import 'package:process_run/shell.dart';
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
  });
}
