import 'package:path/path.dart';
import 'package:process_run/shell_run.dart';
import 'package:process_run/stdio.dart';
import 'package:pub_semver/pub_semver.dart';

/// Installed cli packages name and version (local cache).
Map<String, Version>? _installedCliPackages;

/// Parse `dart installed` output lines.
///
/// Lines look like:
/// - `webdev 3.7.1`
/// - `my_package 0.1.0 from "/path/to/my_package" at 2026-07-27 13:17:34.711576`
///
/// Non package lines (i.e. `No Dart CLI tools installed.`) and non active
/// packages are ignored.
Map<String, Version> parseDartInstalledOutLines(Iterable<String> lines) {
  var packages = <String, Version>{};
  for (var line in lines) {
    if (line.contains('(not active)')) {
      continue;
    }
    var parts = line.trim().split(RegExp(r'\s+'));
    if (parts.length < 2) {
      continue;
    }
    try {
      packages[parts[0]] = Version.parse(parts[1]);
    } catch (_) {}
  }
  return packages;
}

/// Get the installed cli packages with their version (with a local cache).
Future<Map<String, Version>> _getInstalledCliPackages({bool? verbose}) async {
  verbose ??= false;
  return _installedCliPackages ??= parseDartInstalledOutLines(
    (await run('dart installed', verbose: verbose)).outLines,
  );
}

/// Get the list of cli packages installed with `dart install` (with a local
/// cache).
Future<List<String>> getInstalledCliPackages({bool? verbose}) async {
  return (await _getInstalledCliPackages(verbose: verbose)).keys.toList();
}

/// Check if a package is installed with `dart install` (with a local cache).
Future<bool> isCliPackageInstalled(String package, {bool? verbose}) async {
  return (await _getInstalledCliPackages(
    verbose: verbose,
  )).containsKey(package);
}

/// Get the version of a package installed with `dart install`, null if not
/// installed (with a local cache).
Future<Version?> getInstalledCliPackageVersion(
  String package, {
  bool? verbose,
}) async {
  return (await _getInstalledCliPackages(verbose: verbose))[package];
}

/// Install (or update) a package with `dart install`.
Future<void> _dartInstall(String package, {bool? verbose}) async {
  verbose ??= false;
  await run('dart install $package', verbose: verbose);
  // Clear the cache to read the installed version on next access.
  _installedCliPackages = null;
}

/// Install a package executables with `dart install` if not installed yet.
///
/// Preferred over `checkAndActivatePackage` (`dart pub global activate`).
///
/// Returns true if the package was installed during this call.
Future<bool> checkAndInstallCliPackage(String package, {bool? verbose}) async {
  if (!await isCliPackageInstalled(package, verbose: verbose)) {
    await _dartInstall(package, verbose: verbose);
    return true;
  }
  return false;
}

/// Uninstall a package installed with `dart install`.
///
/// Returns true if the package was uninstalled during this call.
Future<bool> uninstallCliPackage(String package, {bool? verbose}) async {
  verbose ??= false;
  if (!await isCliPackageInstalled(package, verbose: verbose)) {
    return false;
  }
  await run('dart uninstall $package', verbose: verbose);
  _installedCliPackages?.remove(package);
  return true;
}

/// Check if webdev is installed with `dart install`, install or update it if
/// needed.
///
/// Preferred over `checkAndActivateWebdev` (`dart pub global activate`).
Future<void> checkAndInstallCliWebdev({bool? verbose}) async {
  var webdev = 'webdev';
  verbose ??= false;
  var installed = await checkAndInstallCliPackage(webdev, verbose: verbose);

  var webdevVersion = await getInstalledCliPackageVersion(
    webdev,
    verbose: verbose,
  );
  var needUpdate =
      !installed &&
      (webdevVersion == null || webdevVersion <= Version(2, 7, 11));
  if (verbose) {
    stdout.writeln(
      'webdev version: $webdevVersion ${needUpdate ? '(need update)' : ''}',
    );
  }
  if (needUpdate) {
    await _dartInstall(webdev, verbose: verbose);
  }
}

/// The directory where `dart install` puts the executables.
///
/// It is not always in the PATH (i.e. on CI).
///
/// - Windows: `%LOCALAPPDATA%\Dart\install\bin`
/// - MacOS: `$HOME/Library/Application Support/Dart/install/bin`
/// - Linux: `$XDG_STATE_HOME/Dart/install/bin` or
///   `$HOME/.local/state/Dart/install/bin`
///
/// The `DART_DATA_HOME` environment variable overrides the `Dart` directory.
String getDartInstallBinDir({Map<String, String>? environment}) {
  environment ??= Platform.environment;
  var dartDataHome = environment['DART_DATA_HOME'];
  if (dartDataHome == null) {
    String stateHome;
    if (Platform.isWindows) {
      stateHome = environment['LOCALAPPDATA']!;
    } else if (Platform.isMacOS) {
      stateHome = join(environment['HOME']!, 'Library', 'Application Support');
    } else {
      stateHome =
          environment['XDG_STATE_HOME'] ??
          join(environment['HOME']!, '.local', 'state');
    }
    dartDataHome = join(stateHome, 'Dart');
  }
  return join(dartDataHome, 'install', 'bin');
}
