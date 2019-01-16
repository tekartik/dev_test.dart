import 'package:dev_test/test.dart';
import 'package:test/test.dart' as _test;

void main() {
  _test.group('regular_group', () {
    test('dev_test1', () {
      expect(true, isTrue);
    });
    _test.test('test1', () {
      expect(true, isTrue);
    });
  });

  _test.group('other_regular_group', () {
    test('dev_test2', () {
      expect(true, isTrue);
      // This is an unpredictable scenario
      // this test is only attached when devTestRun() is called
      // which is here in the next group...
    });
    _test.test('test2', () {
      expect(true, isTrue);
    });
  });

  _test.group('third_regular_group', () {
    test('dev_test3', () {
      expect(true, isTrue);
    });
    _test.test('test3', () {
      expect(true, isTrue);
    });
  });
}
