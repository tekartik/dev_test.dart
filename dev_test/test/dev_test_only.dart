import 'package:dev_test/test.dart';

void main() {
  test('simple', () {
    expect('test', isA<String>());
    expect(() => fail('test'), throwsA(isA<TestFailure>()));
  });
}
