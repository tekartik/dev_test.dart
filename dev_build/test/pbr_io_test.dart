@TestOn('vm')
library;

import 'dart:async';

import 'package:process_run/cmd_run.dart';
import 'package:test/test.dart';

import 'test_utils.dart';

Future checkCaseTest(String name, int count, {String? testNameFilter}) async {
  // PubPackage pkg = PubPackage('.');
  // $ pub run build_runner test -- -r json -j 1 --no-color -p vm test/multiplatform/case/one_solo_test_case_test.dart

  final runResult = await runExecutableArguments('dart', [
    'pub',
    'run',
    'build_runner',
    'test',
    '--',
    '-r',
    'json',
    '-j',
    '1',
    '--no-color',
    '-p',
    'vm',
    if (testNameFilter != null) ...['-n', testNameFilter],
    caseNamePath(name),
  ]);

  expect(runResult.exitCode, 0);

  // but it must both run exactly 'count' test (look for +'count') and not 'count + 1'
  expect(
    pubRunTestJsonSuccessCount(runResult.stdout as String),
    count,
    reason: '$name $testNameFilter',
  );
}

var longTimeout = const Timeout(Duration(minutes: 4));

void main() {
  group('pub_run_io_test', () {
    test('cases', () async {
      await checkCaseTest('one_solo_test_case_test.dart', 1); // report included
      await checkCaseTest(
        'one_skipped_test_case_test.dart',
        1,
      ); // report included
      await checkCaseTest(
        'one_solo_test_in_group_case_test.dart',
        1,
      ); // report included
    }, timeout: longTimeout);
    test('various', () async {
      await checkCaseTest('various_case_test.dart', 4);
      await checkCaseTest('various_regular_case_test.dart', 5);
    }, timeout: longTimeout);
    test('filter', () async {
      await checkCaseTest('various_case_test.dart', 3, testNameFilter: 'test');
      await checkCaseTest(
        'various_regular_case_test.dart',
        4,
        testNameFilter: 'test',
      );
    }, timeout: longTimeout);
  }, skip: 'Temp null safety disabled');
}
