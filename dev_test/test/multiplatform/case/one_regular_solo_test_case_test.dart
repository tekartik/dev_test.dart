// Use src to avoid warning
import 'package:dev_test/test.dart';

void main() {
  test('test', () {
    fail('regular test should be skipped');
  });
  test(
    'solo_test',
    () {
      expect(true, isTrue);
    },
    // ignore: deprecated_member_use, deprecated_member_use_from_same_package
    solo: true,
  );
}
