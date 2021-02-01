import 'package:dev_test/src/dart_test.dart';
import 'package:dev_test/src/description_test.dart';
import 'package:test/test.dart' show Timeout;

// default implementation is a regular dart test
Test testImplementation = WithDescriptionsTest(DartTest());

List<String> get testDescriptions =>
    (testImplementation is WithTestDescriptions)
        ? (testImplementation as WithTestDescriptions).testDescriptions
        : ['dev_test'];

abstract class Test {
  void test(String description, Function() body,
      {String? testOn,
      Timeout? timeout,
      skip,
      bool solo = false,
      Map<String, dynamic>? onPlatform});

// overriding  [_test.group]
  void group(String description, void Function() body,
      {String? testOn,
      Timeout? timeout,
      skip,
      bool solo = false,
      Map<String, dynamic>? onPlatform});

// overriding  [_test.setUp]
  void setUp(Function() callback);

// overriding  [_test.tearDown]
  void tearDown(Function() callback);

// overriding  [_test.setUp]
  void setUpAll(Function() callback);

// overriding  [_test.tearDown]
  void tearDownAll(Function() callback);

  void expect(actual, matcher, {String? reason, skip});
}

abstract class WithTestDescriptions {
  List<String> get testDescriptions;
}

void test(String description, Function() body,
    {String? testOn,
    Timeout? timeout,
    skip,
    @deprecated bool solo = false,
    Map<String, dynamic>? onPlatform}) {
  testImplementation.test(description, body,
      testOn: testOn,
      timeout: timeout,
      skip: skip,
      onPlatform: onPlatform,
      // ignore: deprecated_member_use
      solo: solo);
}

// overriding  [_test.group]
void group(String description, void Function() body,
    {String? testOn,
    Timeout? timeout,
    skip,
    @deprecated bool solo = false,
    Map<String, dynamic>? onPlatform}) {
  testImplementation.group(description, body,
      testOn: testOn,
      timeout: timeout,
      skip: skip,
      onPlatform: onPlatform,
      solo: solo);
}

// overriding  [_test.setUp]
void setUp(Function() callback) {
  testImplementation.setUp(callback);
}

// overriding  [_test.tearDown]
void tearDown(Function() callback) {
  testImplementation.tearDown(callback);
}

// overriding  [_test.setUp]
void setUpAll(Function() callback) {
  testImplementation.setUpAll(callback);
}

// overriding  [_test.tearDown]
void tearDownAll(Function() callback) {
  testImplementation.tearDownAll(callback);
}

void expect(actual, matcher, {String? reason, skip}) {
  testImplementation.expect(actual, matcher, reason: reason, skip: skip);
}

// Add-ons

///
/// Run the test solo temporarily
/// mark as deprecated so that you don't checkin such code
///
@deprecated
void
// ignore: non_constant_identifier_names
    solo_test(String description, Function() body,
        {String? testOn,
        Timeout? timeout,
        skip,
        @deprecated bool solo = false,
        Map<String, dynamic>? onPlatform}) {
  testImplementation.test(description, body,
      testOn: testOn,
      timeout: timeout,
      skip: skip,
      onPlatform: onPlatform,
      // ignore: deprecated_member_use
      solo: true);
}

///
/// Run the group solo temporarily
/// mark as deprecated so that you don't checkin such code
///
@deprecated
void
// ignore: non_constant_identifier_names
    solo_group(String description, void Function() body,
        {String? testOn,
        Timeout? timeout,
        skip,
        @deprecated bool solo = false,
        Map<String, dynamic>? onPlatform}) {
  testImplementation.group(description, body,
      testOn: testOn,
      timeout: timeout,
      skip: skip,
      onPlatform: onPlatform,
      solo: true);
}

///
/// Skip the test temporarily
/// mark as deprecated so that you don't checkin such code
/// to permanently skip a test use the skip paremeter
///
@deprecated
void
// ignore: non_constant_identifier_names
    skip_test(String description, Function() body,
        {String? testOn,
        Timeout? timeout,
        skip,
        @deprecated bool solo = false,
        Map<String, dynamic>? onPlatform}) {
  testImplementation.test(description, body,
      testOn: testOn,
      timeout: timeout,
      skip: true,
      onPlatform: onPlatform,
      // ignore: deprecated_member_use
      solo: solo);
}

///
/// Skip the group temporarily
/// mark as deprecated so that you don't checkin such code
/// to permanently skip a group use the skip paremeter
///
@deprecated
void
// ignore: non_constant_identifier_names
    skip_group(String description, void Function() body,
        {String? testOn,
        Timeout? timeout,
        skip,
        @deprecated bool solo = false,
        Map<String, dynamic>? onPlatform}) {
  testImplementation.group(description, body,
      testOn: testOn,
      timeout: timeout,
      skip: true,
      onPlatform: onPlatform,
      solo: solo);
}
