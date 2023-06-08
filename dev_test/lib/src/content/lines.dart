import 'dart:convert';

import 'package:yaml/yaml.dart';

import 'characters.dart';

/// YamlLinesContent
abstract class YamlLinesContent {
  /// Split lines.
  static List<String> splitLines(String content) {
    return LineSplitter.split(content).toList();
  }

  factory YamlLinesContent.withText(String content) {
    return _YamlLinesContent.withText(content);
  }
  factory YamlLinesContent.withLines(List<String> lines) {
    return _YamlLinesContent.withLines(lines);
  }

  // Separator default to \n but on io it is \r\n
  String get separator;
  List<String> get lines;
  Map<String, Object?> get yaml;
}

mixin YamlLinesContentMixin implements YamlLinesContent {
  @override
  late List<String> lines;
  @override
  late Map<String, Object?> yaml;

  void reloadYaml() {
    yaml = (loadYaml(lines.join(separator)) as Map).cast<String, Object?>();
  }
}

class _YamlLinesContent with YamlLinesContentMixin {
  _YamlLinesContent.withText(String content) {
    lines = YamlLinesContent.splitLines(content.trim());
    var yaml = loadYaml(content);
    if (yaml is Map) {
      this.yaml = yaml.cast<String, Object?>();
    } else {
      this.yaml = <String, Object?>{};
    }
  }
  _YamlLinesContent.withLines(List<String> lines) {
    lines = lines;
  }

  @override
  String get separator => '\n';
}

extension YamlLinesContentExtension on YamlLinesContent {
  YamlLinesContentMixin get _mixin => this as YamlLinesContentMixin;

  /// Returns true if modified.
  bool _setOrAppendKey(String key, String value) {
    var index = indexOfTopLevelKey(key);
    if (index >= 0) {
      var newLine = '$key: $value';
      var existingLine = lines[index];
      if (existingLine != newLine) {
        lines[index] = newLine;
        return true;
      } else {
        return false;
      }
    } else {
      lines.add('$key: $value');
      return true;
    }
  }

  bool setOrAppendKey(String key, String value) {
    if (_setOrAppendKey(key, value)) {
      _mixin.reloadYaml();
      return true;
    } else {
      return false;
    }
  }

  /// -1 if not found
  int indexOfTopLevelKey(String key) {
    for (var i = 0; i < lines.length; i++) {
      var line = lines[i];
      // Assume a proper format
      if (line.startsWith(key) &&
          line.substring(key.length).trim().startsWith(':')) {
        return i;
      }
    }

    return -1;
  }

  String toContent() {
    var content = '${lines.join(separator)}$separator';
    return content;
  }

  static bool isTopLevelKey(String line) {
    if (startsWithWhitespace(line)) {
      return false;
    }
    if (line.startsWith('#')) {
      return false;
    }
    return true;
  }
}
