@TestOn('vm')
library dev_build.test.package_test;

import 'dart:io';

import 'package:dev_build/package.dart';
import 'package:dev_build/src/package/recursive_pub_path.dart'
    show posixNormalize, recursiveActions;
import 'package:dev_build/src/run_ci.dart';
import 'package:path/path.dart';
import 'package:process_run/cmd_run.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:test/test.dart';

void main() {
  test('posixNormalize', () async {
    expect(posixNormalize('.'), '.');
    expect(posixNormalize('..'), '..');
    expect(posixNormalize('.\\'), '.');
    expect(posixNormalize('..\\'), '..');
    expect(posixNormalize('.\\a'), 'a');
    expect(posixNormalize('./a'), 'a');
    expect(posixNormalize('..\\a'), '../a');
    expect(posixNormalize('../a'), '../a');
  });
  var repoSupportEntry = join('..', 'repo_support');
  var devTestEntry = join('..', 'dev_test');
  var devBuildEntry = join('..', 'dev_build');
  test('recursivePubPath', () async {
    expect(await recursivePubPath(['.', '..']),
        ['.', devTestEntry, repoSupportEntry]);
    expect(await recursivePubPath(['..', '.']),
        ['.', devTestEntry, repoSupportEntry]);
    expect(await recursivePubPath(['..']),
        [devBuildEntry, devTestEntry, repoSupportEntry]);

    expect(await recursivePubPath(['.']), ['.']);
  });

  test('recursivePubPath dependencies', () async {
    expect(await recursivePubPath(['..'], dependencies: ['dev_build']),
        [devTestEntry, repoSupportEntry]);
    expect(await recursivePubPath(['..'], dependencies: ['dev_test']),
        [repoSupportEntry]);
    expect(
        await recursivePubPath(['..'], dependencies: ['dev_test', 'dev_build']),
        [devTestEntry, repoSupportEntry]);
    expect(await recursivePubPath(['..'], dependencies: ['direct:dev_build']),
        [devTestEntry]);
  });

  test('recursivePubPath ignore build', () async {
    // Somehow on node, build contains pubspec.yaml at its root and should be ignored
    // try to reproduce here
    var outDir = join('.dart_tool', 'dev_build', 'test', 'recursive_test');
    var file = File(join(outDir, 'build', 'pubspec.yaml'));
    await file.parent.create(recursive: true);
    await file.writeAsString('name: dummy');

    expect(await recursivePubPath([outDir]), isEmpty);
  });

  test('check isPubPackageRoot', () async {
    // Check dart version boundaries
    var outDir = join('.dart_tool', 'dev_build', 'test', 'is_pub_package_root');
    var file = File(join(outDir, 'pubspec.yaml'));
    await file.parent.create(recursive: true);
    await file.writeAsString('''
      environment:
        sdk: '>=$dartVersion'
      ''');
    expect(await recursivePubPath([outDir]), [outDir]);

    await file.writeAsString('''
      environment:
        sdk: '>$dartVersion'
      ''');
    expect(await recursivePubPath([outDir]), isEmpty);

    await file.writeAsString('''
      environment:
        sdk: '<=$dartVersion'
      ''');
    expect(await recursivePubPath([outDir]), [outDir]);

    await file.writeAsString('''
      environment:
        sdk: '<$dartVersion'
      ''');
    expect(await recursivePubPath([outDir]), isEmpty);
  });

  test('filterTopLevelDartDirs', () async {
    expect(await filterTopLevelDartDirs(join('..', 'repo_support')), ['tool']);
    expect(await filterTopLevelDartDirs('.'),
        ['bin', 'example', 'lib', 'test', 'tool']);
  });

  test('recursiveActions', () async {
    var list = <String>[];
    await recursiveActions(['.'], action: (src) {
      list.add(src);
    });
    expect(list, ['.']);

    list = <String>[];
    await recursiveActions(['..'], action: (src) {
      list.add(src);
    });
    expect(list, [
      join('..', 'dev_build'),
      join('..', 'dev_test'),
      join('..', 'repo_support')
    ]);
    list = <String>[];
    await recursiveActions(['.', '..'], action: (src) {
      list.add(src);
    });
    expect(list, ['.', join('..', 'dev_test'), join('..', 'repo_support')]);
  });

  test('packageRunCi', () async {
    await packageRunCi('..', noTest: true);
  });

  test('analyze no dart code', () async {
    // Somehow on node, build contains pubspec.yaml at its root and should be ignored
    // try to reproduce here
    var outDir =
        join('.dart_tool', 'dev_build', 'test', 'analyze_no_dart_code_test');
    var file = File(join(outDir, 'pubspec.yaml'));
    await file.parent.create(recursive: true);
    await file.writeAsString('''
name: no_dart_code
environment:
  sdk: '>=2.12.0 <3.0.0'
''');

    await packageRunCi(outDir,
        options: PackageRunCiOptions(analyzeOnly: true, offline: true));
  });
  test('analyze no flutter code', () async {
    // Somehow on node, build contains pubspec.yaml at its root and should be ignored
    // try to reproduce here
    var outDir = join('.dart_tool', 'dev_build', 'test',
        'analyze_no_flutter_code_test', 'sub');
    var file = File(join(outDir, 'pubspec.yaml'));
    await file.parent.create(recursive: true);
    await file.writeAsString('''
name: no_dart_code
environment:
  sdk: '>=2.12.0 <3.0.0'
dependencies:
  flutter:
    sdk: flutter
''');

    // Make it handles sub dir too
    await packageRunCi(dirname(outDir),
        options: PackageRunCiOptions(
            analyzeOnly: true,
            formatOnly: true,
            offline: true,
            recursive: true));
    await packageRunCi(outDir,
        options: PackageRunCiOptions(analyzeOnly: true, offline: true));
  });

  test('DartPackageIo', () async {
    var outDir =
        join('.dart_tool', 'dev_build', 'test', 'dart_package_io_test');
    var file = File(join(outDir, 'pubspec.yaml'));
    await file.parent.create(recursive: true);
    await file.writeAsString('''
name: dart_package_io
version: 1.0.0
environment:
  sdk: 1
''');
    var package = DartPackageIo(outDir);
    await package.ready;
    expect(package.getVersion(), Version(1, 0, 0));
    expect(package.setVersion(Version(1, 0, 1)), isTrue);
    expect(package.getVersion(), Version(1, 0, 1));
    await package.write();
    package = DartPackageIo(outDir);
    await package.ready;
    expect(package.getVersion(), Version(1, 0, 1));
  });
}
