@TestOn('vm')
import 'package:dev_test/build_support.dart';
import 'package:process_run/shell.dart';
import 'package:test/test.dart';

Future<void> main() async {
  group('pub global', () {
    test('checkAndActivateWebdev verbose', () async {
      await run('dart pub global deactivate webdev');
      await checkAndActivateWebdev(verbose: true);
      await run('dart pub global run webdev --version');
    }, timeout: const Timeout(Duration(minutes: 5)));
    test('checkAndActivateWebdev silent', () async {
      await checkAndActivateWebdev();
    });
    test('checkAndActivatePackage', () async {
      await checkAndActivatePackage('process_run');
    });
  });
}
