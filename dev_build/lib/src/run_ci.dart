import 'package:dev_build/package.dart';
import 'package:dev_build/src/package/package.dart';
import 'package:dev_build/src/package/pub_io_package.dart';
import 'package:dev_build/src/package/test_config.dart';
import 'package:dev_build/src/pub_io.dart';
import 'package:path/path.dart';
import 'package:process_run/shell.dart';

import 'package:process_run/stdio.dart';
import 'package:yaml/yaml.dart';

import 'import.dart';
import 'mixin/package.dart';
import 'node_support.dart';
import 'package/recursive_pub_path.dart';
import 'pub_global.dart';
import 'run_ci_config.dart';

/// Options for [packageRunCi]
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
  await Directory(dir).list(recursive: false, followLinks: false).listen((
    event,
  ) {
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
  await Directory(dir).list(recursive: false, followLinks: false).listen((
    event,
  ) {
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
    if (await isPubPackageRoot(
      dirPath,
      filterDartProjectOptions: FilterDartProjectOptions(
        ignoreSdkConstraints: true,
      ),
    )) {
      continue;
    }
    if (!await hasDartFiles(dirPath)) {
      continue;
    }
    sanitized.add(dirname);
  }
  return sanitized..sort();
}

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
Future<void> packageRunCi(
  String path, {
  PackageRunCiOptions? options,
  bool? recursive,
  bool? noFormat,
  bool? noAnalyze,
  bool? noTest,
  bool? noBuild,
  bool? noPubGet,
  bool? verbose,
  bool? pubUpgrade,
  int? poolSize,

  /// Internally a pub cache is used
  /// for a given action
  /// If set to false or unset, a new cache is created
  /// If set to true, no cache is used, unless a one exists
  bool? noPubWorkspaceCache,
}) async {
  noPubWorkspaceCache ??= false;
  if (!noPubWorkspaceCache) {
    runCiInitPubWorkspacesCache();
  }
  options ??= PackageRunCiOptions(
    noPubGet: noPubGet ?? false,
    noTest: noTest ?? false,
    noFormat: noFormat ?? false,
    noAnalyze: noAnalyze ?? false,
    noBuild: noBuild ?? false,
    verbose: verbose ?? false,
    poolSize: poolSize,
    recursive: recursive ?? false,
    pubUpgradeOnly: pubUpgrade ?? false,
  );

  await packageRunCiImpl(
    path,
    options,
    recursive: recursive ?? options.recursive,
    poolSize: poolSize ?? options.poolSize,
  );
}

final _runCiOverridePath = join('tool', 'run_ci_override.dart');

/// Setup script run before the tests and the build when found (relative to
/// the package root), i.e. to build a web worker the tests or the app need.
final devBuildSetupPath = join('tool', 'dev_build_setup.dart');

/// Cleanup script run after the tests and the build when found (relative to
/// the package root), unless [PackageRunCiOptions.noCleanup], i.e. to free
/// space on a CI running several packages.
final devBuildCleanupPath = join('tool', 'dev_build_cleanup.dart');

/// Top level folders of a package deleted after the tests and the build when
/// they created them (missing before [devBuildSetupPath] is looked for),
/// unless [PackageRunCiOptions.noCleanup].
const runCiCleanupTopDirs = ['build'];

/// Package run ci.
Future<void> packageRunCiImpl(
  String path,
  PackageRunCiOptions options, {
  bool recursive = false,
  int? poolSize,
}) async {
  if (recursive) {
    await pubPathsRunActions(
      await runCiRecursivePubPath([path]),
      poolSize: poolSize,
      action: (dir) async {
        await shellStdioLinesGrouper.runZoned(() async {
          await singlePackageRunCiImpl(dir, options);
        });
      },
    );
  } else {
    if (!(await isPubPackageRoot(
      path,
      filterDartProjectOptions: options.filterDartProjectOptions,
    ))) {
      stderr.writeln(
        '${absolute(path)} not a dart package, use --recursive option',
      );
    } else {
      await singlePackageRunCiImpl(path, options);
    }
  }
}

/// Stream type.
enum StdioStreamType {
  /// Out
  out,

  /// Err
  err,
}

/// Run basic tests on dart/flutter package
///
Future<void> singlePackageRunCi(
  String path, {
  PackageRunCiOptions? options,

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
  bool? pubUpgradeOnly,
}) async {
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

enum _PubWorkspaceCacheAction { get, upgrade, downgrade }

/// Last action done on a workspace, invalide others.
class _PubWorkspaceCache {
  _PubWorkspaceCache(this.workspaceRoot, this.action, this.offline);
  final String workspaceRoot;
  final bool offline;
  final _PubWorkspaceCacheAction action;
}

class _PubWorkspacesCache {
  _PubWorkspacesCache();
  final _map = <String, _PubWorkspaceCache>{};
}

_PubWorkspacesCache? _pubWorkspacesCache;

/// Internal only use for run_ci binary for now
void runCiInitPubWorkspacesCache() {
  _pubWorkspacesCache = _PubWorkspacesCache();
}

/// Run basic tests on dart/flutter package
///
Future<void> singlePackageRunCiImpl(
  String path,
  PackageRunCiOptions options,
) async {
  options = options.clone();
  try {
    var pubIoPackage = PubIoPackage(
      path,
      options: PubIoPackageOptions(verbose: options.verbose),
    );
    await pubIoPackage.ready;
    await pubIoPackage.shellEnvironment.runZoned(() async {
      await _zonedSinglePackageRunCiImpl(pubIoPackage, options);
    });
  } catch (e) {
    if (options.ignoreErrors) {
      stderr.writeln('Ignoring error $e');
    } else {
      rethrow;
    }
  }
}

/// Special macos chrome timeout issue
var _chromeTestTimeoutRetriedOnce = false;

/// `dart test` exit code when no test ran (`noTestsRan` in package:test_core),
/// i.e. "No tests were found." for a platform (all tests `@TestOn('vm')`
/// on chrome for example).
const _dartTestNoTestsRanExitCode = 79;

/// True when the `test` folder of the package in [path] holds a
/// `_test.dart` file (in a sub folder too).
Future<bool> _hasTestFile(String path) async {
  var testDir = Directory(join(path, 'test'));
  if (!testDir.existsSync()) {
    return false;
  }
  try {
    return await testDir
        .list(recursive: true, followLinks: false)
        .any((entity) => entity is File && entity.path.endsWith('_test.dart'));
  } catch (_) {
    // Unreadable: let the test command tell.
    return true;
  }
}

/// Run basic tests on dart/flutter package
///
Future<void> _zonedSinglePackageRunCiImpl(
  PubIoPackage pubIoPackage,
  PackageRunCiOptions options,
) async {
  var ciRunner = SinglePackageCiRunner(pubIoPackage, options);
  await ciRunner.init();
  var path = pubIoPackage.path;
  if (options.printPath) {
    stdout.writeln(normalize(absolute(path)));
    return;
  }
  var dofPub = pubIoPackage.dofPub;
  if (options.prjInfo) {
    stdout.writeln('# package: ${normalize(absolute(path))}');
  } else {
    stdout.writeln('# package: $path');
  }
  // Project info
  if (options.prjInfo) {
    try {
      var boundaries = ciRunner.pubspecSdkBoundaries;
      if (boundaries != null) {
        var minSdkVersion = boundaries.min?.value ?? _unsetVersion;
        // devPrint(minSdk Version $minSdkVersion vs $unsetVersion/$warnMinimumVersion');
        var tags = <String>[
          if (ciRunner.isFlutterPackage) 'flutter',
          if (minSdkVersion < _minNullableVersion) 'non-nullable',
        ];
        if (tags.isNotEmpty) {
          stdout.writeln('sdk: $boundaries (${tags.join(',')})');
        } else {
          stdout.writeln('sdk: $boundaries');
        }
      }
    } catch (e) {
      stderr.writeln(e.toString());
    }
  }
  if (options.noRunCi) {
    return;
  }

  if (!options.noOverride && File(join(path, skipRunCiFilePath)).existsSync()) {
    stdout.writeln('Skipping run_ci');
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

  // ensure test exists, with a test file (`flutter test` fails on a test
  // folder without any, an empty folder left by git for example).
  if (!await _hasTestFile(path)) {
    options.noTest = true;
  }

  var runScript = ciRunner.runScript;

  if (!options.noPubGetOrUpgrade) {
    var offline = options.offline;
    var action = options.pubUpgradeOnly
        ? _PubWorkspaceCacheAction.upgrade
        : (options.pubDowngradeOnly
              ? _PubWorkspaceCacheAction.downgrade
              : _PubWorkspaceCacheAction.get);
    var skip = false;
    var workspaceBehavior =
        (pubIoPackage.isWorkspace || pubIoPackage.hasWorkspaceResolution) &&
        _pubWorkspacesCache != null;
    if (workspaceBehavior) {
      var workspaceRoot = normalize(
        absolute(await pubIoPackage.getWorkspaceRootPath()),
      );
      var lastCache = _pubWorkspacesCache!._map[workspaceRoot];
      if (lastCache?.offline == offline && lastCache?.action == action) {
        skip = true;
      } else {
        _pubWorkspacesCache!._map[workspaceRoot] = _PubWorkspaceCache(
          workspaceRoot,
          action,
          offline,
        );
      }
    }
    if (!skip) {
      var offlineSuffix = options.offline ? ' --offline' : '';

      switch (action) {
        case _PubWorkspaceCacheAction.upgrade:
          await runScript('$dofPub upgrade$offlineSuffix');
          break;
        case _PubWorkspaceCacheAction.downgrade:
          await runScript('$dofPub downgrade$offlineSuffix');
          break;
        case _PubWorkspaceCacheAction.get:
          await runScript('$dofPub get$offlineSuffix');
          break;
      }
    }
  }
  // Enough for workspace root
  if (ciRunner.isWorkspaceRoot) {
    return;
  }
  var name = pubspecYamlGetPackageName(pubspecMap)!;
  // Enough if its name starts with an underscore
  if (name.startsWith('_')) {
    return;
  }

  if (options.fixOnly) {
    await ciRunner.fix();
    return;
  }
  // Specific run
  if (!options.noOverride &&
      File(join(path, _runCiOverridePath)).existsSync()) {
    // Run it instead
    await runScript('dart run $_runCiOverridePath');
    return;
  }

  await ciRunner.format();
  await ciRunner.analyze();
  var testOrBuild = !options.noTest || !options.noBuild;
  if (!testOrBuild) {
    return;
  }
  ciRunner.prepareCleanup();
  try {
    await ciRunner.devBuildSetup();
    await ciRunner.runTest();
    await _build(ciRunner, pubspecMap, isFlutterPackage);
  } finally {
    // On failure too: the next packages run with --ignore-errors.
    await ciRunner.cleanup();
  }
}

/// Build step of [_zonedSinglePackageRunCiImpl].
Future<void> _build(
  SinglePackageCiRunner ciRunner,
  Map pubspecMap,
  bool isFlutterPackage,
) async {
  var options = ciRunner.options;
  var path = ciRunner.path;
  var dofPub = ciRunner._pubIoPackage.dofPub;
  var runScript = ciRunner.runScript;
  if (isFlutterPackage) {
    if (!options.noBuild) {
      /// Try building web if possible

      /// requires at least beta
      if (await flutterEnableWeb()) {
        if (File(join(path, 'web', 'index.html')).existsSync()) {
          if (File(join(path, flutterWebMainDartPath)).existsSync()) {
            // await checkAndActivatePackage('webdev');
            await runScript('flutter build web --no-pub');
          } else {
            stdout.writeln(
              'Skipping flutter build web (no $flutterWebMainDartPath)',
            );
          }
        }
      }
    }
  } else {
    if (!options.noBuild) {
      /// Try web dev if possible
      if (pubspecYamlHasAllDependencies(pubspecMap, [
        'build_web_compilers',
        'build_runner',
      ])) {
        if (File(join(path, 'web', 'index.html')).existsSync()) {
          if (options.dryRun) {
            stdout.writeln('# Activate webdev if needed');
            stdout.writeln('\$ $dofPub global activate webdev');
          } else {
            await checkAndActivateWebdev();
          }

          // Work around for something that happens on windows
          // https://github.com/tekartikdev/service_worker/runs/4342612734?check_suite_focus=true
          // $ dart pub global run webdev build
          // webdev could not run for this project.
          // The pubspec.lock file has changed since the .dart_tool/package_config.json file was generated, please run "pub get" again.
          if (Platform.isWindows) {
            await runScript('$dofPub get');
          }
          var webdevBuild = '$dofPub global run webdev build';
          try {
            await runScript(webdevBuild);
          } on ShellException catch (e) {
            // build/ holding other contents (no .build.manifest, such as the
            // output of a `webdev build -o web:build/web`): build_runner
            // cannot ask to delete it (not interactive), delete it and build
            // again, once.
            var result = e.result;
            var conflict = result == null
                ? null
                : webdevBuildMergedDirectoryConflict(
                    '${result.outText}\n${result.errText}',
                  );
            var buildDir = normalize(absolute(join(path, 'build')));
            if (conflict == null ||
                !equals(normalize(absolute(conflict)), buildDir) ||
                !Directory(buildDir).existsSync()) {
              rethrow;
            }
            stdout.writeln(
              '# $buildDir holds other contents: deleted, building again',
            );
            await Directory(buildDir).delete(recursive: true);
            await runScript(webdevBuild);
          }
        }
      }
    }
  }
}

/// The merged output directory `webdev build` (build_runner) refused to
/// overwrite according to its [output] (`Unable to create merged directory
/// /path/build. Choose a different directory or delete the contents of that
/// directory.`: the directory exists with other contents, no
/// `.build.manifest`), null for another failure.
String? webdevBuildMergedDirectoryConflict(String output) => RegExp(
  r'Unable to create merged directory (.+?)\. Choose a different directory',
).firstMatch(output)?.group(1);

/// Flutter web default entry point (relative to the package root).
///
/// `flutter build web` fails when missing so the build step is skipped.
final flutterWebMainDartPath = join('lib', 'main.dart');

bool? _flutterWebEnabled;

/// Enable flutter web if possible. No longer required.
Future<bool> flutterEnableWeb() async {
  if (_flutterWebEnabled == null) {
    if (isFlutterSupportedSync) {
      // await checkAndActivatePackage('flutter');
      // await run('flutter config --enable-web');
      _flutterWebEnabled = true;
    } else {
      _flutterWebEnabled = false;
    }
    /*
    /// requires at least beta
    if (await getFlutterBinChannel() != dartChannelStable) {
      await run('flutter config --enable-web');
      _flutterWebEnabled = true;
    } else {
      _flutterWebEnabled = false;
    }*/
  }
  return _flutterWebEnabled!;
}

/// CiRunner helper
class SinglePackageCiRunner {
  /// CiRunner
  SinglePackageCiRunner(this._pubIoPackage, this.options);
  final PubIoPackage _pubIoPackage;

  /// Shell
  late final shell = Shell(workingDirectory: path);

  /// Filtered dart dirs
  List<String>? filteredDartDirs;

  late Map _pubspecMap;
  late bool _isFlutterPackage;

  /// True for flutter package
  bool get isFlutterPackage => _isFlutterPackage;

  bool get _verbose => options.verbose;

  /// True for workspace root
  bool get isWorkspaceRoot => pubspecYamlIsWorkspaceRoot(_pubspecMap);

  /// Pubspec sdk boundaries
  VersionBoundaries? get pubspecSdkBoundaries =>
      pubspecYamlGetSdkBoundaries(_pubspecMap);

  /// Init pubspec map
  Future<void> init() async {
    await _pubIoPackage.ready;
    _pubspecMap = _pubIoPackage.pubspecYaml;
    _isFlutterPackage = pubspecYamlSupportsFlutter(_pubspecMap);
    if (_verbose) {
      stdout.writeln(
        'package: $path, sdk: $pubspecSdkBoundaries${isFlutterPackage ? ', flutter' : ''}${isWorkspaceRoot ? ', workspace' : ''}',
      );
    }
  }

  /// Path
  String get path => _pubIoPackage.path;

  /// Options
  final PackageRunCiOptions options;

  /// [nodeSetupCheck], only displayed in dry run.
  Future<void> _nodeSetupCheck() async {
    if (options.dryRun) {
      if (nodeSetupNeeded(path)) {
        stdout.writeln('\$ npm install');
      }
      return;
    }
    await nodeSetupCheck(path);
  }

  /// Run a script
  Future<List<ProcessResult>> runScript(String script) async {
    if (options.dryRun) {
      shellScriptSplitLines(script).forEach((line) {
        if (shellScriptLineIsComment(line)) {
          stdout.writeln(line);
        } else {
          stdout.writeln('\$ $line');
        }
      });
      return <ProcessResult>[];
    }
    return await shell.run(script);
  }

  /// Analyze
  Future<void> analyze() async {
    if (isWorkspaceRoot) {
      return;
    }
    if (!options.noAnalyze) {
      // Errors only: the warnings and the infos are reported, not fatal.
      var noFatalWarnings = options.noFatalWarnings;
      if (isFlutterPackage) {
        var fatalArgs = noFatalWarnings
            ? ' --no-fatal-infos --no-fatal-warnings'
            : '';
        await runScript('''
      # Analyze code
      flutter analyze --no-pub$fatalArgs .
    ''');
      } else {
        var fatalArgs = noFatalWarnings
            ? '--no-fatal-warnings'
            : '--fatal-warnings --fatal-infos';
        await runScript('''
      # Analyze code
      dart analyze $fatalArgs .
  ''');
      }
    }
  }

  /// Check or fix format
  Future<void> format({bool fix = false}) async {
    if (isWorkspaceRoot) {
      return;
    }
    filteredDartDirs ??= await filterTopLevelDartDirs(path);
    var filteredDartDirsArg = filteredDartDirs!.join(' ');

    if (fix || !options.noFormat) {
      // Previous version were using dart_style, we now use dart format
      // Even for flutter we use `dart format`, before flutter 3.7 `flutter format` was alloed

      // Needed otherwise formatter is stuck
      if (filteredDartDirsArg.isEmpty) {
        filteredDartDirsArg = '.';
      }
      try {
        if (fix) {
          await runScript('''
            # Format
            dart format $filteredDartDirsArg
    ''');
        } else {
          await runScript('''
            # Check Formatting
            dart format --set-exit-if-changed $filteredDartDirsArg
    ''');
        }
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
  }

  /// Run `tool/dev_build_setup.dart` when found ([devBuildSetupPath]).
  ///
  /// Its errors are reported and ignored: the file could have been created
  /// for another purpose.
  Future<void> devBuildSetup() async {
    if (isWorkspaceRoot) {
      return;
    }
    if (!File(join(path, devBuildSetupPath)).existsSync()) {
      return;
    }
    try {
      await runScript('''
        # Setup
        dart run $devBuildSetupPath
      ''');
    } catch (e) {
      stderr.writeln('(ignored) $devBuildSetupPath failed: $e');
    }
  }

  /// The [runCiCleanupTopDirs] missing when [prepareCleanup] was called.
  List<String>? _cleanupMissingTopDirs;

  /// Record which [runCiCleanupTopDirs] are missing before the tests and the
  /// build (and [devBuildSetup]), the ones then created are deleted by
  /// [cleanup].
  void prepareCleanup() {
    if (isWorkspaceRoot || options.noCleanup) {
      return;
    }
    _cleanupMissingTopDirs = runCiCleanupTopDirs
        .where(
          (dir) =>
              FileSystemEntity.typeSync(join(path, dir), followLinks: false) ==
              FileSystemEntityType.notFound,
        )
        .toList();
  }

  /// Run `tool/dev_build_cleanup.dart` when found ([devBuildCleanupPath]), then
  /// delete the [runCiCleanupTopDirs] created since [prepareCleanup], unless
  /// [PackageRunCiOptions.noCleanup].
  ///
  /// Its errors are reported and ignored.
  Future<void> cleanup() async {
    if (isWorkspaceRoot || options.noCleanup) {
      return;
    }
    if (File(join(path, devBuildCleanupPath)).existsSync()) {
      try {
        await runScript('''
          # Cleanup
          dart run $devBuildCleanupPath
        ''');
      } catch (e) {
        stderr.writeln('(ignored) $devBuildCleanupPath failed: $e');
      }
    }
    var missingTopDirs = _cleanupMissingTopDirs;
    _cleanupMissingTopDirs = null;
    if (missingTopDirs == null) {
      return;
    }
    for (var dir in missingTopDirs) {
      if (options.dryRun) {
        stdout.writeln('# Delete $dir/ if created');
        continue;
      }
      var dirPath = join(path, dir);
      if (isDirectoryNotLinkSynk(dirPath)) {
        stdout.writeln('# Cleanup: delete $dir/ (created)');
        try {
          await Directory(dirPath).delete(recursive: true);
        } catch (e) {
          stderr.writeln('(ignored) deleting $dirPath failed: $e');
        }
      }
    }
  }

  /// Fix basic issues
  Future<void> fix() async {
    await format(fix: true);
    await runScript('dart fix --apply');
  }

  /// Run tests
  Future<void> runTest({List<String>? testOptions}) async {
    var extraArgs = '';
    if (testOptions != null && testOptions.isNotEmpty) {
      extraArgs = ' ${testOptions.join(' ')}';
    }
    if (isFlutterPackage) {
      // flutter test runs on the host (the vm tests).
      if (!options.noTest && !options.noVmTest && !options.chromeJsTestOnly) {
        // 'test', '--no-pub'
        // Flutter way
        await runScript('''
        # Test
        flutter test --no-pub$extraArgs
      ''');
      }
    } else {
      // Test?
      if (!options.noTest) {
        filteredDartDirs ??= await filterTopLevelDartDirs(path);
        if (filteredDartDirs!.contains('test')) {
          var vmTestOnly = options.vmTestOnly;
          var chromeJsTestOnly = options.chromeJsTestOnly;
          var isWeb = pubspecYamlSupportsWeb(_pubspecMap);
          var noVmTest = options.noVmTest || chromeJsTestOnly;
          var noBrowserTest = !isWeb || options.noBrowserTest || vmTestOnly;
          // No node test when node is not installed.
          var noNodeTest =
              !isNodeSupportedSync ||
              options.noNodeTest ||
              vmTestOnly ||
              chromeJsTestOnly;
          var platforms = <String>[if (!noVmTest) 'vm'];
          var supportedPlatforms = <String>[
            if (!noVmTest) 'vm',
            if (!noBrowserTest) 'chrome',
            if (!noNodeTest) 'node',
          ];
          // Tmp don't compile as wasm on windows as it times out, and only
          // dart2js for chrome js tests.
          var noWasm = Platform.isWindows || chromeJsTestOnly;

          if (!noBrowserTest) {
            platforms.add('chrome');
          }
          // Add node for standard run test
          var isNodePackage = pubspecYamlSupportsNode(_pubspecMap);
          if (!noNodeTest && isNodePackage) {
            platforms.add('node');

            if (!options.noNpmInstall) {
              await _nodeSetupCheck();
              // Workaround issue about complaining old pubspec on node...
              // https://travis-ci.org/github/tekartik/aliyun.dart/jobs/724680004
            }

            await runScript('''
            # Get dependencies
            ${_pubIoPackage.dofPub} get --offline
      ''');
          }

          // Check available dart test platforms
          var dartTestFile = File(join(path, 'dart_test.yaml'));
          Map? dartTestMap;
          if (dartTestFile.existsSync()) {
            try {
              dartTestMap =
                  (loadYaml(await dartTestFile.readAsString()) as Map);
            } catch (_) {}
          }
          var testConfig = buildTestConfig(
            platforms: platforms,
            supportedPlatforms: supportedPlatforms,
            dartTestMap: dartTestMap,
            noWasm: noWasm,
          );

          if (testConfig.hasNode) {
            try {
              await _nodeSetupCheck();
            } catch (e) {
              stderr.writeln('(ignored) Error setting up node: $e');
            }
          }
          if (testConfig.configLines.isNotEmpty) {
            for (var line in testConfig.configLines) {
              Future<void> doRunTest() async {
                await runScript(
                  'dart test${line.toCommandLineArgument()}$extraArgs',
                );
              }

              try {
                await doRunTest();
              } catch (e) {
                // No test for this platform, ok
                if (e is ShellException &&
                    e.result?.exitCode == _dartTestNoTestsRanExitCode) {
                  stderr.writeln(
                    '(ignored) No tests ran: dart test${line.toCommandLineArgument()}',
                  );
                  continue;
                }
                // Handle timeout at least once....
                // happens on github actions
                // Compiled nnnnnnnn input bytes (nnnn characters source) to nnnnnnnn characters JavaScript in nnn seconds
                // Failed to load "test/xxxx_test.dart":
                // Timed out waiting for Chrome to connect.
                // Browser output: [5290:20472:0401/230040.569143:ERROR:chrome/browser/chrome_browser_main.cc:1263] The use of Rosetta to run the x64 version of Chromium on Arm is neither tested nor maintained, and unexpected behavior will likely result. Please check that all tools that spawn Chromium are Arm-native.
                if (!_chromeTestTimeoutRetriedOnce &&
                    Platform.isMacOS &&
                    (e is ShellException) &&
                    ((e.result?.errText.contains(
                              'Timed out waiting for Chrome to connect',
                            ) ??
                            false) ||
                        (e.result?.outText.contains(
                              'Timed out waiting for Chrome to connect',
                            ) ??
                            false))) {
                  stderr.writeln(
                    '(ignored) Timeout waiting for Chrome to connect, retrying once...',
                  );
                  _chromeTestTimeoutRetriedOnce = true;
                  await doRunTest();
                } else {
                  rethrow;
                }
              }
            }
          } else if (testConfig.args.isNotEmpty) {
            await runScript('''
      # Test
      dart test${testConfig.toCommandLineArgument()}$extraArgs
      ''');
          }
        }
      }
    }
  }
}

/// Flutter dart prepended env
ShellEnvironment get flutterDartShellEnvironment {
  var env = ShellEnvironment();
  var stdDartExePath = dartExecutable;
  var flutterDartExeParth = flutterDartExecutablePath;
  if (stdDartExePath != null && flutterDartExeParth != null) {
    env.paths.prepend(dirname(flutterDartExeParth));
  }
  return env;
}
