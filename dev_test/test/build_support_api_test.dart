@TestOn('vm')
import 'package:dev_test/build_support.dart';
import 'package:test/test.dart';

// ignore_for_file: unnecessary_statements

void main() {
  test('flutter config', () async {
    dartTemplatePackage;
    dartTemplateWeb;
    dartTemplateConsole;
  });
}
