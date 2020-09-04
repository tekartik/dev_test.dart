import 'dart:io';

import 'package:args/args.dart';
import 'package:dev_test/package.dart';
import 'package:path/path.dart';
import 'package:pub_semver/pub_semver.dart';

final version = Version(0, 1, 0);

void printVersion() {
  stdout.writeln(version);
}

Future<void> main(List<String> arguments) async {
  var parser = ArgParser()
    ..addFlag('version', abbr: 'v', help: 'Application version')
    ..addFlag('help', abbr: 'h', help: 'Help');
  var result = parser.parse(arguments);
  if (result['help'] as bool) {
    printVersion();
    stdout.writeln(' package_info [<dir>]');
    stdout.writeln(parser.usage);
    exit(0);
  }
  if (result['version'] as bool) {
    printVersion();
    stdout.writeln(parser.usage);
    exit(0);
  }
  for (var dir in (result.rest.isEmpty ? ['.'] : result.rest)) {
    stdout.writeln('${normalize(absolute(dir))}:');
    await ioPackageRunCi(dir);
  }
  // var pubspecYaml = pathGetPubspecYamlMap(packageDir)
}
