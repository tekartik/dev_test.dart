import 'package:dev_build/package.dart';
import 'package:path/path.dart';
import 'package:process_run/stdio.dart';

/// Get the top level directories.
Future<List<String>> topLevelDir(String dir) async {
  var list = <String>[];
  await Directory(dir).list(recursive: false).listen((event) {
    if (event is Directory) {
      list.add(basename(event.path));
    }
  }).asFuture<void>();
  return list;
}

List<String> _forbiddenDirs = ['node_modules', '.dart_tool', 'build'];

/// Filter dart directories.
List<String> filterDartDirs(List<String> dirs) => dirs
    .where((element) {
      if (element.startsWith('.')) {
        return false;
      }
      if (_forbiddenDirs.contains(element)) {
        return false;
      }
      return true;
    })
    .toList(growable: false);

/// Package run options
class PackageRunCiOptions {
  /// Run in verbose mode.
  final bool verbose;

  /// Run in offline mode.
  final bool offline;

  /// Do not run node tests.
  final bool noNodeTest;

  /// Do not run browser tests.
  final bool noBrowserTest;

  /// Do not run any tests.
  late bool noTest;

  /// Do not run vm tests.
  final bool noVmTest;

  /// Do not run pub get.
  final bool noPubGet;

  /// Do not run format.
  late bool noFormat;

  /// Do not run analyze.
  late bool noAnalyze;

  /// Do not run npm install.
  final bool noNpmInstall;

  /// Do not build.
  late bool noBuild;

  /// Only run the specified folder.
  final bool recursive;

  /// Only run pub upgrade.
  final bool pubUpgradeOnly;

  /// Only run pub downgrade.
  final bool pubDowngradeOnly;

  /// Only run fix.
  final bool fixOnly;

  /// Only run format.
  final bool formatOnly;

  /// Only run test.
  final bool testOnly;

  /// Only run vm test
  final bool vmTestOnly;

  /// Only run chrome dart2js test
  final bool chromeJsTestOnly;

  /// Only run build.
  final bool buildOnly;

  /// Only run analyze.
  final bool analyzeOnly;

  /// Only run pub get.
  final bool pubGetOnly;

  /// Dry run (no execution)
  final bool dryRun;

  /// Pool size
  final int? poolSize;

  /// Do not run `run_ci_override.dart`, typically to use in this file
  final bool noOverride;

  /// Extra project info displayed
  final bool prjInfo;

  /// No actions are performed, only project info if specified.
  final bool noRunCi;

  /// Ignore shell errors.
  final bool ignoreErrors;

  /// Ignore sdk constraints
  final FilterDartProjectOptions? filterDartProjectOptions;

  /// Just print the path
  final bool printPath;

  /// Package run ci options.
  PackageRunCiOptions({
    this.formatOnly = false,
    this.testOnly = false,
    this.buildOnly = false,
    this.analyzeOnly = false,
    this.pubGetOnly = false,
    this.verbose = false,
    this.recursive = false,
    this.pubUpgradeOnly = false,
    this.pubDowngradeOnly = false,
    this.fixOnly = false,
    this.noNodeTest = false,
    this.noVmTest = false,
    this.vmTestOnly = false,
    this.noBrowserTest = false,
    this.chromeJsTestOnly = false,
    this.noTest = false,
    this.noAnalyze = false,
    this.noFormat = false,
    this.noPubGet = false,
    this.noBuild = false,
    this.offline = false,
    this.noNpmInstall = false,
    this.poolSize,
    this.noOverride = false,
    this.dryRun = false,
    this.prjInfo = false,
    this.noRunCi = false,
    this.ignoreErrors = false,
    this.filterDartProjectOptions,
    this.printPath = false,
  }) {
    var isTestOnlyAction = testOnly || vmTestOnly || chromeJsTestOnly;
    var isOnlyAction =
        (formatOnly ||
            buildOnly ||
            isTestOnlyAction ||
            analyzeOnly ||
            pubGetOnly ||
            pubUpgradeOnly ||
            fixOnly);
    if (isOnlyAction) {
      noTest = !isTestOnlyAction;

      noBuild = !buildOnly;
      noAnalyze = !analyzeOnly;
      noFormat = !formatOnly;
    }
  }

  /// Clone the options
  PackageRunCiOptions clone() => PackageRunCiOptions(
    formatOnly: formatOnly,
    testOnly: testOnly,
    buildOnly: buildOnly,
    analyzeOnly: analyzeOnly,
    pubGetOnly: pubGetOnly,
    verbose: verbose,
    recursive: recursive,
    pubUpgradeOnly: pubUpgradeOnly,
    pubDowngradeOnly: pubDowngradeOnly,
    fixOnly: fixOnly,
    noNodeTest: noNodeTest,
    noVmTest: noVmTest,
    vmTestOnly: vmTestOnly,
    noBrowserTest: noBrowserTest,
    chromeJsTestOnly: chromeJsTestOnly,
    noTest: noTest,
    noAnalyze: noAnalyze,
    noFormat: noFormat,
    noPubGet: noPubGet,
    noBuild: noBuild,
    offline: offline,
    noNpmInstall: noNpmInstall,
    poolSize: poolSize,
    noOverride: noOverride,
    dryRun: dryRun,
    prjInfo: prjInfo,
    noRunCi: noRunCi,
    ignoreErrors: ignoreErrors,
    filterDartProjectOptions: filterDartProjectOptions,
    printPath: printPath,
  );

  /// True if no pub get or upgrade
  bool get noPubGetOrUpgrade =>
      (pubGetOnly || pubUpgradeOnly) ? false : noPubGet;
}
