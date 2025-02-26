// in dev tree
import 'package:dev_build/src/content/lines.dart';
import 'package:dev_build/src/map_utils.dart';
import 'package:dev_build/src/yaml_utils.dart';
import 'package:pub_semver/pub_semver.dart';
import 'version_boundary.dart';
export 'version_boundary.dart';

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
abstract class DartPackage implements DartPackageReader {
  /// Dart package from a yaml content.
  factory DartPackage.withContent(String content) {
    return _DartPackageImpl(YamlLinesContent.withText(content));
  }
}

/// Dart package reader.
abstract class DartPackageReader {
  /// Pubspec yaml content.
  Map<String, Object?> get pubspecYaml;

  /// Factory constructor from existing pubspec yaml.
  factory DartPackageReader.pubspecYaml(Map<String, Object?> pubspecYaml) {
    return _DartPackageReader(pubspecYaml: pubspecYaml);
  }

  /// Factory constructor from pubspec string content.
  factory DartPackageReader.pubspecString(String content) {
    return DartPackageReader.pubspecYaml(content.yamlMap);
  }
}

class _DartPackageReader implements DartPackageReader {
  @override
  final Map<String, Object?> pubspecYaml;

  _DartPackageReader({required this.pubspecYaml});
}

/// Dart package reader extension.
extension DartPackageReaderExt on DartPackageReader {
  /// Get version from pubspec.yaml
  Version getVersion() {
    return pubspecYamlGetVersion(pubspecYaml);
  }

  /// Get the dependency map as `{"dependency: <content>"}`
  /// Null if not found
  Object? getDependencyObject({
    required String dependency,
    PubDependencyKind? kind,
  }) {
    return pubspecYamlGetDependencyObject(pubspecYaml, dependency);
  }
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
extension DartPackageWriterExt on DartPackage {
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
  var dependencies = pubspecYamlGetDependenciesMap(yaml);
  if (dependencies != null) {
    return dependencies.keys.cast<String>();
  }
  return <String>[];
}

/// Get the dependency map
Model? pubspecYamlGetDependenciesMap(Map yaml, {PubDependencyKind? kind}) {
  kind ??= PubDependencyKind.direct;
  var key = _kindKeyMap[kind]!;
  var dependencies = mapValueAsMap(yaml, key);
  return dependencies;
}

/// Get the dependency map as `{"dependency: <content>"}`
Model? pubspecYamlGetDependencyObject(
  Map yaml,
  String dependency, {
  PubDependencyKind? kind,
}) {
  var dependencies = pubspecYamlGetDependenciesMap(yaml);
  if (dependencies != null) {
    if (dependencies.containsKey(dependency)) {
      return Model.from({dependency: dependencies[dependency]});
    }
  }
  return null;
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
