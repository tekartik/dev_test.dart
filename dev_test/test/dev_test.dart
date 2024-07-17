import 'package:dev_test/test.dart' as dev_test;
import 'package:test/test.dart';
// ignore: deprecated_member_use, depend_on_referenced_packages
import 'package:test_api/test_api.dart' as test_api;

void main() {
  test('simple', () {});
  dev_test.test('dev_test', () {});
  test_api.test('test_api', () {});
}
