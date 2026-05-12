import 'package:dev_build/build_support.dart';
import 'package:dev_build/shell.dart';
import 'package:dev_build/src/package/pub_global_package.dart';
import 'package:process_run/stdio.dart';

/// Check or
Future<void> checkOrPubActivateHostedPackage(
  String name, {
  bool? verbose,
  VersionBoundaries? versionBoundaries,
}) async {
  verbose ??= false;

  var service = PubGlobalPackageService();
  var package = PubGlobalHostedPackageInstall(
    name,
    versionBoundaries: versionBoundaries,
  );
  await service.checkOrActivateHostedPackage(package, verbose: verbose);
}

/// Service to manage pub global packages
class PubGlobalPackageService {
  /// Get activated package information if any
  Future<PubGlobalPackage?> getActivatedPackage(
    String name, {
    bool? verbose,
  }) async {
    var shell = Shell(verbose: verbose ?? false);
    var result = await shell.run('dart pub global list');
    var lines = result.outLines;

    for (final line in lines) {
      final package = PubGlobalPackage.fromListLine(line);
      if (package?.name == name) {
        return package;
      }
    }
    return null;
  }

  /// Check package version
  Future<void> checkOrActivateHostedPackage(
    PubGlobalHostedPackageInstall package, {
    bool? verbose,
  }) async {
    var name = package.name;
    var existing = await getActivatedPackage(name, verbose: verbose);
    var versionBoundaries = package.versionBoundaries;
    if (existing != null) {
      if (versionBoundaries != null) {
        var version = existing.version;
        if (version != null) {
          if (versionBoundaries.matches(version)) {
            return;
          }
        }
      } else {
        return;
      }
    }
    await activateGlobalPackage(package, verbose: verbose);
  }

  /// Activate package according its saved configuration if any
  Future<void> activateGlobalPackage(
    PubGlobalPackage package, {

    /// Set when updating
    bool? dryRun,
    bool? verbose,
  }) async {
    dryRun ??= false;
    verbose ??= false;

    String cmd;
    cmd =
        'dart pub global activate ${package.activateArgs.map((e) => shellArgument(e)).join(' ')}';
    if (dryRun) {
      stdout.writeln(cmd);
    } else {
      var packageName = package.name;
      if (verbose) {
        stdout.writeln('checking: $packageName');
      }

      final result = await Shell(verbose: verbose).run(cmd);

      final lines = result.outLines;
      for (final line in lines) {
        final updatedPackage = PubGlobalPackage.fromActivatedLine(
          line,
          packageName,
        );
        if (updatedPackage != null) {
          stdout.writeln('activated: $updatedPackage');
        }
      }
    }
  }

  /// Deactivate package
  Future<void> deactivateGlobalPackage(
    String name, {
    bool? dryRun,
    bool? verbose,
  }) async {
    dryRun ??= false;
    verbose ??= false;

    String cmd;
    cmd = 'dart pub global deactivate $name';
    if (dryRun) {
      stdout.writeln(cmd);
    } else {
      if (verbose) {
        stdout.writeln('deactivating: $name');
      }
      await Shell(verbose: verbose).run(cmd);
    }
  }
}
