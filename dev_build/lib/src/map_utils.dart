import 'list_utils.dart';

/// Clone a map.
Map<K, V> cloneMap<K, V>(Map<K, V> original) {
  final map = <K, V?>{};
  original.forEach((key, value) {
    dynamic cloneValue;
    if (value is Map) {
      cloneValue = cloneMap(value);
    } else if (value is List) {
      cloneValue = cloneList(value);
    } else {
      cloneValue = value;
    }
    map[key] = cloneValue as V?;
  });
  return map as Map<K, V>;
}

/// Map value from parts
T? mapValueFromParts<T>(Map? map, Iterable<String> parts) =>
    _getPartsMapValue(map, parts);

/// true if the key exists even if the value is null
bool mapPartsExists(Map map, Iterable<String> parts) {
  assert(parts.isNotEmpty);
  var lastMap = _getPartsMapValue<Object?>(map, List<String>.from(parts));
  if (lastMap is Map) {
    if (lastMap.containsKey(parts.last)) {
      return true;
    }
  }
  return false;
}

T? _getPartsMapValue<T>(Map? map, Iterable<String> parts) {
  dynamic value = map;
  for (var part in parts) {
    if (value is Map) {
      value = value[part];
    } else {
      return null;
    }
  }
  return value as T?;
}
