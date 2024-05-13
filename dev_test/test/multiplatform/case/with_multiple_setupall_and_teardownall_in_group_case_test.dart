@Skip('Currently hanging with test 0.12.5')
library;

import 'package:dev_test/test.dart';

void main() {
  var setUpAll1Called = false;
  var setUpAll2Called = false;
  var tearDownAll1Called = false;
  var tearDownAll2Called = false;

  setUpAll(() {
    expect(setUpAll1Called, isFalse);
    expect(setUpAll2Called, isFalse);
  });
  group('multiple', () {
    setUpAll(() {
      expect(setUpAll1Called, isFalse);
      setUpAll1Called = true;
    });

    setUpAll(() {
      expect(setUpAll2Called, isFalse);
      expect(setUpAll1Called, isTrue);
      setUpAll2Called = true;
    });

    test('test', () {
      expect(setUpAll1Called, isTrue);
      expect(setUpAll2Called, isTrue);
    });

    tearDownAll(() {
      // Weird this tearDown is called after the other one
      expect(tearDownAll1Called, isTrue);
      tearDownAll2Called = true;
    });

    tearDownAll(() {
      expect(tearDownAll1Called, isFalse);
      tearDownAll1Called = true;
    });
  });

  tearDownAll(() {
    expect(tearDownAll1Called, isTrue);
    expect(tearDownAll2Called, isTrue);
  });
}
