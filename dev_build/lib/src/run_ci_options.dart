import 'package:dev_build/package.dart';

/// The steps and settings of `packageRunCi`, one field per `run_ci` flag
/// (`noTest` is `--no-test`, `analyzeOnly` is `--analyze`).
///
/// An "only" option (`formatOnly`, `analyzeOnly`, `testOnly`, `vmTestOnly`,
/// `chromeJsTestOnly`, `buildOnly`, `webBuildOnly`, `pubGetOnly`,
/// `pubUpgradeOnly`, `pubDowngradeOnly`, `fixOnly`) turns the other format,
/// analyze, test and build steps off; `pub get` still runs unless
/// [noPubGet].
///
/// ```dart
/// await packageRunCi(
///   '.',
///   options: PackageRunCiOptions(recursive: true, analyzeOnly: true),
/// );
/// ```
class PackageRunCiOptions {
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
    this.noFatalWarnings = false,
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
    this.noCleanup = false,
    this.webBuildOnly = false,
    this.noWebBuild = false,
  }) {
    var isTestOnlyAction = testOnly || vmTestOnly || chromeJsTestOnly;
    var isBuildOnlyAction = buildOnly || webBuildOnly;
    var isOnlyAction =
        (formatOnly ||
        isBuildOnlyAction ||
        isTestOnlyAction ||
        analyzeOnly ||
        pubDowngradeOnly ||
        pubGetOnly ||
        pubUpgradeOnly ||
        fixOnly);
    if (isOnlyAction) {
      noTest = !isTestOnlyAction;

      noBuild = !isBuildOnlyAction;
      noAnalyze = !analyzeOnly;
      noFormat = !formatOnly;
    }
  }

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

  /// Analyze fails on errors only, the warnings and the infos are reported
  /// (`dart analyze --no-fatal-warnings`, `flutter analyze --no-fatal-infos
  /// --no-fatal-warnings`), i.e. on the lowest versions after a pub downgrade.
  final bool noFatalWarnings;

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

  /// No cleanup after the tests and the build: `tool/dev_build_cleanup.dart` is
  /// not run and the `build/` folder they created is kept.
  final bool noCleanup;

  /// Only run the web build (`flutter build web`, `webdev build`), not the
  /// other builds.
  final bool webBuildOnly;

  /// No web build (`flutter build web`, `webdev build`), the other builds
  /// run, i.e. on windows and macos when the web build is done on linux.
  final bool noWebBuild;

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
    noFatalWarnings: noFatalWarnings,
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
    noCleanup: noCleanup,
    webBuildOnly: webBuildOnly,
    noWebBuild: noWebBuild,
  );

  /// True if no pub get or upgrade
  bool get noPubGetOrUpgrade => !(pubGetOnly || pubUpgradeOnly) && noPubGet;
}
