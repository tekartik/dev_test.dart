# dev_test.dart

[![Build Status](https://travis-ci.org/tekartik/dev_test.dart.svg?branch=master)](https://travis-ci.org/tekartik/dev_test.dart)

## Testing

### IO utility `run_ci`

There is a convenient way to run a validation test on your package:
- analyze
- format
- test

It handles VM, web and flutter projects.

```
# Once only
pub global activate dev_test

# Run common validation test (analyzer, format, test) on your package (and nested packages)
pub global run dev_test:run_ci

# Run common validation tests on another package (and nested packages)
pub global run dev_test:run_ci <path>

# You might run it simply (if global pub path is in your paths)
run_ci
```

- By default it also checks subfolder projects (i.e. you can run it at the top of your repo)
- You can override the behavior by creating a 'tool/run_ci_override.dart' file
- You can skip a folder by creating an empty placeholder file '.local/.skip_run_ci'

### API

Initial goal of `dev_test` was to bring (back) the solo and skip features on top of the `test` package.
See [dev_test API](https://github.com/tekartik/dev_test.dart/blob/master/dev_test/doc/test.md) for more information

