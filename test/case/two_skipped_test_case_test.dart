// Use src to avoid warning
import 'package:dev_test/test.dart';

void main() {
  // ignore: deprecated_member_use
  skip_test('skipped_test', () {
    fail("should be skipped");
  });
  test('test', () {
    expect(true, isTrue);
  });
  // ignore: deprecated_member_use
  skip_test('skipped_test2', () {
    fail("should be skipped");
  });
}
