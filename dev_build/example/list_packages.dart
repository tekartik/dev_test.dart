import 'dart:io';

import 'package:args/args.dart';
import 'package:dev_build/package.dart';
import 'package:path/path.dart';

Future<void> main(List<String> arguments) async {
  var parser = ArgParser()
    ..addFlag('help', abbr: 'h', help: 'Usage help', negatable: false);
  var result = parser.parse(arguments);

  if (result['help'] as bool) {
    stdout.writeln('List recursive pub packages.');
    stdout.writeln('\nUsage: list_packages [<dir1> <dir2> ...]');
    stdout.writeln(parser.usage);
    exit(0);
  }

  var paths = result.rest.isEmpty ? [Directory.current.path] : result.rest;

  var pubDirs = await recursivePubPath(paths);

  for (var dir in pubDirs) {
    stdout.writeln(normalize(absolute(dir)));
  }
}
