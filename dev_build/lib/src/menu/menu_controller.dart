import 'package:dev_build/src/menu/menu.dart';

import 'dev_menu.dart';

/// Test menu controller.
class DevMenuController {
  /// Declare your menu using item/menu.
  final void Function() declare;

  /// [declare your menu using item/menu
  DevMenuController(this.declare);

  DevMenu? _menu;

  /// Resulting menu
  DevMenu get menu =>
      _menu ??= () {
        var declarer = menuNewDeclarer();
        declare();
        return declarer.devMenu;
      }();
}
