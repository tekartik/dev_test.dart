import 'list_utils.dart';

/// Internal use only
typedef Model = Map<String, Object?>;

/// as Model
Model asModel(Map map) => map is Model ? map : map.cast<String, Object?>();

/// as Model or null
Model? asModelOrNull(Map? map) => map?.cast<String, Object?>();

/// Internal use only
extension TekartikObjectPrvExt on Object {
  /// as Model if possible
  Model? get anyAsModel {
    var self = this;
    if (self is Map) {
      return asModel(self);
    }
    return null;
  }
}

/// Get a map value as a map
Model? mapValueAsMap(Map map, String key) {
  var value = map[key] as Object?;
  return value?.anyAsModel;
}

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
  var lastMap = _getPartsMapValue<Object?>(map, parts.take(parts.length - 1));
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
  if (value is T) {
    return value;
  }
  return null;
}
