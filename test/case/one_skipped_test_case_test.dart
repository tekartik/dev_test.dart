import 'package:dev_test/test.dart';

main() {
  skip_test('skipped_test', () {
    fail("should be skipped");
  });
  test('test', () {
    expect(true, isTrue);
  });
}
