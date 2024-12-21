/// Read pubspec.yaml file (io only)
Future<Map<String, Object?>> pathGetPubspecYamlMap(String packageDir) =>
    throw UnsupportedError('pathGetPubspecYamlMap io only');

/// Read analysis_options.yaml file (io only)
Future<Map<String, Object?>> pathGetAnalysisOptionsYamlMap(String packageDir) =>
    throw UnsupportedError('pathGetAnalysisOptionsYamlMap io only');

/// Map a package to a location
Future<Map<String, Object?>> pathGetPackageConfigMap(String packageDir) =>
    throw UnsupportedError('pathGetPackageConfigMap io only');

/// Map a package to a location
Future<String> pathGetPackageConfigJsonPath(String packageDir) =>
    throw UnsupportedError('pathGetPackageConfigMap io only');

/// Get overrides path
Future<String> pathGetPubspecOverridesYamlPath(String packageDir) =>
    throw UnsupportedError('pathGetPubspecOverridesYamlPath io only');

/// Get resolved work path (overrides, config), handle workspace resolution
Future<String> pathGetResolvedWorkPath(String packageDir) =>
    throw UnsupportedError('pathGetResolvedWorkPath io only');

/// Get resolved package path, handle workspace resolution
Future<String?> pathGetResolvedPackagePath(String path, String package,
        {bool? windows}) =>
    throw UnsupportedError('pathGetResolvedPackagePath io only');
