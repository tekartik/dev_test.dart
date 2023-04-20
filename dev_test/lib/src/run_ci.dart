import 'dart:async';
import 'dart:io';

import 'package:dev_test/package.dart';
import 'package:dev_test/src/package/package.dart';
import 'package:dev_test/src/pub_io.dart';
import 'package:path/path.dart';
import 'package:process_run/shell_run.dart';
import 'package:process_run/src/shell_utils.dart'; // ignore: implementation_imports
import 'package:pub_semver/pub_semver.dart';
import 'package:yaml/yaml.dart';

import 'import.dart';
import 'mixin/package.dart';
import 'node_support.dart';
import 'package/recursive_pub_path.dart';
import 'pub_global.dart';

var skipRunCiFilePath = join('.local', '.skip_run_ci');

Future main(List<String> arguments) async {
  String? path;
  if (arguments.isNotEmpty) {
    var firstArg = arguments.first.toString();
    if (await isPubPackageRoot(firstArg)) {
      path = firstArg;
    }
  }
  path ??= Directory.current.path;
  await packageRunCi(path);
}

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
  }).asFuture<void>();
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
  }).asFuture<void>();
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
/// // run CI (format, analyze, test) on the current folder
/// await packageRunCi('.');
/// ```
Future<void> packageRunCi(String path,
    {PackageRunCiOptions? options,
    bool? recursive,
    bool? noFormat,
    bool? noAnalyze,
    bool? noTest,
    bool? noBuild,
    bool? noPubGet,
    bool? verbose,
    bool? pubUpgrade,
    int? poolSize}) async {
  options ??= PackageRunCiOptions(
      noPubGet: noPubGet ?? false,
      noTest: noTest ?? false,
      noFormat: noFormat ?? false,
      noAnalyze: noAnalyze ?? false,
      noBuild: noBuild ?? false,
      verbose: verbose ?? false,
      poolSize: poolSize,
      recursive: recursive ?? false,
      pubUpgradeOnly: pubUpgrade ?? false);

  await packageRunCiImpl(path, options,
      recursive: recursive ?? options.recursive);
}

final _runCiOverridePath = join('tool', 'run_ci_override.dart');

Future<void> packageRunCiImpl(String path, PackageRunCiOptions options,
    {bool recursive = false, int? poolSize}) async {
  if (recursive) {
    await recursiveActions([path], verbose: options.verbose, poolSize: poolSize,
        action: (dir) async {
      await singlePackageRunCi(dir, options: options);
    });
  } else {
    if (!(await isPubPackageRoot(path))) {
      stderr.writeln(
          '${absolute(path)} not a dart package, use --recursive option');
    } else {
      await singlePackageRunCi(path, options: options);
    }
  }
}

/// Run basic tests on dart/flutter package
///
Future<void> singlePackageRunCi(String path,
    {PackageRunCiOptions? options,
    // Later might deprecated in the future - Deprecated since 2021/03/11

    bool? noFormat,
    bool? noAnalyze,
    bool? noTest,
    bool? noBuild,
    bool? noPubGet,
    bool? pubUpgrade,
    bool? formatOnly,
    bool? analyzeOnly,
    bool? testOnly,
    bool? buildOnly,
    bool? pubGetOnly,
    bool? pubUpgradeOnly}) async {
  options ??= PackageRunCiOptions(
    formatOnly: formatOnly ?? false,
    buildOnly: buildOnly ?? false,
    testOnly: testOnly ?? false,
    analyzeOnly: analyzeOnly ?? false,
    pubGetOnly: pubGetOnly ?? false,
    pubUpgradeOnly: pubUpgradeOnly ?? false,
    noPubGet: noPubGet ?? false,
    noTest: noTest ?? false,
    noFormat: noFormat ?? false,
    noAnalyze: noAnalyze ?? false,
    noBuild: noBuild ?? false,
  );
  await singlePackageRunCiImpl(path, options);
}

var _minNullableVersion = Version(2, 12, 0);
var _unsetVersion = Version(1, 0, 0);

