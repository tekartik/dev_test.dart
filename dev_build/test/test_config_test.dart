import 'package:dev_build/src/package/test_config.dart';
import 'package:test/test.dart';

void main() {
  test('test_config', () {
    expect(buildTestConfig(platforms: []).toCommandLineArgument(), '');
    var testConfig = buildTestConfig(platforms: ['vm']);
    expect(testConfig.toCommandLineArgument(), ' --platform vm');
    expect(testConfig.hasNode, isFalse);
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
        ' --platform vm --compiler dart2js --compiler dart2wasm --platform chrome');
    expect(
        buildTestConfig(platforms: [
          'vm',
          'chrome'
        ], dartTestMap: {
          'platforms': ['vm', 'chrome'],
          'compilers': ['dart2js', 'dart2wasm']
        }).toCommandLineArgument(),
        ' --platform vm --compiler dart2js --compiler dart2wasm --platform chrome');

    expect(
        buildTestConfig(platforms: [
          'vm',
          'chrome'
        ], dartTestMap: {
          'platforms': ['chrome'],
          'compilers': ['dart2js', 'dart2wasm']
        }).toCommandLineArgument(),
        ' --compiler dart2js --compiler dart2wasm --platform chrome');

    expect(
        buildTestConfig(platforms: [
          'vm',
          'chrome'
        ], dartTestMap: {
          'platforms': ['chrome'],
          'compilers': ['dart2js', 'dart2wasm']
        }, noWasm: true)
            .toCommandLineArgument(),
        ' --compiler dart2js --platform chrome');

    expect(
        buildTestConfig(platforms: [
          'chrome',
          'node',
          'vm',
        ], dartTestMap: {
          'platforms': ['chrome', 'vm', 'node'],
          'compilers': ['dart2js', 'dart2wasm']
        }).toCommandLineArgument(),
        ' --compiler dart2js --compiler dart2wasm --platform chrome'
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
        ' --compiler dart2js --compiler dart2wasm --platform chrome'
        ' --platform vm'
        ' --platform node');

    testConfig = buildTestConfig(supportedPlatforms: [
      'vm',
      'chrome',
      'node'
    ], dartTestMap: {
      'platforms': ['node'],
    });
    expect(testConfig.toCommandLineArgument(), ' --platform node');
    expect(testConfig.hasNode, isTrue);
  });
}
