# dev_build

Development tools for Dart and Flutter packages: `run_ci` (pub get, format
check, analyze, tests on every platform the package supports, web build) for
one package or a whole repository, console menus for developer scripts, and
helpers to read pubspec files, find packages and install pub tools.

[![pub package](https://img.shields.io/pub/v/dev_build.svg)](https://pub.dev/packages/dev_build)

## Getting started

### Run the CI checks, nothing to add

```sh
# In a package or at the top of a repository (nested packages included)
dart run dev_build:run_ci@

# Any run_ci option, i.e. analyze only, or fix the format and the lints
dart run dev_build:run_ci@ --analyze
dart run dev_build:run_ci@ --fix
```

`run_ci@` runs the latest `dev_build` from pub.dev. To have a `run_ci`
command instead (Dart 3.10+, run it again to upgrade):

```sh
dart install dev_build
run_ci --version
```

### From a script of your repository

```sh
dart pub add --dev dev_build
```

```dart
// tool/run_ci.dart, run with: dart run tool/run_ci.dart
import 'package:dev_build/package.dart';

Future<void> main() async {
  // This package only. Pass PackageRunCiOptions(recursive: true) for the
  // packages below too.
  await packageRunCi('.');
}
```

What a run does, in order, for each package: `dart pub get` (`flutter pub
get` for Flutter), `dart format --set-exit-if-changed`, `dart analyze
--fatal-warnings --fatal-infos` (`flutter analyze`), `tool/dev_build_setup.dart`
when found, `dart test` on the vm, chrome (when `build_web_compilers` is a
dependency) and node (`build_node_compilers`) platforms (`flutter test`),
then the web build when the package has a `web/index.html` (`webdev build`
with `build_runner` and `build_web_compilers`, `flutter build web` with a
`lib/main.dart`), then `tool/dev_build_cleanup.dart` when found. A
`dart_test.yaml` `platforms:` list restricts the test platforms.

### Platforms

io only: Dart VM on Linux, macOS and Windows, the `dart` executable (and
`flutter` for Flutter packages) on the PATH. `package:dev_build/menu/menu.dart`
(the menu declarations) compiles on the web and in Flutter apps too, without
a console there.

## Libraries

| Import | Use it for |
|---|---|
| `package:dev_build/package.dart` | `packageRunCi`, `PackageRunCiOptions`, `recursivePubPath` (find the packages of a tree), `recursivePackagesRun`, `DartPackageIo` (read, bump the version) |
| `package:dev_build/build_support.dart` | `pubspec.yaml` readers (`pathGetPubspecYamlMap`, `pubspecYamlSupportsFlutter`...), `isPubPackageRoot`, `VersionBoundaries`, `checkAndInstallCliPackage` (`dart install`), `checkAndPubGlobalActivatePackage`, `dartCreateProject`, `flutterCreateProject` |
| `package:dev_build/shell.dart` | `package:process_run/shell.dart` (`Shell`, `run`, `which`) |
| `package:dev_build/menu/menu_io.dart` | a numbered console menu for a `tool/` script: `mainMenuConsole`, `menu`, `item`, `write`, `prompt` |
| `package:dev_build/menu/menu_agent.dart` | let an LLM agent drive a menu (`--agent`, VM service) |

A console menu:

```dart
// tool/menu.dart, run with: dart run tool/menu.dart
import 'package:dev_build/menu/menu_io.dart';

void main(List<String> arguments) {
  mainMenuConsole(arguments, () {
    item('hello', () => write('Hello'));
    item('ask', () async {
      var name = await prompt('Name');
      write('Hi $name');
    });
  });
}
```

`dart run tool/menu.dart 1 Alice .` runs item 1, answers its prompt with
`Alice`, then `.` exits.

## run_ci conventions

- By default `run_ci` also runs the packages below the given folder (`--no-recursive` for the folder only), the API
  `packageRunCi` does not (`PackageRunCiOptions(recursive: true)`).
- A `tool/run_ci_override.dart` file is run instead of the standard steps (it must pass `noOverride: true` to
  `packageRunCi`, or it runs itself again).
- A `tool/dev_build_setup.dart` file is run (`dart run tool/dev_build_setup.dart`) after format and analyze, before
  the tests and the build, i.e. to build what they need (a web worker script). Its errors are reported and ignored.
- After the tests and the build (on failure too), a `tool/dev_build_cleanup.dart` file is run when found, then the
  `build/` and `.dart_tool/flutter_build/` (flutter build cache) folders they created are deleted (an existing one is
  kept), i.e. to free space on CI. Its errors are reported and ignored. `--no-cleanup` skips both.
- An empty `.local/.skip_run_ci` file skips the package (`run_ci config --skip-run-ci <path>` creates it).
- A `dev_build_run_ci_config.yaml` file filters the folders scanned recursively, it applies to its folder and sub
  folders (paths relative to the file, the files above the `<path>` argument are ignored):

```yaml
# Only look for packages in these sub folders (default to all)
include:
  - packages
  - example
# Don't look for packages in these folders, use `.` to skip this folder
exclude:
  - example/legacy
```

More examples:

```sh
# pub downgrade then analyze every package: are the minimum versions right?
run_ci --pub-downgrade --analyze --no-override

# The vm tests only, offline
run_ci --vm-test --offline

# List the packages found and their sdk constraint
run_ci --prj-info --no-run-ci
```

`run_ci --help` lists every option.

## Common mistakes

- A package whose `environment: sdk:` constraint does not match the running `dart` is skipped (not a package for
  `run_ci`); `--ignore-sdk-constraints` lists it (`--print-path`, `--prj-info`) but does not run it.
- `dart analyze` runs with `--fatal-infos`: an info fails the run (`--no-fatal-warnings` for errors only, i.e. after a
  `--pub-downgrade`).
- Adding `build_web_compilers` to a package turns on its chrome tests.
- `run_ci` installed with both `dart install` and `dart pub global activate`: the first bin folder on the PATH wins,
  check with `run_ci --version`.
- A menu script reading its answers from a pipe: lines arriving together are read as menu lines before the item
  prompts, and a `prompt` still waiting when the input ends never completes, the script exits (code 0) in the middle
  of the item. Pass the answers as arguments instead.

## More

- Agent skills (also a detailed guide): [run_ci](skills/dev-build-run-ci/SKILL.md) and its
  [options](skills/dev-build-run-ci/references/cli-options.md), [menus](skills/dev-build-menu/SKILL.md),
  [package helpers](skills/dev-build-package/SKILL.md).
- [CI helper](doc/ci_helper.md), [setup](doc/setup.md).
