import 'package:dev_test/test.dart';

void main() {
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
  });

  /*
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
  */

  group('', () {
    test('test_in_empty_group', () {
      expect(true, isTrue);
      expect(testDescriptions, ['', 'test_in_empty_group']);
    });
  });

  test('', () {
    expect(true, isTrue);
    expect(testDescriptions, ['']);
  });
}

/*
  //no longer working in test in sdk 1.13
  //was testing group in a test
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
  */
/*
  // no longer support 1.13, test name must not be null

  test(null, () {
    expect(true, isTrue);
    expect(testDescriptions, []);
  });
  */
