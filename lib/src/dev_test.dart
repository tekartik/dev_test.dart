import 'package:dev_test/src/dart_test.dart';
import 'package:test/test.dart' show Timeout;

// default implementation is a regular dart test
Test testImplementation = DartTest();

abstract class Test {
  void test(String description, body(),
      {String testOn,
      Timeout timeout,
      skip,
      bool solo = false,
      Map<String, dynamic> onPlatform});

// overriding  [_test.group]
  void group(String description, void body(),
      {String testOn,
      Timeout timeout,
      skip,
      bool solo = false,
      Map<String, dynamic> onPlatform});
// overriding  [_test.setUp]
  void setUp(callback());
// overriding  [_test.tearDown]
  void tearDown(callback());

// overriding  [_test.setUp]
  void setUpAll(callback());
// overriding  [_test.tearDown]
  void tearDownAll(callback());

  void expect(actual, matcher, {String reason, skip});
}

void test(String description, body(),
    {String testOn,
    Timeout timeout,
    skip,
    @deprecated bool solo = false,
    Map<String, dynamic> onPlatform}) {
  testImplementation.test(description, body,
      testOn: testOn,
      timeout: timeout,
      skip: skip,
      onPlatform: onPlatform,
      // ignore: deprecated_member_use
      solo: solo);
}

// overriding  [_test.group]
void group(String description, void body(),
    {String testOn,
    Timeout timeout,
    skip,
    @deprecated bool solo = false,
    Map<String, dynamic> onPlatform}) {
  testImplementation.group(description, body,
      testOn: testOn,
      timeout: timeout,
      skip: skip,
      onPlatform: onPlatform,
      solo: solo);
}

// overriding  [_test.setUp]
void setUp(callback()) {
  testImplementation.setUp(callback);
}

// overriding  [_test.tearDown]
void tearDown(callback()) {
  testImplementation.tearDown(callback);
}

// overriding  [_test.setUp]
void setUpAll(callback()) {
  testImplementation.setUpAll(callback);
}

// overriding  [_test.tearDown]
void tearDownAll(callback()) {
  testImplementation.tearDownAll(callback);
}

void expect(actual, matcher, {String reason, skip}) {
  testImplementation.expect(actual, matcher, reason: reason, skip: skip);
}
