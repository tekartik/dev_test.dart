import 'dart:io';

import 'package:path/path.dart';

Future<List<String>> topLevelDir(String dir) async {
  var list = <String>[];
  await Directory(dir).list(recursive: false).listen((event) {
    if (event is Directory) {
      list.add(basename(event.path));
    }
  }).asFuture();
  return list;
}

List<String> _forbiddenDirs = ['node_modules', '.dart_tool', 'build'];

List<String> filterDartDirs(List<String> dirs) => dirs.where((element) {
      if (element.startsWith('.')) {
        return false;
      }
      if (_forbiddenDirs.contains(element)) {
        return false;
      }
      return true;
    }).toList(growable: false);

/// Package run options
class PackageRunCiOptions {
  final bool verbose;
  final bool offline;
  final bool noNodeTest;
  final bool noBrowserTest;
  late bool noTest;
  final bool noVmTest;
  final bool noPubGet;
  late bool noFormat;
  late bool noAnalyze;
  final bool noNpmInstall;
  late bool noBuild;
  final bool recursive;
  final bool pubUpgradeOnly;
  final bool formatOnly;
  final bool testOnly;
  final bool buildOnly;
  final bool analyzeOnly;
  final bool pubGetOnly;
  final int? poolSize;

  PackageRunCiOptions(
      {this.formatOnly = false,
      this.testOnly = false,
      this.buildOnly = false,
      this.analyzeOnly = false,
      this.pubGetOnly = false,
      this.verbose = false,
      this.recursive = false,
      this.pubUpgradeOnly = false,
      this.noNodeTest = false,
      this.noVmTest = false,
      this.noBrowserTest = false,
      this.noTest = false,
      this.noAnalyze = false,
      this.noFormat = false,
      this.noPubGet = false,
      this.noBuild = false,
      this.offline = false,
      this.noNpmInstall = false,
      this.poolSize}) {
    var isOnlyAction = (formatOnly ||
        buildOnly ||
        testOnly ||
        analyzeOnly ||
        pubGetOnly ||
        pubUpgradeOnly);
    if (isOnlyAction) {
      noTest = !testOnly;

      noBuild = !buildOnly;
      noAnalyze = !analyzeOnly;
      noFormat = !formatOnly;
    }
  }

  bool get noPubGetOrUpgrade => noPubGet || (!pubGetOnly && !pubUpgradeOnly);
}
