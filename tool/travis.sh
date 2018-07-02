#!/bin/bash

# Fast fail the script on failures.
set -e

dartanalyzer --fatal-warnings .

pub run test -p vm,firefox -j 1
pub run build_runner test -- -p vm,chrome -j 1

# test dartdevc support
# pub build example/browser --web-compiler=dartdevc