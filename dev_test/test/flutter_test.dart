@TestOn('vm')
import 'dart:io';

import 'package:dev_test/build_support.dart';
import 'package:dev_test/package.dart';
import 'package:path/path.dart';
import 'package:process_run/shell.dart';
import 'package:test/test.dart';

Future<void> main() async {
  group('flutter', () {
    test('format', () async {
      var path = join('.dart_tool', 'dev_test', 'test', 'flutter_format');

      await flutterCreateProject(path: path, template: flutterTemplatePackage);
      // shell.run('flutter create --template $template ${shellArgument(basename(path))}');
      // Create a bad file
      await File(join(path, 'lib', 'dummy.dart'))
          .writeAsString('void dummy() {}');
      await expectLater(
          packageRunCi(path,
              options: PackageRunCiOptions(
                  noAnalyze: true, noTest: true, offline: true)),
          throwsException);
      await Shell(workingDirectory: path).run('flutter format --fix lib');
      await packageRunCi(path,
          options: PackageRunCiOptions(
              noAnalyze: true, noTest: true, noPubGet: true));
    });
  }, skip: !isFlutterSupported ? 'skipped - flutter not supported' : false);
}
