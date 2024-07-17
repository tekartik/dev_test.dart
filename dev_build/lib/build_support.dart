export 'package:dev_build/src/mixin/package.dart'
    show
        pubspecYamlHasAnyDependencies,
        pubspecYamlGetSdkBoundaries,
        pubspecYamlGetVersion,
        pubspecYamlGetPackageName,
        pubspecYamlSupportsFlutter,
        pubspecYamlSupportsNode,
        pubspecYamlSupportsTest,
        pubspecYamlSupportsWeb,
        VersionBoundaries,
        VersionBoundaryVersionExt,
        VersionBoundary,
        pathGetAnalysisOptionsYamlMap,
        pathGetPubspecYamlMap,
        pathGetPackageConfigMap,
        packageConfigGetPackages;
export 'package:dev_build/src/node_support.dart'
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
        flutterTemplatePackage,
        flutterCreateProject,
        buildInitDart,
        dartTemplateConsoleSimple,
        dartTemplateConsole,
        dartTemplatePackage,
        dartTemplateWeb,
        dartCreateProject,
        pathPackageConfigMapGetPackagePath;
export 'src/pub_global.dart'
    show checkAndActivateWebdev, checkAndActivatePackage;
