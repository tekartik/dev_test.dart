import 'package:test/test.dart';
import 'dart:async';

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
      });
    });
    test('test_in_null_group', () {
      expect(true, isTrue);
    });
  });
  group('', () {
    test('test_in_empty_group', () {
      expect(true, isTrue);
    });
  });
  test(null, () {
    expect(true, isTrue);
  });
  test('', () {
    expect(true, isTrue);
  });

  // delayed definition
  await new Future.delayed(new Duration(milliseconds: 1));

  group('delayed_group', () {
    test('test', () {
      // only called when using pub run test
      expect(true, isTrue);
    });
  });
}
