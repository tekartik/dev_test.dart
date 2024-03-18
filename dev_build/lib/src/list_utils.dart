import 'map_utils.dart';

/// Clone list and list of list
List<T>? cloneList<T>(List<T>? original) {
  if (original == null) {
    return null;
  }
  var clone = <T?>[];
  for (var item in original) {
    if (item is List) {
      item = cloneList(item) as T;
    } else if (item is Map) {
      item = cloneMap(item) as T;
    }
    clone.add(item);
  }
  return clone as List<T>;
}
