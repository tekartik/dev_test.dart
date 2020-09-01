@TestOn('vm')
import 'package:dev_test/src/package_impl.dart';
import 'package:dev_test/test.dart';

void main() {
  group('package', () {
    test('pubspec', () async {
      var pubspecMap = await getPubspecYamlMap('.');
      expect(
          pubspecYamlHasAnyDependencies(pubspecMap, ['build_node_compilers']),
          isFalse);
      expect(pubspecYamlHasAnyDependencies(pubspecMap, ['build_web_compilers']),
          isTrue);
      expect(pubspecYamlHasAnyDependencies(pubspecMap, ['pedantic']), isTrue);
    });
  });
}
