import 'package:yaml/yaml.dart';

import 'map_utils.dart';

/// Load yaml as map
extension TekartikYamlUtilsStringExt on String {
  /// Load yaml as map
  Model get yamlMap {
    return asModel(loadYaml(this) as Map);
  }
}
