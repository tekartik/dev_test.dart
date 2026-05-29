library;

import 'package:dev_build/build_support.dart';
import 'package:pub_semver/pub_semver.dart';

/// Global package definition.
abstract class PubGlobalPackage {
  /// Package name.
  String get name;

  /// Package version.
  Version? get version;

  /// `pub global activate` arguments
  List<String> get activateArgs;

  ///
  /// return null if it cannot be parsed
  ///
  static PubGlobalPackage? fromListLine(String line) {
    // split the line by spaces to get the arguments
    var parts = line.split(' ');

    String? name;

    Version? version;
    _PubGlobalPackageMixin? package;
    // pub.dartlang.org hosted package
    // ignore name
    if (parts.length >= 2) {
      // first is package name, last is path
      name = parts[0];
      try {
        version = Version.parse(parts[1]);
      } catch (_) {
        return null;
      }
    } else {
      // ignore
      return null;
    }

    //
    // hosted
    // pub.dartlang.org hosted package
    // ignore name
    if (parts.length == 2) {
      return PubGlobalHostedPackage(name, version: version);
    } else if (parts.length >= 4) {
      //
      // handle git first
      //
      bool isPartGit(int index) {
        return parts[index].toLowerCase() == 'git';
      }

      // look for git in the 2 arguments preceding the source
      if (isPartGit(parts.length - 2) || isPartGit(parts.length - 3)) {
        package = PubGlobalGitPackage(name, version: version);
      }

      if (package == null) {
        //
        // handle part
        //
        bool isPartPath(int index) {
          return parts[index].toLowerCase() == 'path';
        }

        if (isPartPath(parts.length - 2) || isPartPath(parts.length - 3)) {
          package = PubGlobalPathPackage(name, version: version);
        }
      }

      // Git and path are source pacjage
      if (package is PubGlobalSourcePackage) {
        package._source = _extractSource(parts.last);
      }
    }

    return package;
  }

  /// Get global package from actived line.
  static PubGlobalPackage? fromActivatedLine(String line, String packageName) {
    const activated = 'activated';
    if (line.toLowerCase().startsWith(activated)) {
      final start = line.indexOf(packageName, activated.length);
      if (start != -1) {
        line = line.substring(start);
        // removing ending . if any
        if (line.endsWith('.')) {
          line = line.substring(0, line.length - 1);
        }
        final updatedPackage = PubGlobalPackage.fromListLine(line);
        return updatedPackage;
      }
    }
    return null;
  }
}

mixin _PubGlobalPackageMixin implements PubGlobalPackage {
  @override
  late final String name;
  @override
  late final Version? version;

  @override
  String toString() => '$name $version';
}

/// pub.dartlang.org hosted package
class PubGlobalHostedPackage
    with _PubGlobalPackageMixin
    implements PubGlobalPackage {
  /// Hosted package
  PubGlobalHostedPackage(String name, {Version? version}) {
    this.version = version;
    this.name = name;
  }
  @override
  List<String> get activateArgs => [name];
}

/// Hosted package with install constraint
class PubGlobalHostedPackageInstall
    with _PubGlobalPackageMixin
    implements PubGlobalHostedPackage {
  /// Hosted package
  PubGlobalHostedPackageInstall(String name, {this.versionBoundaries}) {
    this.name = name;
  }

  /// For installation
  final VersionBoundaries? versionBoundaries;
  @override
  List<String> get activateArgs => [name, ?versionBoundaries?.toShortString()];
}

String _insetString(String source, [int offset = 1]) {
  return source.substring(offset, source.length - offset);
}

///
/// remove enclosing " or '
///
String _extractSource(String source) {
  if (source.startsWith('"') && source.endsWith('"')) {
    return _extractSource(_insetString(source));
  }
  if (source.startsWith("'") && source.endsWith("'")) {
    return _extractSource(_insetString(source));
  }
  return source;
}

/// Global package from source (git, path).
abstract class PubGlobalSourcePackage
    with _PubGlobalPackageMixin
    implements PubGlobalPackage {
  /// Global package from source (git, path).
  PubGlobalSourcePackage(String name, {Version? version}) {
    this.name = name;
    this.version = version;
  }
  late String _source;

  /// Package source.
  String get source => _source;

  /// Source type (git, path)
  String get sourceType;
  @override
  List<String> get activateArgs => ['--source', sourceType, source];

  @override
  String toString() => '${super.toString()} $sourceType $source';
}

/// Global package from git for installation.
class PubGlobalGitPackageInstall extends PubGlobalGitPackage {
  /// Global package from git.
  PubGlobalGitPackageInstall(
    super.name, {
    super.version,
    required this.gitUrl,
    this.gitPath,
    this.gitRef,
  }) {
    _source = gitUrl;
  }

  @override
  String get sourceType => 'git';

  /// Git url
  final String gitUrl;

  /// Git path
  final String? gitPath;

  /// Git ref
  final String? gitRef;

  @override
  List<String> get activateArgs => [
    '--source',
    sourceType,
    gitUrl,
    if (gitPath != null) ...['--git-path', gitPath!],
    if (gitRef != null) ...['--git-ref', gitRef!],
  ];
}

/// Global package from git.
class PubGlobalGitPackage extends PubGlobalSourcePackage {
  /// Global package from git.
  PubGlobalGitPackage(super.name, {super.version});

  @override
  String get sourceType => 'git';
}

/// Global package from git for installation.
class PubGlobalPathPackageInstall extends PubGlobalPathPackage {
  /// Global package from git.
  PubGlobalPathPackageInstall(super.name, {super.version, required this.path}) {
    _source = path;
  }

  /// Source path
  final String path;
}

/// Global package from path.
class PubGlobalPathPackage extends PubGlobalSourcePackage {
  /// Global package from path.
  PubGlobalPathPackage(super.name, {super.version});
  @override
  String get sourceType => 'path';
}
