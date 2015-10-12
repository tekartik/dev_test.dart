import 'package:dev_test/test.dart';

main() async {
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
  test('test', () {
    group('group_in_test', () {
      test('test', () {
        // only called when using pub run test
        expect(true, isTrue);
      });
    });
    test('sub_test', () {
      // only called when using pub run test
      expect(true, isTrue);
    });
    expect(true, isTrue);
  });
  group(null, () {
    group(null, () {
      test('test_in_null_group', () {
        expect(true, isTrue);
        expect(testDescriptions, ['test_in_null_group']);
      });
    });
    test('test_in_null_group', () {
      expect(true, isTrue);
      expect(testDescriptions, ['test_in_null_group']);
    });
  });
  group('', () {
    test('test_in_empty_group', () {
      expect(true, isTrue);
      expect(testDescriptions, ['', 'test_in_empty_group']);
    });
  });
  test(null, () {
    expect(true, isTrue);
    expect(testDescriptions, []);
  });
  test('', () {
    expect(true, isTrue);
    expect(testDescriptions, ['']);
  });
}
