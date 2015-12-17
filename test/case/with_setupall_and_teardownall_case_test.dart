//@Skip("Currently hanging with test 0.12.5")
import 'package:dev_test/test.dart';

main() {
  //bool setUpCalled = false;
  bool setUpAllCalled = false;
  bool tearDownAllCalled = false;

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
}