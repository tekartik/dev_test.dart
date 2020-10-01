// in dev tree
import 'package:dev_test/src/map_utils.dart';
import 'package:pub_semver/pub_semver.dart';

String pubspecYamlGetPackageName(Map yaml) => yaml['name'] as String;

Version pubspecYamlGetVersion(Map yaml) =>
    Version.parse(yaml['version'] as String);

Iterable<String> pubspecYamlGetTestDependenciesPackageName(Map yaml) {
  if (yaml.containsKey('test_dependencies')) {
    var list = (yaml['test_dependencies'] as Iterable)?.cast<String>();
    list ??= <String>[];
  }
  return null;
}

Iterable<String> pubspecYamlGetDependenciesPackageName(Map yaml) {
  return ((yaml['dependencies'] as Map)?.keys)?.cast<String>();
}

Version pubspecLockGetVersion(Map yaml, String packageName) =>
    Version.parse(yaml['packages'][packageName]['version'] as String);

bool _hasKindDependency(Map yaml, String kind, String dependency) {
  var dependencies = yaml[kind] as Map;
  if (dependencies != null) {
    if (dependencies.containsKey(dependency)) {
      return true;
    }
  }
  return false;
}

bool _hasDependency(Map yaml, String dependency) {
  for (var kind in [
    'dependencies',
    'dev_dependencies',
    'dependency_overrides'
  ]) {
    if (_hasKindDependency(yaml, kind, dependency)) {
      return true;
    }
  }
  return false;
}

bool pubspecYamlHasAnyDependencies(Map yaml, List<String> dependencies) {
  for (var dependency in dependencies) {
    if (_hasDependency(yaml, dependency)) {
      return true;
    }
  }
  return false;
}

bool pubspecYamlHasAllDependencies(Map yaml, List<String> dependencies) {
  for (var dependency in dependencies) {
    if (!_hasDependency(yaml, dependency)) {
      return false;
    }
  }
  return true;
}

bool pubspecYamlSupportsFlutter(Map map) =>
    pubspecYamlHasAnyDependencies(map, ['flutter']);

bool pubspecYamlSupportsWeb(Map map) {
  return pubspecYamlHasAnyDependencies(map, ['build_web_compilers']);
}

bool pubspecYamlSupportsTest(Map map) {
  return pubspecYamlHasAnyDependencies(map, ['test']);
}

bool pubspecYamlSupportsNode(Map map) {
  return pubspecYamlHasAnyDependencies(map, ['build_node_compilers']);
}

bool pubspecYamlSupportsBuildRunner(Map map) {
  return pubspecYamlHasAnyDependencies(map, ['build_runner']);
}

class VersionBoundary {
  final Version value;
  final bool include;

  VersionBoundary(this.value, this.include);

  @override
  String toString() => '$value $include';
}

class VersionBoundaries {
  final VersionBoundary min;
  final VersionBoundary max;

  @override
  String toString() {
    var sb = StringBuffer();
    if (min != null) {
      if (max == min) {
        return min.value.toString();
      }
      sb.write('>');
      if (min.include) {
        sb.write('=');
      }
      sb.write(min.value);
    }
    if (max != null) {
      if (sb.isNotEmpty) {
        sb.write(' ');
      }
      sb.write('<');
      if (max.include) {
        sb.write('=');
      }
      sb.write(max.value);
    }
    return sb.toString();
  }

  VersionBoundaries(this.min, this.max);

  static VersionBoundaries tryParse(String text) {
    if (text is String) {
      var parts = text.trim().split(' ');
      VersionBoundary min;
      VersionBoundary max;
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
    return null;
  }

  // True if a version match the boundaries
  bool match(Version version) {
    if (min != null) {
      if (min.include) {
        if (version < min.value) {
          return false;
        }
      } else if (version <= min.value) {
        return false;
      }
    }
    if (max != null) {
      if (max.include) {
        if (version > max.value) {
          return false;
        }
      } else if (version >= max.value) {
        return false;
      }
    }
    return true;
  }
}

VersionBoundaries pubspecYamlGetSdkBoundaries(Map map) {
  // environment:
  //   sdk: '>=2.8.0 <3.0.0'
  var rawSdk = mapValueFromParts(map, ['environment', 'sdk']);
  if (rawSdk is String) {
    return VersionBoundaries.tryParse(rawSdk);
  }
  return null;
}

bool analysisOptionsSupportsNnbdExperiment(Map map) {
  // analyzer:
  //   enable-experiment:
  //     - non-nullable
  var experiments = mapValueFromParts(map, ['analyzer', 'enable-experiment']);
  return experiments is List && experiments.contains('non-nullable');
}
