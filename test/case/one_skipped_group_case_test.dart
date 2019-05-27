// Use src to prevent warnings
import 'package:dev_test/test.dart';

void main() {
  // ignore: deprecated_member_use, deprecated_member_use_from_same_package
  skip_group('skipped_group', () {
    test('test', () {
      fail("regular test should be skipped");
    });
  });
  group('group', () {
    test('test', () {
      expect(true, isTrue);
    });
  });
}
