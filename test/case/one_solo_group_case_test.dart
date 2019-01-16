// Use src to avoid warning
import 'package:dev_test/test.dart';

void main() {
  // ignore: deprecated_member_use
  solo_group('solo_group', () {
    test('test', () {
      expect(true, isTrue);
    });
  });
  group('group', () {
    test('test', () {
      fail("regular test should be skipped");
    });
  });
}
