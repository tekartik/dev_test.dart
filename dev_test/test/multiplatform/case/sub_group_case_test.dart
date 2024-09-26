library;

import 'package:dev_test/test.dart';

void main() {
  group('group', () {
    group('sub', () {
      test('test', () {
        expect(true, isTrue);
      });
    });
  });
}
