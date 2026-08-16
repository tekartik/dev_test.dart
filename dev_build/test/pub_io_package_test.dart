@TestOn('vm')
library;

import 'package:dev_build/menu/menu_run_ci.dart' show PubIoPackage;
import 'package:dev_build/src/io/file_utils.dart';
import 'package:path/path.dart';
import 'package:process_run/stdio.dart';
import 'package:test/test.dart';

var _testOutTopDir = join('.dart_tool', 'dev_build', 'test', 'pub_io_package');

/// Prepare an empty package dir with the given pubspec content.
Future<String> _preparePackageDir(
  String name, {
  required String pubspecYamlContent,
}) async {
  var outDir = join(_testOutTopDir, name);
  await Directory(outDir).prepare();
  await Directory(outDir).create(recursive: true);
  await File(
    join(outDir, 'pubspec.yaml'),
  ).writeAsString(pubspecYamlContent, flush: true);
  return outDir;
}

Future<void> _writeDartFile(String path, String content) async {
  var file = File(path);
  await file.parent.create(recursive: true);
  await file.writeAsString(content, flush: true);
}

var _unformattedDartContent = 'void main()   {   }\n';
var _formattedDartContent = 'void main() {}\n';

var _simplePubspecYamlContent = '''
name: pub_io_package_test
environment:
  sdk: ^3.6.0
''';

void main() {
  group('PubIoPackage', () {
    test('getFilteredDartDirs', () async {
      var outDir = await _preparePackageDir(
        'filtered_dart_dirs',
        pubspecYamlContent: _simplePubspecYamlContent,
      );
      await _writeDartFile(
        join(outDir, 'lib', 'my_lib.dart'),
        _formattedDartContent,
      );
      await _writeDartFile(
        join(outDir, 'test', 'my_test.dart'),
        _formattedDartContent,
      );
      // No dart file, should be ignored
      await File(
        join(outDir, 'doc', 'readme.md'),
      ).create(recursive: true).then((file) => file.writeAsString('doc'));

      var package = PubIoPackage(outDir);
      expect(await package.getFilteredDartDirs(), ['lib', 'test']);
      // Cached (same list instance)
      expect(
        await package.getFilteredDartDirs(),
        same(await package.getFilteredDartDirs()),
      );
    });

    test('checkFormat/format', () async {
      var outDir = await _preparePackageDir(
        'format',
        pubspecYamlContent: _simplePubspecYamlContent,
      );
      var dartFilePath = join(outDir, 'lib', 'my_lib.dart');
      await _writeDartFile(dartFilePath, _unformattedDartContent);

      var package = PubIoPackage(outDir);
      await package.format();
      expect(await File(dartFilePath).readAsString(), _formattedDartContent);

      // Now it is formatted
      await package.checkFormat();

      // Break the format again, check should fail
      await _writeDartFile(dartFilePath, _unformattedDartContent);
      await expectLater(package.checkFormat(), throwsA(anything));
    });

    test('format no dart dir', () async {
      var outDir = await _preparePackageDir(
        'format_no_dart_dir',
        pubspecYamlContent: _simplePubspecYamlContent,
      );
      // Top level dart file only, no dart dir
      await _writeDartFile(
        join(outDir, 'top_level.dart'),
        _unformattedDartContent,
      );

      var package = PubIoPackage(outDir);
      expect(await package.getFilteredDartDirs(), isEmpty);
      // Should format the current dir instead of hanging
      await package.format();
      expect(
        await File(join(outDir, 'top_level.dart')).readAsString(),
        _formattedDartContent,
      );
      await package.checkFormat();
    });

    test('format workspace root is a no-op', () async {
      var outDir = await _preparePackageDir(
        'format_workspace',
        pubspecYamlContent: '''
name: pub_io_package_test_workspace
environment:
  sdk: ^3.6.0
workspace:
  - sub
''',
      );
      var subDir = join(outDir, 'sub');
      await File(join(subDir, 'pubspec.yaml'))
          .create(recursive: true)
          .then(
            (file) => file.writeAsString('''
name: pub_io_package_test_workspace_sub
environment:
  sdk: ^3.6.0
resolution: workspace
''', flush: true),
          );
      var dartFilePath = join(subDir, 'lib', 'my_lib.dart');
      await _writeDartFile(dartFilePath, _unformattedDartContent);

      var package = PubIoPackage(outDir);
      await package.ready;
      expect(package.isWorkspace, isTrue);
      // Nothing formatted, nothing thrown
      await package.format();
      await package.checkFormat();
      expect(await File(dartFilePath).readAsString(), _unformattedDartContent);

      // But the sub package is handled
      var subPackage = PubIoPackage(subDir);
      await subPackage.ready;
      expect(subPackage.isWorkspace, isFalse);
      expect(subPackage.hasWorkspaceResolution, isTrue);
      await subPackage.format();
      expect(await File(dartFilePath).readAsString(), _formattedDartContent);
      await subPackage.checkFormat();
    });
  });
}
