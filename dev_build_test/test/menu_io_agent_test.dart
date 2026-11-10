/// A console menu run with `--agent`, driven over its VM service.
@TestOn('vm')
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io' show Process, Platform;

import 'package:dev_build/menu/menu_agent.dart';
import 'package:path/path.dart';
import 'package:process_run/shell.dart';
import 'package:tekartik_dev_build_test/vm_service_json_rpc.dart';
import 'package:test/test.dart';

const _agentPrefix = 'agent: VM service ';

void main() {
  test('--agent: menu driven over the VM service, stdin closed', () async {
    final script = join('test', 'data', 'menu_console_agent.dart');
    // A background run: no input, its end at once.
    final stdout = ShellLinesController();
    final stderr = ShellLinesController();
    final shell = Shell(
      stdin: const Stream<List<int>>.empty(),
      stdout: stdout.sink,
      stderr: stderr.sink,
      verbose: false,
      throwOnError: false,
    );
    final agentLine = Completer<String>();
    final out = <String>[];
    stdout.stream.listen((line) {
      out.add(line);
      if (line.startsWith(_agentPrefix) && !agentLine.isCompleted) {
        agentLine.complete(line);
      }
    });
    final err = StringBuffer();
    stderr.stream.listen(err.writeln);
    final started = Completer<Process>();
    final done = shell.runExecutableArguments(Platform.resolvedExecutable, [
      'run',
      script,
      '--agent',
    ], onProcess: started.complete);
    final process = await started.future;
    VmServiceJsonRpc? service;
    try {
      final line = await agentLine.future.timeout(
        const Duration(seconds: 90),
        onTimeout: () => throw StateError('no agent line: $out $err'),
      );
      service = await VmServiceJsonRpc.connect(
        Uri.parse(line.substring(_agentPrefix.length)),
      );
      final isolateId = await service.findIsolateWithExtension(
        menuAgentVmRunExtension,
      );
      expect(isolateId, isNotNull);

      final commands = await service.call(menuAgentVmCommandsExtension, {
        'isolateId': isolateId,
      });
      expect((commands['commands'] as List).map((c) => (c as Map)['name']), [
        'menu',
        'menu_line',
      ]);

      Future<Map<String, Object?>> run(
        String name,
        Map<String, Object?> args,
      ) async {
        final response = await service!.call(menuAgentVmRunExtension, {
          'isolateId': isolateId,
          'name': name,
          'args': jsonEncode(args),
        });
        expect(response['ok'], isTrue, reason: '$response');
        return (response['result'] as Map).cast<String, Object?>();
      }

      var state = await run('menu', {});
      expect((state['items'] as List).length, 3);
      state = await run('menu_line', {'line': '0'});
      expect(state['output'], ['hi']);
      state = await run('menu_line', {'line': '1'});
      expect(state['status'], 'input');
      expect(state['prompt'], 'Name?');
      state = await run('menu_line', {'line': 'Alex'});
      expect(state['output'], ['ANSWER Alex', 'got Alex']);
      expect(state['status'], 'ready');
      state = await run('menu_line', {'line': '2'});
      expect(state['path'], ['sub']);
      state = await run('menu_line', {'line': '0'});
      expect(state['output'], ['in sub']);
      state = await run('menu_line', {'line': '-'});
      expect(state['path'], isEmpty);

      // The console still writes on stdout, the agent lines echoed as if
      // typed.
      for (var i = 0; i < 100 && !out.contains('in sub'); i++) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }
      expect(out, containsAll(['_root_ > 0', 'hi', 'Name? > Alex', 'in sub']));
    } finally {
      await service?.close();
      process.kill();
      await process.exitCode;
      await done;
      stdout.close();
      stderr.close();
    }
  }, timeout: const Timeout(Duration(minutes: 3)));
}
