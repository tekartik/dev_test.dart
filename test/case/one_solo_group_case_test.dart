// Use src to avoid warning
import 'package:dev_test/src/test.dart';

main() {
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
