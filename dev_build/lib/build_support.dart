export 'package:dev_build/src/mixin/package.dart'
    show
        pubspecYamlHasAnyDependencies,
        pubspecYamlGetSdkBoundaries,
        pubspecYamlGetVersion,
        pubspecYamlGetVersionOrNull,
        pubspecYamlGetPackageName,
        pubspecYamlSupportsFlutter,
        pubspecYamlIsWorkspaceRoot,
        pubspecYamlHasWorkspaceResolution,
        pubspecYamlSupportsNode,
        pubspecYamlSupportsTest,
        pubspecYamlSupportsWeb,
        VersionBoundaries,
        VersionBoundaryVersionExt,
        VersionBoundary,
        pathGetAnalysisOptionsYamlMap,
        pathGetPubspecYamlMap,
        pathGetPackageConfigMap,
        packageConfigGetPackages,
        PubDependencyKind,
        pubspecYamlGetDependenciesPackageName,
        pubspecYamlGetDependenciesMap;
export 'package:dev_build/src/node_support.dart'
    show nodeSetupCheck, isNodeSupportedSync;
export 'package:process_run/shell.dart' show isFlutterSupportedSync;

export 'package.dart' show VersionBoundaries;
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
        dartCreateProject;
export 'src/dev_build_support.dart' show checkOrPubActivateDevBuild;
export 'src/package/package_io_impl.dart'
    show pathPackageConfigMapGetPackagePath, pathGetResolvedPackagePath;
export 'src/pub_global.dart'
    show checkAndActivateWebdev, checkAndActivatePackage;
export 'src/pub_io.dart'
    show
        isPubPackageRootSync,
        isPubPackageRoot,
        getPubPackageRoot,
        getPubPackageRootSync;
