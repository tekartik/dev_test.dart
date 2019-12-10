// not flutter
import 'package:dev_test/src/dev_test.dart' show Test;
import 'package:test/test.dart' as _impl;
import 'package:test/test.dart' show Timeout;

class DartTest implements Test {
  @override
  void test(String description, dynamic Function() body,
      {String testOn,
      Timeout timeout,
      skip,
      @deprecated bool solo = false,
      Map<String, dynamic> onPlatform}) {
    _impl.test(description, body,
        testOn: testOn,
        timeout: timeout,
        skip: skip,
        onPlatform: onPlatform,
        // ignore: deprecated_member_use
        solo: solo);
  }

// overriding  [_test.group]
  @override
  void group(String description, void Function() body,
      {String testOn,
      Timeout timeout,
      skip,
      @deprecated bool solo = false,
      Map<String, dynamic> onPlatform}) {
    _impl.group(description, body,
        testOn: testOn,
        timeout: timeout,
        skip: skip,
        onPlatform: onPlatform,
        // ignore: deprecated_member_use
        solo: solo);
  }

// overriding  [_test.setUp]
  @override
  void setUp(Function() callback) {
    _impl.setUp(callback);
  }

// overriding  [_test.tearDown]
  @override
  void tearDown(Function() callback) {
    _impl.tearDown(callback);
  }

// overriding  [_test.setUp]
  @override
  void setUpAll(Function() callback) {
    _impl.setUpAll(callback);
  }

// overriding  [_test.tearDown]
  @override
  void tearDownAll(Function() callback) {
    _impl.tearDownAll(callback);
  }

  @override
  void expect(actual, matcher, {String reason, skip}) {
    _impl.expect(actual, matcher, reason: reason, skip: skip);
  }
}
