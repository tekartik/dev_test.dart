// Use src to prevent warnings
import 'package:dev_test/src/test.dart';

main() {
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
