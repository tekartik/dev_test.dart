import 'dart:io';

import 'package:dev_test/src/package_impl.dart';
import 'package:dev_test/src/pub_io.dart';
import 'package:process_run/shell_run.dart';
import 'package:pub_semver/pub_semver.dart';

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

/// Run basic tests on dart/flutter package
///
/// Dart:
/// ```
/// ```
Future ioPackageRunCi(String path) async {
  var shell = Shell(workingDirectory: path);

  var pubspecMap = await getPubspecYamlMap(path);
  var isFlutterPackage = pubspecYamlIsFlutterPackageRoot(pubspecMap);

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

  if (await isFlutterPackageRoot(path)) {
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
    await shell.run('''
      # Analyze code
      dartanalyzer --fatal-warnings --fatal-infos .
  ''');

    var options = <String>['vm'];

    var isWeb =
        pubspecYamlHasAnyDependencies(pubspecMap, ['build_web_compilers']);
    if (isWeb) {
      options.add('chrome');
    }
    await shell.run('''
    # Test
    pub run test -p ${options.join(',')}
    ''');

    if (isWeb) {
      if (pubspecYamlHasAnyDependencies(pubspecMap, ['build_runner'])) {
        await shell.run('''
      # Build runner test
      pub run build_runner test -p chrome
      ''');
      }
    }
  }
}
