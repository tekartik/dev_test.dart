// in dev tree
import 'dart:io';

import 'package:dev_test/src/map_utils.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:path/path.dart';
import 'package:yaml/yaml.dart';

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

bool pubspecYamlHasAnyDependencies(Map yaml, List<String> dependencies) {
  bool _hasDependencies(String kind, String dependency) {
    var dependencies = yaml[kind] as Map;
    if (dependencies != null) {
      if (dependencies.containsKey(dependency)) {
        return true;
      }
    }
    return false;
  }

  for (var dependency in dependencies) {
    if (_hasDependencies('dependencies', dependency) ||
        _hasDependencies('dev_dependencies', dependency) ||
        _hasDependencies('dependency_overrides', dependency)) {
      return true;
    }
  }

  return false;
}

@deprecated
Future<Map> getPackageYaml(String packageDir) => getPubspecYaml(packageDir);

@deprecated
Future<Map> getPubspecYaml(String packageDir) => getPubspecYamlMap(packageDir);

Future<Map<String, dynamic>> getPubspecYamlMap(String packageDir) =>
    _getYaml(join(packageDir, 'pubspec.yaml'));

Future<Map<String, dynamic>> _getYaml(String path) async {
  var content = await File(path).readAsString();
  return (loadYaml(content) as Map)?.cast<String, dynamic>();
}

bool pubspecYamlIsFlutterPackageRoot(Map map) {
  return mapValueFromParts(map, ['dependencies', 'flutter']) != null;
}
