# dev_test

A thin layer on top of the `test` package: the same `test`, `group`,
`setUp`, `expect`, matchers..., plus `solo_test`, `solo_group`,
`skip_test`, `skip_group` to run or skip one test from the IDE, and
`testDescriptions`, the names of the current groups and test. Tests still
run with `dart test` (or `flutter test`).

[![pub package](https://img.shields.io/pub/v/dev_test.svg)](https://pub.dev/packages/dev_test)

## Getting started

Add both as dev dependencies, `test` is the runner (`dart test` needs it):

```sh
dart pub add --dev test dev_test
```

In your `test/*_test.dart` files, import `package:dev_test/test.dart`
instead of `package:test/test.dart`:

```dart
import 'package:dev_test/test.dart';

void main() {
  group('group', () {
    test('test', () {
      expect(1 + 1, 2);
      // The enclosing groups and the test name.
      expect(testDescriptions, ['group', 'test']);
    });
  });
}
```

Run them as before: `dart test`.

### Platforms

Everything `dart test` runs: the Dart VM, the browser (`dart test -p
chrome`, dart2js and dart2wasm) and node (`-p node`). In a Flutter package
it works under `flutter test` for plain tests; widget tests (`testWidgets`)
still need `package:flutter_test`.

## What it adds

| API | Use it to |
|---|---|
| `solo_test`, `solo_group` | run only this test (or group) of the file, the others are reported skipped |
| `skip_test`, `skip_group` | skip this test (or group) for now |
| `testDescriptions` | name a resource after the running test (a database, a folder) |
| `mainDevTestMenu` (`package:dev_test/dev_test_menu.dart`) | run the tests of a file as a console menu |

The `solo_` and `skip_` functions are deprecated on purpose: the analyzer
reports each use, so that they are not committed (a CI running `dart
analyze --fatal-infos` fails). For a permanent skip, use the `skip:`
parameter, which is not deprecated: `test('x', body, skip: 'flaky on
node')`.

Everything else is `package:test`, re-exported: `setUpAll`,
`tearDownAll`, `addTearDown`, `expectLater`, `throwsA`, `completion`,
`emitsInOrder`, `TestOn`, `Timeout`, `Skip`... `test` and `group` take
`testOn`, `timeout`, `skip` and `onPlatform`, not `tags` nor `retry` (use
the `@Tags([...])` and `@Retry(n)` library annotations).

### testDescriptions

Inside a test body it is `[...groups, test]`; inside `setUp`, `tearDown`,
`setUpAll`, `tearDownAll` and a group body it is the groups only; at the
top level of `main` and in an `addTearDown` callback it is `[]`.

```dart
import 'package:dev_test/test.dart';

/// A database name unique to the running test.
String dbName() => '${testDescriptions.join('_')}.db';

void main() {
  group('store', () {
    test('insert', () {
      expect(dbName(), 'store_insert.db');
    });
  });
}
```

### Tests as a console menu

`mainDevTestMenu` shows the tests of a function as a menu: each group is a
menu, each test an item to pick. Handy to run one slow or manual test at a
time, with its prints.

```dart
// tool/my_test_menu.dart, run with: dart run tool/my_test_menu.dart
import 'package:dev_test/dev_test_menu.dart';

void main(List<String> arguments) {
  mainDevTestMenu(() {
    group('math', () {
      setUp(() => print('before each test of math'));
      test('add', () => expect(1 + 1, 2));
      test('fails', () => expect(1 + 1, 3)); // printed, the menu goes on
    });
  }, arguments: arguments);
}
```

Type the number of an item, `.` to go back (or exit), `?` to show the menu
again; the arguments are typed first (`dart run tool/my_test_menu.dart 0 0 1
. .` enters `math`, runs `add` and `fails`, goes back and exits). `setUp`/`tearDown` run around each
test, those of the parent groups included; `setUpAll`/`tearDownAll` when a
group menu is entered and left. The console is the one of `dev_build` (see
its `dev-build-menu` skill).

In the menu only the calls of `dev_test` are seen, and:

* `skip`, `testOn`, `timeout` and `onPlatform` are ignored: a skipped test
  is listed and runs when picked;
* the async matchers (`throwsA`, `throwsStateError`..., `completion`,
  `emits`, `prints`) and `expectLater` need a running `package:test` test
  and fail there;
* a failure is printed, the exit code stays 0.

## Common mistakes

* Importing `package:test/test.dart` and `package:dev_test/test.dart` in
  the same file: `test`, `group` and `expect` are ambiguous.
* Only `dev_test` in the dev dependencies: `dart test` then says "Could not
  find package `test`".
* Committing a `solo_test`: the other tests of the file stop running.
* Reading `testDescriptions` in a top-level variable initializer (it is
  `[]`), or expecting the test name in a `setUp` (only the groups are known
  there).
* Naming a `mainDevTestMenu` script `*_test.dart`: `dart test` runs it.

More: [doc/dev_test.md](doc/dev_test.md) (details) and
[doc/setup.md](doc/setup.md) (git dependency).
