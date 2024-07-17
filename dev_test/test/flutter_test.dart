@TestOn('vm')
library;

import 'dart:io';

import 'package:dev_build/build_support.dart';
import 'package:dev_build/package.dart';
import 'package:path/path.dart';
import 'package:process_run/shell.dart';
import 'package:test/test.dart';

Future<void> main() async {
  group('flutter', () {
    test('test', () async {
      var currentDirectory = Directory.current;
      var path = join('.dart_tool', 'dev_test', 'test', 'flutter_dev_test');

      await flutterCreateProject(path: path, template: flutterTemplatePackage);
      // shell.run('flutter create --template $template ${shellArgument(basename(path))}');
      // Create a bad file
      await File(join(path, 'lib', 'dummy.dart'))
          .writeAsString('void dummy() {}');
      await File(join(path, 'test', 'dev_flutter_test.dart')).writeAsString('''
import 'package:dev_test/test.dart' as dev_test;
import 'package:flutter_test/flutter_test.dart';
// ignore: deprecated_member_use, depend_on_referenced_packages
import 'package:test_api/test_api.dart' as test_api;

void main() {
  test('simple', () {});
  dev_test.test('dev_test', () {});
  test_api.test('test_api', () {});
}
      ''');
      for (var file in [
        'dev_test_api_only_test',
        'dev_test_api_test',
        'dev_test_core_only_test',
        'dev_test_only_test',
      ]) {
        await File(join('test', '$file.dart'))
            .copy(join(path, 'test', '$file.dart'));
      }
      var shell = Shell(workingDirectory: path);
      await shell.run(
          'flutter pub add ${shellArgument('dev:dev_test:{"path":"${currentDirectory.path}"}')} --directory .');
      var pubspecYaml = (await pathGetPubspecYamlMap(path));
      var boundaries = pubspecYamlGetSdkBoundaries(pubspecYaml)!;
      // Handle the case current dart version is not compatible with flutter
      if (boundaries.matches(dartVersion)) {
        await expectLater(
            packageRunCi(path,
                options: PackageRunCiOptions(
                    noAnalyze: true,
                    noTest: true,
                    offline: true,
                    verbose: true)),
            throwsException);
        // Even for flutter we use `dart format`, before flutter 3.7 `flutter format` was alloed
        await Shell(workingDirectory: path).run('dart format --fix lib');
        await packageRunCi(path,
            options: PackageRunCiOptions(noAnalyze: true, noPubGet: true));
      }
    });
  }, skip: !isFlutterSupported ? 'skipped - flutter not supported' : false);
}
