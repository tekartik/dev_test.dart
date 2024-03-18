import 'dart:convert';

import 'package:yaml/yaml.dart';

import 'characters.dart';

const _backtick = 0x60;

/// Unescape a table or column name.
String unescapeKeyName(String name) {
  final codeUnits = name.codeUnits;
  if (_areCodeUnitsEscaped(codeUnits)) {
    return name.substring(1, name.length - 1);
  }
  return name;
}

/// escape with back tick
String escapeKeyName(String name) {
  return '`$name`';
}

/// is already escaped (backtick)
bool isKeyNameEscaped(String name) {
  final codeUnits = name.codeUnits;
  return _areCodeUnitsEscaped(codeUnits);
}

/// True if already escaped
bool _areCodeUnitsEscaped(List<int> codeUnits) {
  if (codeUnits.isNotEmpty) {
    final first = codeUnits.first;
    switch (first) {
      case _backtick:
        final last = codeUnits.last;
        return last == first;
    }
  }
  return false;
}

/// YamlLinesContent
abstract class YamlLinesContent {
  /// Split lines.
  static List<String> splitLines(String content) {
    return LineSplitter.split(content).toList();
  }

  /// Create a YamlLinesContent from text.
  factory YamlLinesContent.withText(String content) {
    return _YamlLinesContent.withText(content);
  }

  /// Create a YamlLinesContent from lines.
  factory YamlLinesContent.withLines(List<String> lines) {
    return _YamlLinesContent.withLines(lines);
  }

  /// Separator default to \n but on io it is \r\n on windows
  String get separator;

  /// Lines
  List<String> get lines;

  /// Yaml decoded as a map
  Map<String, Object?> get yaml;
}

/// YamlLinesContentMixin.
mixin YamlLinesContentMixin implements YamlLinesContent {
  @override
  late List<String> lines;
  @override
  late Map<String, Object?> yaml;

  /// Reload yaml from lines.
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
    this.lines = lines;
  }

  @override
  String get separator => '\n';
}

/// YamlLinesContentExtension
extension YamlLinesContentExtension on YamlLinesContent {
  YamlLinesContentMixin get _mixin => this as YamlLinesContentMixin;

  /// Returns true if modified.
  bool _setOrAppendKey(String key, String value) {
    String topLovelKey;
    if (isKeyNameEscaped(key)) {
      topLovelKey = unescapeKeyName(key);
    } else {
      var keyPaths = key.split('.');

      if (keyPaths.length > 1) {
        var modified = false;
        var lineIndex = 0;
        for (var depth = 0; depth < keyPaths.length; depth++) {
          var keyPart = keyPaths[depth];
          var last = depth == keyPaths.length - 1;

          String getExpectedLine() {
            return '${_preDepth(depth)}$keyPart:${last ? ' $value' : ''}';
          }

          // Find top level key
          var index = indexOfSubLevelKey(keyPart, depth, lineIndex);
          if (index >= 0) {
            lineIndex = index;
            if (lines[lineIndex] != getExpectedLine()) {
              modified = true;
              lines[lineIndex] = getExpectedLine();
            }
            lineIndex++;
          } else {
            // Add before next upper level key
            var positionIndex = lineIndex;
            while (positionIndex < lines.length) {
              var nextDepth = _getLineDepth(lines[positionIndex]);
              if (nextDepth != null && nextDepth < depth) {
                lineIndex = positionIndex;
                break;
              } else {
                positionIndex++;
              }
            }

            modified = true;
            // Create top level key
            lines.insert(lineIndex, getExpectedLine());
            lineIndex++;
          }
        }
        return modified;
      }
      topLovelKey = keyPaths.first;
    }
    var index = indexOfTopLevelKey(topLovelKey);
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

  /// key can contain dot.separated.keys unless escaped
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

  int? _getLineDepth(String line) {
    var count = 0;
    for (var char in line.codeUnits) {
      if (isWhitespace(char)) {
        count++;
      } else {
        break;
      }
    }
    return count ~/ 2;
  }

  String _preDepth(int depth) {
    var sb = StringBuffer();
    for (var i = 0; i < depth; i++) {
      sb.write('  ');
    }
    return sb.toString();
  }

  /// -1 if not found
  int indexOfSubLevelKey(String key, int depth, int startIndex) {
    for (var i = startIndex; i < lines.length; i++) {
      var line = lines[i];
      // Assume a proper format
      var lineDepth = _getLineDepth(line);
      if (lineDepth != null) {
        if (lineDepth == depth) {
          line = line.trim();
          if (line.startsWith(key) &&
              line.substring(key.length).trim().startsWith(':')) {
            return i;
          }
        } else if (lineDepth < depth) {
          return -1;
        }
      }
    }

    return -1;
  }

  /// returns properly formatted lines.
  String toContent() {
    var content = '${lines.join(separator)}$separator';
    return content;
  }

  /// true if the line is a top level key.
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
