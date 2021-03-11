import 'dart:io';

import 'package:args/args.dart';
import 'package:dev_test/package.dart';
import 'package:dev_test/src/package/recursive_pub_path.dart';
import 'package:dev_test/src/pub_io.dart';
import 'package:dev_test/src/run_ci.dart';
import 'package:path/path.dart';
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
    ..addFlag('no-pub-get', help: 'No pub get first', negatable: false)
    ..addFlag('no-vm-test', help: 'No VM test', negatable: false)
    ..addFlag('no-browser-test', help: 'No Browser test', negatable: false)
    ..addFlag('no-node-test', help: 'No Node test', negatable: false)
    ..addFlag('no-npm-install', help: 'No NPM install', negatable: false)
    ..addFlag('format', help: 'Format only', negatable: false)
    ..addFlag('test', help: 'Test only', negatable: false)
    ..addFlag('analyze', help: 'Analyze only', negatable: false)
    ..addFlag('build', help: 'Build only', negatable: false)
    ..addFlag('pub-get', help: 'Get only', negatable: false)
    ..addFlag('pub-upgrade', help: 'Run pub upgrade only', negatable: false)
    ..addFlag('offline', help: 'Offline', negatable: false)
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
  var offline = result['offline'] as bool;
  var noFormat = result['no-format'] as bool;
  var noTest = result['no-test'] as bool;
  var noAnalyze = result['no-analyze'] as bool;
  var noBuild = result['no-build'] as bool;
  var noPubGet = result['no-pub-get'] as bool;
  var noVmTest = result['no-vm-test'] as bool;
  var noNodeTest = result['no-node-test'] as bool;
  var noBrowserTest = result['no-browser-test'] as bool;
  var noNpmInstall = result['no-npm-install'] as bool;
  var formatOnly = result['format'] as bool;
  var testOnly = result['test'] as bool;
  var analyzeOnly = result['analyze'] as bool;
  var buildOnly = result['build'] as bool;
  var pubGetOnly = result['pub-get'] as bool;
  var pubUpgradeOnly = result['pub-upgrade'] as bool;
  // default to true
  var recursive = result['recursive'] as bool;

  var poolSize = int.tryParse('concurrency');

  var paths = result.rest.isEmpty ? ['.'] : result.rest;

  var options = PackageRunCiOptions(
    verbose: verbose,
    offline: offline,
    noFormat: noFormat,
    noTest: noTest,
    noAnalyze: noAnalyze,
    noBuild: noBuild,
    noPubGet: noPubGet,
    noVmTest: noVmTest,
    noNodeTest: noNodeTest,
    noNpmInstall: noNpmInstall,
    noBrowserTest: noBrowserTest,
    formatOnly: formatOnly,
    testOnly: testOnly,
    buildOnly: buildOnly,
    analyzeOnly: analyzeOnly,
    pubGetOnly: pubGetOnly,
    pubUpgradeOnly: pubUpgradeOnly,
  );

  Future _runDir(String dir) async {
    await singlePackageRunCi(
      dir,
      options: options,
    );
  }

  if (recursive) {
    await recursiveActions(paths, verbose: verbose, poolSize: poolSize,
        action: (dir) async {
      await _runDir(dir);
    });
  } else {
    for (var path in paths) {
      if (!(await isPubPackageRoot(path))) {
        stderr.writeln(
            '${absolute(path)} not a dart package, use --recursive option');
        exit(1);
      } else {
        await _runDir(path);
      }
    }
  }
  // var pubspecYaml = pathGetPubspecYamlMap(packageDir)
}
