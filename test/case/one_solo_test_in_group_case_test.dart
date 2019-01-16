// Use src to avoid warning
import 'package:dev_test/test.dart';

void main() {
  group('first_group', () {
    test('test', () {
      fail("test in regular group should be skipped");
    });
  });

  group('group', () {
    test('test', () {
      fail("regular test should be skipped");
    });
    // ignore: deprecated_member_use
    solo_test('solo_test', () {
      expect(true, isTrue);
    });
  });

  group('other_group', () {
    test('test', () {
      fail("test in regular group should be skipped");
    });
  });
}
