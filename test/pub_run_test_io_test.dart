@TestOn("vm")
library tekartik_dev_test.descriptions_test;

import 'package:dev_test/test.dart';
import 'package:tekartik_io_tools/pub_utils.dart';
import 'package:tekartik_io_tools/process_utils.dart';
import 'dart:mirrors';

class _TestUtils {
  static final String scriptPath =
      (reflectClass(_TestUtils).owner as LibraryMirror).uri.toFilePath();
}

String get testScriptPath => _TestUtils.scriptPath;
String get pubPackageRoot => getPubPackageRootSync(testScriptPath);

checkCaseTest(String name, int count) async {
  PubPackage pkg = new PubPackage(pubPackageRoot);
  RunResult runResult = await pkg.runTest(['test/case/${name}'],
      platforms: ["vm"],
      reporter: TestReporter.EXPANDED,
      concurrency: 1,
      color: false,
      connectIo: false);

  expect(runResult.exitCode, 0);

  // but it must both run exactly 'count' test (look for +'count') and not 'count + 1'
  expect(runResult.out, contains("+${count}:"));
  expect(runResult.out, isNot(contains("+${count + 1}:")));
}

void main() {
  group('pub_run_test_io', () {
    test('cases', () {
      checkCaseTest('one_solo_test_case_test.dart', 1);
      checkCaseTest('one_skipped_test_case_test.dart', 1);
      checkCaseTest('one_solo_test_in_group_case_test.dart', 1);
    });
    test('various', () async {
      checkCaseTest('various_case_test.dart', 8);
      checkCaseTest('various_regular_case_test.dart', 8);
    });
  });
}
