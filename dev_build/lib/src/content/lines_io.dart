import 'package:process_run/stdio.dart';

import 'lines.dart';

/// Io implementation of [YamlLinesContent] with proper line feeds on windows.
final yamlSeparatorIo = Platform.isWindows ? '\r\n' : '\n';

/// Io implementation of [YamlLinesContent] with proper line feeds on windows.
abstract class YamlLinesContentIo implements YamlLinesContent {
  /// Contructor.
  factory YamlLinesContentIo(String path) => _YamlLinesContentIo(path);

  /// Read the file.
  Future<bool> read();

  /// Write the file content.
  Future<void> write();
}

class _YamlLinesContentIo
    with YamlLinesContentMixin
    implements YamlLinesContentIo {
  /// File.
  late File file;

  /// Create a YamlLinesContentIo from a path.
  _YamlLinesContentIo(String path) {
    file = File(path);
  }

  @override
  String get separator => yamlSeparatorIo;

  /// Read the file.
  @override
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

  /// Write the file content.
  @override
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
