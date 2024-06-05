import 'package:dev_build/src/package/test_config.dart';
import 'package:test/test.dart';

void main() {
  test('test_config', () {
    expect(buildTestConfig(platforms: []).toCommandLineArgument(), '');
    expect(buildTestConfig(platforms: ['vm']).toCommandLineArgument(),
        ' --platform vm');
    expect(buildTestConfig(platforms: ['vm', 'chrome']).toCommandLineArgument(),
        ' --platform vm --platform chrome');
    expect(
        buildTestConfig(platforms: [
          'vm',
          'chrome'
        ], dartTestMap: {
          'platforms': ['chrome']
        }).toCommandLineArgument(),
        ' --platform chrome');
    expect(
        buildTestConfig(platforms: [
          'vm',
          'chrome'
        ], dartTestMap: {
          'compilers': ['dart2js', 'dart2wasm']
        }).toCommandLineArgument(),
        ' --platform vm --platform chrome --compiler dart2js --platform chrome --compiler dart2wasm');
    expect(
        buildTestConfig(platforms: [
          'vm',
          'chrome'
        ], dartTestMap: {
          'platforms': ['vm', 'chrome'],
          'compilers': ['dart2js', 'dart2wasm']
        }).toCommandLineArgument(),
        ' --platform vm --platform chrome --compiler dart2js --platform chrome --compiler dart2wasm');

    expect(
        buildTestConfig(platforms: [
          'vm',
          'chrome'
        ], dartTestMap: {
          'platforms': ['chrome'],
          'compilers': ['dart2js', 'dart2wasm']
        }).toCommandLineArgument(),
        ' --platform chrome --compiler dart2js --platform chrome --compiler dart2wasm');

    expect(
        buildTestConfig(platforms: [
          'chrome',
          'node',
          'vm',
        ], dartTestMap: {
          'platforms': ['chrome', 'vm', 'node'],
          'compilers': ['dart2js', 'dart2wasm']
        }).toCommandLineArgument(),
        ' --platform chrome --compiler dart2js --platform chrome --compiler dart2wasm'
        ' --platform node'
        ' --platform vm');
    expect(
        buildTestConfig(supportedPlatforms: [
          'chrome',
          'node',
          'vm',
        ], dartTestMap: {
          'platforms': ['chrome', 'vm', 'node'],
          'compilers': ['dart2js', 'dart2wasm']
        }).toCommandLineArgument(),
        ' --platform chrome --compiler dart2js --platform chrome --compiler dart2wasm'
        ' --platform vm'
        ' --platform node');
    expect(
        buildTestConfig(supportedPlatforms: [
          'vm',
          'chrome',
          'node'
        ], dartTestMap: {
          'platforms': ['node'],
        }).toCommandLineArgument(),
        ' --platform node');
  });
}
