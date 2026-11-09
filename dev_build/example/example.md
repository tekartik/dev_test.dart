# dev_build examples

## Run the CI checks

```sh
# pub get, format check, analyze, tests and web build of the current package
# and of the packages below it, using the latest dev_build of pub.dev
dart run dev_build:run_ci@

# Or install a `run_ci` command once (Dart 3.10+)
dart install dev_build
run_ci --analyze
```

## tool/run_ci.dart

With `dart pub add --dev dev_build`:

```dart
import 'package:dev_build/package.dart';

Future<void> main() async {
  // Every package of the repository, every step.
  await packageRunCi('.', options: PackageRunCiOptions(recursive: true));
}
```

An "only" option runs that step alone (after `pub get`):
`PackageRunCiOptions(recursive: true, vmTestOnly: true)` runs the vm tests,
`analyzeOnly: true` the analyzer, `fixOnly: true` `dart format` and
`dart fix --apply`.

## A console menu

```dart
// tool/menu.dart, run with: dart run tool/menu.dart
import 'package:dev_build/menu/menu_io.dart';
import 'package:dev_build/shell.dart' hide prompt;

void main(List<String> arguments) {
  mainMenuConsole(arguments, () {
    item('dart version', () async {
      await run('dart --version');
    });
    item('ask', () async {
      var name = await prompt('Name');
      write('Hi $name');
    });
  });
}
```

## List the packages of a folder tree

```dart
import 'package:dev_build/package.dart';

Future<void> main() async {
  for (var path in await recursivePubPath(['.'])) {
    print(path);
  }
}
```

More in [list_packages.dart](list_packages.dart), [package_info.dart](package_info.dart) and
[menu/common_main_menu.dart](menu/common_main_menu.dart).
