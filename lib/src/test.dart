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
library dev_test.src.test;

import 'package:test/test.dart' as _test;
export 'package:test/test.dart'
    hide test, group, setUp, tearDown, setUpAll, tearDownAll;
import 'declarer.dart';
import 'dart:async';

Declarer __declarer;
Declarer get _declarer {
  if (__declarer == null) {
    __declarer = DeclarerImpl();
    scheduleMicrotask(() {
      devTestRun();
    });
  }
  return __declarer;
}

set declarer(Declarer declarer) {
  assert(__declarer == null, "set declarer before the first test declaration");
  __declarer = declarer;
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
      solo: true);
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
      solo: true);
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
    bool solo = false,
    @deprecated bool devSkip,
    Map<String, dynamic> onPlatform}) {
  _declarer.test(description, body,
      testOn: testOn,
      timeout: timeout,
      skip: skip,
      onPlatform: onPlatform,
      solo: solo,
      devSkip: devSkip);
}

// overriding  [_test.group]
void group(String description, void body(),
    {String testOn,
    _test.Timeout timeout,
    skip,
    bool solo = false,
    @deprecated bool devSolo,
    @deprecated bool devSkip,
    Map<String, dynamic> onPlatform}) {
  _declarer.group(description, body,
      testOn: testOn,
      timeout: timeout,
      skip: skip,
      onPlatform: onPlatform,
      solo: solo,
      devSkip: devSkip);
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
    // We no longer run the tests
    // It is run during the
    // (__declarer as DeclarerImpl).run();
    // declarer is set back to null
    __declarer = null;
  }
}
