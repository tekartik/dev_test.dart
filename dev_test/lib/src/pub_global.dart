import 'package:process_run/shell_run.dart';
import 'package:pub_semver/pub_semver.dart';

List<String>? _installedGlobalPackages;

/// Returns true if the package was activated during this call.
Future<bool> checkAndActivatePackage(String package, {bool? verbose}) async {
  var list = await getInstalledGlobalPackages(verbose: verbose);
  if (!list.contains(package)) {
    await _pubGlobalActivate(package, verbose: verbose);
    return true;
  }
  return false;
}

/// Returns true if the package was activated during this call.
Future<void> _pubGlobalActivate(String package, {bool? verbose}) async {
  verbose ??= false;
  var list = await getInstalledGlobalPackages(verbose: verbose);
  await run('dart pub global activate $package', verbose: verbose);
  list.add(package);
}

Future<List<String>> getInstalledGlobalPackages({bool? verbose}) async {
  verbose ??= false;
  if (_installedGlobalPackages == null) {
    var lines = (await run('dart pub global list', verbose: verbose)).outLines;
    _installedGlobalPackages =
        lines.map((line) => line.split(' ')[0]).toList(growable: true);
  }
  return _installedGlobalPackages!;
}

Future<bool> isPackageActivated(String package, {bool? verbose}) async {
  var list = await getInstalledGlobalPackages(verbose: verbose);
  return list.contains(package);
}

Future<void> deactivatePackage(String package, {bool? verbose}) async {
  var list = await getInstalledGlobalPackages(verbose: verbose);
  await run('dart pub global deactivate $package', verbose: true);
  list.remove(package);
}

Future<void> checkAndActivateWebdev({bool? verbose}) async {
  var webdev = 'webdev';
  verbose ??= false;
  var justInstalled = await checkAndActivatePackage(webdev, verbose: verbose);
  if (!justInstalled) {
    try {
      var webdevVersion = Version.parse(
          (await run('dart pub global run $webdev --version', verbose: verbose))
              .outText
              .trim());
      var needUpdate = false;
      // Handle flutter dart 2.19
      if (dartVersion >= Version(2, 19, 0, pre: '0') &&
          (webdevVersion <= Version(2, 7, 11))) {
        needUpdate = true;
      }
      if (needUpdate) {
        await _pubGlobalActivate(webdev);
      }
    } catch (e) {
      print('failed to get webdev version $e');
    }
  }
}
