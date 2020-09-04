// in dev tree
import 'dart:io';

import 'package:path/path.dart';
import 'package:yaml/yaml.dart';

Future<Map<String, dynamic>> pathGetYaml(String path) async {
  var content = await File(path).readAsString();
  return (loadYaml(content) as Map)?.cast<String, dynamic>();
}

Future<Map<String, dynamic>> pathGetJson(String path) async {
  var content = await File(path).readAsString();
  return (loadYaml(content) as Map)?.cast<String, dynamic>();
}

Future<Map<String, dynamic>> pathGetPubspecYamlMap(String packageDir) =>
    pathGetYaml(join(packageDir, 'pubspec.yaml'));

Future<Map<String, dynamic>> pathGetAnalysisOptionsYamlMap(String packageDir) =>
    pathGetYaml(join(packageDir, 'analysis_options.yaml'));
