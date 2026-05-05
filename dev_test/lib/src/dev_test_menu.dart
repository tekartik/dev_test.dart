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

/// Run a dev test menu.
void mainDevTestMenu(
  void Function() body, {
  List<String>? arguments,
  bool? showConsole,
}) {
  initDevTestMenu();
  mainMenuConsole(arguments ?? <String>[], body);
}

/// Dev test menu implementation.
class DevTestMenu with DevTestMixin implements Test {
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
    tmf.item(
      description,
      body,
      // ignore: deprecated_member_use
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
      body,
      // ignore: deprecated_member_use
      solo: solo,
    );
  }

  @override
  void setUp(Object? Function() callback) {
    tmf.enterItem(callback);
  }

  @override
  void tearDown(Object? Function() callback) {
    tmf.leaveItem(callback);
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
