import 'package:dev_build/package.dart';
import 'package:dev_build/src/package/package.dart';
import 'package:dev_build/src/package/pub_io_package.dart';
import 'package:dev_build/src/package/test_config.dart';
import 'package:dev_build/src/pub_io.dart';
import 'package:path/path.dart';
import 'package:process_run/shell_run.dart';
import 'package:process_run/src/shell_utils.dart'; // ignore: implementation_imports
import 'package:process_run/stdio.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:yaml/yaml.dart';

import 'import.dart';
import 'mixin/package.dart';
import 'node_support.dart';
import 'package/recursive_pub_path.dart';
import 'pub_global.dart';

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
}) async {
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
    poolSize: poolSize,
  );
}

final _runCiOverridePath = join('tool', 'run_ci_override.dart');

/// Package run ci.
Future<void> packageRunCiImpl(
  String path,
  PackageRunCiOptions options, {
  bool recursive = false,
  int? poolSize,
}) async {
  if (recursive) {
    await recursiveActions(
      [path],
      verbose: options.verbose,
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
  final String workspaceRoot;
  final bool offline;
  final _PubWorkspaceCacheAction action;

  _PubWorkspaceCache(this.workspaceRoot, this.action, this.offline);
}

class _PubWorkspacesCache {
  final _map = <String, _PubWorkspaceCache>{};

  _PubWorkspacesCache();
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
  var shell = Shell(workingDirectory: path);

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

  // ensure test exists
  if (!Directory(join(path, 'test')).existsSync()) {
    options.noTest = true;
  }

  Future<List<ProcessResult>> runScript(String script) async {
    if (options.dryRun) {
      scriptToCommands(script).forEach((command) {
        stdout.writeln('\$ $command');
      });
      return <ProcessResult>[];
    }
    return await shell.run(script);
  }

  if (!options.noPubGetOrUpgrade) {
    var offline = options.offline;
    var action =
        options.pubUpgradeOnly
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
  if (options.fixOnly) {
    await runScript('dart fix --apply');
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
  if (isFlutterPackage) {
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
    // Test?
    if (!options.noTest) {
      var filteredDartDirs = await filterTopLevelDartDirs(path);
      if (filteredDartDirs.contains('test')) {
        var vmTestOnly = options.vmTestOnly;
        var chromeJsTestOnly = options.chromeJsTestOnly;
        var isWeb = pubspecYamlSupportsWeb(pubspecMap);
        var noVmTest = options.noVmTest || chromeJsTestOnly;
        var noBrowserTest = !isWeb || options.noBrowserTest || vmTestOnly;
        var noNodeTest =
            isNodeSupportedSync &&
            (options.noNodeTest || vmTestOnly || chromeJsTestOnly);
        var platforms = <String>[if (!options.noVmTest) 'vm'];
        var supportedPlatforms = <String>[
          if (!noVmTest) 'vm',
          if (!noBrowserTest) 'chrome',
          if (!noNodeTest) 'node',
        ];
        // Tmp don't compile as wasm on windows as it times out
        var noWasm = Platform.isWindows;

        if (!noBrowserTest) {
          platforms.add('chrome');
        }
        // Add node for standard run test
        var isNodePackage = pubspecYamlSupportsNode(pubspecMap);
        if (!noNodeTest && isNodePackage) {
          platforms.add('node');

          if (!options.noNpmInstall) {
            await nodeSetupCheck(path);
            // Workaround issue about complaining old pubspec on node...
            // https://travis-ci.org/github/tekartik/aliyun.dart/jobs/724680004
          }

          await runScript('''
          # Get dependencies
          $dofPub get --offline
    ''');
        }

        // Check available dart test platforms
        var dartTestFile = File(join(path, 'dart_test.yaml'));
        Map? dartTestMap;
        if (dartTestFile.existsSync()) {
          try {
            dartTestMap = (loadYaml(await dartTestFile.readAsString()) as Map);
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
            await nodeSetupCheck(path);
          } catch (e) {
            stderr.writeln('(ignored) Error setting up node: $e');
          }
        }
        if (testConfig.configLines.isNotEmpty) {
          for (var line in testConfig.configLines) {
            await runScript('dart test${line.toCommandLineArgument()}'); //
          }
        } else if (testConfig.args.isNotEmpty) {
          await runScript('''
    # Test
    dart test${testConfig.toCommandLineArgument()}
    ''');
        }

        if (!noBrowserTest) {
          if (pubspecYamlSupportsBuildRunner(pubspecMap)) {
            if (dartVersion >= Version(2, 10, 0, pre: '110')) {
              stderr.writeln(
                '\'$dofPub run build_runner test -- -p chrome\' skipped issue: https://github.com/dart-lang/sdk/issues/43589',
              );
            } else {
              await runScript('''
      # Build runner test
      $dofPub run build_runner test -- -p chrome
      ''');
            }
          }
        }
      }
    }

    if (!options.noBuild) {
      /// Try web dev if possible
      if (pubspecYamlHasAllDependencies(pubspecMap, [
        'build_web_compilers',
        'build_runner',
      ])) {
        if (File(join(path, 'web', 'index.html')).existsSync()) {
          await checkAndActivateWebdev();

          // Work around for something that happens on windows
          // https://github.com/tekartikdev/service_worker/runs/4342612734?check_suite_focus=true
          // $ dart pub global run webdev build
          // webdev could not run for this project.
          // The pubspec.lock file has changed since the .dart_tool/package_config.json file was generated, please run "pub get" again.
          if (Platform.isWindows) {
            await runScript('$dofPub get');
          }
          await runScript('$dofPub global run webdev build');
        }
      }
    }
  }
}

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

  /// CiRunner
  SinglePackageCiRunner(this._pubIoPackage, this.options);

  /// Run a script
  Future<List<ProcessResult>> runScript(String script) async {
    if (options.dryRun) {
      scriptToCommands(script).forEach((command) {
        stdout.writeln('\$ $command');
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
      if (isFlutterPackage) {
        await runScript('''
      # Analyze code
      flutter analyze --no-pub .
    ''');
      } else {
        await runScript('''
      # Analyze code
      dart analyze --fatal-warnings --fatal-infos .
  ''');
      }
    }
  }

  /// Analyze
  Future<void> format() async {
    if (isWorkspaceRoot) {
      return;
    }
    filteredDartDirs ??= await filterTopLevelDartDirs(path);
    var filteredDartDirsArg = filteredDartDirs!.join(' ');

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
