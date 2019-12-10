import 'dart:async';

import 'package:test/test.dart';

Future main() async {
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
    try {
      group('group_in_test', () {
        test('test', () {
          // only called when using pub run test
          expect(true, isTrue);
        });
      });
      fail('should fail before');
    } on StateError catch (_) {
      // Bad state: Can't call group() once tests have begun running.
      // ignore error of calling group from within a test
    }
    try {
      test('sub_test', () {
        // only called when using pub run test
        expect(true, isTrue);
      });
      fail('should fail before');
    } on StateError catch (_) {
      // Bad state: Can't call test() once tests have begun running.
      // ignore error of calling group from within a test
    }
  });

  /*
  no more support with pub run test -n xxx
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
  */

  group('', () {
    test('test_in_empty_group', () {
      expect(true, isTrue);
    });
  });

  /*
  no more support with pub run test -n xxx
  test(null, () {
    expect(true, isTrue);
  });
  */

  test('', () {
    expect(true, isTrue);
  });
}
