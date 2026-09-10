# run_ci executable reference

`dart run dev_build:run_ci [<path>...] [<flags>]`
(`bin/run_ci.dart`, also `dart pub global run dev_build:run_ci` or `run_ci`
once activated with `dart pub global activate dev_build`).

Without a path the current directory is used. Several paths can be given.

## Flags

| Flag | `PackageRunCiOptions` | Effect |
|---|---|---|
| `--version` | | print the dev_build version |
| `-v`, `--verbose` | `verbose` | verbose output |
| `--no-pub-get` | `noPubGet` | skip `pub get` |
| `--no-format` | `noFormat` | skip the format check |
| `--no-analyze` | `noAnalyze` | skip analyze |
| `--no-test` | `noTest` | skip tests |
| `--no-build` | `noBuild` | skip web builds |
| `--pub-get` | `pubGetOnly` | only `pub get` |
| `--pub-upgrade` | `pubUpgradeOnly` | only `pub upgrade` |
| `--pub-downgrade` | `pubDowngradeOnly` | only `pub downgrade` |
| `--format` | `formatOnly` | only the format check |
| `--analyze` | `analyzeOnly` | only analyze |
| `--test` | `testOnly` | only tests |
| `--build` | `buildOnly` | only builds |
| `--fix` | `fixOnly` | `dart format` then `dart fix --apply` |
| `--vm-test` | `vmTestOnly` | tests on the VM only |
| `--no-vm-test` | `noVmTest` | no VM tests |
| `--no-browser-test` | `noBrowserTest` | no chrome tests |
| `--chrome-js-test` | `chromeJsTestOnly` | chrome with dart2js only |
| `--no-node-test` | `noNodeTest` | no node tests |
| `--no-npm-install` | `noNpmInstall` | do not run `npm install` |
| `--offline` | `offline` | `pub get --offline` |
| `--no-override` | `noOverride` | ignore `tool/run_ci_override.dart` and `.local/.skip_run_ci` |
| `-i`, `--ignore-errors` | `ignoreErrors` | continue with the next package on failure |
| `--recursive` / `--no-recursive` | `recursive` | default on in the CLI |
| `-j`, `--concurrency <n>` | `poolSize` | packages run in parallel (default 1) |
| `--ignore-sdk-constraints` | `FilterDartProjectOptions(ignoreSdkConstraints: true)` | include packages whose sdk constraint does not match |
| `--min-sdk '<constraint>'` | `FilterDartProjectOptions(minSdk:)` | only packages whose `sdk` lower bound matches |
| `--max-sdk '<constraint>'` | `FilterDartProjectOptions(maxSdk:)` | only packages whose `sdk` upper bound matches |
| `--prj-info` | `prjInfo` | print absolute path, sdk constraint, `flutter` tag |
| `--no-run-ci` | `noRunCi` | stop after project info |
| `--print-path` | `printPath` | only print the package path |
| `--dry-run` | `dryRun` | print the commands, do not run them |
| `-h`, `--help` | | usage |

Sub commands:

* `run_ci config --skip-run-ci [<path>]` creates `<path>/.local/.skip_run_ci`.
* `run_ci menu` opens the interactive console menu (`runCiMenu`, see the
  `dev-build-menu` skill): info, pub get/upgrade/downgrade, dump
  dependencies, run_ci, analyze, format.

## Commands run per package

Dart package (`$dofPub` is `dart pub`, or `flutter pub` when the package or
its workspace contains a Flutter package):

```
$dofPub get [--offline]            # or upgrade / downgrade
dart format --set-exit-if-changed <dirs>
dart analyze --fatal-warnings --fatal-infos .
dart test --platform vm [<testOptions>]
dart test --platform chrome [--compiler dart2js --compiler dart2wasm]   # build_web_compilers
dart test --platform node --compiler dart2js                            # build_node_compilers
dart pub global run webdev build   # build_web_compilers + build_runner + web/index.html
```

Flutter package:

```
flutter pub get [--offline]
dart format --set-exit-if-changed <dirs>
flutter analyze --no-pub .
flutter test --no-pub [<testOptions>]
flutter build web --no-pub         # web/index.html + lib/main.dart present
```

`--fix`:

```
dart format <dirs>
dart fix --apply
```

`<dirs>` are the top level folders of the package that contain at least one
`.dart` file, excluding hidden folders, `build`, `deploy`, `node_modules`,
`.dart_tool` and nested packages. `.` is used when none is found.

## Package selection in recursive mode

* A folder is a package when it has a `pubspec.yaml` with an
  `environment: sdk:` constraint matching the running `dart` (or the
  `--min-sdk`/`--max-sdk`/`--ignore-sdk-constraints` filter).
* Hidden folders, `build`, `deploy`, `node_modules` are not visited.
  Symbolic links are followed.
* Packages named `_something` only get `pub get`.
* A pub workspace root gets a single `pub get`; its members are then run
  without repeating it.
* `.local/.skip_run_ci` skips the package (unless `--no-override`).
* A Flutter package is skipped with a message when `flutter` is not
  installed.
* On macOS a `Timed out waiting for Chrome to connect` failure is retried
  once.
