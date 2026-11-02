import 'package:path/path.dart';
import 'package:process_run/shell_run.dart';
import 'package:process_run/stdio.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:synchronized/synchronized.dart';

/// The activated packages, listed once per isolate.
///
/// A future so that concurrent callers share the same `dart pub global list`.
Future<List<String>>? _installedGlobalPackages;

/// Serializes the callers of this isolate before the lock file, which polls.
final _pubGlobalIsolateLock = Lock();

/// Older locks are considered stale (i.e. killed process).
const _pubGlobalLockTimeout = Duration(minutes: 5);

/// Run [action] holding a lock file shared by all isolates and processes.
///
/// Concurrent `dart pub global activate` of the same package fail (exit code
/// 66) when building its executables snapshot at the same time, which happens
/// with concurrent test files or run_ci packages on a fresh pub cache.
///
/// Not reentrant: [action] must not call it again.
Future<T> _pubGlobalLock<T>(Future<T> Function() action) =>
    _pubGlobalIsolateLock.synchronized(() => _pubGlobalFileLock(action));

/// The lock file part of [_pubGlobalLock], shared with other isolates and
/// processes.
Future<T> _pubGlobalFileLock<T>(Future<T> Function() action) async {
  var lockFile = File(
    join(Directory.systemTemp.path, 'dev_build_pub_global.lock'),
  );
  var sw = Stopwatch()..start();
  var locked = false;
  while (true) {
    try {
      await lockFile.create(exclusive: true);
      locked = true;
      break;
    } on FileSystemException catch (_) {
      if (sw.elapsed > _pubGlobalLockTimeout) {
        // Proceed anyway
        break;
      }
      try {
        if (DateTime.now().difference(lockFile.lastModifiedSync()) >
            _pubGlobalLockTimeout) {
          await lockFile.delete();
        }
      } catch (_) {}
      await Future<void>.delayed(const Duration(milliseconds: 250));
    }
  }
  try {
    return await action();
  } finally {
    if (locked) {
      try {
        await lockFile.delete();
      } catch (_) {}
    }
  }
}

/// Prefer [checkAndPubGlobalActivatePackage] (or `PubGlobalPackageService`
/// for version boundaries).
///
/// Returns true if the package was activated during this call.
Future<bool> checkAndActivatePackage(String package, {bool? verbose}) =>
    checkAndPubGlobalActivatePackage(package, verbose: verbose);

/// Activate a package with `dart pub global activate` if not activated yet.
///
/// [force] activates it even if already activated (i.e. updates it to its
/// latest version).
///
/// `checkAndInstallCliPackage` (`dart install`) is preferred for executables.
///
/// Returns true if the package was activated during this call.
Future<bool> checkAndPubGlobalActivatePackage(
  String package, {
  bool? force,
  bool? verbose,
}) => _pubGlobalLock(
  () => _checkAndActivatePackage(package, force: force, verbose: verbose),
);

Future<bool> _checkAndActivatePackage(
  String package, {
  bool? force,
  bool? verbose,
}) async {
  if (!(force ?? false)) {
    if (await isPackageActivated(package, verbose: verbose)) {
      return false;
    }
    // Another isolate or process might have activated it meanwhile.
    var list = await getPubGlobalInstalledPackages(
      force: true,
      verbose: verbose,
    );
    if (list.contains(package)) {
      return false;
    }
  }
  await _pubGlobalActivate(package, verbose: verbose);
  return true;
}

/// Activate (or update) a package.
Future<void> _pubGlobalActivate(String package, {bool? verbose}) async {
  verbose ??= false;
  var list = await getPubGlobalInstalledPackages(verbose: verbose);
  await run('dart pub global activate $package', verbose: verbose);
  // Already there when updating (webdev), a duplicate would survive a
  // deactivate.
  if (!list.contains(package)) {
    list.add(package);
  }
}

/// Get the list of activated packages (with a local cache).
///
/// Prefer [getPubGlobalInstalledPackages].
Future<List<String>> getInstalledGlobalPackages({bool? verbose}) =>
    getPubGlobalInstalledPackages(verbose: verbose);

/// Get the list of packages activated with `dart pub global activate` (with a
/// local cache, per isolate).
///
/// [force] lists them again (`dart pub global list`) and refreshes the cache,
/// i.e. when another process might have activated or deactivated a package.
Future<List<String>> getPubGlobalInstalledPackages({
  bool? force,
  bool? verbose,
}) async {
  if (force ?? false) {
    _installedGlobalPackages = null;
  }
  var future = _installedGlobalPackages ??= _listInstalledGlobalPackages(
    verbose: verbose ?? false,
  );
  try {
    return await future;
  } catch (_) {
    // Don't cache a failure.
    if (identical(_installedGlobalPackages, future)) {
      _installedGlobalPackages = null;
    }
    rethrow;
  }
}

Future<List<String>> _listInstalledGlobalPackages({
  required bool verbose,
}) async {
  var lines = (await run('dart pub global list', verbose: verbose)).outLines;
  return lines.map((line) => line.split(' ')[0]).toList(growable: true);
}

/// Check if a package is activated (with a local cache).
Future<bool> isPackageActivated(String package, {bool? verbose}) async {
  var list = await getPubGlobalInstalledPackages(verbose: verbose);
  return list.contains(package);
}

/// deactivate a package.
Future<void> deactivatePackage(String package, {bool? verbose}) =>
    _pubGlobalLock(() async {
      var list = await getPubGlobalInstalledPackages(verbose: verbose);
      await run('dart pub global deactivate $package', verbose: true);
      list.remove(package);
    });

/// Typically the last line contains the version
Version? extractWebdevVersionFromOutLines(List<String> lines) {
  for (var line in lines.reversed) {
    try {
      return Version.parse(line.trim());
    } catch (_) {}
  }
  return null;
}

/// Check if webdev is activated.
///
/// The version check runs under the lock too as `dart pub global run` builds
/// the snapshot if missing.
Future<void> checkAndActivateWebdev({bool? verbose}) =>
    _pubGlobalLock(() => _checkAndActivateWebdev(verbose: verbose));

Future<void> _checkAndActivateWebdev({bool? verbose}) async {
  var webdev = 'webdev';
  verbose ??= false;
  await _checkAndActivatePackage(webdev, verbose: verbose);

  var needUpdate = false;
  try {
    var lines = (await run(
      'dart pub global run $webdev --version',
      verbose: verbose,
    )).outLines.toList();
    var webdevVersion = extractWebdevVersionFromOutLines(lines);
    if (webdevVersion == null) {
      // ignore: avoid_print
      print('failed to get webdev version');
      needUpdate = true;
    } else
    // Handle flutter dart 2.19
    if (dartVersion >= Version(2, 19, 0, pre: '0') &&
        (webdevVersion <= Version(2, 7, 11))) {
      needUpdate = true;
    }
    if (verbose) {
      stdout.writeln(
        'webdev version: $webdevVersion ${needUpdate ? '(need update)' : ''}',
      );
    }
  } catch (e) {
    if (verbose) {
      stderr.writeln('failed to get webdev version $e, updating...');
    }
    needUpdate = true;
  }

  if (needUpdate) {
    await _pubGlobalActivate(webdev, verbose: verbose);
  }
}
