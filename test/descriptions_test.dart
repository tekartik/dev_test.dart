library tekartik_dev_test.descriptions_test;

import 'package:dev_test/test.dart';

void main() {
  // test descriptions
  group('sample', () {
    List<String> testDescriptionsInGroup = testDescriptions;

    setUp(() {
      expect(testDescriptions, ['sample']);
      expect(testDescriptionsInGroup, testDescriptions);
    });
    test('one', () async {
      expect(testDescriptions, ['sample', 'one']);
    });

    group('sub', () {
      List<String> testDescriptionsInSub = testDescriptions;
      setUp(() {
        expect(testDescriptions, ['sample', 'sub']);
        expect(testDescriptionsInSub, testDescriptions);
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
