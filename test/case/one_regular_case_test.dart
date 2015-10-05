import 'package:test/test.dart';

main() {
  test('regular_test', () {
    expect(true, isTrue);
  });
  group('regular_group', () {
    setUp(() {
      // expect is allowed in setUp
      expect(true, isTrue);
    });
    test('test', () {
      expect(true, isTrue);
    });

    group('null', () {
      // somehow null is allowed for setUp, tearDown...
      tearDown(null);
      setUp(null);
    });
  });
}
