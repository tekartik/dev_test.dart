---
name: dev-build-menu
description: >-
  Use when writing an interactive console script, a developer tool menu, or
  a demo/debug harness with package:dev_build/menu (menu.dart, menu_io.dart,
  menu_run_ci.dart): mainMenuConsole, initMenuConsole, menu, item, enter,
  leave, enterItem, leaveItem, command, write, writeln, prompt, showMenu,
  popMenu, solo_item, solo_menu, menuRun, runCiMenu, numbered items, cmd
  shortcuts, initial commands from the command line.
---

# dev_build console menu

`package:dev_build/menu/menu_io.dart` turns a Dart script into a numbered
console menu: you declare menus and items with plain functions, the console
prints the choices, reads a line on stdin and runs the item (sync or async).
Nested menus, enter/leave hooks and prompts are supported. `dev_test` uses
the same declarations to run tests as a menu.

```dart
// tool/menu.dart — run with: dart run tool/menu.dart
import 'package:dev_build/menu/menu_io.dart';

void main(List<String> arguments) {
  mainMenuConsole(arguments, () {
    menu('main', () {
      item('say hi', () => write('hi'));
      item('slow', () async {
        await Future<void>.delayed(const Duration(seconds: 1));
        write('done');
      });
    });
  });
}
```

## Guidelines

### Structure

* Import `package:dev_build/menu/menu_io.dart` in a script; it re-exports
  `package:dev_build/menu/menu.dart` (the declaration API) and adds
  `initMenuConsole(arguments)` and `mainMenuConsole(arguments, declare)`.
  `mainMenuConsole` initializes the console then calls `declare`.
* Declare with `menu(name, body)` (a sub menu, `body` must be synchronous)
  and `item(name, body)` (`body` may return a `Future`; it is awaited).
  Declarations are collected and the menu is shown after the declaring
  microtask completes, so declare everything up front, not from inside an
  item.
* Items are listed as `0 name`, `1 name`... Pass `cmd: 'x'` to `item` or
  `menu` to use a word instead of the index. `.` pops the current menu and
  exits when typed at the top level, `?` prints the menu again.
* Items declared outside any `menu()` form the top level. A `menu()` is
  listed as `N menu name` and has to be entered first (`N`), so a script
  with a single `menu('main', ...)` starts with `0` to reach its items.
* Extra command line arguments are executed as if typed:
  `dart run tool/menu.dart 0 2 .` runs item 0, then item 2, then `.`.
  `-h` prints the console help, `-v` echoes each command.
* `write(message)` / `writeln(message)` print through the active presenter;
  use them instead of `print` inside menu bodies. `await prompt('Name')`
  reads one line from the user and returns it.
* `enter(body)` / `leave(body)` run once when a menu is entered / left.
  `enterItem(body)` / `leaveItem(body)` run before / after every item of
  that menu (leave hooks also run when the item throws). Errors thrown by
  an item are printed (`ERROR CAUGHT`) and the menu stays open.
* `command((line) {...})` on a menu receives any typed line that is not an
  item index, a `cmd` or `.`/`?`.
* `showMenu(() { item(...); })` pushes a menu declared on the fly and
  completes when it is popped; `popMenu()` leaves the current menu
  programmatically (returns false at the top level).
* `solo_item(...)` / `solo_menu(...)` (also `item(..., solo: true)`) run
  only that item/menu when the script starts, for a quick debug loop. They
  are `@doNotSubmit`: the analyzer flags them so they are not committed.
  Same for `devWrite`.
* `menuRun()` runs the declared menu without `mainMenuConsole` (e.g. in a
  test, the output goes to `print`) and resets the declaration.

### Ready-made CI menu

* `package:dev_build/menu/menu_run_ci.dart` exports `runCiMenu(path)`
  which declares items for `info`, `pub get`, `pub upgrade`,
  `pub downgrade`, `dump dependencies`, `run_ci`, `analyze`, `format` and
  a `cd (prompt)` for the package at `path`. Wrap it in `mainMenuConsole`
  or nest it in your own menu.

### Platform

* `menu.dart` alone has no `dart:io` dependency and can be imported from
  Flutter or web code. `menu_io.dart` reads stdin; on non-io platforms
  `initMenuConsole` is a no-op. Interactive use is meant for
  `dart run` scripts.

## Examples

### Nested menus with enter/leave hooks

```dart
import 'package:dev_build/menu/menu_io.dart';

void main(List<String> arguments) {
  mainMenuConsole(arguments, () {
    menu('db', () {
      enter(() async {
        write('opening database');
      });
      leave(() async {
        write('closing database');
      });
      enterItem(() => write('--'));
      item('count', () async {
        write('count: 42');
      });
      item('clear', cmd: 'c', () async {
        write('cleared');
      });
      item('back', () => popMenu());
    });
    item('print args', () => write(arguments));
  });
}
```

### Prompting the user

```dart
import 'package:dev_build/menu/menu_io.dart';

void main(List<String> arguments) {
  mainMenuConsole(arguments, () {
    item('greet', () async {
      var name = await prompt('Your name');
      write('Hello $name');
    });
  });
}
```

### Menu built from data with showMenu

```dart
import 'package:dev_build/menu/menu_io.dart';

void main(List<String> arguments) {
  var files = ['a.txt', 'b.txt'];
  mainMenuConsole(arguments, () {
    item('pick a file', () async {
      await showMenu(() {
        for (var file in files) {
          item(file, () async {
            write('picked $file');
            await popMenu();
          });
        }
      });
    });
  });
}
```

### Catch-all command handler

```dart
import 'package:dev_build/menu/menu_io.dart';

void main(List<String> arguments) {
  mainMenuConsole(arguments, () {
    menu('shell', () {
      command((line) async {
        write('unknown command: $line');
      });
      item('help', () => write('type anything'));
    });
  });
}
```

### CI menu for the current package

```dart
import 'package:dev_build/menu/menu_io.dart';
import 'package:dev_build/menu/menu_run_ci.dart';

Future<void> main(List<String> args) async {
  mainMenuConsole(args, () {
    runCiMenu('.');
  });
}
```

### Debugging one item with solo_item

```dart
import 'package:dev_build/menu/menu_io.dart';

void main(List<String> arguments) {
  mainMenuConsole(arguments, () {
    item('one', () => write('one'));
    // Only this item runs at startup; remove before committing.
    // ignore: invalid_use_of_do_not_submit_member
    solo_item('two', () => write('two'));
  });
}
```

### Testing a menu script

```dart
import 'package:dev_build/menu/menu.dart';
import 'package:test/test.dart';

void main() {
  test('enterItem/leaveItem wrap the item', () async {
    var log = <String>[];
    menu('main', () {
      enterItem(() => log.add('enter'));
      leaveItem(() => log.add('leave'));
      // ignore: invalid_use_of_do_not_submit_member
      solo_item('work', () => log.add('work'));
    });
    await menuRun();
    expect(log, ['enter', 'work', 'leave']);
  });
}
```

## Common mistakes

* Making the body of `menu()` `async` or calling `item()` from inside a
  running item: declarations must happen synchronously at declaration time
  (use `showMenu` for dynamic menus).
* Using `print` instead of `write` inside items: it bypasses the presenter
  (works in a console, lost elsewhere).
* Forgetting `.` in scripted invocations (`dart run tool/menu.dart 0`): the
  process keeps waiting for input after running item 0.
* Committing `solo_item`/`solo_menu`/`devWrite`: they are meant for a
  temporary debug session.
