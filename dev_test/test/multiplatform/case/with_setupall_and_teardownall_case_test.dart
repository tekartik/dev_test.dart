//@Skip("Currently hanging with test 0.12.5")
import 'package:dev_test/test.dart';

void main() {
  //bool setUpCalled = false;
  var setUpAllCalled = false;
  var tearDownAllCalled = false;

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
