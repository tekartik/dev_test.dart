// not flutter
import 'package:dev_test/src/dev_test.dart' show Test;
import 'package:test/test.dart' as test_impl;
import 'package:test/test.dart' show Timeout;

class DartTest implements Test {
  @override
  void test(String description, dynamic Function() body,
      {String? testOn,
      Timeout? timeout,
      skip,
      @Deprecated('Dev only') bool solo = false,
      Map<String, Object?>? onPlatform}) {
    test_impl.test(description, body,
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
      {String? testOn,
      Timeout? timeout,
      skip,
      @Deprecated('Dev only') bool solo = false,
      Map<String, Object?>? onPlatform}) {
    test_impl.group(description, body,
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
    test_impl.setUp(callback);
  }

// overriding  [_test.tearDown]
  @override
  void tearDown(Function() callback) {
    test_impl.tearDown(callback);
  }

// overriding  [_test.setUp]
  @override
  void setUpAll(Function() callback) {
    test_impl.setUpAll(callback);
  }

// overriding  [_test.tearDown]
  @override
  void tearDownAll(Function() callback) {
    test_impl.tearDownAll(callback);
  }

  @override
  void expect(actual, matcher, {String? reason, skip}) {
    test_impl.expect(actual, matcher, reason: reason, skip: skip);
  }
}
