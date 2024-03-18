// not flutter
import 'dart:async';

import 'package:dev_test/src/dev_test.dart' show Test, WithTestDescriptions;
import 'package:dev_test/test.dart' show Timeout;

/// dWith descriptions test implementation.
class WithDescriptionsTest implements Test, WithTestDescriptions {
  final Test _impl;

  @override
  List<String> get testDescriptions =>
      List.from(_currentDescriptions ?? _descriptions);

  List<String>? _currentDescriptions; // set when the test is ran
  final List<String> _descriptions = [];

  /// With descriptions test implementation.
  WithDescriptionsTest(this._impl);

  @override
  void test(String description, dynamic Function() body,
      {String? testOn,
      Timeout? timeout,
      skip,
      @Deprecated('Dev only') bool solo = false,
      Map<String, Object?>? onPlatform}) {
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
      {String? testOn,
      Timeout? timeout,
      skip,
      @Deprecated('Dev only') bool solo = false,
      Map<String, Object?>? onPlatform}) {
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
  void setUp(dynamic Function() body) {
    final descriptions = List<String>.from(_descriptions);
    _impl.setUp(() {
      return _wrap(descriptions, body);
    });
  }

// overriding  [_test.tearDown]
  @override
  void tearDown(dynamic Function() body) {
    final descriptions = List<String>.from(_descriptions);
    _impl.tearDown(() {
      return _wrap(descriptions, body);
    });
  }

// overriding  [_test.setUp]
  @override
  void setUpAll(dynamic Function() body) {
    final descriptions = List<String>.from(_descriptions);
    _impl.setUpAll(() {
      return _wrap(descriptions, body);
    });
  }

// overriding  [_test.tearDown]
  @override
  void tearDownAll(dynamic Function() body) {
    final descriptions = List<String>.from(_descriptions);
    _impl.tearDownAll(() {
      return _wrap(descriptions, body);
    });
  }

  @override
  void expect(actual, matcher, {String? reason, skip}) {
    _impl.expect(actual, matcher, reason: reason, skip: skip);
  }

  dynamic _wrap(List<String> descriptions, dynamic Function() body) {
    _currentDescriptions = descriptions;
    Object? result;
    Object? error;
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
