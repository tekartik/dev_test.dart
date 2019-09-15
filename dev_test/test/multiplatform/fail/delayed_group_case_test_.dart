import 'dart:async';

import 'package:dev_test/test.dart';

void main() async {
  test('test1', () {
    expect(true, isTrue);
  });

  await Future.delayed(const Duration());

  // this should fail running dart directly
  group('group2', () {
    fail("should not execute");
  });
}
