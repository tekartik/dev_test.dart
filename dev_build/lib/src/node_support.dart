import 'package:path/path.dart';
import 'package:process_run/shell.dart';
import 'package:process_run/stdio.dart';

/// to deprecate
bool get isNodeSupported => isNodeSupportedSync;

/// true if flutter is supported
final isNodeSupportedSync = whichSync('node') != null;

/// true if flutter is supported
final isNpmSupported = whichSync('npm') != null;

/// True if [nodeSetupCheck] would run `npm install` in [dir].
bool nodeSetupNeeded(String dir) =>
    isNpmSupported &&
    File(join(dir, 'package.json')).existsSync() &&
    !Directory(join(dir, 'node_modules')).existsSync();

/// Install node modules for test.
Future nodeSetupCheck(String dir) async {
  if (nodeSetupNeeded(dir)) {
    await Shell(workingDirectory: dir).run('npm install');
  }
}
