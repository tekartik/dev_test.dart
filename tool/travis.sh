#!/bin/bash

# Fast fail the script on failures.
set -e

dartanalyzer --fatal-warnings \
  lib/test.dart \

pub run test -p vm,firefox -j 1