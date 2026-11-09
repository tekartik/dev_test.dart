// for flutter
import 'package:dev_build/menu/menu.dart' as tmf;
import 'package:dev_build/menu/menu_io.dart';
// ignore: implementation_imports
import 'package:dev_test/src/description_test.dart' show WithDescriptionsTest;
import 'package:dev_test/src/dev_test.dart'
    show Test, testImplementation, DevTestMixin;
import 'package:dev_test/test.dart' show Timeout;
import 'package:matcher/expect.dart' as xp;
import 'package:meta/meta.dart';

export 'package:dev_test/test.dart'
    show expect, test, group, setUp, tearDown, setUpAll, tearDownAll;

/// Init dev test menu
void initDevTestMenu() {
  testImplementation = WithDescriptionsTest(DevTestMenu());
}

/// Shows the tests declared by [body] as a console menu (`dart run`, not
/// `dart test`): each `group` is a menu, each `test` an item.
///
/// [arguments] (the `main` arguments) are the first lines typed (`0 0 .`),
/// then stdin is read. `setUp`/`tearDown` run around each test (those of
/// the parent groups too), `setUpAll`/`tearDownAll` when a group menu is
/// entered and left; a failing `expect` is printed and the menu goes on.
/// `skip`, `testOn`, `timeout` and `onPlatform` are ignored, the async
/// matchers and `expectLater` do not work in a menu. [showConsole] is
/// ignored.
///
/// ```dart
/// import 'package:dev_test/dev_test_menu.dart';
///
/// void main(List<String> arguments) {
///   mainDevTestMenu(() {
///     test('add', () => expect(1 + 1, 2));
///   }, arguments: arguments);
/// }
/// ```
void mainDevTestMenu(
  void Function() body, {
  List<String>? arguments,
  bool? showConsole,
}) {
  initDevTestMenu();
  mainMenuConsole(arguments ?? <String>[], body);
}

/// The `setUp` and `tearDown` callbacks of a group (or of the root).
class _DevTestMenuScope {
  final setUps = <Object? Function()>[];
  final tearDowns = <Object? Function()>[];
}

/// Calls [callback], awaiting it when it returns a future.
Future<void> _call(Object? Function() callback) async {
  var result = callback();
  if (result is Future) {
    await result;
  }
}

/// Runs [body] the way package:test runs a test: the `setUp` callbacks of
/// [scopes] (the root first), the body, then the `tearDown` callbacks, the
/// inner group first and each group in reverse order, even after a failure.
/// The first error is thrown.
Future<void> _runTest(
  List<_DevTestMenuScope> scopes,
  Object? Function() body,
) async {
  Object? error;
  StackTrace? stackTrace;
  try {
    for (var scope in scopes) {
      for (var setUp in List.of(scope.setUps)) {
        await _call(setUp);
      }
    }
    await _call(body);
  } catch (e, st) {
    error = e;
    stackTrace = st;
  }
  for (var scope in scopes.reversed) {
    for (var tearDown in scope.tearDowns.reversed.toList()) {
      try {
        await _call(tearDown);
      } catch (e, st) {
        if (error == null) {
          error = e;
          stackTrace = st;
        }
      }
    }
  }
  if (error != null) {
    Error.throwWithStackTrace(error, stackTrace!);
  }
}

/// Dev test menu implementation.
class DevTestMenu with DevTestMixin implements Test {
  /// The scopes of the groups being declared, the root first.
  final _scopes = <_DevTestMenuScope>[_DevTestMenuScope()];

  @override
  void test(
    String description,
    dynamic Function() body, {
    String? testOn,
    Timeout? timeout,
    skip,
    @doNotSubmit bool solo = false,
    Map<String, Object?>? onPlatform,
  }) {
    // The scopes themselves: a setUp declared after the test applies too.
    var scopes = List.of(_scopes);
    tmf.item(
      description,
      () => _runTest(scopes, body),
      // ignore: invalid_use_of_do_not_submit_member
      solo: solo,
    );
  }

  @override
  void group(
    String description,
    void Function() body, {
    String? testOn,
    Timeout? timeout,
    Object? skip,
    @Deprecated('Dev only') bool solo = false,
    Map<String, Object?>? onPlatform,
  }) {
    tmf.menu(
      description,
      () {
        _scopes.add(_DevTestMenuScope());
        try {
          body();
        } finally {
          _scopes.removeLast();
        }
      },
      // ignore: invalid_use_of_do_not_submit_member
      solo: solo,
    );
  }

  /// Runs before each test of the current group and of its sub groups (not
  /// a menu `enterItem`, which only covers the items of its own menu).
  @override
  void setUp(Object? Function() callback) {
    _scopes.last.setUps.add(callback);
  }

  /// Runs after each test of the current group and of its sub groups.
  @override
  void tearDown(Object? Function() callback) {
    _scopes.last.tearDowns.add(callback);
  }

  @override
  void setUpAll(Object? Function() callback) {
    tmf.enter(callback);
  }

  @override
  void tearDownAll(Object? Function() callback) {
    tmf.leave(callback);
  }

  /// Returns a pretty-printed representation of [value].
  ///
  /// The matcher package doesn't expose its pretty-print function directly, but
  /// we can use it through StringDescription.
  String prettyPrint(Object? value) =>
      xp.StringDescription().addDescriptionOf(value).toString();

  /// Indent each line in [text] by [first] spaces.
  ///
  /// [first] is used in place of the first line's indentation.
  String indent(String text, {required String first}) {
    final prefix = ' ' * first.length;
    var lines = text.split('\n');
    if (lines.length == 1) return '$first$text';

    var buffer = StringBuffer('$first${lines.first}\n');

    // Write out all but the first and last lines with [prefix].
    for (var line in lines.skip(1).take(lines.length - 2)) {
      buffer.writeln('$prefix$line');
    }
    buffer.write('$prefix${lines.last}');
    return buffer.toString();
  }

  /// Converts [strings] to a bulleted list.
  String formatFailure(
    xp.Matcher expected,
    Object? actual,
    String which, {
    String? reason,
  }) {
    var buffer = StringBuffer();
    buffer.writeln(indent(prettyPrint(expected), first: 'Expected: '));
    buffer.writeln(indent(prettyPrint(actual), first: '  Actual: '));
    if (which.isNotEmpty) buffer.writeln(indent(which, first: '   Which: '));
    if (reason != null) buffer.writeln(reason);
    return buffer.toString();
  }

  /// formatter
  late var formatter =
      (
        Object? actual,
        xp.Matcher matcher,
        String? reason,
        Map<Object?, Object?> matchState,
        bool verbose,
      ) {
        var mismatchDescription = xp.StringDescription();
        matcher.describeMismatch(
          actual,
          mismatchDescription,
          matchState,
          verbose,
        );

        return formatFailure(
          matcher,
          actual,
          mismatchDescription.toString(),
          reason: reason,
        );
      };
  @override
  void expect(Object? actual, Object? matcher, {String? reason, Object? skip}) {
    if (skip != null && skip != false) {
      return;
    }
    var newMatcher = xp.wrapMatcher(matcher);
    var matchState = <Object?, Object?>{};
    try {
      if (newMatcher.matches(actual, matchState)) {
        return;
      }
    } catch (e, trace) {
      reason ??= '$e at $trace';
    }
    //xp.fail(reason ?? 'error');
    xp.fail(formatter(actual, newMatcher, reason, matchState, false));
  }
}
