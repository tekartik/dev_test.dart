import 'dart:io';

import 'package:dev_build/package.dart';
import 'package:dev_build/src/version_utils.dart';
import 'package:path/path.dart';
import 'package:process_run/shell.dart';
import 'package:pub_semver/pub_semver.dart';

/// Compile exe info
class DartPackageIoCompiledExe {
  /// Exe path
  final String path;

  /// Version
  final Version? version;

  /// Compile exe info
  DartPackageIoCompiledExe(this.path, this.version);
}

///
extension DartPackageIoCompileExeExt on DartPackageIo {
  Future<Version?> _getVersion(String exe) async {
    try {
      var version = parseFirstVersion(
        (await run('$exe --version')).outText.trim(),
      );
      return version;
    } catch (_) {}
    return null;
  }

  /// Simple exe compiler
  Future<DartPackageIoCompiledExe> compiledExe({
    String? script,
    bool force = false,
    Version? minVersion,
  }) async {
    script = normalize(
      absolute(
        joinAll([
          path,
          if (script != null) script else ...['bin', 'main.dart'],
        ]),
      ),
    );
    var scriptBasename = basenameWithoutExtension(script);
    var folder =
        Platform.isWindows ? 'windows' : (Platform.isMacOS ? 'macos' : 'linux');
    var exeExtension = Platform.isWindows ? '.exe' : '';
    var exe = join(path, 'build', folder, '$scriptBasename$exeExtension');
    var exeDir = dirname(exe);

    var shell = Shell(verbose: false);
    var file = File(exe);

    var needCompile = force || !file.existsSync();

    if (!needCompile && minVersion == null) {
      return DartPackageIoCompiledExe(exe, null);
    }
    if (!needCompile && file.existsSync()) {
      if (minVersion != null) {
        var version = await _getVersion(exe);
        if (version != null && version >= minVersion) {
          return DartPackageIoCompiledExe(exe, version);
        } else {
          needCompile = true;
        }
      }
    }
    if (needCompile) {
      Directory(exeDir).createSync(recursive: true);
      await shell.run(
        'dart compile exe ${shellArgument(script)} -o ${shellArgument(exe)}',
      );
    }
    var version = await _getVersion(exe);
    return DartPackageIoCompiledExe(exe, version);
  }
}
