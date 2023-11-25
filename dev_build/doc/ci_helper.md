# IO utility `run_ci`

There is a convenient way to run a validation test on your package:
- analyze
- format
- test

It handles VM, web and flutter projects.

## Activation:

```
dart pub global activate dev_build
```
### Test your package minimum dependency

This will recursively run `dart/flutter pub downgrade` and `dart analyze` on all dart projects.
Any error will mean that you might update some minimum dependencies.

```
dart pub global run dev_build:run_ci --pub-downgrade --analyze --no-override --recursive
```