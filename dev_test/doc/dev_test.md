# dev_test details

## solo and skip

* `solo_test(name, body)` and `solo_group(name, body)` are `test` and
  `group` with `solo: true`: when a file has a solo test or group, only
  those run, the others are reported as skipped. Use it from the IDE to
  iterate on one test without `dart test -n <name>`.
* `skip_test(name, body)` and `skip_group(name, body)` are `test` and
  `group` with `skip: true`, without touching the body.
* The four are `@Deprecated('Dev only')`: the analyzer reports each use.
  Remove them before committing (do not silence them with `// ignore`).
* They take the other parameters of `test` and `group` (`testOn`,
  `timeout`, `skip`, `onPlatform`).

## testDescriptions

`testDescriptions` (a `List<String>`) names the enclosing groups and the
running test:

| Where it is read | Value |
|---|---|
| test body | `[...groups, test]` |
| `setUp`, `tearDown`, `setUpAll`, `tearDownAll`, group body | `[...groups]` |
| top level of `main`, `addTearDown` callback | `[]` |

The tests of a file run one at a time, so the value is the one of the test
running.

## Mixing with package:test

`package:dev_test/test.dart` exports the whole `package:test` API (through
`test_core`), with its own `test`, `group`, `setUp`, `tearDown`,
`setUpAll`, `tearDownAll` and `expect`. A file imports one or the other
(both only with a prefix). Helpers written with `package:test` can be called from a
`dev_test` file: they share the same runner. `testDescriptions` only knows
the groups and tests declared through `dev_test`.

## Console menu

`package:dev_test/dev_test_menu.dart` exports the same API and
`mainDevTestMenu(body, {arguments})`. `body` declares the tests (call the
`main` of a test file), and each group becomes a menu of the `dev_build`
console, each test an item:

* `setUp`/`tearDown` run around each test, those of the parent groups
  included, in the `package:test` order (setUps outer first, tearDowns
  inner first and in reverse order, even after a failure);
* `setUpAll`/`tearDownAll` run when a group menu is entered and left;
* a failing `expect` is printed and the menu goes on;
* the arguments are the first lines typed (`0 0 .`), then the console reads
  stdin: `.` goes back (exits at the top), `?` shows the menu again.

Not supported in the menu: `skip`, `testOn`, `timeout`, `onPlatform`
(ignored), the async matchers and `expectLater` (they need a running
`package:test` test), tests declared with `package:test` directly. The
program exits with 0, failures included.
