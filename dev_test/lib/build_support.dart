export 'package:dev_test/src/mixin/package.dart'
    show
        pubspecYamlHasAnyDependencies,
        pubspecYamlGetSdkBoundaries,
        pubspecYamlGetVersion,
        pubspecYamlSupportsFlutter,
        pubspecYamlSupportsNode,
        pubspecYamlSupportsTest,
        pubspecYamlSupportsWeb,
        VersionBoundaries,
        VersionBoundary,
        pathGetAnalysisOptionsYamlMap,
        pathGetPubspecYamlMap;
export 'package:dev_test/src/node_support.dart'
    show nodeSetupCheck, isNodeSupportedSync;
export 'package:process_run/shell.dart' show isFlutterSupportedSync;

export 'src/build_support.dart'
    show
        buildSupportsAndroid,
        buildSupportsIOS,
        buildSupportsLinux,
        buildSupportsMacOS,
        buildSupportsWindows,
        buildInitFlutter,
        pathPubspecAddDependency,
        pathPubspecGetDependencyLines,
        pathPubspecRemoveDependency,
        flutterTemplateApp,
        flutterCreateProject,
        buildInitDart,
        dartTemplateConsoleSimple,
        dartCreateProject;
