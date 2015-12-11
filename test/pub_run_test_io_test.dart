@TestOn("vm")
library tekartik_dev_test.descriptions_test;

import 'package:dev_test/test.dart';
import 'package:tekartik_pub/pub.dart';
import 'package:process_run/cmd_run.dart';
import 'dart:mirrors';
import 'dart:io';

class _TestUtils {
  static final String scriptPath =
      (reflectClass(_TestUtils).owner as LibraryMirror).uri.toFilePath();
}

String get testScriptPath => _TestUtils.scriptPath;
String get pubPackageRoot => getPubPackageRootSync(testScriptPath);

checkCaseTest(String name, int count) async {
  PubPackage pkg = new PubPackage(pubPackageRoot);
  ProcessResult runResult = await runCmd(pkg.testCmd(['test/case/${name}'],
      platforms: ["vm"],
      reporter: TestReporter.EXPANDED,
      concurrency: 1,
      color: false)
    ..connectStderr = false
    ..connectStdout = false);

  expect(runResult.exitCode, 0);

  // but it must both run exactly 'count' test (look for +'count') and not 'count + 1'
  expect(runResult.stdout, contains("+${count}:"));
  expect(runResult.stdout, isNot(contains("+${count + 1}:")));
}

void main() {
  group('pub_run_test_io', () {
    test('cases', () async {
      await checkCaseTest('one_solo_test_case_test.dart', 1);
      await checkCaseTest('one_skipped_test_case_test.dart', 1);
      await checkCaseTest('one_solo_test_in_group_case_test.dart', 1);
    });
    test('various', () async {
      await checkCaseTest('various_case_test.dart', 6);
      await checkCaseTest('various_regular_case_test.dart', 8);
    });
  });
}
