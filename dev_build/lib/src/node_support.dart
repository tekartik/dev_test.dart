import 'package:path/path.dart';
import 'package:process_run/shell.dart';
import 'package:process_run/stdio.dart';

/// to deprecate
bool get isNodeSupported => isNodeSupportedSync;

/// true if flutter is supported
final isNodeSupportedSync = whichSync('node') != null;

/// true if flutter is supported
final isNpmSupported = whichSync('npm') != null;

/// Install node modules for test.
Future nodeSetupCheck(String dir) async {
  if (isNpmSupported && (File(join(dir, 'package.json')).existsSync())) {
    if (!(Directory(join(dir, 'node_modules')).existsSync())) {
      await Shell(workingDirectory: dir).run('npm install');
    }
  }
}
