// Copyright (c) 2017, alex. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

// Run with: dart run example/main_menu.dart
// or with typed lines first: dart run example/main_menu.dart 0 0 1 . .
import 'package:dev_test/dev_test_menu.dart';

void main(List<String> arguments) {
  mainDevTestMenu(() {
    group('group', () {
      setUp(() {
        // ignore: avoid_print
        print('setUp: $testDescriptions');
      });
      test('test', () {
        expect(true, isTrue);

        // testDescriptions helper. Can be used to generate a path or a test
        // specific context.
        expect(testDescriptions, ['group', 'test']);
      });
      test('expect fail', () {
        // Printed, the menu goes on.
        expect(true, isFalse);
      });
    });
  }, arguments: arguments);
}
