import 'package:dev_test/test.dart';

main() {
  group('group', () {
    bool setUpCalled = false;
    setUp(() {
      expect(setUpCalled, isFalse);
      setUpCalled = true;
    });
    // first test to make sure setUp is called

    test('test1', () {
      expect(setUpCalled, isTrue);
    });

    // add another test to make sure tearDown is called
    test('test2', () {
      expect(setUpCalled, isTrue);
    });
    tearDown(() {
      expect(setUpCalled, isTrue);
      setUpCalled = false;
    });
  });
}
