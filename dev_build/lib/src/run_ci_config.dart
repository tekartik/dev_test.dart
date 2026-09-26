import 'package:dev_build/src/package/recursive_pub_path.dart';
import 'package:path/path.dart';
import 'package:process_run/stdio.dart';
import 'package:yaml/yaml.dart';

/// run_ci config file name.
///
/// Read in every folder scanned by `run_ci --recursive`, it filters the
/// folder containing it and its sub folders:
///
/// ```yaml
/// # Only look for packages in these sub folders (default to all)
/// include:
///   - packages
///   - example
/// # Don't look for packages in these folders, use `.` to skip this folder
/// exclude:
///   - example/legacy
/// ```
///
/// Paths are relative to the folder containing the file, using `/` as
/// separator.
const runCiConfigFileName = 'dev_build_run_ci_config.yaml';

/// run_ci config, content of [runCiConfigFileName].
class RunCiConfig {
  /// Create a config.
  RunCiConfig({this.include, this.exclude});

  /// Parse the yaml content of [runCiConfigFileName].
  ///
  /// Throws a [FormatException] if invalid.
  factory RunCiConfig.fromYaml(String content) {
    var yaml = loadYaml(content);
    if (yaml == null) {
      return RunCiConfig();
    }
    if (yaml is! Map) {
      throw FormatException('Map expected in $runCiConfigFileName', content);
    }
    List<String>? readPaths(String key) {
      var value = yaml[key];
      if (value == null) {
        return null;
      }
      if (value is! List || value.any((item) => item is! String)) {
        throw FormatException(
          'List of paths expected for \'$key\' in $runCiConfigFileName',
          content,
        );
      }
      return value.cast<String>();
    }

    return RunCiConfig(
      include: readPaths('include'),
      exclude: readPaths('exclude'),
    );
  }

  /// Sub folders to look for packages in, relative, all if null.
  final List<String>? include;

  /// Sub folders not to look for packages in, relative.
  final List<String>? exclude;

  @override
  String toString() => {
    if (include != null) 'include': include,
    if (exclude != null) 'exclude': exclude,
  }.toString();
}

/// Read the run_ci config found in [dir], null if none.
Future<RunCiConfig?> readRunCiConfig(String dir) async {
  var file = File(join(dir, runCiConfigFileName));
  if (!file.existsSync()) {
    return null;
  }
  try {
    return RunCiConfig.fromYaml(await file.readAsString());
  } on FormatException catch (e) {
    throw FormatException('${e.message} (${file.path})', e.source);
  }
}

/// [recursivePubPath] filtered by the run_ci configs found while scanning
/// (the ones above [dirs] are ignored).
Future<List<String>> runCiRecursivePubPath(
  List<String> dirs, {
  IteratePubPathOptions? options,
}) => scanPubPath(dirs, options: options, hook: _runCiScanHook(const []));

/// Scan hook applying the [rules] of the parent folders and the config found
/// in the scanned folder.
PubPathScanHook _runCiScanHook(List<_RunCiScanRule> rules) => (dir) async {
  dir = normalize(absolute(dir));
  // Excluded by a parent, don't even read its config
  if (!rules.every((rule) => rule.canScan(dir))) {
    return null;
  }
  var config = await readRunCiConfig(dir);
  if (config == null) {
    return PubPathScanDir(list: rules.every((rule) => rule.isIncluded(dir)));
  }
  var rule = _RunCiScanRule(dir, config);
  // Excluded by its own config
  if (!rule.canScan(dir)) {
    return null;
  }
  var dirRules = [...rules, rule];
  return PubPathScanDir(
    list: dirRules.every((rule) => rule.isIncluded(dir)),
    hook: _runCiScanHook(dirRules),
  );
};

/// Filter from the run_ci config of a folder, applies to it and its sub
/// folders.
class _RunCiScanRule {
  _RunCiScanRule(this._dir, RunCiConfig config)
    : _include = config.include?.map((path) => _absolute(_dir, path)).toList(),
      _exclude = (config.exclude ?? const <String>[])
          .map((path) => _absolute(_dir, path))
          .toList();

  /// Absolute normalized.
  final String _dir;
  final List<String>? _include;
  final List<String> _exclude;

  static String _absolute(String dir, String path) =>
      normalize(absolute(dir, path));

  /// [dir] is absolute normalized, the folder holding the config is always
  /// included unless excluded.
  bool _check(String dir, bool Function(String include) matchInclude) =>
      !_isSameOrWithin(_dir, dir) ||
      (!_exclude.any((path) => _isSameOrWithin(path, dir)) &&
          (equals(_dir, dir) || (_include?.any(matchInclude) ?? true)));

  /// True if [dir] must be scanned: included or containing an included folder.
  bool canScan(String dir) => _check(
    dir,
    (include) => _isSameOrWithin(include, dir) || isWithin(dir, include),
  );

  /// True if [dir] can be listed.
  bool isIncluded(String dir) =>
      _check(dir, (include) => _isSameOrWithin(include, dir));
}

bool _isSameOrWithin(String parent, String child) =>
    equals(parent, child) || isWithin(parent, child);
