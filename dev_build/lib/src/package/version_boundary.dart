import 'package:pub_semver/pub_semver.dart';

/// Public helper
extension VersionBoundaryVersionExt on Version {
  /// Lower boundary included by default
  VersionBoundary get lowerBoundary => VersionBoundary.lower(this);

  /// Upper boundary excluded by default
  VersionBoundary get upperBoundary => VersionBoundary.upper(this);
}

/// Version boundary.
class VersionBoundary {
  /// Version.
  final Version value;

  /// Include.
  final bool include;

  /// Version boundary.
  const VersionBoundary(this.value, this.include);

  /// Lower boundary included by default
  const VersionBoundary.lower(this.value) : include = true;

  /// Upper boundary excluded by default
  const VersionBoundary.upper(this.value) : include = false;

  @override
  String toString() => '$value $include';

  @override
  int get hashCode => value.hashCode + include.hashCode;

  @override
  bool operator ==(Object other) {
    if (other is VersionBoundary) {
      if (other.value != value) {
        return false;
      }
      if (other.include != include) {
        return false;
      }
      return true;
    }
    return false;
  }
}

/// Version boundaries.
class VersionBoundaries {
  /// min.
  final VersionBoundary? min;

  /// max.
  final VersionBoundary? max;

  @override
  String toString() {
    return toShortString();
  }

  /// Escape with '' if needed.
  String toYamlString() {
    String escape(String text) => "'$text'";
    if (_isShort()) {
      return _toShortString();
    } else if (_isSingle()) {
      return _toSingleString();
    } else if (_isEmpty()) {
      return '';
    }
    return escape(toMinMaxString());
  }

  // True for no version
  bool _isEmpty() {
    return min == null && max == null;
  }

  // True for 1.0.0
  bool _isSingle() {
    return min == max && (min?.include ?? false);
  }

  // True for ^1.0.0
  bool _isShort() {
    var min = this.min;
    var max = this.max;
    if (min == null || max == null) {
      return false;
    }
    if (!min.include || max.include) {
      return false;
    }
    if (Version(min.value.major + 1, 0, 0) == max.value) {
      return true;
    }
    if (min.value.major == 0) {
      if (min.value.minor == 0) {
        if (Version(min.value.major, min.value.minor, min.value.patch + 1) ==
            max.value) {
          return true;
        }
      } else {
        if (Version(min.value.major, min.value.minor + 1, 0) == max.value) {
          return true;
        }
      }
    } else {
      if (Version(min.value.major + 1, 0, 0) == max.value) {
        return true;
      }
    }
    return false;
  }

  /// Short string if possible, default to minMaxString.
  String toShortString() {
    if (_isShort()) {
      return _toShortString();
    } else {
      return toMinMaxString();
    }
  }

  /// If short
  String _toShortString() {
    return '^${min!.value}';
  }

  /// If single
  String _toSingleString() {
    return '${min!.value}';
  }

  /// >=minVersion <maxVersion
  String toMinMaxString() {
    var sb = StringBuffer();
    if (min != null) {
      if (_isSingle()) {
        return _toSingleString();
      }
      sb.write('>');
      if (min!.include) {
        sb.write('=');
      }
      sb.write(min!.value);
    }
    if (max != null) {
      if (sb.isNotEmpty) {
        sb.write(' ');
      }
      sb.write('<');
      if (max!.include) {
        sb.write('=');
      }
      sb.write(max!.value);
    }
    return sb.toString();
  }

  /// Version boundaries.
  const VersionBoundaries(this.min, this.max);

  /// Default is lower bound included, upper excluted.
  VersionBoundaries.versions(Version? versionMin, Version? versionMax)
    : min = versionMin?.lowerBoundary,
      max = versionMax?.upperBoundary;

  /// Version boundaries pinned.
  VersionBoundaries.version(Version version)
    : min = VersionBoundary(version, true),
      max = VersionBoundary(version, true);

  /// Compat
  static VersionBoundaries? tryParse(String text) {
    try {
      return parse(text);
    } catch (_) {
      return null;
    }
  }

  /// Parse
  static VersionBoundaries parse(String text) {
    var parts = text.trim().split(' ');
    VersionBoundary? min;
    VersionBoundary? max;
    for (var part in parts) {
      if (part.startsWith('>=')) {
        try {
          min = VersionBoundary(Version.parse(part.substring(2)), true);
        } catch (_) {}
      } else if (part.startsWith('>')) {
        try {
          min = VersionBoundary(Version.parse(part.substring(1)), false);
        } catch (_) {}
      } else if (part.startsWith('<=')) {
        try {
          max = VersionBoundary(Version.parse(part.substring(2)), true);
        } catch (_) {}
      } else if (part.startsWith('<')) {
        try {
          max = VersionBoundary(Version.parse(part.substring(1)), false);
        } catch (_) {}
      } else if (part.startsWith('^')) {
        try {
          min = VersionBoundary(Version.parse(part.substring(1)), true);
          if (min.value.major != 0) {
            max = VersionBoundary(Version(min.value.major + 1, 0, 0), false);
          } else if (min.value.minor != 0) {
            max = VersionBoundary(Version(0, min.value.minor + 1, 0), false);
          } else {
            max = VersionBoundary(Version(0, 0, min.value.patch + 1), false);
          }
        } catch (_) {}
      } else {
        try {
          min = max = VersionBoundary(Version.parse(part), true);
        } catch (_) {}
      }
    }
    return VersionBoundaries(min, max);
  }

  // TO deprecate
  /// Prefer [matches]
  bool match(Version version) {
    return matches(version);
  }

  /// True if a version match the boundaries
  bool matches(Version version) {
    return matchesMin(version) && matchesMax(version);
  }

  /// True if a version match the max boundary
  bool matchesMax(Version version) {
    if (max != null) {
      if (max!.include) {
        if (version > max!.value) {
          return false;
        }
      } else if (version >= max!.value) {
        return false;
      }
    }
    return true;
  }

  /// True if a version match the min boundary.
  bool matchesMin(Version version) {
    if (min != null) {
      if (min!.include) {
        if (version < min!.value) {
          return false;
        }
      } else if (version <= min!.value) {
        return false;
      }
    }
    return true;
  }

  @override
  int get hashCode => (min?.hashCode ?? 0) + (max?.hashCode ?? 0);

  @override
  bool operator ==(Object other) {
    if (other is VersionBoundaries) {
      if (other.min != min) {
        return false;
      }
      if (other.max != max) {
        return false;
      }
      return true;
    }
    return false;
  }

  /// Copy with new values
  VersionBoundaries copyWith({VersionBoundary? min, VersionBoundary? max}) {
    return VersionBoundaries(min ?? this.min, max ?? this.max);
  }
}
