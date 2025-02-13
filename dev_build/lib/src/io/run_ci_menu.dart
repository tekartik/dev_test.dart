import 'dart:convert';

import 'package:dev_build/menu/menu_io.dart';
import 'package:dev_build/package.dart';
import 'package:dev_build/shell.dart' hide prompt;
import 'package:dev_build/src/package/pub_io_package.dart';

import '../mixin/package.dart';

Future<void> main(List<String> args) async {
  mainMenuConsole(args, () {
    runCiMenu('.');
  });
}

/// Common CI menu
void runCiMenu(String path) {
  var package = PubIoPackage(path, options: PubIoPackageOptions(verbose: true));
  var verbose = true;
  enter(() async {
    try {
      await package.ready;
      write('Running CI for package ${package.path}');
    } catch (e) {
      write('Not a dart project, error: $e');
    }
  });
  item('info', () async {
    try {
      await package.ready;
      write(
        _jsonPretty({
          'isFlutter': package.isFlutter,
          'isWorkspace': package.isWorkspace,
          'workPath': await pathGetResolvedWorkPath(package.path),
          'packageConfigPath': await pathGetPackageConfigJsonPath(package.path),
        }),
      );
      write('Running CI for package ${package.path}');
    } catch (e) {
      write('Not a dart project, error: $e');
    }
  });
  item('pub get', () async {
    await package.pubGet();
  });
  item('pub upgrade', () async {
    await package.pubUpgrade();
  });
  item('pub downgrade', () async {
    await package.pubDowngrade();
  });
  item('dump dependencies', () async {
    await package.dumpDeps();
  });
  item('run_ci', () async {
    await packageRunCi(package.path);
  });
  item('analyze', () async {
    await packageRunCi(
      package.path,
      options: PackageRunCiOptions(
        analyzeOnly: true,
        noPubGet: true,
        verbose: verbose,
      ),
    );
  });
  item('format', () async {
    await packageRunCi(
      package.path,
      options: PackageRunCiOptions(
        formatOnly: true,
        noPubGet: true,
        verbose: verbose,
      ),
    );
  });
  item('cd (prompt)', () async {
    var dir = await prompt('Enter a directory');
    package.shell = Shell(workingDirectory: dir);
  });
}

String _jsonPretty(Object? object) {
  return const JsonEncoder.withIndent(' ').convert(object);
}
