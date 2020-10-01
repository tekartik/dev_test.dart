import 'dart:async';
import 'dart:io';

import 'package:dev_test/src/node_support.dart';
import 'package:dev_test/src/package/package.dart';
import 'package:dev_test/src/pub_io.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart';
import 'package:process_run/shell_run.dart';
import 'package:process_run/which.dart';
import 'package:pub_semver/pub_semver.dart';

import 'import.dart';
import 'mixin/package.dart';
import 'package/recursive_pub_path.dart';

Future main(List<String> arguments) async {
  String path;
  if (arguments.isNotEmpty ?? false) {
    var firstArg = arguments.first?.toString();
    if (await isPubPackageRoot(firstArg)) {
      path = firstArg;
    }
  }
  path ??= Directory.current.path;
  await packageRunCi(path);
}

/// true if flutter is supported
final isNodeSupported = whichSync('node') != null;

/// List the top level dirs basenames
Future<List<String>> topLevelDirs(String dir) async {
  var list = <String>[];
  await Directory(dir)
      .list(recursive: false, followLinks: false)
      .listen((event) {
    if (isDirectoryNotLinkSynk(event.path)) {
      // devPrint('adding top ${basename(event.path)}');
      list.add(basename(event.path));
    }
  }).asFuture();
  return list;
}

List<String> _forbiddenDirs = ['node_modules', '.dart_tool', 'build', 'deploy'];

/// True if a dir has at least one dart file
Future<bool> hasDartFiles(String dir) async {
  var dirs = <String>[];
  var hasOneDartFile = false;
  await Directory(dir)
      .list(recursive: false, followLinks: false)
      .listen((event) {
    if (event is Directory) {
      dirs.add(basename(event.path));
    } else if (extension(event.path) == '.dart') {
      hasOneDartFile = true;
      //subscription.cancel();
    }
  }).asFuture();
  if (!hasOneDartFile) {
    for (var subDir in dirs) {
      if (await hasDartFiles(join(dir, subDir))) {
        hasOneDartFile = true;
        break;
      }
    }
  }
  return hasOneDartFile;
}

/// Only return sub dirs that contains dart files
///
/// Return top level are relative
Future<List<String>> filterTopLevelDartDirs(String path) async {
  var dirs = await topLevelDirs(path);
  var sanitized = <String>[];
  for (var dirname in dirs) {
    var dirPath = path == '.' ? dirname : join(path, dirname);
    if (dirname.startsWith('.')) {
      continue;
    }
    if (_forbiddenDirs.contains(dirname)) {
      continue;
    }
    // Ignore nested-projects
    if (await isPubPackageRoot(dirPath)) {
      continue;
    }
    if (!await hasDartFiles(dirPath)) {
      continue;
    }
    sanitized.add(dirname);
  }
  return sanitized..sort();
}

/*
/// find the path at the top level that contains dart file
/// and does not contain sub project
Future<List<String>> findTargetDartDirectories(String dir) async {
  var targets = <String>[];
  for (var entity in await Directory(dir).list(followLinks: false).toList()) {
    var entityBasename = basename(entity.path);
    var subDir = join(dir, entityBasename);
    if (isDirectoryNotLinkSynk(subDir)) {
      bool _isToBeIgnored(String baseName) {
        if (_blackListedTargets.contains(baseName)) {
          return true;
        }

        if (baseName.startsWith('.')) {
          return true;
        }

        return false;
      }

      if (!_isToBeIgnored(entityBasename) &&
          !(await isPubPackageRoot(subDir))) {
        var paths = (await recursiveDartEntities(subDir))
            .map((path) => join(subDir, path))
            .toList(growable: false);

        if (containsPubPackage(paths)) {
          continue;
        }
        if (!containsDartFiles(paths)) {
          continue;
        }
        targets.add(entityBasename);
      }

      //devPrint(entities);
    }
  }
  // devPrint('targets: $targets');
  return targets;
}
*/

/// Kept for compatibility
///
/// use [packageRunCi] instead
Future<void> ioPackageRunCi(String path) => packageRunCi(path);

/// Run basic tests on dart/flutter package
///
/// if [recursive] is true, it also find dart/flutter package recursively
/// [poolSite] allow concurrent testing (default to 4)
///
///
/// ```
/// ```
Future packageRunCi(String path,
    {bool recursive,
    bool noFormat,
    bool noAnalyze,
    bool noTest,
    bool noBuild,
    bool verbose,
    int poolSize}) async {
  recursive ??= false;
  noFormat ??= false;
  noAnalyze ??= false;
  noTest ??= false;
  noBuild ??= false;

  if (recursive) {
    await recursiveActions([path], verbose: verbose, poolSize: poolSize,
        action: (dir) async {
      await singlePackageRunCi(dir,
          noTest: noTest,
          noFormat: noFormat,
          noAnalyze: noAnalyze,
          noBuild: noBuild);
    });
  } else {
    await singlePackageRunCi(path,
        noAnalyze: noAnalyze,
        noFormat: noFormat,
        noTest: noTest,
        noBuild: noBuild);
  }
}

