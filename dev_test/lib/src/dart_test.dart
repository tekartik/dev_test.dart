// not flutter
import 'package:dev_test/src/dev_test.dart' show Test;
import 'package:dev_test/src/import_test.dart' as test_impl;
import 'package:dev_test/src/import_test.dart' show Timeout;

/// Dart test implementation.
class DartTest implements Test {
  @override
  void test(
    String description,
    dynamic Function() body, {
    String? testOn,
    Timeout? timeout,
    skip,
    @Deprecated('Dev only') bool solo = false,
    Map<String, Object?>? onPlatform,
  }) {
    test_impl.test(
      description,
      body,
      testOn: testOn,
      timeout: timeout,
      skip: skip,
      onPlatform: onPlatform,
      // ignore: deprecated_member_use, invalid_use_of_do_not_submit_member
      solo: solo,
    );
  }

  // overriding  [_test.group]
  @override
  void group(
    String description,
    void Function() body, {
    String? testOn,
    Timeout? timeout,
    skip,
    @Deprecated('Dev only') bool solo = false,
    Map<String, Object?>? onPlatform,
  }) {
    test_impl.group(
      description,
      body,
      testOn: testOn,
      timeout: timeout,
      skip: skip,
      onPlatform: onPlatform,
      // ignore: deprecated_member_use, invalid_use_of_do_not_submit_member
      solo: solo,
    );
  }

  // overriding  [_test.setUp]
  @override
  void setUp(dynamic Function() callback) {
    test_impl.setUp(callback);
  }

  // overriding  [_test.tearDown]
  @override
  void tearDown(dynamic Function() callback) {
    test_impl.tearDown(callback);
  }

  // overriding  [_test.setUp]
  @override
  void setUpAll(dynamic Function() callback) {
    test_impl.setUpAll(callback);
  }

  // overriding  [_test.tearDown]
  @override
  void tearDownAll(dynamic Function() callback) {
    test_impl.tearDownAll(callback);
  }
}
