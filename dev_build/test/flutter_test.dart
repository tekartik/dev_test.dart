@TestOn('vm')
import 'dart:io';

import 'package:dev_build/build_support.dart';
import 'package:dev_build/package.dart';
import 'package:path/path.dart';
import 'package:process_run/shell.dart';
import 'package:test/test.dart';

Future<void> main() async {
  group('flutter', () {
    test('format', () async {
      var path = join('.dart_tool', 'dev_build', 'test', 'flutter_format_test');

      await flutterCreateProject(path: path, template: flutterTemplatePackage);
      // shell.run('flutter create --template $template ${shellArgument(basename(path))}');
      // Create a bad file
      await File(join(path, 'lib', 'dummy.dart'))
          .writeAsString('void dummy() {}');
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
            options: PackageRunCiOptions(
                noAnalyze: true, noTest: true, noPubGet: true));
      }
    });
  }, skip: !isFlutterSupported ? 'skipped - flutter not supported' : false);
}
