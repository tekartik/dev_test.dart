// Use src to avoid warning
import 'package:dev_test/test.dart';

void main() {
  group(
    'solo_group',
    () {
      test('test', () {
        expect(true, isTrue);
      });
    },
    skip: false,
    // ignore: deprecated_member_use, deprecated_member_use_from_same_package
    solo: true,
  );
  group('group', () {
    test('test', () {
      fail('regular test should be skipped');
    });
  });
}
