import 'package:dev_build/package.dart';
import 'package:path/path.dart';

Future main() async {
  await packageRunCi(join('..'), options: PackageRunCiOptions(recursive: true));
}
