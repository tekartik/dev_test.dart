import 'dart:convert';

import 'package:dev_build/src/io/file_utils.dart';
import 'package:dev_build/src/mixin/package.dart';
import 'package:path/path.dart';
import 'package:process_run/shell_run.dart';
import 'package:process_run/stdio.dart';

import 'build_support_common.dart';

/// Returns true if added
Future<bool> pathPubspecAddDependency(
  String dir,
  String dependency, {
  List<String>? dependencyLines,
}) async {
  var map = await pathGetPubspecYamlMap(dir);
  if (!pubspecYamlHasAnyDependencies(map, [dependency])) {
    var content = _loadPubspecContent(dir);
    content = pubspecStringAddDependency(
      content,
      dependency,
      dependencyLines: dependencyLines,
    );
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

/// Null if not a dependency, formatted on a single line with depencency prefix or
/// multiple lines
Future<List<String>?> pathPubspecGetDependencyLines(
  String dir,
  String dependency,
) async {
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

/// Returns true if removed
Future<bool> pathPubspecRemoveDependency(String dir, String dependency) async {
  var map = await pathGetPubspecYamlMap(dir);
  if (pubspecYamlHasAnyDependencies(map, [dependency])) {
    var content = _loadPubspecContent(dir);
    content = pubspecStringRemoveDependency(content, dependency);
    await _writePubspecContent(dir, content);
    return true;
  }
  return false;
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

/// Build supports MacOS
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

/// Build supports Linux
bool get buildSupportsLinux =>
    Platform.isLinux &&
    [dartChannelDev, dartChannelMaster].contains(_flutterChannel);

/// Build supports Windows
bool get buildSupportsWindows =>
    Platform.isWindows && [dartChannelMaster].contains(_flutterChannel);

/// console: A command-line application. (default)
const dartTemplateConsole = 'console';

/// console-simple: A simple command-line application. (default)
/// @Deprecated
const dartTemplateConsoleSimple = dartTemplateConsole;

/// console-full: A command-line application sample.
/// @Deprecated
const dartTemplateConsoleFull = dartTemplateConsole;

/// package: A package containing shared Dart libraries
const dartTemplatePackage = 'package';

/// package-simple: A starting point for Dart libraries or applications.
const dartTemplatePackageSimple = dartTemplatePackage;

/// web: A web app that uses only core Dart libraries.
const dartTemplateWeb = 'web';

/// web-simple: A web app that uses only core Dart libraries.
/// @Deprecated
const dartTemplateWebSimple = dartTemplateWeb;

/// app: A Flutter application.
const flutterTemplateApp = 'app';

/// Flutter package shared dart code.
const flutterTemplatePackage = 'package';

/// Create a dart project.
Future<void> dartCreateProject({
  String template = dartTemplateConsoleSimple,
  required String path,
}) async {
  await Directory(path).prepare();

  var shell = Shell().cd(dirname(path));
  await shell.run(
    'dart create --template $template ${shellArgument(basename(path))}',
  );
}

/// Create a flutter project.
Future<void> flutterCreateProject({
  required String path,
  String template = flutterTemplateApp,
  List<String>? platforms,
  bool? noAnalyze,
}) async {
  await Directory(path).prepare();

  var shell = Shell().cd(dirname(path));

  await shell.run(
    'flutter create --template $template ${shellArgument(basename(path))}${platforms != null ? ' --platforms ${platforms.join(',')}' : ''}',
  );
}
