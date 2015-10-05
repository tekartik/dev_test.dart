import 'package:dev_test/test.dart';

main() {
  group('first_group', () {
    test('test', () {
      fail("test in regular group should be skipped");
    });
  });

  group('group', () {
    test('test', () {
      fail("regular test should be skipped");
    });
    solo_test('solo_test', () {
      expect(true, isTrue);
    });
  });

  group('other_group', () {
    test('test', () {
      fail("test in regular group should be skipped");
    });
  });
}
