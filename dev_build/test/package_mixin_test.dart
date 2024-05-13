@TestOn('vm')
library;

import 'package:dev_build/src/mixin/package.dart';
import 'package:test/test.dart';

void main() {
  group('package', () {
    test('pubspec', () async {
      // ignore: unnecessary_statements
      pubspecYamlHasAnyDependencies;
      // ignore: unnecessary_statements
      pubspecYamlHasAnyDependencies;
      // ignore: unnecessary_statements
      pubspecYamlSupportsFlutter;
      // ignore: unnecessary_statements
      pubspecYamlSupportsNode;
      // ignore: unnecessary_statements
      pubspecYamlSupportsWeb;
      // ignore: unnecessary_statements
      pubspecYamlGetVersion;
      // ignore: unnecessary_statements
      pubspecYamlSupportsTest;
      // ignore: unnecessary_statements
      analysisOptionsSupportsNnbdExperiment;
      // ignore: unnecessary_statements
      pathGetAnalysisOptionsYamlMap;
      // ignore: unnecessary_statements
      pathGetPubspecYamlMap;
      // ignore: unnecessary_statements
      packageConfigGetPackages;
    });
  });
}
