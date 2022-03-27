import 'package:dev_test/test.dart';
import 'package:test/test.dart' as test_impl;

void main() {
  test_impl.group('regular_group', () {
    test('dev_test', () {
      expect(true, isTrue);
    });

    test_impl.test('test', () {
      expect(true, isTrue);
    });
  });
}
