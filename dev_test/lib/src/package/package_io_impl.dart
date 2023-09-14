// in dev tree
import 'dart:async';
import 'dart:io';

import 'package:dev_test/src/content/lines_io.dart';
import 'package:path/path.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:yaml/yaml.dart';
import 'package.dart';

/// Io base implementation.
abstract class DartPackageIo with DartPackageMixin {
  /// Package path
  String get path;

  factory DartPackageIo(String path) => _DartPackageIoImpl(path);

  /// File has been read and can be used.
  Future<void> get ready;

  /// Write current content to file.
  Future<void> write();
}

extension DartPackageIoExt on DartPackageIo {
  /// Write a package version.
  Future<bool> writeVersion(Version version) async {
    await ready;
    if (setVersion(version)) {
      await write();
      return true;
    }

    return false;
  }
}

class _DartPackageIoImpl with DartPackageMixin implements DartPackageIo {
  @override
  final String path;
  _DartPackageIoImpl(this.path) {
    pubspecYamlContent = YamlLinesContentIo(join(path, 'pubspec.yaml'));
  }
  YamlLinesContentIo get pubspecYamlContentIo =>
      pubspecYamlContent as YamlLinesContentIo;

  /// Or throw
  Future<void> _read() async {
    if (!await pubspecYamlContentIo.read()) {
      throw Exception('Error reading $path');
    }
  }

  /// File has been read and can be used.
  @override
  late final ready = _read();
  @override
  Future<void> write() async {
    await pubspecYamlContentIo.write();
  }
}

Future<Map<String, Object?>> pathGetYaml(String path) async {
  var content = await pathGetString(path);
  try {
    return (loadYaml(content) as Map).cast<String, Object?>();
  } catch (e) {
    print('error in $path $e');
    rethrow;
  }
}

Future<String> pathGetString(String path) async {
  var content = await File(path).readAsString();
  return content;
}

Future<Map<String, Object?>> pathGetJson(String path) async {
  var content = await File(path).readAsString();
  return (loadYaml(content) as Map).cast<String, Object?>();
}

Future<Map<String, Object?>> pathGetPubspecYamlMap(String packageDir) =>
    pathGetYaml(join(packageDir, 'pubspec.yaml'));

Future<Map<String, Object?>> pathGetAnalysisOptionsYamlMap(String packageDir) =>
    pathGetYaml(join(packageDir, 'analysis_options.yaml'));

Future<Map<String, Object?>> pathGetPackageConfigMap(String packageDir) =>
    pathGetYaml(join(pathGetDartToolDir(packageDir), 'package_config.json'));

String pathGetDartToolDir(String packageDir) =>
    normalize(absolute(join(packageDir, '.dart_tool')));
