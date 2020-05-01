// not flutter
import 'dart:async';

import 'package:dev_test/src/dev_test.dart' show Test, WithTestDescriptions;
import 'package:dev_test/test.dart' show Timeout;

class WithDescriptionsTest implements Test, WithTestDescriptions {
  final Test _impl;

  @override
  List<String> get testDescriptions =>
      List.from(_currentDescriptions ?? _descriptions);

  List<String> _currentDescriptions; // set when the test is ran
  final List<String> _descriptions = [];

  WithDescriptionsTest(this._impl);

  @override
  void test(String description, Function() body,
      {String testOn,
      Timeout timeout,
      skip,
      @deprecated bool solo = false,
      Map<String, dynamic> onPlatform}) {
    var descriptions = List<String>.from(_descriptions)..add(description);
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
  @override
  void group(String description, void Function() body,
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
  @override
  void setUp(Function() body) {
    final descriptions = List<String>.from(_descriptions);
    _impl.setUp(() {
      return _wrap(descriptions, body);
    });
  }

// overriding  [_test.tearDown]
  @override
  void tearDown(Function() body) {
    final descriptions = List<String>.from(_descriptions);
    _impl.tearDown(() {
      return _wrap(descriptions, body);
    });
  }

// overriding  [_test.setUp]
  @override
  void setUpAll(Function() body) {
    final descriptions = List<String>.from(_descriptions);
    _impl.setUpAll(() {
      return _wrap(descriptions, body);
    });
  }

// overriding  [_test.tearDown]
  @override
  void tearDownAll(Function() body) {
    final descriptions = List<String>.from(_descriptions);
    _impl.tearDownAll(() {
      return _wrap(descriptions, body);
    });
  }

  @override
  void expect(actual, matcher, {String reason, skip}) {
    _impl.expect(actual, matcher, reason: reason, skip: skip);
  }

  dynamic _wrap(List<String> descriptions, Function() body) {
    _currentDescriptions = descriptions;
    var result;
    var error;
    try {
      result = body();
    } catch (e) {
      error = e;
      rethrow;
    } finally {
      if (result is Future) {
        result = result.whenComplete(() {
          _currentDescriptions = null;
        });
      } else {
        _currentDescriptions = null;
      }
    }
    if (error == null) {
      return result;
    }
  }
}