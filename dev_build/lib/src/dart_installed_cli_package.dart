import 'package:pub_semver/pub_semver.dart';

/// A package installed with `dart install`, a line of `dart installed [--all]`
/// (Dart 3.10+).
///
/// Shapes (verified with Dart 3.13):
/// - hosted: `webdev 4.0.3`
/// - git: `my_tool 1.0.0 from Git repository "<url>" at "<8 char ref>"`
/// - path: `my_tool 1.0.0 from "<path>" at 2026-09-28 17:06:49.116900`
/// - any of them followed by ` (not active)` or another status in
///   parentheses (only listed with `--all`).
///
/// Same parser as pubglobalupdate `DartInstalledPackage`.
class DartInstalledCliPackage {
  /// A parsed line.
  DartInstalledCliPackage({
    required this.name,
    required this.version,
    required this.source,
    this.gitUrl,
    this.gitRef,
    this.path,
    this.lastModified,
    this.status,
  });

  /// Hosted source (pub.dev).
  static const sourceHosted = 'hosted';

  /// Git source.
  static const sourceGit = 'git';

  /// Path source.
  static const sourcePath = 'path';

  /// Unknown source.
  static const sourceUnknown = 'unknown';

  /// Package name.
  final String name;

  /// Installed version.
  final Version version;

  /// [sourceHosted], [sourceGit], [sourcePath] or [sourceUnknown].
  final String source;

  /// Git url (git source).
  final String? gitUrl;

  /// Resolved git ref, 8 characters (git source).
  final String? gitRef;

  /// Package path as given at install time (path source).
  final String? path;

  /// Install time as printed (path source).
  final String? lastModified;

  /// Status in parentheses, null when active (`not active`...).
  final String? status;

  /// True when its executables are in the `dart install` bin directory.
  bool get active => status == null;

  /// The git url or the path.
  String? get sourceValue => gitUrl ?? path;

  static final _statusRegExp = RegExp(r' \(([^()]*)\)$');
  static final _gitRegExp = RegExp(
    r'^from Git repository "(.*)" at "([^"]*)"$',
  );
  static final _pathRegExp = RegExp(r'^from "(.*)" at (.*)$');
  static final _unknownRegExp = RegExp(r'^from an unknown source "(.*)"$');

  /// Parses a `dart installed` line, null if it is not one (i.e.
  /// `No Dart CLI tools installed.`).
  static DartInstalledCliPackage? fromLine(String line) {
    var text = line.trim();
    String? status;
    final statusMatch = _statusRegExp.firstMatch(text);
    if (statusMatch != null) {
      status = statusMatch.group(1);
      text = text.substring(0, statusMatch.start);
    }
    final nameEnd = text.indexOf(' ');
    if (nameEnd <= 0) {
      return null;
    }
    final name = text.substring(0, nameEnd);
    var rest = text.substring(nameEnd + 1);
    final versionEnd = rest.indexOf(' ');
    final versionText = versionEnd < 0 ? rest : rest.substring(0, versionEnd);
    final Version version;
    try {
      version = Version.parse(versionText);
    } catch (_) {
      return null;
    }
    rest = versionEnd < 0 ? '' : rest.substring(versionEnd + 1);
    if (rest.isEmpty) {
      return DartInstalledCliPackage(
        name: name,
        version: version,
        source: sourceHosted,
        status: status,
      );
    }
    final git = _gitRegExp.firstMatch(rest);
    if (git != null) {
      return DartInstalledCliPackage(
        name: name,
        version: version,
        source: sourceGit,
        gitUrl: git.group(1),
        gitRef: git.group(2),
        status: status,
      );
    }
    final unknown = _unknownRegExp.firstMatch(rest);
    if (unknown != null) {
      return DartInstalledCliPackage(
        name: name,
        version: version,
        source: sourceUnknown,
        status: status,
      );
    }
    final path = _pathRegExp.firstMatch(rest);
    if (path != null) {
      return DartInstalledCliPackage(
        name: name,
        version: version,
        source: sourcePath,
        path: path.group(1),
        lastModified: path.group(2),
        status: status,
      );
    }
    return null;
  }

  @override
  String toString() =>
      '$name $version'
      '${source == sourceHosted ? '' : ' $source ${sourceValue ?? ''}'}'
      '${status == null ? '' : ' ($status)'}';
}

/// Parse `dart installed [--all]` output lines, other lines are ignored.
List<DartInstalledCliPackage> parseDartInstalledCliPackages(
  Iterable<String> lines,
) => lines.map(DartInstalledCliPackage.fromLine).nonNulls.toList();
