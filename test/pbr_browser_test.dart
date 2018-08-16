@TestOn("vm")
library tekartik_dev_test.pub_run_test_browser_test;

import 'package:dev_test/test.dart';
import 'package:tekartik_pub/io.dart';
import 'package:process_run/cmd_run.dart';
import 'package:fs_shim/fs_io.dart';

checkCaseTest(String name, int count, {String testNameFilter}) async {
  PubPackage pkg = new PubPackage('.');
  ProcessResult runResult = await runCmd(pkg.pubCmd([
    'run',
    'build_runner',
    'test',
    '--'
  ]..addAll(pubRunTestRunnerArgs(new TestRunnerArgs(
      args: ['test/case/${name}'],
      platforms: ["chrome"],
      //reporter: pubRunTestReporterJson,
      reporter: RunTestReporter.JSON,
      concurrency: 1,
      color: false,
      name: testNameFilter)))));

  expect(runResult.exitCode, 0, reason: runResult.stdout?.toString());

  // but it must both run exactly 'count' test (look for +'count') and not 'count + 1'
  expect(pubRunTestJsonSuccessCount(runResult.stdout as String), count,
      reason: "$name $testNameFilter");
}

var longTimeout = new Timeout(new Duration(minutes: 4));

void main() {
  group('pub_run_browser_test', () {
    test('cases', () async {
      await checkCaseTest('one_solo_test_case_test.dart', 1); // report included
      await checkCaseTest(
          'one_skipped_test_case_test.dart', 2); // report included
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
  });
}
