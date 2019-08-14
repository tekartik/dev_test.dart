import 'dart:async';

import 'package:dev_test/test.dart';

void main() async {
  test('test1', () {
    expect(true, isTrue);
  });

  await Future.delayed(Duration());

  // this should fail running dart directly
  tearDownAll(() {
    fail("should not execute");
  });
}
