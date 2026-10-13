@TestOn('vm')
library;

import 'dart:io';

import 'package:path/path.dart';
import 'package:test/test.dart';

void main() {
  group('menu_io_console', () {
    var script = join(
      'test',
      'menu',
      'data',
      'menu_console_command_error.dart',
    );

    Future<ProcessResult> runMenu(List<String> arguments) =>
        Process.run(Platform.resolvedExecutable, ['run', script, ...arguments]);

    test('command error reported, menu keeps running', () async {
      var result = await runMenu(['boom', '0', '.']);
      expect(result.exitCode, 0);
      expect(
        result.stderr as String,
        contains('error: Bad state: command failed boom'),
      );
      // The next command still ran
      expect(result.stdout as String, contains('item ran'));
    });

    test('help hint exits with the exit command', () async {
      var result = await runMenu(['-h']);
      expect(result.exitCode, 0);
      var hint = (result.stdout as String)
          .split('\n')
          .map((line) => line.trim())
          .firstWhere((line) => line.startsWith('dart test_menu.dart'));
      expect(hint, 'dart test_menu.dart 0 .');
      // The hint works
      result = await runMenu(hint.split(' ').sublist(2));
      expect(result.exitCode, 0);
      expect(result.stdout as String, contains('item ran'));
      expect(result.stdout as String, isNot(contains('errorValue')));
    });
  });
}
