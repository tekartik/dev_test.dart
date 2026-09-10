---
name: dev-build-package
description: >-
  Use when a Dart script needs to read or edit pubspec.yaml, find packages in
  a folder tree, resolve dependency paths, bump versions, or manage pub global
  packages with package:dev_build: pathGetPubspecYamlMap,
  pubspecYamlGetPackageName, pubspecYamlGetVersion, pubspecYamlSupportsFlutter,
  pubspecYamlHasAnyDependencies, VersionBoundaries, isPubPackageRoot,
  getPubPackageRoot, recursivePubPath, iteratePubPath, DartPackageIo,
  DartPackageReader, PubIoPackage, pathGetResolvedPackagePath,
  pathPubspecAddDependency, compiledExe, PubGlobalPackageService,
  checkOrPubActivateHostedPackage, checkAndActivatePackage, and the
  package:dev_build/shell.dart re-export of process_run.
---

# dev_build package helpers

`package:dev_build` reads `pubspec.yaml`, `analysis_options.yaml` and
`.dart_tool/package_config.json` as plain maps, walks folder trees to find
packages, edits versions and dependencies in place, and wraps `dart pub
global`. All of it is for VM scripts (`tool/*.dart`, `bin/*.dart`, tests).

```dart
import 'package:dev_build/build_support.dart';

Future<void> main() async {
  var pubspec = await pathGetPubspecYamlMap('.');
  print(pubspecYamlGetPackageName(pubspec)); // my_package
  print(pubspecYamlGetVersion(pubspec)); // 1.2.3 (pub_semver Version)
  print(pubspecYamlSupportsFlutter(pubspec)); // false
}
```

## Guidelines

### Imports

* `package:dev_build/build_support.dart`: pubspec/analysis_options/
  package_config readers (`pathGet*`, `pubspecYaml*`,
  `packageConfigGetPackages`, `pathGetResolvedPackagePath`), package root
  lookups (`isPubPackageRoot`, `isPubPackageRootSync`, `getPubPackageRoot`,
  `getPubPackageRootSync`), `VersionBoundaries`, pubspec editing
  (`pathPubspecAddDependency`, `pathPubspecRemoveDependency`,
  `pathPubspecGetDependencyLines`), project creation (`dartCreateProject`,
  `flutterCreateProject`), `checkAndActivatePackage`,
  `checkAndActivateWebdev`, `checkOrPubActivateDevBuild`,
  `isFlutterSupportedSync`, `isNodeSupportedSync`, `nodeSetupCheck`.
* `package:dev_build/package.dart`: re-exports `package:pub_semver`
  (`Version`), `DartPackageReader`, `DartPackageIo`, `recursivePubPath`,
  `iteratePubPath`, `IteratePubPathOptions`, `recursivePackagesRun`,
  `FilterDartProjectOptions`, `PubGlobalPackage*`,
  `PubGlobalPackageService`, `checkOrPubActivateHostedPackage`, plus the
  CI entry points (`packageRunCi`, see the `dev-build-run-ci` skill).
* `package:dev_build/shell.dart` is `package:process_run/shell.dart`:
  `Shell`, `run`, `which`/`whichSync`, `dartVersion`, `dartExecutable`,
  `ShellException`, `shellArgument`, `ShellEnvironment`, `prompt`.
* `package:dev_build/menu/menu_run_ci.dart` exports `PubIoPackage` and
  `PubIoPackageOptions` (a package with `pub get`/`upgrade`/`downgrade`,
  format, dependency listing).

### Reading pubspec.yaml

* `await pathGetPubspecYamlMap(dir)` returns `Map<String, Object?>`; pass it
  to the `pubspecYaml*` functions instead of re-reading. Same for
  `pathGetAnalysisOptionsYamlMap(dir)`. They throw if the file is missing.
* `pubspecYamlGetVersion(map)` throws when `version:` is absent (workspace
  root, application); use `pubspecYamlGetVersionOrNull(map)` when unsure.
* `pubspecYamlGetSdkBoundaries(map)` returns `VersionBoundaries?` from
  `environment: sdk:`. `VersionBoundaries.parse('>=3.0.0 <4.0.0')`,
  `.parse('^3.2.0')`, `.matches(dartVersion)`, `.min`/`.max`
  (`VersionBoundary` with `value` and `include`), `toShortString()`,
  `toMinMaxString()`, `toYamlString()`.
* Dependency checks: `pubspecYamlHasAnyDependencies(map, ['test'])` looks
  in `dependencies`, `dev_dependencies` and `dependency_overrides`. Prefix
  a name with `direct:`, `dev:` or `override:` to restrict the section.
  `pubspecYamlGetDependenciesMap(map, kind: PubDependencyKind.dev)` and
  `pubspecYamlGetDependenciesPackageName(map, kind: ...)` list a section
  (`direct` is the default kind).
