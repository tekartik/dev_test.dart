import 'dart:async';

import 'package:dev_test/test.dart';

void main() {
  // check the description after a 1ms delay
  Future _checkDelayedDescription() async {
    var descriptions = testDescriptions;
    await Future.delayed(const Duration(milliseconds: 1));
    expect(testDescriptions, descriptions);
  }

  group('group', () {
    setUp(() async {
      await _checkDelayedDescription();
    });
    // first test to make sure setUp is called

    test('test1', () async {
      await _checkDelayedDescription();
    });

    // add another test to make sure tearDown is called
    test('test2', () async {
      await _checkDelayedDescription();
    });
    tearDown(() async {
      await _checkDelayedDescription();
    });
  });
}
