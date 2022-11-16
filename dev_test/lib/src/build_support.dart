import 'dart:convert';
import 'dart:io';

import 'package:dev_test/src/io/file_utils.dart';
import 'package:dev_test/src/mixin/package.dart';
import 'package:path/path.dart';
import 'package:process_run/shell_run.dart';
import 'package:pub_semver/pub_semver.dart';

var minNnbdVersion = Version(2, 12, 0, pre: '0');

/// Returns true if added
Future<bool> pathPubspecAddDependency(String dir, String dependency,
    {List<String>? dependencyLines}) async {
  var map = await pathGetPubspecYamlMap(dir);
  if (!pubspecYamlHasAnyDependencies(map, [dependency])) {
    var content = _loadPubspecContent(dir);
    content = _pubspecStringAddDependency(content, dependency,
        dependencyLines: dependencyLines);
    await _writePubspecContent(dir, content);
    return true;
  }
  return false;
}

Iterable<String> _loadPubspecContentLines(String dir) {
  return LineSplitter.split(_loadPubspecContent(dir));
}

String _loadPubspecContent(String dir) {
  var file = File(join(dir, 'pubspec.yaml'));
  return file.readAsStringSync();
}

Future<void> _writePubspecContent(String dir, String content) async {
  var file = File(join(dir, 'pubspec.yaml'));
  await file.writeAsString(content);
}

// Null if not a dependency, formatted on a single line with depencency prefix or
// multiple lines
Future<List<String>?> pathPubspecGetDependencyLines(
    String dir, String dependency) async {
  var map = await pathGetPubspecYamlMap(dir);

  var lines = <String>[];
  if (pubspecYamlHasAnyDependencies(map, [dependency])) {
    var readLines = _loadPubspecContentLines(dir).toList();
    String? headerLine;
    var foundHeader = false;
    for (var i = 0; i < readLines.length; i++) {
      var line = readLines[i];
      if (foundHeader) {
        if (line.startsWith('    ')) {
          lines.add(line.substring(4));
        } else {
          break;
        }
      } else if (line.startsWith('  $dependency:')) {
        headerLine = line..trim();
        foundHeader = true;
      }
    }
    if (lines.isEmpty && headerLine != null) {
      lines.add(headerLine);
    }
    return lines;
  }
  return null;
}

// Returns true if removed
Future<bool> pathPubspecRemoveDependency(String dir, String dependency) async {
  var map = await pathGetPubspecYamlMap(dir);
  if (pubspecYamlHasAnyDependencies(map, [dependency])) {
    var content = _loadPubspecContent(dir);
    content = _pubspecStringRemoveDependency(content, dependency);
    await _writePubspecContent(dir, content);
    return true;
  }
  return false;
}

/// Add a dependency in a brut force way
///
String _pubspecStringAddDependency(String content, String dependency,
    {List<String>? dependencyLines}) {
  var lines = LineSplitter.split(content).toList();
  var index = lines.indexOf('dependencies:');
  if (index < 0) {
    // The template might create it commented out
    index = lines.indexOf('#dependencies:');
    if (index < 0) {
      lines.add('\ndependencies:');
      index = lines.length;
    } else {
      lines[index] = 'dependencies:';
      index = index + 1;
    }
  } else {
    index = index + 1;
  }
  lines.insert(index, '  $dependency:');
  if (dependencyLines != null) {
    for (var line in dependencyLines) {
      lines.insert(++index, '    $line');
    }
  }
  return lines.join('\n');
}

/// Remove a dependency in a brut force way
///
String _pubspecStringRemoveDependency(String content, String dependency) {
  var lines = LineSplitter.split(content).toList();
  int? deleteStartIndex;
  int? deleteEndIndex;
  var readLines = lines;
  for (var i = 0; i < readLines.length; i++) {
    var line = readLines[i];
    if (deleteStartIndex != null) {
      if (line.startsWith('  ')) {
        deleteEndIndex = deleteEndIndex! + 1;
      } else {
        break;
      }
    } else if (line.startsWith('  $dependency:')) {
      deleteStartIndex = i;
      deleteEndIndex = i + 1;
    }
  }
  if (deleteStartIndex != null) {
    lines.removeRange(deleteStartIndex, deleteEndIndex!);
  }

  return lines.join('\n');
}

