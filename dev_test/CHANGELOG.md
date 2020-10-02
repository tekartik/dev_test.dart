## 0.13.3+10

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