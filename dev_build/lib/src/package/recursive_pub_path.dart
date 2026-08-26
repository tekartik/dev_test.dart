import 'dart:async';
import 'dart:collection';

import 'package:dev_build/shell.dart';
import 'package:dev_build/src/import.dart';
import 'package:dev_build/src/mixin/package.dart';
import 'package:dev_build/src/pub_io.dart';
import 'package:path/path.dart';
import 'package:pool/pool.dart';
import 'package:process_run/stdio.dart';

/// false if symlink
bool isDirectoryNotLinkSynk(String path) =>
    FileSystemEntity.isDirectorySync(path) &&
    !FileSystemEntity.isLinkSync(path);

/// Resolve a relative link if necessary
String _linkTargetSync(String path) {
  var link = Link(path);
  var target = link.targetSync();

  if (isRelative(target)) {
    target = normalize(absolute(join(path, '..', target)));
  }
  return target;
}

/// Normalize path using posix style
/// Not valid if current path contains a part containing a backslash (not recommended)
String posixNormalize(String path) {
  return posix.normalize(path.replaceAll('\\', '/'));
}

bool _isToBeIgnored(String baseName) {
  var posixName = posixNormalize(baseName);
  // Don't ignore the current directory
  if (posixName == '.') {
    return false;
  }
  // Don't ignore the parent directory
  if (posixName == '..') {
    return false;
  }

  // Don't ignore relative path in parents
  if (posix.normalize(baseName).startsWith('../')) {
    return false;
  }
  // Ignore blacklisted targets
  if (_blackListedTargets.contains(baseName)) {
    return true;
  }

  // Ignore typically hidden folder
  return baseName.startsWith('.');
}

final List<String> _blackListedTargets = [
  '.',
  '..',
  'build',
  'deploy',
  'node_modules',
];

/// Read config
Future<bool> _checkProjectHasTransitiveDependencies(
  String dir, {
  required Map pubspecYaml,
  required List<String> dependencies,
}) async {
  Map? packageConfigMap;
  try {
    packageConfigMap = await pathGetPackageConfigMap(dir);
  } catch (_) {
    // Try pub get
    var isFlutterPackage = pubspecYamlSupportsFlutter(pubspecYaml);
    var dartOrFlutter = isFlutterPackage ? 'flutter' : 'dart';
    try {
      await Shell(workingDirectory: dir).run('$dartOrFlutter pub get');

      packageConfigMap = await pathGetPubspecYamlMap(dir);
    } catch (e) {
      stderr.writeln('Error: $e failed to get package-config.yaml');
    }
    return false;
  }
  if (packageConfigGetPackages(
    packageConfigMap,
  ).toSet().intersection(dependencies.toSet()).isNotEmpty) {
    return true;
  }
  return false;
}

/// True if the dir should be handled
Future<bool> _checkProjectMatch(
  String dir, {
  List<String>? dependencies,
  bool? readConfig,
  FilterDartProjectOptions? filterDartProjectOptions,
}) async {
  // Ignore folder starting with .
  // don't event go below
  if (!_isToBeIgnored(basename(dir))) {
    if (await isPubPackageRoot(
      dir,
      filterDartProjectOptions: filterDartProjectOptions,
    )) {
      if (dependencies is List && dependencies!.isNotEmpty) {
        final pubspecYaml = await pathGetPubspecYamlMap(dir);
        if (pubspecYamlHasAnyDependencies(pubspecYaml, dependencies)) {
          return true;
        }

        if (readConfig ?? false) {
          // Check the config file
          return await _checkProjectHasTransitiveDependencies(
            dir,
            dependencies: dependencies,
            pubspecYaml: pubspecYaml,
          );
        }
      } else {
        // add package path
        return true;
      }
    }
  }
  return false;
}

/// if [forceRecursive] is true, we folder going deeper even if the current
/// path is a dart project
///
/// If [readConfig] is true, it will read the config file to get the dependencies
Future<List<String>> filterPubPath(
  List<String> dirs, {
  List<String>? dependencies,
  bool? readConfig,
  FilterDartProjectOptions? filterDartProjectOptions,
}) async {
  var list = <String>[];

  for (final dir in dirs) {
    if (FileSystemEntity.isDirectorySync(dir)) {
      final handled = await _checkProjectMatch(
        dir,
        dependencies: dependencies,
        readConfig: readConfig,
        filterDartProjectOptions: filterDartProjectOptions,
      );
      if (handled) {
        list.add(dir);
      }
    } else {
      throw ArgumentError('$dir not a directory');
    }
  }
  return list;
}

