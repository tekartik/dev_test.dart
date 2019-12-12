import 'package:dev_test/test.dart';

void main() {
  var setUpAllCalled = false;
  var tearDownAllCalled = false;

  setUpAll(() {
    expect(setUpAllCalled, isFalse);
  });

  group('group', () {
    setUpAll(() {
      setUpAllCalled = true;
    });

    setUp(() {
      expect(setUpAllCalled, isTrue);
    });

    test('test1', () {
      expect(setUpAllCalled, isTrue);
      expect(tearDownAllCalled, isFalse);
    });

    test('test2', () {
      expect(setUpAllCalled, isTrue);
      expect(tearDownAllCalled, isFalse);
    });
    tearDown(() {
      expect(tearDownAllCalled, isFalse);
    });
    tearDownAll(() {
      // called only once
      expect(tearDownAllCalled, isFalse);
      tearDownAllCalled = true;
    });
  });

  tearDownAll(() {
    expect(setUpAllCalled, isTrue);
    expect(tearDownAllCalled, isTrue);
  });
}
