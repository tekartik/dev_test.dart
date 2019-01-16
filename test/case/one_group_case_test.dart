library tekartik_dev_test.test.one_group_case_test;

// Use src to avoid warning
import 'package:dev_test/test.dart';

void main() {
  group('group', () {
    test('test', () {
      expect(true, isTrue);
    });
    // ignore: deprecated_member_use
    skip_test('skipped_test', () {
      fail("should be skipped");
    });
  });
}
