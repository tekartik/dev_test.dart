import 'dart:io';

import 'package:process_run/package/package.dart';
import 'package:process_run/shell.dart';

Future main() async {
  var shell = Shell();
  var version = await getPackageVersion();
  // ignore: avoid_print
  stdout.writeln('Version $version');
  // ignore: avoid_print
  stdout.writeln('Tap anything or CTRL-C: $version');

  await stdin.first;
  await shell.run('''
git tag dev_build-v$version
git push origin --tags
''');
}
