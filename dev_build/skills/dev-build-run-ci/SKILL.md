---
name: dev-build-run-ci
description: >-
  Use when running or scripting CI checks (pub get, dart format check, dart
  analyze, dart/flutter test, web build) on a Dart or Flutter package or on a
  whole repository tree with package:dev_build: the run_ci executable
  (dart run dev_build:run_ci, --recursive, --no-test, --analyze, --fix,
  --pub-downgrade, --offline, --prj-info, --ignore-errors, --vm-test), the
  packageRunCi / PackageRunCiOptions / recursivePackagesRun /
  SinglePackageCiRunner API, the tool/run_ci.dart and
  tool/run_ci_override.dart conventions, .local/.skip_run_ci, dart_test.yaml
  platforms and pub workspaces.
---

# dev_build run_ci: validate a package or a tree

`package:dev_build` runs the standard validation steps of a Dart or Flutter
package: `pub get`, format check, analyze, tests on every supported platform,
and an optional web build. It works on a single package or recursively on
every package found under a folder. Same code drives the `run_ci` executable
and the `packageRunCi()` API. VM only (it spawns `dart`/`flutter` processes).

```dart
// tool/run_ci.dart
import 'package:dev_build/package.dart';

Future<void> main() async {
  await packageRunCi('.');
}
```

```bash
dart run dev_build:run_ci            # same steps from the command line
```

## Guidelines

### Setup

* Add `dev_build` to `dev_dependencies`. Import
  `package:dev_build/package.dart` for `packageRunCi`, `PackageRunCiOptions`,
  `recursivePackagesRun`, `recursivePubPath`, `SinglePackageCiRunner`.
* Put the script in `tool/run_ci.dart` (repository convention) and run it
  with `dart run tool/run_ci.dart`. For a one-off from the command line use
  `dart run dev_build:run_ci [<path>] [<flags>]`, or activate it once with
  `dart pub global activate dev_build` and run `run_ci`.

### What a run does, in order

* `dart pub get` (or `flutter pub get` when the package, or any package of
  its pub workspace, depends on `flutter`). `--offline` adds `--offline`.
* Format check: `dart format --set-exit-if-changed <top level dirs that
  contain dart files>` (`lib test bin tool example ...`). Nested packages,
  hidden dirs, `build`, `deploy`, `node_modules`, `.dart_tool` are excluded.
* Analyze: `dart analyze --fatal-warnings --fatal-infos .` for Dart,
  `flutter analyze --no-pub .` for Flutter. Infos fail the build: keep
  `analysis_options.yaml` clean.
* Test: `flutter test --no-pub` for Flutter. For Dart, `dart test` is run
  once per platform: `vm` always, `chrome` when `build_web_compilers` is a
  dependency, `node` when `build_node_compilers` is a dependency and `node`
  is installed. Skipped entirely when there is no `test/` folder.
* Build: `flutter build web --no-pub` when `web/index.html` and
  `lib/main.dart` exist; `dart pub global run webdev build` for a Dart
  package that depends on `build_web_compilers` + `build_runner` and has
  `web/index.html`.
* A `dart_test.yaml` `platforms:` list restricts the platforms above,
  `compilers:` (`dart2js`, `dart2wasm`) adds `--compiler` for browser runs.

### Options (`PackageRunCiOptions` / flags)

* Skip a step: `noPubGet`, `noFormat`, `noAnalyze`, `noTest`, `noBuild`
  (`--no-pub-get`, `--no-format`, `--no-analyze`, `--no-test`,
  `--no-build`).
* Run only one step: `formatOnly`, `analyzeOnly`, `testOnly`, `buildOnly`,
  `pubGetOnly`, `pubUpgradeOnly`, `pubDowngradeOnly`, `fixOnly` (`--format`,
  `--analyze`, `--test`, `--build`, `--pub-get`, `--pub-upgrade`,
  `--pub-downgrade`, `--fix`). An "only" option turns every other step off;
  `analyzeOnly` still runs `pub get` first unless `noPubGet: true`.
* Test platforms: `vmTestOnly` (`--vm-test`), `noVmTest`, `noBrowserTest`,
  `chromeJsTestOnly` (`--chrome-js-test`, dart2js only), `noNodeTest`,
  `noNpmInstall`.
* `fixOnly` runs `dart format <dirs>` then `dart fix --apply` and stops.
* `recursive: true` (`--recursive`, the CLI default; API default is
  `false`) finds every package below `path`, links followed, and runs them
  through a pool of `poolSize` (default 4 in the API, `-j`/`--concurrency`
  default 1 in the CLI).
* `ignoreErrors` (`--ignore-errors`, `-i`): a failing package is reported
  and the run continues with the next one, instead of throwing.
* `dryRun` (`--dry-run`) prints the shell lines instead of running them.
  `prjInfo` (`--prj-info`) prints the sdk constraint and flutter tag,
  `noRunCi` (`--no-run-ci`) stops after that, `printPath` (`--print-path`)
  only prints the package path. `verbose` (`-v`).
* `filterDartProjectOptions: FilterDartProjectOptions(minSdk:, maxSdk:,
  ignoreSdkConstraints:)` (`--min-sdk '>=3.0.0'`, `--max-sdk`,
  `--ignore-sdk-constraints`) selects which packages are considered. By
  default a package whose `environment: sdk:` does not match the running
  `dart` is skipped.
* `noOverride` (`--no-override`) ignores `tool/run_ci_override.dart` and
  `.local/.skip_run_ci`.

### Repository conventions the runner honours

