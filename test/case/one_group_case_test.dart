library tekartik_dev_test.test.one_group_case_test;

// Use src to avoid warning
import 'package:dev_test/src/test.dart';

main() {
  group('group', () {
    test('test', () {
      expect(true, isTrue);
    });
    skip_test('skipped_test', () {
      fail("should be skipped");
    });
  });
}
