import 'dart:async';

import 'package:dev_test/test.dart';

void main() async {
  test('test1', () {
    expect(true, isTrue);
  });

  await Future<void>.delayed(const Duration());

  // this should fail running dart directly
  setUpAll(() {
    fail('should not execute');
  });
}
