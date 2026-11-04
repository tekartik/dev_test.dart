import 'package:dev_build/package.dart';
import 'package:test/test.dart';

void main() {
  group('run_ci_options', () {
    test('root_no_package', () async {
      var options = PackageRunCiOptions();
      expect(options.noPubGetOrUpgrade, isFalse);
      options = PackageRunCiOptions(noPubGet: true);
      expect(options.noPubGetOrUpgrade, isTrue);
      options = PackageRunCiOptions(noPubGet: true, pubGetOnly: true);
      expect(options.noPubGetOrUpgrade, isFalse);
      options = PackageRunCiOptions(noPubGet: true, pubUpgradeOnly: true);
      expect(options.noPubGetOrUpgrade, isFalse);
    });
    test('noCleanup', () async {
      expect(PackageRunCiOptions().noCleanup, isFalse);
      expect(PackageRunCiOptions(noCleanup: true).clone().noCleanup, isTrue);
    });
    test('web build', () async {
      // Web build only: the build step only.
      var options = PackageRunCiOptions(webBuildOnly: true).clone();
      expect(options.webBuildOnly, isTrue);
      expect(options.noBuild, isFalse);
      expect(options.noTest, isTrue);
      expect(options.noAnalyze, isTrue);
      expect(options.noFormat, isTrue);
      options = PackageRunCiOptions(buildOnly: true, noWebBuild: true).clone();
      expect(options.noWebBuild, isTrue);
      expect(options.noBuild, isFalse);
    });
  });
}
