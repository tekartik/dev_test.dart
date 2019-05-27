// Copyright (c) 2017, alex. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

import 'package:dev_test/test.dart';

void main() {
  group('group', () {
    test('test', () {
      expect(true, isTrue);

      // testDescriptions helper. Can be used to generate a path or a test
      // specific context.
      expect(testDescriptions, ['group', 'test']);
    });
  });
}
