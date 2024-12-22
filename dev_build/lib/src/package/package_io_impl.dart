// in dev tree
import 'dart:async';

import 'package:dev_build/src/content/lines_io.dart';
import 'package:path/path.dart';
import 'package:process_run/stdio.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:yaml/yaml.dart';

import 'package.dart';

/// Io base implementation.
abstract class DartPackageIo with DartPackageMixin {
  /// Package path
  String get path;

  /// Create a package from a path.
  factory DartPackageIo(String path) => _DartPackageIoImpl(path);

  /// File has been read and can be used.
  Future<void> get ready;

  /// Write current content to file.
  Future<void> write();
}

/// Io base implementation.
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

/// Read yaml map from a path.
Future<Map<String, Object?>> pathGetYaml(String path) async {
  var content = await pathGetString(path);
  try {
    return (loadYaml(content) as Map).cast<String, Object?>();
  } catch (e) {
    // ignore: avoid_print
    print('error in $path $e');
    rethrow;
  }
}

/// Read yaml map from a path.
Map<String, Object?> pathGetYamlSync(String path) {
  var content = pathGetStringSync(path);
  try {
    return (loadYaml(content) as Map).cast<String, Object?>();
  } catch (e) {
    // ignore: avoid_print
    print('error in $path $e');
    rethrow;
  }
}

/// Read a file as string.
Future<String> pathGetString(String path) async {
  var content = await File(path).readAsString();
  return content;
}

/// Read a file as string.
String pathGetStringSync(String path) {
  var content = File(path).readAsStringSync();
  return content;
}

/// Read json map from a path.
Future<Map<String, Object?>> pathGetJson(String path) async {
  var content = await File(path).readAsString();
  return (loadYaml(content) as Map).cast<String, Object?>();
}

/// Read pubspec.yaml file (io only)
Future<Map<String, Object?>> pathGetPubspecYamlMap(String packageDir) =>
    pathGetYaml(join(packageDir, 'pubspec.yaml'));

/// Read analysis_options.yaml file (io only).
Future<Map<String, Object?>> pathGetAnalysisOptionsYamlMap(String packageDir) =>
    pathGetYaml(join(packageDir, 'analysis_options.yaml'));

class _DartPackagesCache {
  final Map<String, _DartPackage> map = {};

  _DartPackage? get(String packageDir) {
    var key = normalize(absolute(packageDir));
    return map[key];
  }

  /// Only works if pub get has been ran once
  Future<_DartPackage?> getOrCreate(String packageDir) async {
    var key = normalize(absolute(packageDir));
    var pkg = map[key];
    if (pkg != null) {
      return pkg;
    }
    var standalonePackageConfigPath =
        join(pathGetDartToolDir(packageDir), 'package_config.json');
    var workspaceRefPath =
        join(pathGetDartToolDir(packageDir), 'pub', 'workspace_ref.json');

    _DartPackage setPackage(_DartPackage pkg) {
      map[key] = pkg;
      return pkg;
    }

    if (File(standalonePackageConfigPath).existsSync()) {
      return setPackage(_DartPackage(packageDir, null));
    } else if (File(workspaceRefPath).existsSync()) {
      var workspaceRef = await pathGetYaml(workspaceRefPath);
      var workspaceRoot = workspaceRef['workspaceRoot'];
      if (workspaceRoot is String) {
        var workspaceRootPath =
            normalize(absolute(join(dirname(workspaceRefPath), workspaceRoot)));
        var workspacePackageConfigPath =
            join(workspaceRootPath, pathDartToolDirPart, 'package_config.json');
        if (File(workspacePackageConfigPath).existsSync()) {
          return setPackage(_DartPackage(packageDir, workspaceRootPath));
        }
      }
    }
    return null;
  }
}

class _DartPackage {
  final String path;

  /// Resolved workspace if any, path if root
  final String? workspace;
  _DartPackage(this.path, this.workspace);
}

/// in .dart_tool/pub/workspace_ref.json
/// {
//   "workspaceRoot": "../../../.."
// }
// normalize absolute path
final _cache = _DartPackagesCache();

/// Shortcut to get a dependency, not officient as it reads multiple times the
/// package_config.json file.
///
/// Get a dependency path, you can get the project dir through its parent
/// null if not found
Future<String?> pathGetResolvedPackagePath(String path, String package,
    {bool? windows}) async {
  var packageConfigMap = await pathGetPackageConfigMap(path);
  return pathPackageConfigMapGetPackagePath(path, packageConfigMap, package,
      windows: windows);
}

/// Pubspec overrides path
Future<String> pathGetPackageConfigJsonPath(String packageDir) async {
  var workPath = await pathGetResolvedWorkPath(packageDir);
  return join(pathGetDartToolDir(workPath), 'package_config.json');
}

/// Read package_config.json file (io only).
Future<Map<String, Object?>> pathGetPackageConfigMap(String packageDir) async {
  var path = await pathGetPackageConfigJsonPath(packageDir);
  return await pathGetJson(path);
}

/// Get resolved parent path for some files (config, overrides
Future<String> pathGetResolvedWorkPath(String packageDir) async {
  var pkg = await _cache.getOrCreate(packageDir);
  if (pkg != null) {
    return pkg.workspace ?? packageDir;
  }
  throw UnsupportedError('dart pub get is needed');
}

/// Pubspec overrides path
Future<String> pathGetPubspecOverridesYamlPath(String packageDir) async {
  var workPath = await pathGetResolvedWorkPath(packageDir);
  return join(workPath, 'pubspec_overrides.yaml');
}

/// Build a file path.
String _toFilePath(String parent, String path, {bool? windows}) {
  var uri = Uri.parse(path);
  path = uri.toFilePath(windows: windows);
  if (isRelative(path)) {
    return normalize(absolute(join(parent, path)));
  }
  return normalize(absolute(path));
}

// {
//   "configVersion": 2,
//   "packages": [
//     {
//       "name": "_fe_analyzer_shared",
//       "rootUri": "file:///home/alex/.pub-cache/hosted/pub.dartlang.org/_fe_analyzer_shared-27.0.0",
//       "packageUri": "lib/",
//       "languageVersion": "2.12"
//     },
//      {
//       "name": "dev_build",
//       "rootUri": "../",
//       "packageUri": "lib/",
//       "languageVersion": "2.14"
//     }
/// Get a library path, you can get the project dir through its parent
/// null if not found
String? pathPackageConfigMapGetPackagePath(
    String path, Map packageConfigMap, String package,
    {bool? windows}) {
  var pkg = _cache.get(path);
  var packagesList = packageConfigMap['packages'] as Iterable;
  for (var packageMap in packagesList) {
    if (packageMap is Map) {
      var name = packageMap['name'];

      if (name is String && name == package) {
        var rootUri = packageMap['rootUri'];
        if (rootUri is String) {
          // rootUri if relative is relative to .dart_tool
          // we want it relative to the root project.
          // Replace .. with . to avoid going up twice
          if (rootUri.startsWith('..')) {
            rootUri = rootUri.substring(1);
          }
          var parent = pkg?.workspace ?? path;
          return _toFilePath(parent, rootUri, windows: windows);
        }
      }
    }
  }
  return null;
}

/// Get .dart_tool directory path.
String pathGetDartToolDir(String packageDir) =>
    normalize(absolute(join(packageDir, pathDartToolDirPart)));

/// path part
const pathDartToolDirPart = '.dart_tool';