/// if [forceRecursive] is true, we folder going deeper even if the current
/// path is a dart project
///
/// if [ignoreSdkConstraints] is true, it lists the project even if not compatible.
///
/// if [dependencies] is specified, it will only list the project that contains
/// such dependency, use either dependency like `path`, or 'direct:path', 'dev:path' or 'override:path'.
/// Returns the list of valid pub folder, including me
Future<List<String>> recursivePubPath(
  List<String> dirs, {
  List<String>? dependencies,
  bool? readConfig,
  FilterDartProjectOptions? filterDartProjectOptions,
}) async {
  var pubDirs = await filterPubPath(
    dirs,
    dependencies: dependencies,
    readConfig: readConfig,
    filterDartProjectOptions: filterDartProjectOptions,
  );

  Future<List<String>> getSubDirs(String dir) async {
    if (!_isToBeIgnored(basename(dir))) {
      // devPrint('testing: $dir');
      final sub = <String>[];
      final futures = <Future>[];
      await Directory(dir).list().listen((FileSystemEntity fse) {
        var subDir = fse.path;
        // Make sure it is not added even if it is a package root
        if (!_isToBeIgnored(basename(subDir))) {
          if (FileSystemEntity.isDirectorySync(subDir)) {
            // Also handle the case where the directory linked is a dart project
            futures.add(() async {
              // follow links
              var dir = subDir;

              var isLink = FileSystemEntity.isLinkSync(dir);
              if (isLink) {
                dir = _linkTargetSync(dir);
              }
              var subPubDirs = await filterPubPath(
                [dir],
                dependencies: dependencies,
                readConfig: readConfig,
                filterDartProjectOptions: filterDartProjectOptions,
              );
              sub.addAll(subPubDirs);
              sub.addAll(await getSubDirs(dir));
            }());
          }
        }
      }).asFuture<void>();
      await Future.wait(futures);
      return sub;
    }
    return <String>[];
  }

  for (final dir in dirs) {
    if (FileSystemEntity.isDirectorySync(dir)) {
      pubDirs.addAll(await getSubDirs(dir));
    } else {
      throw ArgumentError('$dir not a directory');
    }
  }

  return removeDuplicates(pubDirs)..sort();
}

/// Remove duplicates.
List<String> removeDuplicates(List<String> dirs) {
  // remove duplicates
  var absolutes = <String>{};
  // devPrint(pubDirs);
  var list = <String>[];
  for (var dir in dirs) {
    var absolutePath = normalize(absolute(dir));
    if (!absolutes.contains(absolutePath)) {
      absolutes.add(absolutePath);
      list.add(dir);
    }
  }
  return list;
}

/// Each path is tested
///
/// [poolSize] default to 4
Future<void> recursivePackagesRun(
  List<String> paths, {
  required FutureOr<dynamic> Function(String package) action,
  bool? verbose,
  int? poolSize,
  List<String>? dependencies,
  FilterDartProjectOptions? filterDartProjectOptions,
}) => recursiveActions(
  paths,
  action: action,
  verbose: verbose,
  poolSize: poolSize,
  dependencies: dependencies,
  filterDartProjectOptions: filterDartProjectOptions,
);

/// Each path is tested
///
/// [poolSize] default to 4
Future<void> recursiveActions(
  List<String> paths, {
  required FutureOr<dynamic> Function(String package) action,
  bool? verbose,
  int? poolSize,
  List<String>? dependencies,
  FilterDartProjectOptions? filterDartProjectOptions,
}) async {
  poolSize ??= 4;
  verbose ??= false;
  // filter what could be packages in the paths list
  var dirsOrFiles = paths;
  if (dirsOrFiles.isEmpty) {
    dirsOrFiles = [Directory.current.path];
  }

  final packagePool = Pool(poolSize);

  var packages = await recursivePubPath(
    paths,
    dependencies: dependencies,
    filterDartProjectOptions: filterDartProjectOptions,
  );

  var futures = <Future>[];
  for (final pkg in packages) {
    futures.add(
      packagePool.withResource(() async {
        try {
          await action(pkg);
        } catch (e) {
          stderr.writeln('ERROR $e in $pkg');
          rethrow;
        }
      }),
    );
  }
  await Future.wait(futures);
}

