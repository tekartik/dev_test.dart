@TestOn('vm')
library dev_test.test.test_app_test;

import 'package:dev_test/dev_test.dart';
import 'package:process_run/dartbin.dart';

import 'test_app.dart';

export 'package:path/path.dart';

var topDir = '.dart_tool/dev_test/test_app/tool';

void main() {
  group('test_app', () {
    test('flutter', () async {
      var path = join(topDir, 'test_flutter_app');
      await flutterGenerateAndRunCi(path: path);
    }, skip: !isFlutterSupportedSync);
    test('io app', () async {
      var path = join(topDir, 'test_io_app');
      await generateAndRunCi(path: path, stagehandTemplate: 'console-simple');
    });
    test('web app', () async {
      var path = join(topDir, 'test_web_app');
      await generateAndRunCi(path: path, stagehandTemplate: 'web-simple');
    });
  });
}
