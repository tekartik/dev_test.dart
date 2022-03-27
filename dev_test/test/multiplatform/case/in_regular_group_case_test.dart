import 'package:dev_test/test.dart';
import 'package:test/test.dart' as test_impl;

void main() {
  test_impl.group('regular_group', () {
    test('dev_test1', () {
      expect(true, isTrue);
    });
    test_impl.test('test1', () {
      expect(true, isTrue);
    });
  });

  test_impl.group('other_regular_group', () {
    test('dev_test2', () {
      expect(true, isTrue);
      // This is an unpredictable scenario
      // this test is only attached when devTestRun() is called
      // which is here in the next group...
    });
    test_impl.test('test2', () {
      expect(true, isTrue);
    });
  });

  test_impl.group('third_regular_group', () {
    test('dev_test3', () {
      expect(true, isTrue);
    });
    test_impl.test('test3', () {
      expect(true, isTrue);
    });
  });
}
