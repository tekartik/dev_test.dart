// in dev tree
import 'dart:async';
import 'dart:io';

import 'package:path/path.dart';
import 'package:yaml/yaml.dart';

Future<Map<String, Object?>> pathGetYaml(String path) async {
  var content = await File(path).readAsString();
  try {
    return (loadYaml(content) as Map).cast<String, Object?>();
  } catch (e) {
    print('error in $path $e');
    rethrow;
  }
}

Future<Map<String, Object?>> pathGetJson(String path) async {
  var content = await File(path).readAsString();
  return (loadYaml(content) as Map).cast<String, Object?>();
}

Future<Map<String, Object?>> pathGetPubspecYamlMap(String packageDir) =>
    pathGetYaml(join(packageDir, 'pubspec.yaml'));

Future<Map<String, Object?>> pathGetAnalysisOptionsYamlMap(String packageDir) =>
    pathGetYaml(join(packageDir, 'analysis_options.yaml'));
