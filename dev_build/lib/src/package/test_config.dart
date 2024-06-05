/// Test running configuration.
class TestConfig {
  /// List of arguments
  final args = <String>[];

  /// true is non empty.
  bool get isNotEmpty => args.isNotEmpty;

  /// To command line argument.
  String toCommandLineArgument() =>
      '${args.isEmpty ? '' : ' '}${args.join(' ')}';
}

/// build test config on the supported platforms and dart_test.yaml config map.
TestConfig buildTestConfig(
    {List<String>? platforms,
    List<String>? supportedPlatforms,
    Map? dartTestMap}) {
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
        if (supportedPlatforms?.isNotEmpty ?? false) {
          platforms.clear();
          for (var platform in dartTestPlatforms) {
            if (supportedPlatforms!.contains(platform) &&
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
      var dartSupportedWebCompilers = ['dart2js', 'dart2wasm'];
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
            testConfig.args.add('--platform $platform --compiler $compiler');
          }
        } else {
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
      }
    }
  }
  return testConfig;
}
