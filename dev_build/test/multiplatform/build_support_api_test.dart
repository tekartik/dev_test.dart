// ignore_for_file: unnecessary_statements

library;

import 'package:dev_build/build_support.dart';
//import 'package:dev_build/src/mixin/package_io.dart';
import 'package:test/test.dart';

void main() {
  group('build_support', () {
    test('api', () async {
      pathGetPubspecYamlMap;

      pubspecYamlHasAnyDependencies;
      pubspecYamlSupportsFlutter;
      pubspecYamlSupportsWeb;
      pubspecYamlSupportsNode;

      pathPubspecAddDependency;
      pathPubspecRemoveDependency;
      pubspecYamlGetSdkBoundaries;
      VersionBoundaries;
      pathGetPackageConfigMap;
      pathPackageConfigMapGetPackagePath;
    });
  });
}
