@TestOn("vm")
library tekartik_dev_test.descriptions_test;

import 'package:dev_test/test.dart';
import 'package:tekartik_pub/pub_fs_io.dart';
import 'package:process_run/cmd_run.dart';
import 'dart:mirrors';
import 'package:fs_shim/fs_io.dart';
import 'dart:async';

class _TestUtils {
  static final String scriptPath =
      (reflectClass(_TestUtils).owner as LibraryMirror).uri.toFilePath();
}

String get testScriptPath => _TestUtils.scriptPath;
Future<Directory> get pubPackageDir =>
    getPubPackageDir(new Directory(testScriptPath));

checkCaseTest(String name, int count, {String testNameFilter}) async {
  IoFsPubPackage pkg = new IoFsPubPackage(await pubPackageDir);
  ProcessResult runResult = await runCmd(pkg.pubCmd(pubRunTestArgs(
      args: ['test/case/${name}'],
      platforms: ["vm"],
      //reporter: pubRunTestReporterJson,
      reporter: pubRunTestReporterJson,
      concurrency: 1,
      color: false,
      name: testNameFilter))
    ..connectStderr = false
    ..connectStdout = false);

  expect(runResult.exitCode, 0);

  // but it must both run exactly 'count' test (look for +'count') and not 'count + 1'
  expect(pubRunTestJsonSuccessCount(runResult.stdout), count);
}

void main() {
  group('pub_run_test_io', () {
    test('cases', () async {
      await checkCaseTest('one_solo_test_case_test.dart', 1);
      await checkCaseTest('one_skipped_test_case_test.dart', 1);
      await checkCaseTest('one_solo_test_in_group_case_test.dart', 1);
    });
    test('various', () async {
      await checkCaseTest('various_case_test.dart', 4);
      await checkCaseTest('various_regular_case_test.dart', 5);
    });
    test('filter', () async {
      await checkCaseTest('various_case_test.dart', 3, testNameFilter: 'test');
      await checkCaseTest('various_regular_case_test.dart', 4,
          testNameFilter: 'test');
    });
  });
}
