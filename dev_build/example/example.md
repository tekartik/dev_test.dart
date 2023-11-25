# To run Global CI

```
# Once only
pub global activate dev_build

# Run common validation test (analyzer, format, test) on your package (and nested packages)
pub global run dev_build:run_ci
```