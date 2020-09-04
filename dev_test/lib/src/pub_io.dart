import 'dart:async';
import 'dart:io' as io;

import 'package:path/path.dart';

import 'mixin/package.dart';
import 'package/package.dart';

final String _pubspecYaml = 'pubspec.yaml';

/// return true if root package

/// @deprecated
Future<bool> isPubPackageRoot(String dirPath) async {
  var pubspecYamlPath = join(dirPath, _pubspecYaml);
  // ignore: avoid_slow_async_io
  return io.FileSystemEntity.isFile(pubspecYamlPath);
}

bool isPubPackageRootSync(String dirPath) {
  var pubspecYamlPath = join(dirPath, _pubspecYaml);
  return io.FileSystemEntity.isFileSync(pubspecYamlPath);
}

Future<bool> isFlutterPackageRoot(String dirPath) async {
  var map = await pathGetPubspecYamlMap(dirPath);
  return pubspecYamlSupportsFlutter(map);
}

/// throws if no project found
Future<String> getPubPackageRoot(String resolverPath) async {
  var dirPath = normalize(absolute(resolverPath));

  while (true) {
    // Find the project root path
    if (await isPubPackageRoot(dirPath)) {
      return dirPath;
    }
    var parentDirPath = dirname(dirPath);

    if (parentDirPath == dirPath) {
      throw Exception("No project found for path '$resolverPath");
    }
    dirPath = parentDirPath;
  }
}

String getPubPackageRootSync(String resolverPath) {
  var dirPath = normalize(absolute(resolverPath));

  while (true) {
    // Find the project root path
    if (isPubPackageRootSync(dirPath)) {
      return dirPath;
    }
    var parentDirPath = dirname(dirPath);

    if (parentDirPath == dirPath) {
      throw Exception("No project found for path '$resolverPath");
    }
    dirPath = parentDirPath;
  }
}
