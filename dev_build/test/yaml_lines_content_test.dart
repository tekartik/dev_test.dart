import 'package:dev_build/src/content/lines.dart';
import 'package:test/test.dart';

void main() {
  group('yaml lines content', () {
    test('read', () {
      var test = '''
# test
key: value
''';

      var lines = YamlLinesContent.withText(test);
      expect(lines.getValueAt(['key']), 'value');
    });
  });
}
