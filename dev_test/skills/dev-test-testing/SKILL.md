---
name: dev-test-testing
description: >-
  Use when writing or running Dart tests with package:dev_test, a drop-in
  replacement for import 'package:test/test.dart': solo_test, solo_group,
  skip_test, skip_group to isolate or skip one test from the IDE,
  testDescriptions for the current group/test path, mainDevTestMenu to run a
  test file as an interactive console menu, and which package:test API
  (test, group, setUp, tearDown, expect, matchers, TestOn, Timeout, Skip,
  addTearDown, printOnFailure) it re-exports.
---

# dev_test: solo/skip on top of package:test

`package:dev_test/test.dart` exports the same API as `package:test/test.dart`
(`test`, `group`, `setUp`, `tearDown`, `setUpAll`, `tearDownAll`, `expect`,
all matchers and annotations) and adds `solo_test`, `solo_group`,
`skip_test`, `skip_group` and `testDescriptions`. Tests still run with
`dart test` / `flutter test`; nothing else changes. Works on the VM, in the
browser and on node.

```dart
import 'package:dev_test/test.dart';

void main() {
  group('group', () {
    test('test', () {
      expect(true, isTrue);
      expect(testDescriptions, ['group', 'test']);
    });
  });
}
```

## Guidelines

### Setup

* Add both to `dev_dependencies`: `test` (the runner) and `dev_test`.
* In `test/*_test.dart` replace `import 'package:test/test.dart';` with
  `import 'package:dev_test/test.dart';`. Never import both in one file:
  `test`, `group`, `expect`... are defined by each and conflict.
  `package:dev_test/dev_test.dart` is the same library under another name.
* `dev_test` provides the `dart test` API only. It does not provide
  `testWidgets`/`WidgetTester`; keep `package:flutter_test` for widget
  tests.

### Re-exported package:test API

* Structure: `test`, `group`, `setUp`, `tearDown`, `setUpAll`,
  `tearDownAll`, `addTearDown`, `printOnFailure`, `markTestSkipped`,
  `pumpEventQueue`, `registerException`, `spawnHybridUri`,
  `spawnHybridCode`.
* Annotations and parameters: `TestOn`, `Timeout`, `Skip`, `Tags`,
  `OnPlatform`, `Retry`; `test(..., testOn: 'vm', timeout:
  const Timeout(Duration(minutes: 2)), skip: 'reason', onPlatform: {...})`
  behave exactly as in `package:test`.
* Expectations: `expect`, `expectLater`, `expectAsync0..6`,
  `expectAsyncUntil0..6`, `fail`, `TestFailure`, `neverCalled`, `prints`,
  `throwsA`, `throwsArgumentError`..., `completes`, `completion`,
  `emits`, `emitsInOrder`, `StreamMatcher`, and every `package:matcher`
  matcher (`equals`, `isTrue`, `isNull`, `contains`, `hasLength`,
  `isA<T>()`, `closeTo`, ...).

### solo and skip

* `solo_test('name', body)` / `solo_group('name', body)`: only the
  solo-marked tests and groups of that file run; the others are reported
  as skipped. Use it from the IDE to iterate on one test without
  `dart test -n`. `test(..., solo: true)` is the parameter form.
* `skip_test('name', body)` / `skip_group('name', body)`: temporarily skip
  without touching the body. For a permanent skip use the `skip:`
  parameter (`test('x', body, skip: 'flaky on node')`) which is not
  deprecated.