/// Run basic tests on dart/flutter package
///
Future singlePackageRunCi(String path,
    {@required bool noFormat,
    @required bool noAnalyze,
    @required bool noTest,
    @required bool noBuild}) async {
  print('# package: $path');
  var shell = Shell(workingDirectory: path);

  var pubspecMap = await pathGetPubspecYamlMap(path);
  var analysisOptionsMap = await pathGetAnalysisOptionsYamlMap(path);
  var isFlutterPackage = pubspecYamlSupportsFlutter(pubspecMap);

  var sdkBoundaries = pubspecYamlGetSdkBoundaries(pubspecMap);
  var supportsNnbdExperiment =
      analysisOptionsSupportsNnbdExperiment(analysisOptionsMap);

  if (!sdkBoundaries.match(dartVersion)) {
    stderr.writeln('Unsupported sdk boundaries for dart $dartVersion');
    return;
  }
  if (isFlutterPackage) {
    if (!isFlutterSupportedSync) {
      stderr.writeln('flutter not supported for package in $path');
      return;
    }
    // Flutter way
    await shell.run('''
    # Get dependencies
    flutter pub get
    ''');
  } else {
    await shell.run('''
    # Get dependencies
    pub get
    ''');
  }

  var filteredDartDirs = await filterTopLevelDartDirs(path);
  var filteredDartDirsArg = filteredDartDirs.join(' ');

  if (!noFormat) {
    // Formatting change in 2.9 with hashbang first line
    await checkAndActivatePackage('dart_style');
    try {
      await shell.run('''
      # Formatting
      dart pub global run dart_style:format -n --set-exit-if-changed $filteredDartDirsArg
    ''');
    } catch (e) {
      // Sometimes we allow formatting errors...

      // if (supportsNnbdExperiment) {
      //  stderr.writeln('Error in dartfmt during nnbd experiment, ok...');
      //} else {
      //

      // but in general no!
      rethrow;
    }
  }

  if (isFlutterPackage) {
    if (!noAnalyze) {
      await shell.run('''
      # Analyze code
      flutter analyze --no-pub .
    ''');
    }

    if (!noTest) {
      // 'test', '--no-pub'
      // Flutter way
      await shell.run('''
      # Test
      flutter test --no-pub
    ''');

      if (!noBuild) {
        /// Try building web if possible
        if (File(join(path, 'web', 'index.html')).existsSync()) {
          await checkAndActivatePackage('webdev');
          await shell.run('flutter build web');
        }
      }
    }
  } else {
    var dartExtraOptions = '';
    var dartRunExtraOptions = '';
    if (supportsNnbdExperiment) {
      // Temp dart extra option. To remove once nnbd supported on stable without flags
      dartExtraOptions = '--enable-experiment=non-nullable';
      // Needed for run and test
      dartRunExtraOptions =
          '--enable-experiment=non-nullable --no-sound-null-safety';

      // Only io test for now
      if (dartVersion >= Version(2, 10, 0, pre: '92')) {
        if (!noAnalyze) {
          await shell.run('''
      # Analyze code
      dart analyze $dartExtraOptions --fatal-warnings --fatal-infos .
  ''');
        }

        if (!noTest) {
          await shell.run('''
    # Test
    dart test $dartRunExtraOptions -p vm
    ''');
        } else {
          stderr.writeln('NNBD experiments are skipped for dart $dartVersion');
        }
      }
    } else {
      if (!noAnalyze) {
        await shell.run('''
      # Analyze code
      dart analyze --fatal-warnings --fatal-infos .
  ''');
      }

      // Test?
      if (!noTest) {
        if (filteredDartDirs.contains('test')) {
          var platforms = <String>['vm'];

          var isWeb = pubspecYamlSupportsWeb(pubspecMap);
          if (isWeb) {
            platforms.add('chrome');
          }
          // Add node for standard run test
          var isNode = pubspecYamlSupportsNode(pubspecMap);
          if (isNode && isNodeSupported) {
            platforms.add('node');

            await nodeTestCheck(path);
            // Workaround issue about complaining old pubspec on node...
            // https://travis-ci.org/github/tekartik/aliyun.dart/jobs/724680004
            await shell.run('''
          # Get dependencies
          dart pub get --offline
    ''');
          }

          await shell.run('''
    # Test
    dart test -p ${platforms.join(',')}
    ''');

          if (isWeb) {
            if (pubspecYamlSupportsBuildRunner(pubspecMap)) {
              if (dartVersion >= Version(2, 10, 0, pre: '110') &&
                  isRunningOnTravis) {
                stderr.writeln(
                    '\'dart pub run build_runner test -- -p chrome\' skipped on travis issue: https://github.com/dart-lang/sdk/issues/43589');
              } else {
                await shell.run('''
      # Build runner test
      dart pub run build_runner test -- -p chrome
      ''');
              }
            }
          }
        }
      }

      if (!noBuild) {
        /// Try web dev if possible
        if (pubspecYamlHasAllDependencies(
            pubspecMap, ['build_web_compilers', 'build_runner'])) {
          if (File(join(path, 'web', 'index.html')).existsSync()) {
            await checkAndActivatePackage('webdev');
            await shell.run('dart pub global run webdev build');
          }
        }
      }
    }
  }
}

bool get isRunningOnTravis => Platform.environment['TRAVIS'] == 'true';

List<String> _installedGlobalPackages;

Future<void> checkAndActivatePackage(String package) async {
  var list = await getInstalledGlobalPackages();
  if (!list.contains(package)) {
    await run('dart pub global activate $package');
    list.add(package);
  }
}

Future<List<String>> getInstalledGlobalPackages() async {
  if (_installedGlobalPackages == null) {
    var lines = (await run('dart pub global list', verbose: false)).outLines;
    _installedGlobalPackages =
        lines.map((line) => line.split(' ')[0]).toList(growable: true);
  }
  return _installedGlobalPackages;
}
