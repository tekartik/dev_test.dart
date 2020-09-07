import 'dart:async';
import 'dart:io';

import 'package:dev_test/src/node_support.dart';
import 'package:dev_test/src/package/package.dart';
import 'package:dev_test/src/pub_io.dart';
import 'package:path/path.dart';
import 'package:process_run/shell_run.dart';
import 'package:process_run/which.dart';
import 'package:pub_semver/pub_semver.dart';

import 'mixin/package.dart';

Future main(List<String> arguments) async {
  String path;
  if (arguments.isNotEmpty ?? false) {
    var firstArg = arguments.first?.toString();
    if (await isPubPackageRoot(firstArg)) {
      path = firstArg;
    }
  }
  path ??= Directory.current.path;
  await ioPackageRunCi(path);
}

/// true if flutter is supported
final isNodeSupported = whichSync('node') != null;

/// List the top level dirs
Future<List<String>> topLevelDir(String dir) async {
  var list = <String>[];
  await Directory(dir)
      .list(recursive: false, followLinks: false)
      .listen((event) {
    if (event is Directory) {
      list.add(basename(event.path));
    }
  }).asFuture();
  return list;
}

List<String> _forbiddenDirs = ['node_modules', '.dart_tool', 'build'];

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
Future<List<String>> filterDartDirs(String path) async {
  var dirs = await topLevelDir(path);
  var sanitized = <String>[];
  for (var dir in dirs) {
    if (dir.startsWith('.')) {
      continue;
    }
    if (_forbiddenDirs.contains(dir)) {
      continue;
    }
    if (!await hasDartFiles(join(path, dir))) {
      continue;
    }
    sanitized.add(dir);
  }
  return sanitized;
}

/// Run basic tests on dart/flutter package
///
/// Dart:
/// ```
/// ```
Future ioPackageRunCi(String path) async {
  print('run_ci: $path');
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

  var filteredDartDirs = await filterDartDirs(path);
  var filteredDartDirsArg = filteredDartDirs.join(' ');
  // Formatting change in 2.9 with hashbang first line
  if (dartVersion >= Version(2, 9, 0, pre: '0')) {
    try {
      await shell.run('''
      # Formatting
      dartfmt -n --set-exit-if-changed $filteredDartDirsArg
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
    await shell.run('''
      # Analyze code
      flutter analyze --no-pub .
    ''');

    // 'test', '--no-pub'
    // Flutter way
    await shell.run('''
      # Test
      flutter test --no-pub
    ''');
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
        await shell.run('''
      # Analyze code
      dartanalyzer $dartExtraOptions --fatal-warnings --fatal-infos $filteredDartDirsArg
  ''');

        await shell.run('''
    # Test
    pub run $dartRunExtraOptions test -p vm
    ''');
      } else {
        stderr.writeln('NNBD experiments are skipped for dart $dartVersion');
      }
    } else {
      await shell.run('''
      # Analyze code
      dartanalyzer --fatal-warnings --fatal-infos $filteredDartDirsArg
  ''');

      // Test?
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
          pub get --offline
    ''');
        }

        await shell.run('''
    # Test
    pub run test -p ${platforms.join(',')}
    ''');

        if (isWeb) {
          if (pubspecYamlSupportsBuildRunner(pubspecMap)) {
            await shell.run('''
      # Build runner test
      pub run build_runner test -- -p chrome
      ''');
          }
        }
      }
    }
  }
}
