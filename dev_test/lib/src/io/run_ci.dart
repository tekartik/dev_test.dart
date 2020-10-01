import 'dart:io';

import 'package:args/args.dart';
import 'package:dev_test/src/package/recursive_pub_path.dart';
import 'package:dev_test/src/run_ci.dart';
import 'package:pub_semver/pub_semver.dart';

final version = Version(0, 1, 0);

void printVersion() {
  stdout.writeln(version);
}

Future<void> main(List<String> arguments) async {
  var parser = ArgParser()
    ..addFlag('version', help: 'Application version', negatable: false)
    ..addFlag('verbose', abbr: 'v', help: 'Verbose mode', negatable: false)
    ..addFlag('no-format', help: 'No format test', negatable: false)
    ..addFlag('no-test', help: 'No test ran', negatable: false)
    ..addFlag('no-analyze', help: 'No analyze performed', negatable: false)
    ..addFlag('no-build', help: 'No build performed', negatable: false)
    ..addOption('concurrency',
        abbr: 'j', help: 'Package concurrency (poolSize)', defaultsTo: '4')
    ..addFlag('recursive',
        help: 'Recursive (try to find dart/flutter project recursively',
        defaultsTo: true,
        negatable: true)
    ..addFlag('help', abbr: 'h', help: 'Help', negatable: false);
  var result = parser.parse(arguments);
  if (result['help'] as bool) {
    printVersion();
    stdout.writeln();
    stdout.writeln('Usage: pub run dev_test:run_ci [<path>] [<arguments>]');
    stdout.writeln();
    stdout.writeln(parser.usage);
    exit(0);
  }
  if (result['version'] as bool) {
    printVersion();
    exit(0);
  }
  var verbose = result['verbose'] as bool;
  var noFormat = result['no-format'] as bool;
  var noTest = result['no-test'] as bool;
  var noAnalyze = result['no-analyze'] as bool;
  var recursive = result['recursive'] as bool;
  var noBuild = result['no-build'] as bool;
  var poolSize = int.tryParse('concurrency');

  var paths = result.rest.isEmpty ? ['.'] : result.rest;
  if (recursive) {
    await recursiveActions(paths, verbose: verbose, poolSize: poolSize,
        action: (dir) async {
      await singlePackageRunCi(dir,
          noTest: noTest,
          noFormat: noFormat,
          noAnalyze: noAnalyze,
          noBuild: noBuild);
    });
  } else {
    for (var path in paths) {
      await singlePackageRunCi(path,
          noTest: noTest,
          noFormat: noFormat,
          noAnalyze: noAnalyze,
          noBuild: noBuild);
    }
  }
  // var pubspecYaml = pathGetPubspecYamlMap(packageDir)
}
