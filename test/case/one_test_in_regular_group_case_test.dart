import 'package:dev_test/test.dart';
import 'package:test/test.dart' as _test;

main() {
  _test.group('regular_group', () {
    test('dev_test', () {
      expect(true, isTrue);
    });

    _test.test('test', () {
      expect(true, isTrue);
    });
  });
}
