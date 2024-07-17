@TestOn('vm')
library;

import 'package:process_run/shell.dart';
import 'package:test/test.dart';

void main() {
  test('run', () async {
    var shell = Shell();
    await shell.run('dart run test/dev_test_core_only_test.dart');
    await shell.run('dart run test/dev_test_only_test.dart');
    try {
      await shell.run('dart run test/dev_test_api_only_test.dart');
      fail('should fail');
    } catch (e) {
      expect(e, isNot(isA<TestFailure>()));
      // print(e);
    }
  });
}
