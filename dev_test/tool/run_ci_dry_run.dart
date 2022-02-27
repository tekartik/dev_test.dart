import 'package:dev_test/package.dart';

Future main() async {
  await packageRunCi('.',
      options: PackageRunCiOptions(dryRun: true, noOverride: true));
}
