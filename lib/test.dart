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

import 'package:test/test.dart' as _test;
export 'package:test/test.dart'
    hide test, group, setUp, tearDown, setUpAll, tearDownAll;
import 'src/test.dart' as _impl;

///
/// return the current description int the following form: ['group', 'sub_group', 'test']
/// Work also in setUp and tearDown callback but no
///
List<String> get testDescriptions => _impl.testDescriptions;

///
/// Run the test solo temporarily
/// mark as deprecated so that you don't checkin such code
///
@deprecated
void solo_test(String description, body(),
    {String testOn,
    _test.Timeout timeout,
    skip,
    Map<String, dynamic> onPlatform}) {
  _impl.solo_test(description, body,
      testOn: testOn, timeout: timeout, skip: skip, onPlatform: onPlatform);
}

///
/// Run the group solo temporarily
/// mark as deprecated so that you don't checkin such code
///
@deprecated
void solo_group(String description, void body(),
    {String testOn,
    _test.Timeout timeout,
    skip,
    Map<String, dynamic> onPlatform}) {
  _impl.solo_group(description, body,
      testOn: testOn, timeout: timeout, skip: skip, onPlatform: onPlatform);
}

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
    Map<String, dynamic> onPlatform}) {
  _impl.skip_test(description, body,
      testOn: testOn, timeout: timeout, skip: skip, onPlatform: onPlatform);
}

///
/// Skip the group temporarily
/// mark as deprecated so that you don't checkin such code
/// to permanently skip a group use the skip paremeter
///
@deprecated
void skip_group(String description, void body(),
    {String testOn,
    _test.Timeout timeout,
    skip,
    Map<String, dynamic> onPlatform}) {
  _impl.skip_group(description, body,
      testOn: testOn, timeout: timeout, skip: skip, onPlatform: onPlatform);
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
  _impl.test(description, body,
      testOn: testOn, timeout: timeout, skip: skip, onPlatform: onPlatform);
}

// overriding  [_test.group]
void group(String description, void body(),
    {String testOn,
    _test.Timeout timeout,
    skip,
    Map<String, dynamic> onPlatform}) {
  _impl.group(description, body,
      testOn: testOn, timeout: timeout, skip: skip, onPlatform: onPlatform);
}

// overriding  [_test.setUp]
void setUp(callback()) {
  _impl.setUp(callback);
}

// overriding  [_test.tearDown]
void tearDown(callback()) {
  _impl.tearDown(callback);
}

// overriding  [_test.setUp]
void setUpAll(callback()) {
  _impl.setUpAll(callback);
}

// overriding  [_test.tearDown]
void tearDownAll(callback()) {
  _impl.tearDownAll(callback);
}

///
/// Add to force running the declarer before the scheduled microtask
/// This is needed if you have dev_test test/group inside regular test/group
/// Otherwise they will be run in a seperate group
///
devTestRun() => _impl.devTestRun();
