@TestOn('vm')
library;

import 'dart:io';

import 'package:dev_build/package.dart';
import 'package:dev_build/src/io/file_utils.dart';
import 'package:path/path.dart';
import 'package:test/test.dart';

void main() {
  test('compiledExe in a path with a space', () async {
    var dir = join('.dart_tool', 'dev_build', 'test', 'compile exe', 'pkg');
    await Directory(dir).prepare();
    await File(join(dir, 'bin', 'main.dart')).create(recursive: true);
    await File(
      join(dir, 'pubspec.yaml'),
    ).writeAsString('name: pkg\nenvironment:\n  sdk: ^3.12.0\n');
    await File(
      join(dir, 'bin', 'main.dart'),
    ).writeAsString("void main() => print('1.2.3');\n");
    var package = DartPackageIo(dir);
    var exe = await package.compiledExe(minVersion: Version(1, 0, 0));
    expect(exe.version, Version(1, 2, 3));
    var modified = File(exe.path).lastModifiedSync();
    // Up to date: reused, not compiled again.
    exe = await package.compiledExe(minVersion: Version(1, 0, 0));
    expect(exe.version, Version(1, 2, 3));
    expect(File(exe.path).lastModifiedSync(), modified);
  }, timeout: const Timeout(Duration(minutes: 2)));
}
