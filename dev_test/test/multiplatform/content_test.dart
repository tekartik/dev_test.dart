library dev_test.test.content_test;

import 'package:dev_test/src/content/lines.dart';
import 'package:dev_test/test.dart';

void main() {
  group('content', () {
    test('pubspec', () async {
      var content = YamlLinesContent.withText('');
      expect(content.toContent(), '\n');
      content = YamlLinesContent.withText('\n');
      expect(content.toContent(), '\n');
      content = YamlLinesContent.withText('a');
      expect(content.toContent(), 'a\n');
      content = YamlLinesContent.withText('a\n');
      expect(content.toContent(), 'a\n');
      content = YamlLinesContent.withText('a\nb');
      expect(content.toContent(), 'a\nb\n');
      content = YamlLinesContent.withText('a\nb\n');
      expect(content.toContent(), 'a\nb\n');
      content = YamlLinesContent.withText('\nb\n');
      expect(content.toContent(), 'b\n');
    });
    test('setOrAppendKey', () async {
      var content = YamlLinesContent.withText('');
      expect(content.setOrAppendKey('v', '1'), isTrue);
      expect(content.toContent(), 'v: 1\n');
      expect(content.setOrAppendKey('v', '1'), isFalse);
      expect(content.toContent(), 'v: 1\n');
      content = YamlLinesContent.withText('v: 2');
      expect((content..setOrAppendKey('v', '1')).toContent(), 'v: 1\n');
      content = YamlLinesContent.withText('v: " 2"');
      expect(content.setOrAppendKey('v', '1'), isTrue);

      expect(content.toContent(), 'v: 1\n');
      content = YamlLinesContent.withText('a: 1');
      expect((content..setOrAppendKey('v', '1')).toContent(), 'a: 1\nv: 1\n');
      content = YamlLinesContent.withText('a: 1\nv: 2\nb: 3');
      expect((content..setOrAppendKey('v', '1')).toContent(),
          'a: 1\nv: 1\nb: 3\n');
    });
    test('dot.support', () async {
      var content = YamlLinesContent.withText('');
      expect(content.setOrAppendKey('a.b', '1'), isTrue);
      expect(content.toContent(), 'a:\n  b: 1\n');
      expect(content.setOrAppendKey('a.b', '1'), isFalse);
      expect(content.setOrAppendKey('a.b', '2'), isTrue);
      expect(content.toContent(), 'a:\n  b: 2\n');
      expect(content.setOrAppendKey('c', '3'), isTrue);
      expect(content.toContent(), 'a:\n  b: 2\nc: 3\n');
      expect(content.setOrAppendKey('a.d', '4'), isTrue);
      expect(content.setOrAppendKey('c', '5'), isTrue);
      expect(content.toContent(), 'a:\n  b: 2\n  d: 4\nc: 5\n');
      expect(content.setOrAppendKey('a.b.d.e.f', '6'), isTrue);
      expect(
          content.toContent(),
          'a:\n'
          '  b:\n'
          '    d:\n'
          '      e:\n'
          '        f: 6\n'
          '  d: 4\n'
          'c: 5\n');
    });
  });
}
