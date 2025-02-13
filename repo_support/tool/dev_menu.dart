import 'dart:io';

import 'package:dev_build/build_support.dart';
import 'package:dev_build/menu/menu_io.dart';
import 'package:path/path.dart';

Future<void> main(List<String> args) async {
  mainMenuConsole(args, () {
    item('pick dir', () async {
      var dir = await prompt('Enter a directory');
      write('dir: $dir');
    });
    item('pathGetPackageConfigMap', () async {
      var configMap = await pathGetPackageConfigMap('.');
      print(configMap);
      var packages = packageConfigGetPackages(configMap);
      for (var package in packages) {
        print(package);
        var packagePath =
            pathPackageConfigMapGetPackagePath('.', configMap, package)!;
        // There should be pubspec.yaml in the package
        print(packagePath);
        print(
          'pubspec.yaml: ${File(join(packagePath, 'pubspec.yaml')).existsSync()}',
        );
        //print(pathPackageConfigMapGetPackagePath('.', configMap, package));
      }
      /*
      pathPackageConfigMapGetPackagePath(path, packageConfigMap, package)
      var deps = await pathPackageConfigMapGetPackagePath(path, packageConfigMap, package)*/
    });
  });
}