* Flags: `pubspecYamlSupportsFlutter` (depends on `flutter`),
  `pubspecYamlSupportsWeb` (`build_web_compilers`),
  `pubspecYamlSupportsNode` (`build_node_compilers`),
  `pubspecYamlSupportsTest` (`test`), `pubspecYamlIsWorkspaceRoot`
  (`workspace:` key), `pubspecYamlHasWorkspaceResolution`
  (`resolution: workspace`).
* `DartPackageReader.pubspecString(content)` /
  `DartPackageReader.pubspecYaml(map)` wrap a map with `getVersion()` and
  `getDependencyObject(dependency: 'path')` (returns `{'path': <spec>}` or
  null). Use it for in-memory or test content.

### Locating packages

* `await isPubPackageRoot(dir)` is true when `dir/pubspec.yaml` exists and
  its `sdk` constraint matches the running Dart. Pass
  `filterDartProjectOptions: FilterDartProjectOptions(ignoreSdkConstraints:
  true)` (or `minSdk`/`maxSdk`) to change the filter. `isPubPackageRootSync`
  only checks the file.
* `await getPubPackageRoot(anyPathInside)` walks up to the nearest package
  root and throws if none is found (`getPubPackageRootSync` likewise).
* `await recursivePubPath(['.'])` lists every package folder under the
  given folders, including the folders themselves, sorted and without
  duplicates. Hidden folders, `build`, `deploy`, `node_modules` are not
  visited; links are followed. `dependencies: ['direct:sembast']` keeps
  only packages depending on it; `readConfig: true` also matches
  transitive dependencies through `package_config.json`.
* `iteratePubPath(['.'], onPubPath: (path) => true, options:
  IteratePubPathOptions(recursive:, dependencies:, readConfig:,
  filterDartProjectOptions:))` scans lazily; return `false` from the
  handler to stop early.

### Resolved dependencies

* `await pathGetPackageConfigMap(dir)` reads the package config after
  `pub get` (workspace resolution handled); `packageConfigGetPackages(map)`
  lists package names; `await pathGetResolvedPackagePath(dir, 'sembast')`
  returns the absolute folder of a dependency or null. These throw
  `UnsupportedError('dart pub get is needed')` before a `pub get`.
* `PubIoPackage(dir)`: `await package.ready` then `isFlutter`,
  `isWorkspace`, `dofPub` (`dart pub` or `flutter pub`), `pubGet()`,
  `pubUpgrade()`, `pubDowngrade()` (all with `offline:`), `format()`,
  `checkFormat()` (throws when a file is not formatted),
  `getResolvedDependencies()`, `getResolvedPackagePath(name)`,
  `dumpDeps()`, `getWorkspaceRootPath()`, `versionOrNull`.

### Editing a package

* `DartPackageIo(dir)`: `await package.ready`, `package.getVersion()`,
  `package.setVersion(Version(1, 0, 1))` (returns true if changed),
  `await package.write()`. `await package.writeVersion(version)` does the
  three steps and returns true if the file changed. Only the `version:`
  line is rewritten, the rest of the file is preserved.
* `await pathPubspecAddDependency(dir, 'sembast', dependencyLines:
  ['path: ../sembast'])` inserts under `dependencies:` when absent (true
  when added); `pathPubspecRemoveDependency(dir, name)` removes it;
  `pathPubspecGetDependencyLines(dir, name)` returns the lines or null.
  Text based: it does not reorder or reformat the file.
* `DartPackageIo(dir).compiledExe(script: 'bin/main.dart', minVersion:
  Version(1, 2, 0))` runs `dart compile exe` into
  `build/<linux|macos|windows>/<name>` when missing or when
  `<exe> --version` is older than `minVersion`, and returns
  `DartPackageIoCompiledExe(path, version)`.
* `dartCreateProject(path: 'out/app', template: dartTemplateConsole)` and
  `flutterCreateProject(path:, template: flutterTemplateApp, platforms:)`
  wrap `dart create` / `flutter create` (templates: `dartTemplateConsole`,
  `dartTemplatePackage`, `dartTemplateWeb`, `flutterTemplateApp`,
  `flutterTemplatePackage`).

### pub global packages

* `await checkOrPubActivateHostedPackage('webdev', versionBoundaries:
  VersionBoundaries.parse('^3.0.0'))` activates a hosted package when it is
  missing or its activated version is out of the boundaries.
  `checkOrPubActivateDevBuild()` does it for `dev_build` itself.
* `PubGlobalPackageService()`: `getActivatedPackage(name)` parses
  `dart pub global list` into a `PubGlobalHostedPackage`,
  `PubGlobalGitPackage` or `PubGlobalPathPackage` (`name`, `version`,
  `source`); `activateGlobalPackage(PubGlobalGitPackageInstall(name,
  gitUrl:, gitPath:, gitRef:))` / `PubGlobalPathPackageInstall(name,
  path:)` / `PubGlobalHostedPackageInstall(name, versionBoundaries:)`;
  `deactivateGlobalPackage(name)`. Both accept `dryRun:` and `verbose:`.
