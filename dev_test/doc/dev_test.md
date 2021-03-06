# dev_test.dart

`dev_test` brings (back) the solo and skip features on top of the `test` package

[![Build Status](https://travis-ci.org/tekartik/dev_test.dart.svg?branch=master)](https://travis-ci.org/tekartik/dev_test.dart)

It is a layer on top of the `test` package that adds (back) the solo and skip feature so that you can run/debug a filtered set of tests from the IDE without having to use `pub run test -n xxx`.
It remains however compatible the existing `test` package and tests can be run using `pub run test`. Make sure you have both `dev_test` and `test` as dependencies in your pubspec.yaml

`solo_test`, `solo_group`, `skip_test`, `skip_group` are marked as deprecated so that you don't commit code (check the dart analysis result) that
might skip many needed tests. Also running tests will report if any tests were skipped.

## Usage

Your `pubspec.yaml` should contain the following dev_depencencies:

    dev_dependencies:
      test: any
      dev_test: any

In your `xxxx_test.dart` files replace

    import 'package:test/test.dart';

with

    import 'package:dev_test/test.dart';

`solo_test`, `solo_group`, `skip_test`, `skip_group` are marked as deprecated so that you don't commit code that
might skip many needed tests.

`testDescriptions` add information about the current running test (list of String naming the current group and test)

`devTestRun` will be optionally needed if you have a mix of `test` and `dev_test` to make sure the declared tests or groups belongs to the correct group they are declared in
