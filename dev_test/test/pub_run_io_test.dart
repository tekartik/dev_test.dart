@TestOn('vm')
library tekartik_dev_test.descriptions_test;

import 'dart:async';

import 'package:dev_test/test.dart';
import 'package:process_run/cmd_run.dart';

import 'test_utils.dart';

Future checkCaseTest(String name, int count,
    {String? testNameFilter, int expectedExitCode = 0}) async {
  // pub run test -r json -j 1 --no-color -p vm test/multiplatform/case/one_solo_test_in_group_case_test.dart

  var cmd = PubCmd([
    'run',
    'test',
    '-r',
    'json',
    '-j',
    '1',
    '--no-color',
    '-p',
    'vm',
    if (testNameFilter != null) ...['-n', testNameFilter],
    caseNamePath(name)
  ]);
  final runResult = await runCmd(cmd);
  // print('exitCode: ${runResult.exitCode}');
  // devPrint(cmd);
  // devPrint('stdout: ${runResult.stdout}');
  expect(runResult.exitCode, expectedExitCode);

  // but it must both run exactly 'count' test (look for +'count') and not 'count + 1'
  expect(pubRunTestJsonSuccessCount(runResult.stdout as String), count,
      reason: '$name $testNameFilter');
}

var longTimeout = const Timeout(Duration(minutes: 4));

void main() {
  group('pub_run_io_test', () {
    test('cases', () async {
      await checkCaseTest('one_solo_test_case_test.dart', 1); // report included
      await checkCaseTest(
          'one_skipped_test_case_test.dart', 1); // report included
      await checkCaseTest(
          'one_solo_test_in_group_case_test.dart', 1); // report included
    }, timeout: longTimeout);
    test('various', () async {
      await checkCaseTest('various_case_test.dart', 4);
      await checkCaseTest('various_regular_case_test.dart', 5);
    }, timeout: longTimeout);
    test('filter', () async {
      await checkCaseTest('various_case_test.dart', 3, testNameFilter: 'test');
      await checkCaseTest('various_regular_case_test.dart', 4,
          testNameFilter: 'test');
    }, timeout: longTimeout);
    /*
    test('failure', () async {
      var newFile = File('test/case/simple_failure_test.dart');
      try {
        await newFile.delete();
      } catch (_) {}
      await File('test/case/simple_failure_test_.dart').copy(newFile.path);
      await checkCaseTest('simple_failure_test.dart', 0, expectedExitCode: 1);
    }, timeout: longTimeout);
    */
    test('failure', () async {
      await checkCaseTest('simple_failure_test_.dart', 0, expectedExitCode: 1);
    }, timeout: longTimeout);
  });
}
