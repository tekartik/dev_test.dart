// in dev tree
import 'package:dev_build/src/content/lines.dart';
import 'package:dev_build/src/map_utils.dart';
import 'package:pub_semver/pub_semver.dart';

/// Dart package.
abstract class DartPackage {
  /// Dart package from a yaml content.
  factory DartPackage.withContent(String content) {
    return _DartPackageImpl(YamlLinesContent.withText(content));
  }

  /// Pubspec yaml content.
  Map<String, Object?> get pubspecYaml;
}

/// Dart package.
mixin DartPackageMixin implements DartPackage {
  /// Pubspec yaml content.
  late YamlLinesContent pubspecYamlContent;

  @override
  Map<String, Object?> get pubspecYaml => pubspecYamlContent.yaml;
}

class _DartPackageImpl with DartPackageMixin {
  _DartPackageImpl(YamlLinesContent pubspecYamlContent);
}

/// Dart package.
extension DartPackageExt on DartPackage {
  /// Get version from pubspec.yaml
  Version getVersion() {
    return pubspecYamlGetVersion(pubspecYaml);
  }

  DartPackageMixin get _mixin => this as DartPackageMixin;

  /// True if changed
  bool setVersion(Version version) {
    return _mixin.pubspecYamlContent
        .setOrAppendKey('version', version.toString());
  }
}

/// Get the package name from pubspec.yaml
String? pubspecYamlGetPackageName(Map yaml) => yaml['name'] as String?;

/// Get the package version from pubspec.yaml
Version pubspecYamlGetVersion(Map yaml) =>
    Version.parse(yaml['version'] as String);

/// Get the test_dependencies packages name
Iterable<String>? pubspecYamlGetTestDependenciesPackageName(Map yaml) {
  if (yaml.containsKey('test_dependencies')) {
    var list = (yaml['test_dependencies'] as Iterable?)?.cast<String>();
    list ??= <String>[];
  }
  return null;
}

/// Get the dependencies packages name.
Iterable<String>? pubspecYamlGetDependenciesPackageName(Map yaml) {
  return ((yaml['dependencies'] as Map?)?.keys)?.cast<String>();
}

/// Get the dev_dependencies packages name from pubspec.lock
Version pubspecLockGetVersion(Map yaml, String packageName) => Version.parse(
    ((yaml['packages'] as Map)[packageName] as Map)['version'] as String);

bool _hasKindDependency(Map yaml, String kind, String dependency) {
  var dependencies = yaml[kind] as Map?;
  if (dependencies != null) {
    if (dependencies.containsKey(dependency)) {
      return true;
    }
  }
  return false;
}

bool _hasDependency(Map? yaml, String dependency) {
  for (var kind in [
    'dependencies',
    'dev_dependencies',
    'dependency_overrides'
  ]) {
    if (_hasKindDependency(yaml!, kind, dependency)) {
      return true;
    }
  }
  return false;
}

/// True if the pubspec.yaml has any of the dependencies
bool pubspecYamlHasAnyDependencies(Map yaml, List<String> dependencies) {
  for (var dependency in dependencies) {
    if (_hasDependency(yaml, dependency)) {
      return true;
    }
  }
  return false;
}

/// True if the pubspec.yaml has all the dependencies.
bool pubspecYamlHasAllDependencies(Map yaml, List<String> dependencies) {
  for (var dependency in dependencies) {
    if (!_hasDependency(yaml, dependency)) {
      return false;
    }
  }
  return true;
}

/// True if the pubspec.yaml has the flutter dependency.
bool pubspecYamlSupportsFlutter(Map map) =>
    pubspecYamlHasAnyDependencies(map, ['flutter']);

/// True if the pubspec.yaml has the web dependency.
bool pubspecYamlSupportsWeb(Map map) {
  return pubspecYamlHasAnyDependencies(map, ['build_web_compilers']);
}

/// True if the pubspec.yaml has the test dependency.
bool pubspecYamlSupportsTest(Map map) {
  return pubspecYamlHasAnyDependencies(map, ['test']);
}

/// True if the pubspec.yaml has the node build dependency.
/// Not supported.
bool pubspecYamlSupportsNode(Map map) {
  return pubspecYamlHasAnyDependencies(map, ['build_node_compilers']);
}

/// True if the pubspec.yaml has the build_runner dependency.
bool pubspecYamlSupportsBuildRunner(Map map) {
  return pubspecYamlHasAnyDependencies(map, ['build_runner']);
}

/// Version boundary.
class VersionBoundary {
  /// Version.
  final Version value;

  /// Include.
  final bool include;

  /// Version boundary.
  const VersionBoundary(this.value, this.include);