* `checkAndActivatePackage('webdev')` is the older helper (activate if
  not listed, no version check); `checkAndActivateWebdev()` also upgrades
  an old webdev.

### Platform

* Everything here needs `dart:io`. `pathGetPubspecYamlMap`,
  `pathGetPackageConfigMap`, `pathGetAnalysisOptionsYamlMap` and
  `pathGetResolvedPackagePath` compile on the web but throw
  `UnsupportedError('... io only')` there.

## Examples

### Print information about the packages of a repository

```dart
import 'package:dev_build/build_support.dart';
import 'package:dev_build/package.dart';
import 'package:path/path.dart';

Future<void> main() async {
  for (var dir in await recursivePubPath(['.'])) {
    var pubspec = await pathGetPubspecYamlMap(dir);
    var name = pubspecYamlGetPackageName(pubspec);
    var version = pubspecYamlGetVersionOrNull(pubspec);
    var sdk = pubspecYamlGetSdkBoundaries(pubspec);
    var flutter = pubspecYamlSupportsFlutter(pubspec) ? ' (flutter)' : '';
    print('${normalize(absolute(dir))}: $name $version sdk: $sdk$flutter');
  }
}
```

### Bump the patch version of a package

```dart
import 'package:dev_build/package.dart';

Future<void> bumpPatch(String dir) async {
  var package = DartPackageIo(dir);
  await package.ready;
  var version = package.getVersion();
  var next = Version(version.major, version.minor, version.patch + 1);
  if (await package.writeVersion(next)) {
    print('$dir: $version -> $next');
  }
}
```

### Packages depending on a given package, transitively

```dart
import 'package:dev_build/package.dart';

Future<List<String>> usersOf(String package, {String root = '.'}) =>
    recursivePubPath([root], dependencies: [package], readConfig: true);
```

### Stop at the first Flutter package found

```dart
import 'package:dev_build/build_support.dart';
import 'package:dev_build/package.dart';

Future<String?> firstFlutterPackage(String root) async {
  String? found;
  await iteratePubPath(
    [root],
    onPubPath: (dir) async {
      var pubspec = await pathGetPubspecYamlMap(dir);
      if (pubspecYamlSupportsFlutter(pubspec)) {
        found = dir;
        return false; // stop
      }
      return true;
    },
  );
  return found;
}
```

### Where is a dependency installed?

```dart
import 'package:dev_build/build_support.dart';

Future<void> main() async {
  // Requires a previous `dart pub get`
  var path = await pathGetResolvedPackagePath('.', 'path');
  print(path); // /home/me/.pub-cache/hosted/pub.dev/path-1.9.1
}
```

### Add a path dependency and run pub get

```dart
import 'package:dev_build/build_support.dart';
import 'package:dev_build/menu/menu_run_ci.dart' show PubIoPackage;

Future<void> main() async {
  var dir = 'packages/app';
  var added = await pathPubspecAddDependency(
    dir,
    'my_lib',
    dependencyLines: ['path: ../my_lib'],
  );
  if (added) {
    var package = PubIoPackage(dir);
    await package.ready;
    await package.pubGet();
  }
}
```

### Make sure a global tool is installed before using it

```dart
import 'package:dev_build/package.dart';
import 'package:dev_build/shell.dart';

Future<void> main() async {
  await checkOrPubActivateHostedPackage(
    'webdev',
    versionBoundaries: VersionBoundaries.parse('>=3.0.0 <4.0.0'),
  );
  await run('dart pub global run webdev --version');
}
```

### Compile a package binary once and reuse it

```dart
import 'package:dev_build/package.dart';
import 'package:dev_build/shell.dart';

Future<void> main() async {
  var exe = await DartPackageIo('.').compiledExe(
    script: 'bin/main.dart',
    minVersion: Version(1, 0, 0),
  );
  await run('${shellArgument(exe.path)} --help');
}
```

### Version boundaries

```dart
import 'package:dev_build/build_support.dart';
import 'package:dev_build/shell.dart' show dartVersion;

void main() {
  var boundaries = VersionBoundaries.parse('^3.2.0');
  print(boundaries.toMinMaxString()); // >=3.2.0 <4.0.0
  print(boundaries.matches(dartVersion)); // true on Dart 3.x >= 3.2
  print(VersionBoundaries.parse('>=1.0.0 <2.0.0').toShortString()); // ^1.0.0
}
```

## Common mistakes

* Importing `package:dev_build/package.dart` for `pubspecYamlGetPackageName`
  or `pathGetPubspecYamlMap`: they are in `build_support.dart`.
* Calling `pubspecYamlGetVersion` on a workspace root or an app without
  `version:`: it throws, use `pubspecYamlGetVersionOrNull`.
* Reading `package_config.json` helpers before `pub get`: they throw.
* Using `DartPackageIo` without awaiting `ready` first.
* Expecting `recursivePubPath` to return packages whose sdk constraint does
  not match the running Dart: pass `FilterDartProjectOptions(
  ignoreSdkConstraints: true)` to list them.
