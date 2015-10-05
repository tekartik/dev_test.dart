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

void test(String description, body(),
        {String testOn,
        _test.Timeout timeout,
        skip,
        Map<String, dynamic> onPlatform}) =>
    _declarer.test(description, body,
        testOn: testOn, timeout: timeout, skip: skip, onPlatform: onPlatform);

void group(String description, void body(),
        {String testOn,
        _test.Timeout timeout,
        skip,
        Map<String, dynamic> onPlatform}) =>
    _declarer.group(description, body,
        testOn: testOn, timeout: timeout, skip: skip, onPlatform: onPlatform);

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

void setUp(callback()) {
  _declarer.setUp(callback);
}

void tearDown(callback()) {
  _declarer.tearDown(callback);
}

/*

void group(String description, void body(),
           {String testOn,
           _test.Timeout timeout,
           skip,
           Map<String, dynamic> onPlatform}) =>
(new GroupDefinition()
  ..description = description
  ..body = body
  ..testOn = testOn
  ..timeout = timeout
  ..skip = skip
  ..onPlatform = onPlatform).add();

@deprecated
solo_test(String description, body(),
          {String testOn,
          _test.Timeout timeout,
          skip,
          Map<String, dynamic> onPlatform}) =>
(new TestDefinition()
  ..tmpSolo = true
  ..description = description
  ..body = body
  ..testOn = testOn
  ..timeout = timeout
  ..skip = skip
  ..onPlatform = onPlatform).add();

@deprecated
solo_group(String description, void body(),
           {String testOn,
           _test.Timeout timeout,
           skip,
           Map<String, dynamic> onPlatform}) =>
(new GroupDefinition()
  ..tmpSolo = true
  ..description = description
  ..body = body
  ..testOn = testOn
  ..timeout = timeout
  ..skip = skip
  ..onPlatform = onPlatform).add();

@deprecated
skip_test(String description, body(),
          {String testOn,
          _test.Timeout timeout,
          skip,
          Map<String, dynamic> onPlatform}) =>
(new TestDefinition()
  ..tmpSkip = true
  ..description = description
  ..body = body
  ..testOn = testOn
  ..timeout = timeout
  ..skip = skip
  ..onPlatform = onPlatform).add();

@deprecated
skip_group(String description, void body(),
           {String testOn,
           _test.Timeout timeout,
           skip,
           Map<String, dynamic> onPlatform}) =>
(new GroupDefinition()
  ..tmpSkip = true
  ..description = description
  ..body = body
  ..testOn = testOn
  ..timeout = timeout
  ..skip = "temporarily disabled" // always skip
  ..onPlatform = onPlatform).add();
*/