String? _flutterChannel;

/// Setup minimum Dart support
Future<void> buildInitDart() async {}

/// Setup minimum flutter support
Future<void> buildInitFlutter() async {
  _flutterChannel = await getFlutterBinChannel();
  if (buildSupportsMacOS) {
    await run('flutter config --enable-macos-desktop');
  }
  if (buildSupportsLinux) {
    await run('flutter config --enable-linux-desktop');
  }
  if (buildSupportsWindows) {
    await run('flutter config --enable-windows-desktop');
  }
}

bool get buildSupportsMacOS =>
    Platform.isMacOS &&
    [dartChannelDev, dartChannelMaster].contains(_flutterChannel);

bool? _supportsIOS;

/// For now based on x-code presence.
bool get buildSupportsIOS =>
    _supportsIOS ??= Platform.isMacOS && whichSync('xcode-select') != null;

bool? _supportsAndroid;

/// Always allowed for now
bool get buildSupportsAndroid => _supportsAndroid ??= true;

bool get buildSupportsLinux =>
    Platform.isLinux &&
    [dartChannelDev, dartChannelMaster].contains(_flutterChannel);

bool get buildSupportsWindows =>
    Platform.isWindows && [dartChannelMaster].contains(_flutterChannel);

/// console-simple: A simple command-line application. (default)
const dartTemplateConsoleSimple = 'console-simple';

/// console-full: A command-line application sample.
const dartTemplateConsoleFull = 'console-full';

/// package-simple: A starting point for Dart libraries or applications.
const dartTemplatePackageSimple = 'package-simple';

/// web-simple: A web app that uses only core Dart libraries.
const dartTemplateWebSimple = 'web-simple';

const flutterTemplateApp = 'app';

/// Flutter package shared dart code.
const flutterTemplatePackage = 'package';

Future<void> dartCreateProject(
    {String template = dartTemplateConsoleSimple, required String path}) async {
  await Directory(path).prepare();

  var shell = Shell().cd(dirname(path));
  await shell
      .run('dart create --template $template ${shellArgument(basename(path))}');
}

Future<void> flutterCreateProject({
  required String path,
  String template = flutterTemplateApp,
  bool? noAnalyze,
}) async {
  await Directory(path).prepare();

  var shell = Shell().cd(dirname(path));

  await shell.run(
      'flutter create --template $template ${shellArgument(basename(path))}');
}

/// Build a file path.
String _toFilePath(String parent, String path, {bool? windows}) {
  var uri = Uri.parse(path);
  path = uri.toFilePath(windows: windows);
  if (isRelative(path)) {
    return normalize(join(parent, path));
  }
  return normalize(path);
}

// {
//   "configVersion": 2,
//   "packages": [
//     {
//       "name": "_fe_analyzer_shared",
//       "rootUri": "file:///home/alex/.pub-cache/hosted/pub.dartlang.org/_fe_analyzer_shared-27.0.0",
//       "packageUri": "lib/",
//       "languageVersion": "2.12"
//     },
//      {
//       "name": "dev_test",
//       "rootUri": "../",
//       "packageUri": "lib/",
//       "languageVersion": "2.14"
//     }
/// Get a library path, you can get the project dir through its parent
String? pathPackageConfigMapGetPackagePath(
    String path, Map packageConfigMap, String package,
    {bool? windows}) {
  var packagesList = packageConfigMap['packages'];
  for (var packageMap in packagesList) {
    if (packageMap is Map) {
      var name = packageMap['name'];

      if (name is String && name == package) {
        var rootUri = packageMap['rootUri'];
        if (rootUri is String) {
          // rootUri if relative is relative to .dart_tool
          // we want it relative to the root project.
          // Replace .. with . to avoid going up twice
          if (rootUri.startsWith('..')) {
            rootUri = rootUri.substring(1);
          }
          return _toFilePath(path, rootUri, windows: windows);
        }
      }
    }
  }
  return null;
}