  @override
  String toString() => '$value $include';
}

/// Version boundaries.
class VersionBoundaries {
  /// min.
  final VersionBoundary? min;

  /// max.
  final VersionBoundary? max;

  @override
  String toString() {
    var sb = StringBuffer();
    if (min != null) {
      if (max == min) {
        return min!.value.toString();
      }
      sb.write('>');
      if (min!.include) {
        sb.write('=');
      }
      sb.write(min!.value);
    }
    if (max != null) {
      if (sb.isNotEmpty) {
        sb.write(' ');
      }
      sb.write('<');
      if (max!.include) {
        sb.write('=');
      }
      sb.write(max!.value);
    }
    return sb.toString();
  }

  /// Version boundaries.
  VersionBoundaries(this.min, this.max);

  /// Version boundaries pinned.
  VersionBoundaries.version(Version version)
      : min = VersionBoundary(version, true),
        max = VersionBoundary(version, true);

  /// Compat
  static VersionBoundaries? tryParse(String text) {
    try {
      return parse(text);
    } catch (_) {
      return null;
    }
  }

  /// Parse
  static VersionBoundaries parse(String text) {
    var parts = text.trim().split(' ');
    VersionBoundary? min;
    VersionBoundary? max;
    for (var part in parts) {
      if (part.startsWith('>=')) {
        try {
          min = VersionBoundary(Version.parse(part.substring(2)), true);
        } catch (_) {}
      } else if (part.startsWith('>')) {
        try {
          min = VersionBoundary(Version.parse(part.substring(1)), false);
        } catch (_) {}
      } else if (part.startsWith('<=')) {
        try {
          max = VersionBoundary(Version.parse(part.substring(2)), true);
        } catch (_) {}
      } else if (part.startsWith('<')) {
        try {
          max = VersionBoundary(Version.parse(part.substring(1)), false);
        } catch (_) {}
      } else if (part.startsWith('^')) {
        try {
          min = VersionBoundary(Version.parse(part.substring(1)), true);
          if (min.value.major != 0) {
            max = VersionBoundary(Version(min.value.major + 1, 0, 0), false);
          } else if (min.value.minor != 0) {
            max = VersionBoundary(Version(0, min.value.minor + 1, 0), false);
          } else {
            max = VersionBoundary(Version(0, 0, min.value.patch + 1), false);
          }
        } catch (_) {}
      } else {
        try {
          min = max = VersionBoundary(Version.parse(part), true);
        } catch (_) {}
      }
    }
    return VersionBoundaries(min, max);
  }

  // TO deprecate
  /// Prefer [matches]
  bool match(Version version) {
    return matches(version);
  }

  /// True if a version match the boundaries
  bool matches(Version version) {
    return matchesMin(version) && matchesMax(version);
  }

  /// True if a version match the max boundary
  bool matchesMax(Version version) {
    if (max != null) {
      if (max!.include) {
        if (version > max!.value) {
          return false;
        }
      } else if (version >= max!.value) {
        return false;
      }
    }
    return true;
  }

  /// True if a version match the min boundary.
  bool matchesMin(Version version) {
    if (min != null) {
      if (min!.include) {
        if (version < min!.value) {
          return false;
        }
      } else if (version <= min!.value) {
        return false;
      }
    }
    return true;
  }

  @override
  int get hashCode => (min?.hashCode ?? 0) + (max?.hashCode ?? 0);

  @override
  bool operator ==(Object other) {
    if (other is VersionBoundaries) {
      if (other.min != min) {
        return false;
      }
      if (other.max != max) {
        return false;
      }
      return true;
    }
    return false;
  }
}

/// Get sdk boundaries
VersionBoundaries? pubspecYamlGetSdkBoundaries(Map? map) {
  // environment:
  //   sdk: '>=2.8.0 <3.0.0'
  var rawSdk = mapValueFromParts<Object?>(map, ['environment', 'sdk']);
  if (rawSdk is String) {
    return VersionBoundaries.parse(rawSdk);
  }
  return null;
}

/// True if the pubspec.yaml has the nnbd experiment enabled.
/// No longer used after dart 3.0.0
bool analysisOptionsSupportsNnbdExperiment(Map? map) {
  // analyzer:
  //   enable-experiment:
  //     - non-nullable
  var experiments =
      mapValueFromParts<Object?>(map, ['analyzer', 'enable-experiment']);
  return experiments is List && experiments.contains('non-nullable');
}

/// Get a list of packages
List<String> packageConfigGetPackages(Map packageConfigMap) {
  var packagesList = packageConfigMap['packages'] as Iterable;
  return packagesList.map((e) => (e as Map)['name'] as String).toList();
}
