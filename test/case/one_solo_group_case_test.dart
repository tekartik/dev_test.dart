import 'package:dev_test/test.dart';

main() {
  solo_group('solo_group', () {
    test('test', () {
      expect(true, isTrue);
    });
  });
  group('group', () {
    test('test', () {
      fail("regular test should be skipped");
    });
  });
}
