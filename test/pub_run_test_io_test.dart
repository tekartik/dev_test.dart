@TestOn("vm")
library tekartik_dev_test.descriptions_test;

import 'package:dev_test/test.dart';
import 'package:dev_test/src/meta.dart';
import 'package:tekartik_io_tools/pub_utils.dart';
import 'package:tekartik_io_tools/process_utils.dart';
import 'dart:mirrors';

class _TestUtils {
  static final String scriptPath =
      (reflectClass(_TestUtils).owner as LibraryMirror).uri.toFilePath();
}

String get testScriptPath => _TestUtils.scriptPath;
String get pubPackageRoot => getPubPackageRootSync(testScriptPath);
void main() {
  group('pub_run_test_io', () {
    test('runTest', () async {
      PubPackage pkg = new PubPackage(pubPackageRoot);
      // run the 2 tests
      // - various_case_test.dart
      // - various_regular_case_test.dart
      // output should be the same
      RunResult runResultDevTest = await pkg.runTest(
          ['test/case/various_case_test.dart'],
          platforms: ["vm"],
          reporter: TestReporter.EXPANDED,
          concurrency: 1);

      expect(runResultDevTest.exitCode, 0);
      RunResult runResultRegularTest = await pkg.runTest(
          ['test/case/various_regular_case_test.dart'],
          platforms: ["vm"],
          reporter: TestReporter.EXPANDED,
          concurrency: 1);

      expect(runResultRegularTest.exitCode, 0);

      // Actually order differs
      // but it must both run exactly 9 test (look for +9) and not 10
      expect(runResultDevTest.out, contains("+9"));
      expect(runResultDevTest.out, isNot(contains("+10")));
      expect(runResultRegularTest.out, contains("+9"));
      expect(runResultRegularTest.out, isNot(contains("+10")));
    });
  });
}
