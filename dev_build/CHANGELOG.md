## 1.1.1+8

* Add `pathGetResolvedPackagePath`, `pathGetPubspecOverridesYamlPath`, `pathGetResolvedWorkPath`,
  `pathGetPackageConfigJsonPath`, `pathGetResolvedPackagePath`, `pathGetResolvedWorkPath`  helpers
  to `build_support`
* Add `runCiInitPubWorkspacesCache` to `package`
* Adding basic interactive menu in run_ci
* Start handling workspace

## 1.1.0+3

* Split dart test runner per platform

## 1.1.0+2

* menu: Make prompt not nullable (kind of breaking change, sorry...)
* allow reading config (package_config.json) when finding sub-projects

## 1.0.1

* Export `process_run/shell.dart` in `shell.dart`

## 1.0.0+14

* Make it `1.0.0`
* Add `PubDependencyKind` and `pubspecYamlGetDependenciesPackageName` helper

## 0.16.7+4

* test using node if supported.

## 0.16.6

* test using dart2wasm if supported.

## 0.16.5

* Simple io menu

## 0.16.4+3

* Fix recursive pub path concurrency

## 0.16.3+2

* Initial version from  `dev_test`
* Fix remove dependency