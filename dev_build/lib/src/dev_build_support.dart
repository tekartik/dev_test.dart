import 'package:dev_build/package.dart';

/// Get dev_build pub global update
Future<void> checkOrPubActivateDevBuild({
  bool? verbose,
  VersionBoundaries? versionBoundaries,
}) async {
  await checkOrPubActivateHostedPackage(
    'dev_build',
    verbose: verbose,
    versionBoundaries: versionBoundaries,
  );
}
