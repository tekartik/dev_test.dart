@TestOn('vm')
library dev_test.test.test_app_test;

import 'package:dev_test/dev_test.dart';
import 'package:process_run/dartbin.dart';

import 'test_app.dart';

export 'package:path/path.dart';

var topDir = '.dart_tool/dev_test/test_app/tool';

void main() {
  group('test_app', () {
    test('flutter version', () async {
      print(await getFlutterBinVersion());
    }, skip: !isFlutterSupportedSync);
    test('flutter app', () async {
      var path = join(topDir, 'test_flutter_app');
      await flutterGenerateAndRunCi(
          path: path,
          template: 'app',
          // Temp issue in template!
          noAnalyze: true);
    },
        skip: !isFlutterSupportedSync,
        timeout: const Timeout(Duration(minutes: 5)));

    test('flutter package', () async {
      var path = join(topDir, 'test_flutter_package');
      await flutterGenerateAndRunCi(
        path: path,
        template: 'package',
      );
    },
        skip: !isFlutterSupportedSync,
        timeout: const Timeout(Duration(minutes: 5)));
    test('io app', () async {
      var path = join(topDir, 'test_io_app');
      await dartGenerateAndRunCi(path: path, template: 'console-simple');
    }, timeout: const Timeout(Duration(minutes: 5)));
    test('web app', () async {
      var path = join(topDir, 'test_web_app');
      await dartGenerateAndRunCi(path: path, template: 'web-simple');
    }, timeout: const Timeout(Duration(minutes: 5)));
    test('dart package', () async {
      var path = join(topDir, 'test_package');
      await dartGenerateAndRunCi(path: path, template: 'package-simple');
    }, timeout: const Timeout(Duration(minutes: 5)));
  });
}
