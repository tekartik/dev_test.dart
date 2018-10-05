// Use src to avoid warning
import 'package:dev_test/test.dart';

main() {
  // ignore: deprecated_member_use
  skip_test('skipped_test', () {
    fail("should be skipped");
  });
  test('test', () {
    expect(true, isTrue);
  });
}
