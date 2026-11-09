# IO utility `run_ci`

`run_ci` runs the validation steps of a package (pub get, format check,
analyze, tests, web build) and of the packages below it. It handles VM, web
and Flutter packages.

## Run it

```sh
# No install
dart run dev_build:run_ci@

# Or install a run_ci command (Dart 3.10+)
dart install dev_build

# Legacy
dart pub global activate dev_build
```

### Test your package minimum dependency

This runs `dart pub downgrade` (`flutter pub downgrade`) and `dart analyze` on
every package found. An error means that a minimum dependency version must be
raised.

```sh
dart run dev_build:run_ci@ --pub-downgrade --analyze --no-override
```

`--no-fatal-warnings` makes only the errors fail (the lowest versions often
bring deprecation infos).
