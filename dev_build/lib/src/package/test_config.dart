import 'package:meta/meta.dart';

/// Config line
class TestConfigLine {
  /// Compiler (vm, dart2js, dart2wasm)
  final String? compiler;

  /// Platform (vm, chrome, node)
  final String? platform;

  /// Config line
  TestConfigLine({this.platform, this.compiler, List<String>? compilers}) {
    if (platform != null) {
      args.addAll(['--platform', platform!]);
    }
    if (compilers != null) {
      for (var compiler in compilers) {
        args.addAll(['--compiler', compiler]);
      }
    } else if (compiler != null) {
      args.addAll(['--compiler', compiler!]);
    }
  }

  /// List of arguments
  final args = <String>[];

  /// true is non empty.
  bool get isNotEmpty => args.isNotEmpty;

  /// To command line argument.
  String toCommandLineArgument() =>
      '${args.isEmpty ? '' : ' '}${args.join(' ')}';
}

/// Test running configuration.
class TestConfig {
  final _lines = <TestConfigLine>[];

  /// List of arguments
  final args = <String>[];

  /// true is non empty.
  bool get isNotEmpty => args.isNotEmpty || _lines.isNotEmpty;

  /// DEPRECATED: use toDartTestCommandLineArgument
  ///
  /// To command line argument.
  /// @Deprecated('use toDartTestCommandLineArgument')
  String toCommandLineArgument() =>
      '${args.isEmpty ? '' : ' '}${args.join(' ')}';

  /// Config lines
  List<TestConfigLine> get configLines => _lines;

  /// Config lines (trimmed) for testing
  @visibleForTesting
  List<String> get configLineTexts =>
      configLines.map((e) => e.toCommandLineArgument().trim()).toList();

  /// true if has node supports in test.
  bool hasNode = false;
}

/// build test config on the supported platforms and dart_test.yaml config map.
TestConfig buildTestConfig(
    {List<String>? platforms,
    List<String>? supportedPlatforms,
    Map? dartTestMap,
    bool? noWasm}) {
  var testConfig = TestConfig();

  platforms = platforms?.toList() ?? <String>[];
  if (dartTestMap != null) {
    try {
      List<String> toStringList(Object? value) {
        if (value is String) {
          return [value];
        }
        if (value is List) {
          return value.cast<String>();
        }
        return <String>[];
      }

      var dartTestPlatforms = toStringList(dartTestMap['platforms']);
      if (dartTestPlatforms.isNotEmpty) {
        if (supportedPlatforms != null) {
          platforms.clear();
          for (var platform in dartTestPlatforms) {
            if (supportedPlatforms.contains(platform) &&
                !platforms.contains(platform)) {
              platforms.add(platform);
            }
          }
        } else {
          platforms
              .removeWhere((platform) => !dartTestPlatforms.contains(platform));
        }
      }
      var dartCompilers = toStringList(dartTestMap['compilers']);
      var dartSupportedWebCompilers = [
        'dart2js',
        if (!(noWasm ?? false)) 'dart2wasm'
      ];
      var dartWebPlatforms = ['chrome', 'firefox', 'safari'];
      var dartWebCompilers = <String>[];
      for (var supportedWebCompiler in dartSupportedWebCompilers) {
        if (dartCompilers.contains(supportedWebCompiler) &&
            !dartWebCompilers.contains(supportedWebCompiler)) {
          dartWebCompilers.add(supportedWebCompiler);
        }
      }

      for (var platform in platforms) {
        if (dartWebCompilers.isNotEmpty &&
            dartWebPlatforms.contains(platform)) {
          for (var compiler in dartWebCompilers) {
            testConfig.args.add('--compiler $compiler');
          }
          testConfig.configLines.add(
              TestConfigLine(compilers: dartWebCompilers, platform: platform));
          testConfig.args.add('--platform $platform');
        } else {
          if (platform == 'node') {
            testConfig.hasNode = true;
            // Force dart2js
            testConfig.configLines
                .add(TestConfigLine(platform: platform, compiler: 'dart2js'));
          } else {
            testConfig.configLines.add(TestConfigLine(platform: platform));
          }
          testConfig.args.add('--platform $platform');
        }
      }
    } catch (e) {
      // ignore: avoid_print
      print('Error: $e');
    }
  } else {
    if (platforms.isNotEmpty) {
      for (var platform in platforms) {
        testConfig.args.add('--platform $platform');
        testConfig.configLines.add(TestConfigLine(platform: platform));
      }
    } else {
      // Generic (no args)
      testConfig.configLines.add(TestConfigLine());
    }
  }
  return testConfig;
}
