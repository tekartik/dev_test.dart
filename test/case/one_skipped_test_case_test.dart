// Use src to avoid warning
import 'package:dev_test/src/test.dart';

main() {
  skip_test('skipped_test', () {
    fail("should be skipped");
  });
  test('test', () {
    expect(true, isTrue);
  });
}