/// Pub path handler. Return true to continue, false to stop the iteration.
typedef IteratePubPathHandler = FutureOr<bool> Function(String pubPath);

/// Options for [iteratePubPath].
class IteratePubPathOptions {
  /// Create iterate options.
  const IteratePubPathOptions({
    this.dependencies,
    this.recursive,
    this.readConfig,
    this.filterDartProjectOptions,
  });

  /// if specified, only the projects that contain such dependency are
  /// iterated, use either a dependency like `path`, or 'direct:path',
  /// 'dev:path' or 'override:path'.
  final List<String>? dependencies;

  /// Iterate the sub directories (default true), when false only [dirs]
  /// themselves are tested.
  final bool? recursive;

  /// If true, the package config file is read to also match transitive
  /// [dependencies].
  final bool? readConfig;

  /// Dart project filter (sdk constraints).
  final FilterDartProjectOptions? filterDartProjectOptions;
}

/// List the sub directories of [dir], links resolved, ignoring hidden and
/// black listed folders.
Future<List<String>> _listSubDirs(String dir) async {
  if (_isToBeIgnored(basename(dir))) {
    return const <String>[];
  }
  var subDirs = <String>[];
  await Directory(dir).list().listen((FileSystemEntity fse) {
    var subDir = fse.path;
    // Make sure it is not added even if it is a package root
    if (_isToBeIgnored(basename(subDir))) {
      return;
    }
    if (!FileSystemEntity.isDirectorySync(subDir)) {
      return;
    }
    // Also handle the case where the directory linked is a dart project,
    // follow links
    if (FileSystemEntity.isLinkSync(subDir)) {
      subDir = _linkTargetSync(subDir);
    }
    subDirs.add(subDir);
  }).asFuture<void>();
  return subDirs;
}

/// Iterate over the pub packages found in [dirs].
///
/// [onPubPath] is called for each pub folder found, including [dirs]
/// themselves, in alphabetical path order (i.e. the order of the list
/// returned by [recursivePubPath]). Return false to stop the iteration.
///
/// Contrary to [recursivePubPath], the folders are scanned lazily, so the
/// iteration can stop before the whole tree is read.
///
/// A folder is never handled twice. Links are resolved and reported using
/// their target path, which is reported where the link is found, so it can
/// break the alphabetical order.
Future<void> iteratePubPath(
  List<String> dirs, {
  IteratePubPathOptions? options,
  required IteratePubPathHandler onPubPath,
}) async {
  options ??= const IteratePubPathOptions();
  var dependencies = options.dependencies;
  var readConfig = options.readConfig;
  var filterDartProjectOptions = options.filterDartProjectOptions;
  var recursive = options.recursive ?? true;

  // Folders to visit, sorted by path.
  var pending = SplayTreeSet<String>();

  // Absolute normalized paths already queued, to avoid duplicates and
  // link loops.
  var queued = <String>{};

  void addPending(String dir) {
    if (queued.add(normalize(absolute(dir)))) {
      pending.add(dir);
    }
  }

  for (final dir in dirs) {
    if (!FileSystemEntity.isDirectorySync(dir)) {
      throw ArgumentError('$dir not a directory');
    }
    addPending(dir);
  }

  while (pending.isNotEmpty) {
    // Smallest path first, any folder found later is a sub folder of one of
    // the pending folders, hence greater.
    var dir = pending.first;
    pending.remove(dir);

    final handled = await _checkProjectMatch(
      dir,
      dependencies: dependencies,
      readConfig: readConfig,
      filterDartProjectOptions: filterDartProjectOptions,
    );
    if (handled) {
      if (!await onPubPath(dir)) {
        return;
      }
    }
    if (recursive) {
      for (final subDir in await _listSubDirs(dir)) {
        addPending(subDir);
      }
    }
  }
}
