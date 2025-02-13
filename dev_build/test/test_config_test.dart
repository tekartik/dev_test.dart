import 'package:dev_build/src/package/test_config.dart';
import 'package:test/test.dart';

void main() {
  test('test_config', () {
    var testConfig = buildTestConfig(platforms: []);
    expect(testConfig.toCommandLineArgument(), '');
    expect(testConfig.configLineTexts, ['']);
    testConfig = buildTestConfig(platforms: ['vm']);
    expect(testConfig.toCommandLineArgument(), ' --platform vm');
    expect(testConfig.configLineTexts, ['--platform vm']);
    expect(testConfig.hasNode, isFalse);
    testConfig = buildTestConfig(platforms: ['vm', 'chrome']);
    expect(
      testConfig.toCommandLineArgument(),
      ' --platform vm --platform chrome',
    );
    expect(testConfig.configLineTexts, ['--platform vm', '--platform chrome']);

    testConfig = buildTestConfig(
      platforms: ['vm', 'chrome'],
      dartTestMap: {
        'platforms': ['chrome'],
      },
    );
    expect(testConfig.toCommandLineArgument(), ' --platform chrome');
    expect(testConfig.configLineTexts, ['--platform chrome']);

    testConfig = buildTestConfig(
      platforms: ['vm', 'chrome'],
      dartTestMap: {
        'compilers': ['dart2js', 'dart2wasm'],
      },
    );
    expect(
      testConfig.toCommandLineArgument(),
      ' --platform vm --compiler dart2js --compiler dart2wasm --platform chrome',
    );
    expect(testConfig.configLineTexts, [
      '--platform vm',
      '--platform chrome --compiler dart2js --compiler dart2wasm',
    ]);
    testConfig = buildTestConfig(
      platforms: ['vm', 'chrome'],
      dartTestMap: {
        'platforms': ['vm', 'chrome'],
        'compilers': ['dart2js', 'dart2wasm'],
      },
    );

    expect(
      testConfig.toCommandLineArgument(),
      ' --platform vm --compiler dart2js --compiler dart2wasm --platform chrome',
    );
    expect(testConfig.configLineTexts, [
      '--platform vm',
      '--platform chrome --compiler dart2js --compiler dart2wasm',
    ]);
    testConfig = buildTestConfig(
      platforms: ['vm', 'chrome'],
      dartTestMap: {
        'platforms': ['chrome'],
        'compilers': ['dart2js', 'dart2wasm'],
      },
    );
    expect(
      testConfig.toCommandLineArgument(),
      ' --compiler dart2js --compiler dart2wasm --platform chrome',
    );
    expect(testConfig.configLineTexts, [
      '--platform chrome --compiler dart2js --compiler dart2wasm',
    ]);
    testConfig = buildTestConfig(
      platforms: ['vm', 'chrome'],
      dartTestMap: {
        'platforms': ['chrome'],
        'compilers': ['dart2js', 'dart2wasm'],
      },
      noWasm: true,
    );
    expect(
      testConfig.toCommandLineArgument(),
      ' --compiler dart2js --platform chrome',
    );
    expect(testConfig.configLineTexts, [
      '--platform chrome --compiler dart2js',
    ]);

    testConfig = buildTestConfig(
      platforms: ['chrome', 'node', 'vm'],
      dartTestMap: {
        'platforms': ['chrome', 'vm', 'node'],
        'compilers': ['dart2js', 'dart2wasm'],
      },
    );
    expect(
      testConfig.toCommandLineArgument(),
      ' --compiler dart2js --compiler dart2wasm --platform chrome'
      ' --platform node'
      ' --platform vm',
    );
    expect(testConfig.configLineTexts, [
      '--platform chrome --compiler dart2js --compiler dart2wasm',
      '--platform node --compiler dart2js',
      '--platform vm',
    ]);
    testConfig = buildTestConfig(
      supportedPlatforms: ['chrome', 'node', 'vm'],
      dartTestMap: {
        'platforms': ['chrome', 'vm', 'node'],
        'compilers': ['dart2js', 'dart2wasm'],
      },
    );
    expect(
      testConfig.toCommandLineArgument(),
      ' --compiler dart2js --compiler dart2wasm --platform chrome'
      ' --platform vm'
      ' --platform node',
    );
    expect(testConfig.configLineTexts, [
      '--platform chrome --compiler dart2js --compiler dart2wasm',
      '--platform vm',
      '--platform node --compiler dart2js',
    ]);

    testConfig = buildTestConfig(
      supportedPlatforms: ['vm', 'chrome', 'node'],
      dartTestMap: {
        'platforms': ['node'],
      },
    );
    expect(testConfig.toCommandLineArgument(), ' --platform node');
    expect(testConfig.hasNode, isTrue);
    expect(testConfig.configLineTexts, ['--platform node --compiler dart2js']);
  });
}
