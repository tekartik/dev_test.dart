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

var prjInfoFlagName = 'prj-info';
var noRunCiFlagName = 'no-run-ci';
var ignoreSdkConstraintsFlagName = 'ignore-sdk-constraints';

extension _ArgResults on ArgResults {
  T getValue<T>(String key) => this[key] as T;
}

const flagSkipRunCi = 'skip-run-ci';

Future<void> main(List<String> arguments) async {
  var configParser = ArgParser()
    ..addFlag(flagSkipRunCi,
        negatable: false,
        help:
            'Mark project folder as skipped locally (.local/ must be source control ignored)')
    ..addFlag('help', abbr: 'h', help: 'Help', negatable: false);
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
    ..addFlag('no-override',
        help: 'Do not run \'tool/run_ci_override.dart\' if found',
        negatable: false)
    ..addFlag('ignore-errors',
        abbr: 'i',
        help:
            'Ignore errors (stop the current package but run the other packages)',
        negatable: false)
    ..addFlag('format', help: 'Format only', negatable: false)
    ..addFlag('test', help: 'Test only', negatable: false)
    ..addFlag('analyze', help: 'Analyze only', negatable: false)
    ..addFlag('build', help: 'Build only', negatable: false)
    ..addFlag('pub-get', help: 'Get only', negatable: false)
    ..addFlag('pub-upgrade', help: 'Run pub upgrade only', negatable: false)
    ..addFlag('offline', help: 'Offline', negatable: false)
    ..addFlag(prjInfoFlagName, help: 'Project info', negatable: false)
    ..addFlag(noRunCiFlagName, help: 'No ci is executed', negatable: false)
    ..addFlag('dry-run', help: 'Dry run', negatable: false)
    ..addOption('concurrency',
        abbr: 'j', help: 'Package concurrency (poolSize)', defaultsTo: '4')
    ..addFlag('recursive',
        help: 'Recursive (try to find dart/flutter project recursively',
        defaultsTo: true,
        negatable: true)
    ..addFlag(ignoreSdkConstraintsFlagName,
        help: 'Ignore SDK constraints when selecting projects',
        negatable: false)
    ..addFlag('help', abbr: 'h', help: 'Help', negatable: false)
    ..addCommand('config', configParser);
  var result = parser.parse(arguments);
  var paths = result.rest.isEmpty ? ['.'] : result.rest;

  if (result['version'] as bool) {
    printVersion();
    exit(0);
  }
  var command = result.command?.name;
  if (command == 'config') {
    var configResult = result.command!;

    if (configResult['help'] as bool) {
      printVersion();
      stdout.writeln();
      stdout.writeln(
          'Usage: pub run dev_test:run_ci config [<arguments>] [<path>]');
      stdout.writeln();
      stdout.writeln(configParser.usage);
      exit(0);
    }
    var skipRunCi = configResult[flagSkipRunCi] as bool;
    if (skipRunCi) {
      var file = File(join(paths.first, skipRunCiFilePath));
      if (!file.existsSync()) {
        stdout.writeln('creating ${file.path}');
        await file.parent.create(recursive: true);
        await file.writeAsString('');
      } else {
        stdout.writeln('file $skipRunCiFilePath exists');
      }
    }
    return;
  }
  if (result['help'] as bool) {
    printVersion();
    stdout.writeln();
    stdout.writeln('Usage: pub run dev_test:run_ci [<path>] [<arguments>]');
    stdout.writeln();
    stdout.writeln(parser.usage);
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
  var noOverride = result['no-override'] as bool;
  var formatOnly = result['format'] as bool;
  var testOnly = result['test'] as bool;
  var analyzeOnly = result['analyze'] as bool;
  var buildOnly = result['build'] as bool;
  var pubGetOnly = result['pub-get'] as bool;
  var pubUpgradeOnly = result['pub-upgrade'] as bool;
  var dryRun = result['dry-run'] as bool;
  var ignoreErrors = result['ignore-errors'] as bool;
  // default to true
  var recursive = result['recursive'] as bool;
  var prjInfo = result[prjInfoFlagName] as bool;
  var noRunCi = result.getValue<bool>(noRunCiFlagName);
  var ignoreSdkConstraints =
      result.getValue<bool>(ignoreSdkConstraintsFlagName);

  var poolSize = int.tryParse('concurrency');

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
      noOverride: noOverride,
      dryRun: dryRun,
      prjInfo: prjInfo,
      noRunCi: noRunCi,
      ignoreErrors: ignoreErrors,
      ignoreSdkConstraints: ignoreSdkConstraints);

  Future runDir(String dir) async {
    await singlePackageRunCi(
      dir,
      options: options,
    );
  }

  if (recursive) {
    await recursiveActions(paths, verbose: verbose, poolSize: poolSize,
        action: (dir) async {
      await runDir(dir);
    });
  } else {
    for (var path in paths) {
      if (!(await isPubPackageRoot(path))) {
        stderr.writeln(
            '${absolute(path)} not a dart package, use --recursive option');
        exit(1);
      } else {
        await runDir(path);
      }
    }
  }
  if (ignoreErrors) {
    stdout.writeln('run_ci done ignoring errors.');
  }
  // var pubspecYaml = pathGetPubspecYamlMap(packageDir)
}