/// Run basic tests on dart/flutter package
///
Future<void> singlePackageRunCiImpl(
    String path, PackageRunCiOptions options) async {
  options = options.clone();
  try {
    if (options.prjInfo) {
      stdout.writeln('# package: ${normalize(absolute(path))}');
    } else {
      stdout.writeln('# package: $path');
    }
    var shell = Shell(workingDirectory: path);
    // Project info
    if (options.prjInfo) {
      try {
        var pubspecMap = await pathGetPubspecYamlMap(path);
        var boundaries = pubspecYamlGetSdkBoundaries(pubspecMap);
        if (boundaries != null) {
          var minSdkVersion = boundaries.min?.value ?? _unsetVersion;
          // devPrint(minSdk Version $minSdkVersion vs $unsetVersion/$warnMinimumVersion');
          var tags = <String>[
            if (pubspecYamlSupportsFlutter(pubspecMap)) 'flutter',
            if (minSdkVersion < _minNullableVersion) 'non-nullable'
          ];
          if (tags.isNotEmpty) {
            stdout.writeln('sdk: $boundaries (${tags.join(',')})');
          } else {
            stdout.writeln('sdk: $boundaries');
          }
        }
      } catch (e) {
        print(e);
      }
    }
    if (options.noRunCi) {
      return;
    }

    if (!options.noOverride &&
        File(join(path, skipRunCiFilePath)).existsSync()) {
      print('Skipping run_ci');
      return;
    }

    var pubspecMap = await pathGetPubspecYamlMap(path);
    var isFlutterPackage = pubspecYamlSupportsFlutter(pubspecMap);

    var sdkBoundaries = pubspecYamlGetSdkBoundaries(pubspecMap)!;

    if (!sdkBoundaries.matches(dartVersion)) {
      stderr.writeln('Unsupported sdk boundaries for dart $dartVersion');
      return;
    }

    if (isFlutterPackage) {
      if (!isFlutterSupportedSync) {
        stderr.writeln('flutter not supported for package in $path');
        return;
      }
    }

    // ensure test exists
    if (!Directory(join(path, 'test')).existsSync()) {
      options.noTest = true;
    }

    Future<List<ProcessResult>> runScript(String script) async {
      if (options.dryRun) {
        scriptToCommands(script).forEach((command) {
          print('\$ $command');
        });
        return <ProcessResult>[];
      }
      return await shell.run(script);
    }

    if (!options.noPubGetOrUpgrade) {
      var offlineSuffix = options.offline ? ' --offline' : '';
      if (isFlutterPackage) {
        if (options.pubUpgradeOnly) {
          await runScript('flutter pub upgrade$offlineSuffix');
        } else {
          await runScript('flutter pub get$offlineSuffix');
        }
      } else {
        if (options.pubUpgradeOnly) {
          await runScript('dart pub upgrade$offlineSuffix');
        } else {
          await runScript('dart pub get$offlineSuffix');
        }
      }
    }

    // Specific run
    if (!options.noOverride &&
        File(join(path, _runCiOverridePath)).existsSync()) {
      // Run it instead
      await runScript('dart run $_runCiOverridePath');
      return;
    }

    var filteredDartDirs = await filterTopLevelDartDirs(path);
    var filteredDartDirsArg = filteredDartDirs.join(' ');

    if (!options.noFormat) {
      // Previous version were using dart_style, we now use dart format
      // Even for flutter we use `dart format`, before flutter 3.7 `flutter format` was alloed

      // Needed otherwise formatter is stuck
      if (filteredDartDirsArg.isEmpty) {
        filteredDartDirsArg = '.';
      }
      try {
        await runScript('''
      # Formatting
      dart format --set-exit-if-changed $filteredDartDirsArg
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
      if (!options.noAnalyze) {
        await runScript('''
      # Analyze code
      flutter analyze --no-pub .
    ''');
      }

      if (!options.noTest) {
        // 'test', '--no-pub'
        // Flutter way
        await runScript('''
      # Test
      flutter test --no-pub
    ''');
      }
      if (!options.noBuild) {
        /// Try building web if possible

        /// requires at least beta
        if (await flutterEnableWeb()) {
          if (File(join(path, 'web', 'index.html')).existsSync()) {
            // await checkAndActivatePackage('webdev');
            await runScript('flutter build web');
          }
        }
      }
    } else {
      if (!options.noAnalyze) {
        await runScript('''
      # Analyze code
      dart analyze --fatal-warnings --fatal-infos .
  ''');
      }

      // Test?
      if (!options.noTest) {
        if (filteredDartDirs.contains('test')) {
          var platforms = <String>[if (!options.noVmTest) 'vm'];

          var isWeb = pubspecYamlSupportsWeb(pubspecMap);
          if (!options.noBrowserTest && isWeb) {
            platforms.add('chrome');
          }
          // Add node for standard run test
          var isNodePackage = pubspecYamlSupportsNode(pubspecMap);
          if (!options.noNodeTest && (isNodePackage && isNodeSupportedSync)) {
            platforms.add('node');

            if (!options.noNpmInstall) {
              await nodeSetupCheck(path);
              // Workaround issue about complaining old pubspec on node...
              // https://travis-ci.org/github/tekartik/aliyun.dart/jobs/724680004
            }
            await runScript('''
          # Get dependencies
          dart pub get --offline
    ''');
          }

          // Check available dart test platforms
          var dartTestFile = File(join(path, 'dart_test.yaml'));
          if (dartTestFile.existsSync()) {
            try {
              var dartTestPlatforms =
                  (loadYaml(await dartTestFile.readAsString())
                      as Map)['platforms'];
              // Single one?
              if (dartTestPlatforms is String) {
                dartTestPlatforms = [dartTestPlatforms];
              }
              if (dartTestPlatforms is List) {
                var list = dartTestPlatforms;
                platforms.removeWhere((platform) => !list.contains(platform));
              }
            } catch (_) {}
          }

          if (platforms.isNotEmpty) {
            await runScript('''
    # Test
    dart test -p ${platforms.join(',')}
    ''');
          }

          if (isWeb) {
            if (pubspecYamlSupportsBuildRunner(pubspecMap)) {
              if (dartVersion >= Version(2, 10, 0, pre: '110')) {
                stderr.writeln(
                    '\'dart pub run build_runner test -- -p chrome\' skipped issue: https://github.com/dart-lang/sdk/issues/43589');
              } else {
                await runScript('''
      # Build runner test
      dart pub run build_runner test -- -p chrome
      ''');
              }
            }
          }
        }
      }

      if (!options.noBuild) {
        /// Try web dev if possible
        if (pubspecYamlHasAllDependencies(
            pubspecMap, ['build_web_compilers', 'build_runner'])) {
          if (File(join(path, 'web', 'index.html')).existsSync()) {
            await checkAndActivateWebdev();

            // Work around for something that happens on windows
            // https://github.com/tekartikdev/service_worker/runs/4342612734?check_suite_focus=true
            // $ dart pub global run webdev build
            // webdev could not run for this project.
            // The pubspec.lock file has changed since the .dart_tool/package_config.json file was generated, please run "pub get" again.
            if (Platform.isWindows) {
              await runScript('dart pub get');
            }
            await runScript('dart pub global run webdev build');
          }
        }
      }
    }
  } catch (e) {
    if (options.ignoreErrors) {
      stderr.writeln('Ignoring error $e');
    } else {
      rethrow;
    }
  }
}

bool? _flutterWebEnabled;

Future<bool> flutterEnableWeb() async {
  if (_flutterWebEnabled == null) {
    /// requires at least beta
    if (await getFlutterBinChannel() != dartChannelStable) {
      await run('flutter config --enable-web');
      _flutterWebEnabled = true;
    } else {
      _flutterWebEnabled = false;
    }
  }
  return _flutterWebEnabled!;
}
