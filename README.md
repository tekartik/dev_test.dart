# dev_test.dart

`dev_test` brings back the solo and skip feature on top of the `test` package

[![Build Status](https://drone.io/github.com/alextekartik/dev_test.dart/status.png)](https://drone.io/github.com/alextekartik/dev_test.dart/latest)

It cts as a global replacement for the test package to add (back) the solo and skip feature

## Usage

In your code replace

    import 'package:test/test.dart';

with

    import 'package:dev_test/test.dart';

`solo_test`, `solo_group`, `skip_test`, `skip_group` are marked as deprecated so that you don't commit code that
might skip many needed tests

`testDescriptions` add information about the current running test (list of String naming the current group and test)
