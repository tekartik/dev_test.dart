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
  @Deprecated('Do no use directly')
  String get separator;

  /// Lines
  List<String> get lines;

  @Deprecated('Do no use directly')

  /// Yaml decoded as a map
  Map<String, Object?> get yaml;

  /// Get a value at a path (string keys for map, int value for list)
  /// ['key1', 'key2', index3, 'key4]
  T? getValueAt<T extends Object?>(List<Object> paths);

  /// Set a value at a path (string keys for map, int value for list)
  void setValueAt(List<Object> paths, Object? value) {}
}

extension on List {
  /// ['key1', 'key2', index3, 'key4]
  T? getValueAt<T extends Object?>(List<Object> paths) {
    Object? rawValue;
    var path = paths.first;
    if (path is int && length > path) {
      rawValue = this[path];
      return _rawGetValueAt(rawValue, paths.sublist(1));
    }

    return null;
  }
}

/// Convenient extension on Model
extension on Map {
  /// ['key1', 'key2', index3, 'key4]
  T? getValueAt<T extends Object?>(List<Object> paths) {
    Object? rawValue;
    var path = paths.first;
    for (var entry in entries) {
      if (entry.key == path) {
        rawValue = entry.value;
        return _rawGetValueAt(rawValue, paths.sublist(1));
      }
    }
    return null;
  }
}

/// Get raw value helper for map and list.
T? _rawGetValueAt<T extends Object?>(Object? rawValue, List<Object> paths) {
  if (paths.isEmpty) {
    if (rawValue is T) {
      return rawValue;
    }
    return null;
  } else if (rawValue is Map) {
    return rawValue.getValueAt<T>(paths);
  } else if (rawValue is List) {
    return rawValue.getValueAt<T>(paths);
  }
  return null;
}

/// YamlLinesContentMixin.
mixin YamlLinesContentMixin implements YamlLinesContent {
  @override
  late List<String> lines;

  @Deprecated('Do no use directly')
  @override
  Map<String, Object?> get yaml {
    if (_yamlAny is Map) {
      return _yamlAny as Map<String, Object?>;
    }
    return <String, Object?>{};
  }

  /// Reload yaml from lines.
  void reloadYaml() {
    _yamlAny = loadYaml(lines.join(_separator));
  }

  // ignore: deprecated_member_use_from_same_package
  String get _separator => separator;

  Object? _yamlAny;

  /// ['key1', 'key2', index3, 'key4]
  @override
  T? getValueAt<T extends Object?>(List<Object> paths) {
    return _rawGetValueAt(_yamlAny, paths);
  }

  @override
  void setValueAt(List<Object> paths, Object? value) {
    throw UnimplementedError();
  }

  /// -1 if not found
  int indexOfPathPart(int spaceCount, Object part) {
    var spaces = ' ' * spaceCount;

    for (var i = 0; i < lines.length; i++) {
      var line = lines[i];
      if (line.startsWith(spaces)) {
        // Try here
        line = line.trim();
        if (part is String) {
          // Assume a proper format
          if (line.startsWith(part) &&
              line.substring(part.length).trim().startsWith(':')) {
            return i;
          }
        } else if (part is int) {
          var listIndex = -1;
          if (line.startsWith('-')) {
            if (++listIndex == part) {
              return i;
            }
          }
        } else {
          throw ArgumentError('path part "$part" should be a string or an int');
        }
      } else {
        if (line.trim().startsWith('#')) {
          // ignore
          continue;
        } else {
          return -1;
        }
      }
    }

    return -1;
  }
}

class _YamlLinesContent with YamlLinesContentMixin {
  _YamlLinesContent.withText(String content) {
    lines = YamlLinesContent.splitLines(content.trim());
    reloadYaml();
  }
  _YamlLinesContent.withLines(List<String> lines) {
    this.lines = lines;
    reloadYaml();
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
    var content = '${lines.join(_mixin._separator)}${_mixin._separator}';
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

// ignore: unused_element
int _getSpaceCount(String line) {
  var count = 0;
  for (var char in line.codeUnits) {
    if (isWhitespace(char)) {
      count++;
    } else {
      break;
    }
  }
  return count;
}
