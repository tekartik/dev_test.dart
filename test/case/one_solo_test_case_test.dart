// Use src to avoid warning
import 'package:dev_test/src/test.dart';

main() {
  test('test', () {
    fail("regular test should be skipped");
  });
  solo_test('solo_test', () {
    expect(true, isTrue);
  });
}
