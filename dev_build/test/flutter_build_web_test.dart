@TestOn('vm')
library;

import 'dart:io';

import 'package:dev_build/build_support.dart';
import 'package:path/path.dart';
import 'package:process_run/shell.dart';
import 'package:test/test.dart';

/// Run `run_ci` in dry run mode on [path], returning the printed script lines.
Future<String> runCiBuildDryRun(String path) async {
  var results = await Shell(verbose: false).run(
    'dart run ${shellArgument(join('bin', 'run_ci.dart'))}'
    ' --dry-run --build --no-recursive ${shellArgument(path)}',
  );
  return results.first.outText;
}

Future<void> main() async {
  group('flutter build web', () {
    var topDir = join('.dart_tool', 'dev_build', 'test', 'flutter_build_web');

    /// Flutter package with a `web` folder but no entry point.
    late String noMainPath;

    /// Same with a `lib/main.dart` entry point.
    late String withMainPath;

    setUpAll(() async {
      noMainPath = join(topDir, 'flutter_web_no_main');
      withMainPath = join(topDir, 'flutter_web_with_main');
      for (var path in [noMainPath, withMainPath]) {
        await flutterCreateProject(
          path: path,
          template: flutterTemplatePackage,
        );
        // A flutter package has no web folder, add one.
        await File(join(path, 'web', 'index.html'))
            .create(recursive: true)
            .then(
              (file) => file.writeAsString('''
<!DOCTYPE html>
<html>
<head><title>test</title></head>
<body></body>
</html>
'''),
            );
      }
      // Only the second one has an entry point.
      await File(join(withMainPath, 'lib', 'main.dart')).writeAsString('''
void main() {}
''');
    });

    test('skipped when no main.dart', () async {
      var out = await runCiBuildDryRun(noMainPath);
      // The dry run prints the commands prefixed with '\$ '
      expect(out, isNot(contains(r'$ flutter build web')));
      expect(out, contains('Skipping flutter build web'));
    }, timeout: const Timeout(Duration(minutes: 2)));

    test('built when main.dart exists', () async {
      var out = await runCiBuildDryRun(withMainPath);
      expect(out, contains(r'$ flutter build web --no-pub'));
    }, timeout: const Timeout(Duration(minutes: 2)));
  }, skip: !isFlutterSupported ? 'skipped - flutter not supported' : false);
}
