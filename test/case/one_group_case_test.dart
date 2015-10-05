library tekartik_dev_test.test.one_group_case_test;

import 'package:dev_test/test.dart';

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
