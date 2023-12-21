// ignore_for_file: unnecessary_statements

library dev_build.test.build_support_common_test;

import 'package:dev_build/src/build_support_common.dart';
//import 'package:dev_build/src/mixin/package_io.dart';
import 'package:test/test.dart';

void main() {
  group('build_support_common', () {
    test('add deps flutter', () async {
      expect(pubspecStringAddDependency('''
dependencies:
  flutter:
    sdk: flutter
''', 'sqflite'), '''
dependencies:
  sqflite:
  flutter:
    sdk: flutter
''');
      expect(pubspecStringAddDependency('''
dependencies:
''', 'sqflite'), '''
dependencies:
  sqflite:
''');
    });
    test('remove deps flutter', () async {
      expect(pubspecStringRemoveDependency('''
dependencies:
  sqflite:
  flutter:
    sdk: flutter
''', 'sqflite'), '''
dependencies:
  flutter:
    sdk: flutter
''');
    });
  });
}
