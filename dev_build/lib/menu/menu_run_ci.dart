/// A ready-made console menu for a package (`runCiMenu`: pub get, upgrade,
/// downgrade, run_ci, analyze, format) and `PubIoPackage`.
library;

export 'package:dev_build/src/io/run_ci_menu.dart' show runCiMenu;
export 'package:dev_build/src/package/pub_io_package.dart'
    show PubIoPackage, PubIoPackageOptions;
