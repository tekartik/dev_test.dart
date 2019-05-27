library tekartik_dev_test.descriptions_test;

import 'dart:async';

import 'package:dev_test/test.dart';

void main() {
  // test descriptions
  group('sample', () {
    List<String> testDescriptionsInGroup = testDescriptions;

    print(testDescriptionsInGroup);
    setUp(() {
      print(testDescriptions);
      print(testDescriptionsInGroup);
      expect(testDescriptions, ['sample']);
      print(1);
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
  // test that concurrent test won't affect the testDescriptions
  group('multi', () {
    for (int i = 0; i < 100; i++) {
      test('test$i', () async {
        expect(testDescriptions, ['multi', 'test$i']);
        await Future.delayed(Duration(milliseconds: 5));
        expect(testDescriptions, ['multi', 'test$i']);
      });
    }
  });
}
