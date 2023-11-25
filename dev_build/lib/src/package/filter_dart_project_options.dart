import 'package:pub_semver/pub_semver.dart';

import 'package.dart';

/// Filter dart project options
class FilterDartProjectOptions {
  /// Ignore sdk constraints (default to false)
  final bool? ignoreSdkConstraints;

  /// Constraint on minSdk.
  final VersionBoundaries? minSdk;

  /// Constraint on maxSdk.
  final VersionBoundaries? maxSdk;

  FilterDartProjectOptions(
      {this.ignoreSdkConstraints, this.minSdk, this.maxSdk});

  @override
  String toString() {
    var sb = StringBuffer('Filter(');
    if (!hasConstraintsOverride()) {
      sb.write('noConstraintsOverride');
    } else {
      if (ignoreSdkConstraints ?? false) {
        sb.write('ignoreSdkConstraints');
      } else {
        if (minSdk != null) {
          sb.write('minSdk: $minSdk');
        }
        if (maxSdk != null) {
          if (minSdk != null) {
            sb.write(', ');
          }
          sb.write('maxSdk: $maxSdk');
        }
      }
    }
    sb.write(')');
    return sb.toString();
  }
}

final _versionZero = Version(0, 0, 0);

extension FilterDartProjectOptionsExt on FilterDartProjectOptions {
  /// Return true if the sdk constraints are ignored
  bool matchesBoundaries(VersionBoundaries? boundaries) {
    if (boundaries == null) {
      return false;
    }
    if (ignoreSdkConstraints ?? false) {
      return true;
    }
    if (hasConstraintsOverride()) {
      if (minSdk != null) {
        if (boundaries.min == null) {
          return false;
        }
        if (!minSdk!.matches(boundaries.min!.value)) {
          return false;
        }
      }
      if (maxSdk != null) {
        if (boundaries.max == null) {
          return false;
        }
        if (!maxSdk!.matches(boundaries.max!.value)) {
          return false;
        }
      }
    } else if (boundaries.min?.value == _versionZero ||
        boundaries.max?.value == _versionZero) {
      return false;
    }

    return true;
  }

  /// True if there is a constraint.
  bool hasConstraintsOverride() {
    return ignoreSdkConstraints == true || minSdk != null || maxSdk != null;
  }
}
