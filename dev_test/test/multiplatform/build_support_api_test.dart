// ignore_for_file: unnecessary_statements

library dev_test.test.build_support_api_test;

import 'package:dev_test/build_support.dart';
//import 'package:dev_test/src/mixin/package_io.dart';
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
