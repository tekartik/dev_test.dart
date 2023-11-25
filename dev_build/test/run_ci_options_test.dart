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
  });
}
