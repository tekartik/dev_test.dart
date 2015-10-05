import 'package:dev_test/test.dart';
import 'package:test/test.dart' as _test;

main() {
  _test.test('test', () {
    expect(true, isTrue);
  });
  test('dev_test', () {
    expect(true, isTrue);
  });
}
