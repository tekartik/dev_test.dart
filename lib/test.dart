///
/// Acts as a global replacement for the test package
///
/// # Usage
///
/// In your code replace
///
///     import 'package:test/test.dart';
/// with
///
///     import 'package:dev_test/test.dart';
///
library tekartik_dev_test.test;

import 'package:test/test.dart' as _test;
export 'package:test/test.dart' hide test, group, setUp, tearDown;

import 'src/declarer.dart';
import 'dart:async';

Declarer __declarer;
Declarer get _declarer {
  if (__declarer == null) {
    __declarer = new Declarer();
    scheduleMicrotask(() {
      __declarer.run();
    });
  }
  return __declarer;
}

///
/// return the current description int the following form: ['group', 'sub_group', 'test']
/// Work also in setUp and tearDown callback
///
List<String> get testDescriptions => _declarer.currentItem.descriptions;

///
/// Run the test solo temporarily
/// mark as deprecated so that you don't checkin such code
///
@deprecated
void solo_test(String description, body(),
        {String testOn,
        _test.Timeout timeout,
        skip,
        Map<String, dynamic> onPlatform}) =>
    _declarer.test(description, body,
        testOn: testOn,
        timeout: timeout,
        skip: skip,
        onPlatform: onPlatform,
        devSolo: true);

///
/// Run the group solo temporarily
/// mark as deprecated so that you don't checkin such code
///
void solo_group(String description, void body(),
        {String testOn,
        _test.Timeout timeout,
        skip,
        Map<String, dynamic> onPlatform}) =>
    _declarer.group(description, body,
        testOn: testOn,
        timeout: timeout,
        skip: skip,
        onPlatform: onPlatform,
        devSolo: true);

///
/// Skip the test temporarily
/// mark as deprecated so that you don't checkin such code
/// to permanently skip a test use the skip paremeter
///
@deprecated
void skip_test(String description, body(),
        {String testOn,
        _test.Timeout timeout,
        skip,
        Map<String, dynamic> onPlatform}) =>
    _declarer.test(description, body,
        testOn: testOn,
        timeout: timeout,
        skip: skip,
        onPlatform: onPlatform,
        devSkip: true);

//
// the base declarations
//

// overriding  [_test.test]
void test(String description, body(),
        {String testOn,
        _test.Timeout timeout,
        skip,
        Map<String, dynamic> onPlatform}) =>
    _declarer.test(description, body,
        testOn: testOn, timeout: timeout, skip: skip, onPlatform: onPlatform);

// overriding  [_test.group]
void group(String description, void body(),
        {String testOn,
        _test.Timeout timeout,
        skip,
        Map<String, dynamic> onPlatform}) =>
    _declarer.group(description, body,
        testOn: testOn, timeout: timeout, skip: skip, onPlatform: onPlatform);

// overriding  [_test.setUp]
void setUp(callback()) {
  _declarer.setUp(callback);
}

// overriding  [_test.tearDown]
void tearDown(callback()) {
  _declarer.tearDown(callback);
}
