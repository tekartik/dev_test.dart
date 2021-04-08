import 'package:dev_test/package.dart';

Future main() async {
  await packageRunCi('.', options: PackageRunCiOptions(noOverride: true));
}
