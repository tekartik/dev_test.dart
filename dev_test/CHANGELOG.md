## 0.16.2-1

* Add `DartPackage` and `DartPackageIo` helpers

## 0.16.1+4

* dart 3 support
* Add `--ignore-sdk-constraints`, `--min-sdk` and `--max-sdk` options to `run_ci`

## 0.15.7+3

* Add `--ignore-errors` options to `run_ci`
* Use `dart format` instead of `flutter format` deprecated in dart 2.19

## 0.15.6

* strict-casts and strict-inference support

## 0.15.5+2

* Use `dart format` instead of `dart_style:format`
* Requires sdk 2.18

## 0.15.4+4

* add flag `prj-info` (extra project information) to `run_ci` executable 
* add flag `no-run-ci` (no action) to `run_ci` executable
 
## 0.15.3+1

* recursivePubPath now check whether dart version is supported
* dart 2.14 lints

## 0.15.2+2

* Add `dry-run` options to `run_ci`.

## 0.15.1

* `nnbd` supports, breaking change.

## 0.13.5

* Add `build_support.dart` to help building project for testing.
* Allow running on NNBD projects

## 0.13.3+12

* Add `packageRunCi` to run common dart/flutter package test, node test and nnbd tests.
* Skipped `dart pub run build_runner test -- -p chrome` on travis for ioPackageRunCi
* Add `run_ci` executable, usable with `dart pub global run dev_test:run_ci`

## 0.13.1+1

* remove meta code allow code sharing with flutter

## 0.12.0

* dart2 only

## 0.11.0

* `implicit-casts: false` support

## 0.10.0

* bug fix
* dart 2.0.0 support

## 0.6.0

* Add for multiple `setUp()`, `tearDown()`, `setUpAll()` and `tearDownAll()` in the same group
* Travis test integration

## 0.5.0

* Add support for `setUpAll()` and `tearDownAll()` methods

## 0.4.0

* Initial revision with `solo_test`, `solo_group`, `skip_test` and `skip_group` support 