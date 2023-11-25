import 'dart:io';

import 'lines.dart';

final yamlSeparatorIo = Platform.isWindows ? '\r\n' : '\n';

/// Io implementation of [YamlLinesContent] with proper line feeds on windows.
class YamlLinesContentIo with YamlLinesContentMixin {
  late File file;

  YamlLinesContentIo(String path) {
    file = File(path);
  }

  @override
  String get separator => yamlSeparatorIo;
  Future<bool> read() async {
    try {
      lines = YamlLinesContent.splitLines(await file.readAsString());
      reloadYaml();
      return true;
    } catch (e) {
      stderr.writeln('Error $e reading $file');
      return false;
    }
  }

  Future<void> _write(String content) async {
    await file.writeAsString(content, flush: true);
  }

  Future<void> write() async {
    var content = toContent();
    try {
      await _write(content);
    } catch (_) {
      if (!file.parent.existsSync()) {
        await file.parent.create(recursive: true);
        await _write(content);
      }
    }
  }
}
