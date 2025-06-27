import 'package:dev_build/build_support.dart';
import 'package:dev_build/shell.dart';
import 'package:dev_build/src/pub_io.dart';
import 'package:dev_build/src/run_ci.dart';
import 'package:path/path.dart';
import 'package:process_run/stdio.dart';

/// Pub io options
class PubIoPackageOptions {
  /// Verbose
  final bool verbose;

  /// Pub io package options
  PubIoPackageOptions({this.verbose = false});
}

/// Pub io package
class PubIoPackage {
  /// Options
  final PubIoPackageOptions options;

  /// Path
  final String path;

  Map<String, Object?>? _packageConfigMap;

  /// True if any project has flutter in it
  late bool _useFlutterPub;

  /// Read and cache package config map
  Future<Map<String, Object?>> readPackageConfigMap() async {
    _packageConfigMap = await pathGetPackageConfigMap(path);
    return _packageConfigMap!;
  }

  // {
  //   "configVersion": 2,
  //   "packages": [
  //     {
  //       "name": "dart_flutter_team_lints",
  //       "rootUri": "file:///home/alex/.pub-cache/hosted/pub.dev/dart_flutter_team_lints-3.2.0",
  //       "packageUri": "lib/",
  //       "languageVersion": "3.5"
  //     },
  /// Get resolved dependency list
  Future<List<String>> getResolvedDependencies() async {
    var packageConfigMap = _packageConfigMap ??=
        await cachedOrGetPackageConfigMap();

    var packages = List.of(packageConfigGetPackages(packageConfigMap))..sort();
    return packages;
  }

  /// Get resolved package path
  Future<String?> getResolvedPackagePath(String package) async {
    var packageConfigMap = _packageConfigMap ??=
        await cachedOrGetPackageConfigMap();

    var packages = pathPackageConfigMapGetPackagePath(
      path,
      packageConfigMap,
      package,
    );

    return packages;
  }

  /// Cached or get package config map
  Future<Map<String, Object?>> cachedOrGetPackageConfigMap() async {
    _packageConfigMap ??= await readPackageConfigMap();
    return _packageConfigMap!;
  }

  /// Shell
  late var shell = Shell(workingDirectory: path);

  /// Ready (pubspec.yaml loaded)
  late final ready = () async {
    pubspecYaml = await pathGetPubspecYamlMap(path);
    // stdout.writeln('${normalize(absolute(path))}:');
    isFlutter = pubspecYamlSupportsFlutter(pubspecYaml);
    _useFlutterPub = isFlutter;
    if (!isFlutter && (isWorkspace || hasWorkspaceResolution)) {
      try {
        // Find all projects
        var workspace = await getWorkspaceRootPath();
        var pubspecYaml = await pathGetPubspecYamlMap(workspace);
        var projects = pubspecYaml['workspace'];

        if (projects is List) {
          for (var project in projects) {
            var projectPath = join(workspace, project.toString());
            var projectPubspecYaml = await pathGetPubspecYamlMap(projectPath);
            if (pubspecYamlSupportsFlutter(projectPubspecYaml)) {
              _useFlutterPub = true;
              break;
            }
          }
        }
      } catch (e) {
        stderr.writeln('Error: $e trying to find workspace info');
      }
    }
  }();

  /// Ok when ready
  late Map<String, Object?> pubspecYaml;

  /// True for workspace
  bool get isWorkspace => pubspecYamlIsWorkspaceRoot(pubspecYaml);

  /// True if it has workspace resolution
  bool get hasWorkspaceResolution =>
      pubspecYamlHasWorkspaceResolution(pubspecYaml);

  /// Get the workspace root path (only if isWorkspace or hasWorkspaceResolution)
  Future<String> getWorkspaceRootPath() async {
    if (isWorkspace) {
      return path;
    } else {
      var parent = normalize(absolute(path));
      while (true) {
        var newParent = dirname(parent);
        if (newParent == parent) {
          break;
        }
        parent = newParent;
        if (isPubPackageRootSync(parent)) {
          var pubspecYaml = await pathGetPubspecYamlMap(parent);
          if (pubspecYamlIsWorkspaceRoot(pubspecYaml)) {
            return parent;
          }
        }
      }
    }
    throw 'No workspace root found';
  }

  /// True for flutter project
  late final bool isFlutter;

  /// Pub io package
  PubIoPackage(this.path, {PubIoPackageOptions? options})
    : options = options ?? PubIoPackageOptions();

  /// Dart or flutter
  String get dof => isFlutter ? 'flutter' : 'dart';

  /// shell environment
  ShellEnvironment get shellEnvironment =>
      _useFlutterPub ? flutterDartShellEnvironment : ShellEnvironment();

  /// Dart pub of flutter pub (handles workspace)
  String get dofPub => '${_useFlutterPub ? 'flutter' : 'dart'} pub';

  /// Pub get
  Future<void> pubGet({bool? offline}) async {
    _packageConfigMap = null;
    await shell.run('$dofPub get${offline == true ? ' --offline' : ''}');
  }

  /// Pub upgrade
  Future<void> pubUpgrade({bool? offline}) async {
    _packageConfigMap = null;
    await shell.run('$dofPub upgrade${offline == true ? ' --offline' : ''}');
  }

  /// Pub downgrade
  Future<void> pubDowngrade({bool? offline}) async {
    _packageConfigMap = null;
    await shell.run('$dofPub downgrade${offline == true ? ' --offline' : ''}');
  }

  /// List dependencies
  Future<void> dumpDeps() async {
    var deps = await getResolvedDependencies();
    for (var dep in deps) {
      var packagePath = await getResolvedPackagePath(dep);
      if (packagePath != null) {
        stdout.writeln('$dep: $packagePath');
      } else {
        stdout.writeln('$dep: not found');
      }
    }
  }
}
