// Use src to avoid warning
import 'package:dev_test/test.dart';

void main() {
  test('test', () {
    fail("regular test should be skipped");
  });
  // ignore: deprecated_member_use
  solo_test('solo_test', () {
    expect(true, isTrue);
  });
}
