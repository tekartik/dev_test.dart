// not flutter
import 'dart:async';

import 'package:dev_test/src/dev_test.dart' show Test, WithTestDescriptions;
import 'package:dev_test/test.dart' show Timeout;

class WithDescriptionsTest implements Test, WithTestDescriptions {
  final Test _impl;

  @override
  List<String> get testDescriptions => _currentDescriptions ?? _descriptions;

  List<String> _currentDescriptions; // set when the test is ran
  final List<String> _descriptions = [];
  WithDescriptionsTest(this._impl);
  @override
  void test(String description, body(),
      {String testOn,
      Timeout timeout,
      skip,
      @deprecated bool solo = false,
      Map<String, dynamic> onPlatform}) {
    List<String> descriptions = List.from(_descriptions)..add(description);
    _impl.test(description, () {
      return _wrap(descriptions, body);
    },
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
    _impl.group(description, () {
      _descriptions.add(description);
      body();
      _descriptions.removeLast();
    },
        testOn: testOn,
        timeout: timeout,
        skip: skip,
        onPlatform: onPlatform,
        // ignore: deprecated_member_use
        solo: solo);
  }

// overriding  [_test.setUp]
  void setUp(body()) {
    List<String> descriptions = List.from(_descriptions);
    _impl.setUp(() {
      return _wrap(descriptions, body);
    });
  }

// overriding  [_test.tearDown]
  void tearDown(body()) {
    List<String> descriptions = List.from(_descriptions);
    _impl.tearDown(() {
      return _wrap(descriptions, body);
    });
  }

// overriding  [_test.setUp]
  void setUpAll(body()) {
    List<String> descriptions = List.from(_descriptions);
    _impl.setUpAll(() {
      return _wrap(descriptions, body);
    });
  }

// overriding  [_test.tearDown]
  void tearDownAll(body()) {
    List<String> descriptions = List.from(_descriptions);
    _impl.tearDownAll(() {
      return _wrap(descriptions, body);
    });
  }

  @override
  void expect(actual, matcher, {String reason, skip}) {
    _impl.expect(actual, matcher, reason: reason, skip: skip);
  }

  _wrap(List<String> descriptions, Function() body) {
    _currentDescriptions = descriptions;
    var result;
    try {
      result = body();
    } finally {
      if (result is Future) {
        return result.whenComplete(() {
          _currentDescriptions = null;
        });
      } else {
        _currentDescriptions = null;
        // do not return anything here
        // or it will not make the test failed return result;
      }
    }
  }
}
