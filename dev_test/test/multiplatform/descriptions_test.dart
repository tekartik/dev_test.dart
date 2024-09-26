library;

import 'dart:async';

import 'package:dev_test/test.dart';

void main() {
  // test descriptions
  group('sample', () {
    final testDescriptionsInGroup = testDescriptions;

    setUp(() {
      expect(testDescriptions, ['sample']);
      expect(testDescriptionsInGroup, testDescriptions);
    });
    test('one', () async {
      expect(testDescriptions, ['sample', 'one']);
    });

    group('sub', () {
      final testDescriptionsInSub = testDescriptions;
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
    for (var i = 0; i < 100; i++) {
      test('test$i', () async {
        expect(testDescriptions, ['multi', 'test$i']);
        await Future<void>.delayed(const Duration(milliseconds: 5));
        expect(testDescriptions, ['multi', 'test$i']);
      });
    }
  });
}
