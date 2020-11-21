import 'dart:io';

import 'package:path/path.dart';
import 'package:process_run/shell.dart';
import 'package:process_run/which.dart';

/// to deprecate
bool get isNodeSupported => isNodeSupportedSync;

/// true if flutter is supported
final isNodeSupportedSync = whichSync('node') != null;

/// Install node modules for test.
Future nodeSetupCheck(String dir) async {
  if ((File(join(dir, 'package.json')).existsSync())) {
    if (!(Directory(join(dir, 'node_modules')).existsSync())) {
      await Shell(workingDirectory: dir).run('npm install');
    }
  }
}