* The four functions are `@Deprecated('Dev only')`: the analyzer reports
  each use, and a CI running `dart analyze --fatal-infos` (what
  `dev_build`'s `run_ci` does) fails. That is intentional: remove them
  before committing. Do not silence them with `// ignore` in committed
  code.
* They accept the same named parameters as `test`/`group` (`testOn`,
  `timeout`, `skip`, `onPlatform`).

### testDescriptions

* `testDescriptions` is a `List<String>` naming the enclosing groups and
  the current test. Inside a test body it is `[...groups, test]`. Inside
  `setUp`, `tearDown`, `setUpAll`, `tearDownAll` and while a group body is
  being declared it is the group path only (`[...groups]`), the test name
  is not known there. Async tests that run concurrently each see their
  own value.
* Use it to derive unique resources per test (a database name, a temp
  folder, a document path) instead of repeating the test name:
  `testDescriptions.join('_')` from the test body.
* Outside any group or test it is `[]`.

### Interactive menu runner

* `import 'package:dev_test/dev_test_menu.dart'` (exports `test.dart` too)
  and wrap the declarations in `mainDevTestMenu(() { ... }, arguments:
  args)`: each group becomes a menu, each test an item, `setUp`/`tearDown`
  run around each item, `setUpAll`/`tearDownAll` on menu enter/leave, and
  `expect` failures are printed instead of aborting. Run it with
  `dart run test/my_menu.dart` (name the file so `dart test` ignores it,
  or keep it in `example/`/`tool/`). See the `dev-build-menu` skill for
  the console commands (`0`, `1`..., `.`, `?`).

## Examples

### Isolate one test while debugging

```dart
import 'package:dev_test/test.dart';

void main() {
  test('other', () {
    fail('not run while a solo test exists');
  });
  // Deprecated on purpose: remove before committing.
  solo_test('the one', () {
    expect(1 + 1, 2);
  });
}
```

### Skip a group temporarily

```dart
import 'package:dev_test/test.dart';

void main() {
  skip_group('slow', () {
    test('a', () {});
    test('b', () {});
  });
  test('fast', () {
    expect(true, isTrue);
  });
}
```

### Per-test resources from testDescriptions

```dart
import 'package:dev_test/test.dart';

String dbName() => '${testDescriptions.join('_')}.db';

void main() {
  group('store', () {
    setUp(() {
      // Group path only here.
      expect(testDescriptions, ['store']);
    });
    test('insert', () {
      expect(dbName(), 'store_insert.db');
    });
    group('nested', () {
      test('read', () {
        expect(testDescriptions, ['store', 'nested', 'read']);
        expect(dbName(), 'store_nested_read.db');
      });
    });
  });
}
```

### Platform and timeout annotations still work

```dart
@TestOn('vm')
library;

import 'package:dev_test/test.dart';

void main() {
  test('io', () async {
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }, timeout: const Timeout(Duration(minutes: 2)));

  test('web only', () {}, testOn: 'browser', skip: 'no browser in CI');
}
```

### Async matchers

```dart
import 'dart:async';

import 'package:dev_test/test.dart';

void main() {
  test('futures and streams', () async {
    await expectLater(Future.value(1), completion(1));
    expect(() => throw ArgumentError('x'), throwsArgumentError);
    var controller = StreamController<int>();
    controller
      ..add(1)
      ..add(2)
      ..close();
    await expectLater(controller.stream, emitsInOrder([1, 2, emitsDone]));
  });
}
```

### Run a suite as a console menu

```dart
// example/main_menu.dart — dart run example/main_menu.dart
import 'package:dev_test/dev_test_menu.dart';

void main(List<String> args) {
  mainDevTestMenu(() {
    group('group', () {
      setUp(() => print('before each'));
      test('passes', () {
        expect(testDescriptions, ['group', 'passes']);
      });
      test('fails', () {
        expect(true, isFalse); // printed, does not stop the menu
      });
    });
  }, arguments: args);
}
```

## Common mistakes

* Importing `package:test/test.dart` and `package:dev_test/test.dart` in
  the same file (ambiguous `test`, `group`, `expect`).
* Committing `solo_test`/`skip_test`: CI analysis fails on the deprecation
  and, with `solo_*`, most tests silently stop running.
* Reading `testDescriptions` in a top-level variable initializer (it is
  `[]`), or expecting the test name inside `setUp` (only the groups are
  known there).
* Expecting `mainDevTestMenu` files to run under `dart test`: they are
  scripts started with `dart run`.
