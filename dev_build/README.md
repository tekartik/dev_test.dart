# dev_build.dart

[![Build Status](https://travis-ci.org/tekartik/dev_build.dart.svg?branch=master)](https://travis-ci.org/tekartik/dev_build.dart)

### IO utility `run_ci`

There is a convenient way to run a validation test on your package:
- analyze
- format
- test

It handles VM, web and flutter projects.

## Activation:

```
# Once only
dart pub global activate dev_build
```

```
# Run common validation test (analyzer, format, test) on your package (and nested packages)
pub global run dev_build:run_ci

# Run common validation tests on another package (and nested packages)
pub global run dev_build:run_ci <path>

# You might run it simply (if global pub path is in your paths)
run_ci

# Perform recursively a pub downgrade and analyze.
run_ci --pub-downgrade --analyze --no-override --recursive

# Perform dart fix --apply recursively
run_ci --fix --recursive
```

- By default it also checks subfolder projects (i.e. you can run it at the top of your repo)
- You can override the behavior by creating a 'tool/run_ci_override.dart' file
- You can skip a folder by creating an empty placeholder file '.local/.skip_run_ci'