* `tool/run_ci_override.dart` in a package: run with `dart run` instead of
  the standard steps (use `noOverride`/`--no-override` from inside it or
  the run recurses). Use it for a package that needs custom steps.
* `.local/.skip_run_ci` (empty file) skips the package in recursive runs.
  Create it with `run_ci config --skip-run-ci [<path>]`; git-ignore `.local`.
* A package whose name starts with `_` only gets `pub get`.
* A pub workspace root gets `pub get` once for the whole workspace, then is
  skipped for format/analyze/test; members are run individually.
* Everything under a hidden folder, `build`, `deploy` or `node_modules` is
  never visited.

### Custom actions over a tree

* `recursivePubPath(['.'])` returns every package folder (sorted, links
  resolved). `dependencies: ['sembast']` keeps packages depending on it,
  with `direct:`/`dev:`/`override:` prefixes to narrow the kind, and
  `readConfig: true` also matches transitive dependencies through
  `.dart_tool/package_config.json`.
* `recursivePackagesRun(['.'], action: (dir) async {...}, poolSize: 1)`
  runs a callback per package. Combine with `Shell(workingDirectory: dir)`
  from `package:dev_build/shell.dart`.
* `SinglePackageCiRunner(PubIoPackage(path), options)` (`PubIoPackage` from
  `package:dev_build/menu/menu_run_ci.dart`) exposes the individual steps:
  `init()`, then `format()`, `analyze()`, `runTest(testOptions: [...])`,
  `fix()`. Use it to pass extra `dart test` arguments.
* `runCiInitPubWorkspacesCache()` is called by `packageRunCi` so a
  workspace gets one `pub get`; call it yourself before looping with
  `singlePackageRunCi`-style code.

## Examples

### tool/run_ci.dart for a repository

```dart
import 'package:dev_build/package.dart';

Future<void> main() async {
  // Every package under the repo root, one at a time.
  await packageRunCi('..', options: PackageRunCiOptions(recursive: true));
}
```

### Analyze only, without touching the network

```dart
import 'package:dev_build/package.dart';

Future<void> main() async {
  await packageRunCi(
    '.',
    options: PackageRunCiOptions(
      recursive: true,
      analyzeOnly: true,
      noPubGet: true,
    ),
  );
}
```

### Check minimum dependency versions

```dart
import 'package:dev_build/package.dart';

Future<void> main() async {
  // pub downgrade + analyze on every package, ignoring tool/run_ci_override.dart
  await packageRunCi(
    '.',
    options: PackageRunCiOptions(
      recursive: true,
      pubDowngradeOnly: true,
      analyzeOnly: true,
      noOverride: true,
    ),
  );
}
```

### Fix formatting and lints recursively

```dart
import 'package:dev_build/package.dart';

Future<void> main() async {
  await packageRunCi(
    '.',
    options: PackageRunCiOptions(recursive: true, fixOnly: true),
  );
}
```

### tool/run_ci_override.dart with custom steps

```dart
import 'package:dev_build/package.dart';
import 'package:dev_build/shell.dart';

Future<void> main() async {
  // noOverride is required, otherwise this file runs itself again.
  await packageRunCi(
    '.',
    options: PackageRunCiOptions(noOverride: true, noTest: true),
  );
  await Shell().run('dart test --platform vm --exclude-tags slow');
}
```

### Extra test arguments with SinglePackageCiRunner

```dart
import 'package:dev_build/menu/menu_run_ci.dart' show PubIoPackage;
import 'package:dev_build/package.dart';

Future<void> main() async {
  var package = PubIoPackage('.');
  var runner = SinglePackageCiRunner(package, PackageRunCiOptions());
  await runner.init();
  await package.pubGet();
  await runner.analyze();
  await runner.runTest(testOptions: ['--reporter', 'expanded']);
}
```

### Run a shell command in every package that depends on a package

```dart
import 'package:dev_build/package.dart';
import 'package:dev_build/shell.dart';

Future<void> main() async {
  await recursivePackagesRun(
    ['.'],
    dependencies: ['direct:sembast'],
    poolSize: 1,
    action: (dir) async {
      await Shell(workingDirectory: dir).run('dart pub upgrade sembast');
    },
  );
}
```

### Command line

```bash
dart run dev_build:run_ci                      # this package and nested ones
dart run dev_build:run_ci --no-test ../other   # skip tests, other folder
dart run dev_build:run_ci --analyze --no-pub-get
dart run dev_build:run_ci --pub-downgrade --analyze --no-override --recursive
dart run dev_build:run_ci --fix --recursive
dart run dev_build:run_ci --vm-test --offline
dart run dev_build:run_ci --prj-info --no-run-ci   # list packages and sdk
dart run dev_build:run_ci config --skip-run-ci packages/legacy
dart run dev_build:run_ci menu                 # interactive console menu
```

## Common mistakes

* Expecting `packageRunCi('.')` to recurse: the API default is
  `recursive: false`; the executable defaults to `--recursive`.
* Writing `tool/run_ci_override.dart` that calls `packageRunCi` without
  `noOverride: true`.
* Relying on `--no-analyze` to hide lints: the standard analyze uses
  `--fatal-infos`, fix the code or the `analysis_options.yaml`.
* Adding `build_web_compilers` to a package that has no browser tests: it
  turns on `dart test --platform chrome` for every run.
* Using `packageRunCi` from a web or Flutter app: it needs `dart:io` and
  the `dart`/`flutter` executables on the PATH.

## More

See [references/cli-options.md](references/cli-options.md) for the complete
flag list of the `run_ci` executable and the exact commands executed per
package type.
