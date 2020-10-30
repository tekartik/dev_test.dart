import 'dart:io';

import 'package:dev_test/src/mixin/package.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart';
import 'package:process_run/dartbin.dart';
import 'package:process_run/shell_run.dart';
import 'package:process_run/which.dart';

/// Returns true if added
Future<bool> pathPubspecAddDependency(String dir, String dependency,
    {String dependencyLine}) async {
  var map = await pathGetPubspecYamlMap(dir);
  if (!pubspecYamlHasAnyDependencies(map, [dependency])) {
    var file = File(join(dir, 'pubspec.yaml'));
    var content = await file.readAsString();
    content =
        _pubspecStringAddDependency(content, dependencyLine ?? '$dependency:');
    await file.writeAsString(content);
    return true;
  }
  return false;
}

/// Add a dependency in a brut force way
///
String _pubspecStringAddDependency(String content, String dependencyLine) {
  return content.replaceAllMapped(RegExp(r'^dependencies:$', multiLine: true),
      (match) => 'dependencies:\n  $dependencyLine');
}

String _flutterChannel;

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

bool _supportsIOS;

/// For now based on x-code presence.
bool get buildSupportsIOS =>
    _supportsIOS ??= Platform.isMacOS && whichSync('xcode-select') != null;

bool _supportsAndroid;

/// Always allowed for now
bool get buildSupportsAndroid => _supportsAndroid ??= true;

bool get buildSupportsLinux =>
    Platform.isLinux &&
    [dartChannelDev, dartChannelMaster].contains(_flutterChannel);

bool get buildSupportsWindows =>
    Platform.isWindows && [dartChannelMaster].contains(_flutterChannel);

extension _DirectoryExt on Directory {
  /// Create if needed
  Future<void> prepare() async {
    if (await exists()) {
      try {
        await delete(recursive: true);
      } catch (_) {}
    }
    await parent.create(recursive: true);
  }
}

/// console-simple: A simple command-line application. (default)
const dartTemplateConsoleSimple = 'console-simple';

/// console-full: A command-line application sample.
const dartTemplateConsoleFull = 'console-full';

/// package-simple: A starting point for Dart libraries or applications.
const dartTemplatePackageSimple = 'package-simple';

/// web-simple: A web app that uses only core Dart libraries.
const dartTemplateWebSimple = 'web-simple';

const flutterTemplateApp = 'app';

Future<void> dartCreateProject(
    {String template = dartTemplateConsoleSimple,
    @required String path}) async {
  await Directory(path).prepare();

  var shell = Shell().cd(dirname(path));
  await shell
      .run('dart create --template $template ${shellArgument(basename(path))}');
}

Future<void> flutterCreateProject({
  @required String path,
  String template = flutterTemplateApp,
  bool noAnalyze,
}) async {
  await Directory(path).prepare();

  var shell = Shell().cd(dirname(path));

  await shell.run(
      'flutter create --template $template ${shellArgument(basename(path))}');
}
