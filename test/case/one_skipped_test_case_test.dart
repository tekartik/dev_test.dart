// Use src to avoid warning
import 'package:dev_test/test.dart';

void main() {
  // ignore: deprecated_member_use, deprecated_member_use_from_same_package
  skip_test('skipped_test', () {
    fail("should be skipped");
  });
  test('test', () {
    expect(true, isTrue);
  });
}
