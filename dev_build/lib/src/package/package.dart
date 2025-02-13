// in dev tree
import 'package:dev_build/src/content/lines.dart';
import 'package:dev_build/src/map_utils.dart';
import 'package:pub_semver/pub_semver.dart';

/// Pub dependency kind.
enum PubDependencyKind {
  /// Direct dependency.
  direct,

  /// Dev dependency.
  dev,

  /// Override dependency.
  override,
}

var _kindKeyMap = {
  PubDependencyKind.direct: 'dependencies',
  PubDependencyKind.dev: 'dev_dependencies',
  PubDependencyKind.override: 'dependency_overrides',
};

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
  // ignore: deprecated_member_use_from_same_package
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
    return _mixin.pubspecYamlContent.setOrAppendKey(
      'version',
      version.toString(),
    );
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
///
Iterable<String> pubspecYamlGetDependenciesPackageName(
  Map yaml, {
  PubDependencyKind? kind,
}) {
  kind ??= PubDependencyKind.direct;
  var key = _kindKeyMap[kind]!;
  var dependencies = yaml[key];
  if (dependencies is Map) {
    return dependencies.keys.cast<String>();
  }
  return <String>[];
}

/// Get the dev_dependencies packages name from pubspec.lock
Version pubspecLockGetVersion(Map yaml, String packageName) => Version.parse(
  ((yaml['packages'] as Map)[packageName] as Map)['version'] as String,
);

bool _hasKindDependency(Map yaml, String kind, String dependency) {
  var dependencies = yaml[kind] as Map?;
  if (dependencies != null) {
    if (dependencies.containsKey(dependency)) {
      return true;
    }
  }
  return false;
}

/// Handle dependencies like `path`, or 'direct:path', 'dev:path' or 'override:path'.
bool _hasDependency(Map? yaml, String dependency) {
  var parts = dependency.split(':');
  String? dependencyPrefix;
  if (parts.length == 2) {
    dependencyPrefix = parts[0];
    dependency = parts[1];
  }

  for (var (kind, prefix) in [
    ('dependencies', 'direct'),
    ('dev_dependencies', 'dev'),
    ('dependency_overrides', 'override'),
  ]) {
    if (dependencyPrefix != null && prefix != dependencyPrefix) {
      continue;
    }
    if (_hasKindDependency(yaml!, kind, dependency)) {
      return true;
    }
  }
  return false;
}

/// True if the pubspec.yaml has any of the dependencies
///
/// Handle dependencies like `path`, or 'direct:path', 'dev:path' or 'override:path'.
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

/// True if the pubspec.yaml is a workspace root
bool pubspecYamlIsWorkspaceRoot(Map map) => map.containsKey('workspace');

/// True if the pubspec.yaml has a workspace resolution
bool pubspecYamlHasWorkspaceResolution(Map map) =>
    map['resolution'] == 'workspace';

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

/// Public helper
extension VersionBoundaryVersionExt on Version {
  /// Lower boundary included by default
  VersionBoundary get lowerBoundary => VersionBoundary.lower(this);

  /// Upper boundary excluded by default
  VersionBoundary get upperBoundary => VersionBoundary.upper(this);
}

/// Version boundary.
class VersionBoundary {
  /// Version.
  final Version value;

  /// Include.
  final bool include;

  /// Version boundary.
  const VersionBoundary(this.value, this.include);

  /// Lower boundary included by default
  const VersionBoundary.lower(this.value) : include = true;

  /// Upper boundary excluded by default
  const VersionBoundary.upper(this.value) : include = false;

  @override
  String toString() => '$value $include';

  @override
  int get hashCode => value.hashCode + include.hashCode;

  @override
  bool operator ==(Object other) {
    if (other is VersionBoundary) {
      if (other.value != value) {
        return false;
      }
      if (other.include != include) {
        return false;
      }
      return true;
    }
    return false;
  }
}

/// Version boundaries.
class VersionBoundaries {
  /// min.
  final VersionBoundary? min;

  /// max.
  final VersionBoundary? max;

  @override
  String toString() {
    return toShortString();
  }

  /// Escape with '' if needed.
  String toYamlString() {
    String escape(String text) => "'$text'";
    if (_isShort()) {
      return _toShortString();
    } else if (_isSingle()) {
      return _toSingleString();
    } else if (_isEmpty()) {
      return '';
    }
    return escape(toMinMaxString());
  }

  // True for no version
  bool _isEmpty() {
    return min == null && max == null;
  }

  // True for 1.0.0
  bool _isSingle() {
    return min == max && (min?.include ?? false);
  }

  // True for ^1.0.0
  bool _isShort() {
    var min = this.min;
    var max = this.max;
    if (min == null || max == null) {
      return false;
    }
    if (!min.include || max.include) {
      return false;
    }
    if (Version(min.value.major + 1, 0, 0) == max.value) {
      return true;
    }
    if (min.value.major == 0) {
      if (min.value.minor == 0) {
        if (Version(min.value.major, min.value.minor, min.value.patch + 1) ==
            max.value) {
          return true;
        }
      } else {
        if (Version(min.value.major, min.value.minor + 1, 0) == max.value) {
          return true;
        }
      }
    } else {
      if (Version(min.value.major + 1, 0, 0) == max.value) {
        return true;
      }
    }
    return false;
  }

  /// Short string if possible, default to minMaxString.
  String toShortString() {
    if (_isShort()) {
      return _toShortString();
    } else {
      return toMinMaxString();
    }
  }

  /// If short
  String _toShortString() {
    return '^${min!.value}';
  }

  /// If single
  String _toSingleString() {
    return '${min!.value}';
  }

  /// >=minVersion <maxVersion
  String toMinMaxString() {
    var sb = StringBuffer();
    if (min != null) {
      if (_isSingle()) {
        return _toSingleString();
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
  const VersionBoundaries(this.min, this.max);

  /// Default is lower bound included, upper excluted.
  VersionBoundaries.versions(Version? versionMin, Version? versionMax)
    : min = versionMin?.lowerBoundary,
      max = versionMax?.upperBoundary;

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
  var experiments = mapValueFromParts<Object?>(map, [
    'analyzer',
    'enable-experiment',
  ]);
  return experiments is List && experiments.contains('non-nullable');
}

/// Get a list of packages
List<String> packageConfigGetPackages(Map packageConfigMap) {
  var packagesList = packageConfigMap['packages'] as Iterable;
  return packagesList.map((e) => (e as Map)['name'] as String).toList();
}
