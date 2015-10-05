library tekartik_dev_test.descriptions_test;

import 'package:dev_test/test.dart';

void main() {
  // test descriptions
  group('sample', () {
    setUp(() {
      expect(testDescriptions, ['sample']);
    });
    test('one', () async {
      expect(testDescriptions, ['sample', 'one']);
    });

    group('sub', () {
      setUp(() {
        expect(testDescriptions, ['sample', 'sub']);
      });
      test('two', () {
        expect(testDescriptions, ['sample', 'sub', 'two']);
      });
    });

    test('three', () {
      expect(testDescriptions, ['sample', 'three']);
    });
  });
}
