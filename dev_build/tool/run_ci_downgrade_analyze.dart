import 'package:dev_build/package.dart';

Future main() async {
  await packageRunCi(
    '.',
    options: PackageRunCiOptions(pubDowngradeOnly: true, analyzeOnly: true),
  );
}
