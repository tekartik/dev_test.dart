// ignore_for_file: unnecessary_statements

library dev_build.test.build_support_api_test;

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

      pubspecYamlGetSdkBoundaries;
      VersionBoundaries;
      pathGetPackageConfigMap;
      pathPackageConfigMapGetPackagePath;
    });
  });
}
