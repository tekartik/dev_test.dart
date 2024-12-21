import 'dart:io';

import 'package:dev_build/build_support.dart';
import 'package:dev_build/menu/menu_io.dart';
import 'package:dev_build/package.dart';
import 'package:dev_build/shell.dart' hide prompt;
import 'package:path/path.dart';

Future<void> main(List<String> args) async {
  mainMenuConsole(args, () {
    runCiMenu('.');
  });
}

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
    var packageConfigMap =
        _packageConfigMap ??= await cachedOrGetPackageConfigMap();

    var packages = List.of(packageConfigGetPackages(packageConfigMap))..sort();
    return packages;
  }

  /// Get resolved package path
  Future<String?> getResolvedPackagePath(String package) async {
    var packageConfigMap =
        _packageConfigMap ??= await cachedOrGetPackageConfigMap();

    var packages =
        pathPackageConfigMapGetPackagePath(path, packageConfigMap, package);

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
    var pubspecYaml = await pathGetPubspecYamlMap(path);
    stdout.writeln('${normalize(absolute(path))}:');
    isFlutter = pubspecYamlSupportsFlutter(pubspecYaml);
  }();

  /// True for flutter project
  late final bool isFlutter;

  /// Pub io package
  PubIoPackage(this.path, {PubIoPackageOptions? options})
      : options = options ?? PubIoPackageOptions();

  /// Dart or flutter
  String get dof => isFlutter ? 'flutter' : 'dart';

  /// Pub get
  Future<void> pubGet() async {
    _packageConfigMap = null;
    await shell.run('$dof pub get');
  }

  /// Pub upgrade
  Future<void> pubUpgrade() async {
    _packageConfigMap = null;
    await shell.run('$dof pub upgrade');
  }

  /// Pub downgrade
  Future<void> pubDowngrade() async {
    _packageConfigMap = null;
    await shell.run('$dof pub downgrade');
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

/// Common CI menu
Future<void> runCiMenu(String path) async {
  var package = PubIoPackage(path);
  var verbose = true;
  await package.ready;
  write('Running CI for package ${package.path}');
  item('pub get', () async {
    await package.pubGet();
  });
  item('pub upgrade', () async {
    await package.pubUpgrade();
  });
  item('pub downgrade', () async {
    await package.pubDowngrade();
  });
  item('dump dependencies', () async {
    await package.dumpDeps();
  });
  item('run_ci', () async {
    await packageRunCi(package.path);
  });
  item('analyze', () async {
    await packageRunCi(package.path,
        options: PackageRunCiOptions(
            analyzeOnly: true, noPubGet: true, verbose: verbose));
  });
  item('format', () async {
    await packageRunCi(package.path,
        options: PackageRunCiOptions(
            formatOnly: true, noPubGet: true, verbose: verbose));
  });
  item('cd (prompt)', () async {
    var dir = await prompt('Enter a directory');
    package.shell = Shell(workingDirectory: dir);
  });
}
