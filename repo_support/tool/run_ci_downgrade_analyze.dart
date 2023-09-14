import 'package:dev_test/package.dart';

Future main() async {
  await packageRunCi('..',
      options: PackageRunCiOptions(
          pubDowngradeOnly: true, analyzeOnly: true, recursive: true));
}
