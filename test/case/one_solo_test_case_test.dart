import 'package:dev_test/test.dart';

main() {
  test('test', () {
    fail("regular test should be skipped");
  });
  solo_test('solo_test', () {
    expect(true, isTrue);
  });
}
