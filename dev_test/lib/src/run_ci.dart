import 'dart:io';

import 'package:dev_test/src/package/package.dart';
import 'package:dev_test/src/pub_io.dart';
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

/// Run basic tests on dart/flutter package
///
/// Dart:
/// ```
/// ```
Future ioPackageRunCi(String path) async {
  var shell = Shell(workingDirectory: path);

  var pubspecMap = await pathGetPubspecYamlMap(path);
  var analysisOptionsMap = await pathGetAnalysisOptionsYamlMap(path);
  var isFlutterPackage = pubspecYamlSupportsFlutter(pubspecMap);

  var sdkBoundaries = pubspecYamlGetSdkBoundaries(pubspecMap);
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

  // Formatting change in 2.9 with hashbang first line
  if (dartVersion >= Version(2, 9, 0, pre: '0')) {
    await shell.run('''
      # Formatting
      dartfmt -n --set-exit-if-changed .
    ''');
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
    var supportsNnbdExperiment =
        analysisOptionsSupportsNnbdExperiment(analysisOptionsMap);
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
      dartanalyzer $dartExtraOptions --fatal-warnings --fatal-infos .
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
      dartanalyzer --fatal-warnings --fatal-infos .
  ''');

      var options = <String>['vm'];

      var isWeb = pubspecYamlSupportsWeb(pubspecMap);
      if (isWeb) {
        options.add('chrome');
      }
      // Add node for standard run test
      var isNode = pubspecYamlSupportsNode(pubspecMap);
      if (isNode && isNodeSupported) {
        options.add('node');
      }

      await shell.run('''
    # Test
    pub run test -p ${options.join(',')}
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
