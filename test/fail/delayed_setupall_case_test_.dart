import 'package:dev_test/test.dart';
import 'dart:async';

main() async {
  test('test1', () {
    expect(true, isTrue);
  });

  await Future.delayed(Duration());

  // this should fail running dart directly
  setUpAll(() {
    fail("should not execute");
  });
}
