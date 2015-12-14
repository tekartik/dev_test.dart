///
/// Acts as a global replacement for the test package to add (back) the solo and skip feature
///
/// # Usage
///
/// In your code replace
///
///     import 'package:test/test.dart';
///
/// with
///
///     import 'package:dev_test/test.dart';
///
/// solo_test, solo_group, skip_test, skip_group are marked as deprecated so that you don't commit code that
/// might skip many needed tests
///
library tekartik_dev_test.test;

import 'package:test/test.dart' as _test;
export 'package:test/test.dart'
    hide test, solo_test, skip_test, group, solo_group, skip_group, setUp, tearDown, setUpAll, tearDownAll;
import 'declarer.dart';
import 'dart:async';

Declarer __declarer;
Declarer get _declarer {
  if (__declarer == null) {
    __declarer = new Declarer();
    scheduleMicrotask(() {
      devTestRun();
    });
  }
  return __declarer;
}

///
/// return the current description int the following form: ['group', 'sub_group', 'test']
/// Work also in setUp and tearDown callback but no
///
List<String> get testDescriptions => currentTestDescriptions;

///
/// Run the test solo temporarily
///
void solo_test(String description, body(),
    {String testOn,
    _test.Timeout timeout,
    skip,
    Map<String, dynamic> onPlatform}) {
  _declarer.test(description, body,
      testOn: testOn,
      timeout: timeout,
      skip: skip,
      onPlatform: onPlatform,
      devSolo: true);
}

///
/// Run the group solo temporarily
///
void solo_group(String description, void body(),
    {String testOn,
    _test.Timeout timeout,
    skip,
    Map<String, dynamic> onPlatform}) {
  _declarer.group(description, body,
      testOn: testOn,
      timeout: timeout,
      skip: skip,
      onPlatform: onPlatform,
      devSolo: true);
}

///
/// Skip the test temporarily
///
void skip_test(String description, body(),
    {String testOn,
    _test.Timeout timeout,
    skip,
    Map<String, dynamic> onPlatform}) {
  _declarer.test(description, body,
      testOn: testOn,
      timeout: timeout,
      skip: skip,
      onPlatform: onPlatform,
      devSkip: true);
}

///
/// Skip the group temporarily
///
void skip_group(String description, void body(),
    {String testOn,
    _test.Timeout timeout,
    skip,
    Map<String, dynamic> onPlatform}) {
  _declarer.group(description, body,
      testOn: testOn,
      timeout: timeout,
      skip: skip,
      onPlatform: onPlatform,
      devSkip: true);
}

//
// the base declarations
//

// overriding  [_test.test]
void test(String description, body(),
    {String testOn,
    _test.Timeout timeout,
    skip,
    Map<String, dynamic> onPlatform}) {
  _declarer.test(description, body,
      testOn: testOn, timeout: timeout, skip: skip, onPlatform: onPlatform);
}

// overriding  [_test.group]
void group(String description, void body(),
    {String testOn,
    _test.Timeout timeout,
    skip,
    Map<String, dynamic> onPlatform}) {
  _declarer.group(description, body,
      testOn: testOn, timeout: timeout, skip: skip, onPlatform: onPlatform);
}

// overriding  [_test.setUp]
void setUp(callback()) {
  _declarer.setUp(callback);
}

// overriding  [_test.tearDown]
void tearDown(callback()) {
  _declarer.tearDown(callback);
}

// overriding  [_test.setUp]
void setUpAll(callback()) {
  _declarer.setUpAll(callback);
}

// overriding  [_test.tearDown]
void tearDownAll(callback()) {
  _declarer.tearDownAll(callback);
}

///
/// Add to force running the declarer before the scheduled microtask
/// This is needed if you have dev_test test/group inside regular test/group
/// Otherwise they will be run in a seperate group
///
devTestRun() {
  if (__declarer != null) {
    __declarer.run();
    // declarer is set back to null
    __declarer = null;
  }
}
