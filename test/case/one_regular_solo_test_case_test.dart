// Use src to avoid warning
import 'package:dev_test/test.dart';

main() {
  test('test', () {
    fail("regular test should be skipped");
  });
  test('solo_test', () {
    expect(true, isTrue);
  },
      // ignore: deprecated_member_use
      solo: true);
}
