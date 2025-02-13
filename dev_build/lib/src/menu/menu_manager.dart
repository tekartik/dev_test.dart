import 'package:dev_build/src/menu/menu.dart';
import 'package:dev_build/src/menu/menu_presenter.dart';
import 'package:synchronized/synchronized.dart';
import 'dev_flag.dart';
import 'dev_menu.dart';
import 'menu_runner.dart';

/// Test menu manager.
bool get debugMenuManager => MenuManager.debug.on;

// There is only one test menu manager
MenuManager? _menuManager;

/// Get the test menu manager or null if not initialized.
MenuManager? get menuManagerOrNull => _menuManager;

/// Get the test menu manager.
MenuManager get menuManager {
  _menuManager ??= MenuManager(menuPresenter);
  return _menuManager!;
}

set menuManager(MenuManager? menuManager) => _menuManager = menuManager;

/// Initialize the test menu manager.
void initMenuManager() {}

/// Push a menu.
Future pushMenu(DevMenu menu) async {
  initMenuManager();
  return await menuManager.pushMenu(menu);
}

/// Pop a menu.
Future<bool> popMenu() async {
  return await menuManager.popMenu();
}

/// Process a menu.
Future processMenu(DevMenu menu) async {
  return await menuManager.processMenu(menu);
}

/// The test menu manager.
class MenuManager {
  /// The presenter.
  final MenuPresenter presenter;

  /// The lock.
  var lock = Lock(reentrant: true);

  /// The debug flag.
  static final DevFlag debug = DevFlag('MenuManager');

  //Menu displayedMenu;
  /// The menu runners.
  Map<DevMenu, MenuRunner> menuRunners = {};

  /// The active menu runner.
  MenuRunner? get activeMenuRunner {
    if (stackMenus.isNotEmpty) {
      return stackMenus.last;
    }
    return null;
  }

  /// The active menu.
  DevMenu? get activeMenu => activeMenuRunner?.menu;

  /// The stack of menus.
  List<MenuRunner> get stackMenus => _stackMenus;
  final _stackMenus = <MenuRunner>[];

  /// The stack of menus from a hash
  static List<String> initCommandsFromHash(String hash) {
    if (debugMenuManager) {
      // ignore: avoid_print
      print('hash: $hash');
    }
    final firstHash = hash.indexOf('#');
    if (firstHash == 0) {
      final nextHash = hash.indexOf('#', 1);
      if (nextHash < 0) {
        hash = hash.substring(1);
      } else {
        hash = hash.substring(firstHash + 1, nextHash);
      }
    } else if (firstHash > 0) {
      hash = hash.substring(0, firstHash);
    }
    final commands = hash.split('_');

    if (debugMenuManager) {
      // ignore: avoid_print
      print('hash: $hash commands: $commands');
    }
    return commands;
  }

  /// The test menu manager.
  MenuManager(this.presenter) {
    // unique?
    menuManager = this;
  }

  /// Push a menu.
  Future<bool> pushMenu(DevMenu menu) async {
    if (_push(menu)) {
      if (MenuManager.debug.on) {
        write('[mgr] push presenting $menu');
      }
      presenter.presentMenu(menu);

      //eventually process init items
      await menuRunners[menu]?.enter();

      await processMenu(menu);
    }
    return true;
  }

  /// Return when closed!
  Future showMenu(DevMenu menu) async {
    await pushMenu(menu);
    await menuRunners[menu]!.done;
  }

  /// menu already present?
  bool stackContainsMenu(DevMenu menu) {
    return menuRunners[menu] != null;
  }

  bool _push(DevMenu menu) {
    if (stackContainsMenu(menu)) {
      return false;
    }
    if (menu.parent != null) {
      if (!stackContainsMenu(menu.parent!)) {
        if (!_push(menu.parent!)) {
          // ignore: avoid_print
          print('cant push ${menu.parent}');
          return false;
        }
      }
    }
    if (MenuManager.debug.on) {
      write('[mgr] pushMenu $menu to ${menuManager.stackMenus}');
    }
    // Make sure parent runner exists
    final runner = MenuRunner(activeMenuRunner, menu);
    return _pushMenuRunner(runner);
  }

  bool _pushMenuRunner(MenuRunner menuRunner) {
    //if (stackMenus.contains(menuRunner)) {
    //  return false;
    //}
    menuRunners[menuRunner.menu] = menuRunner;
    stackMenus.add(menuRunner);
    return true;
  }

  /// Can pop.
  bool canPop([int count = 1]) {
    return activeDepth >= count;
  }

  /// Pop a menu.
  Future<bool> popMenu([int count = 1]) async {
    final activeMenuRunner = this.activeMenuRunner;
    if (MenuManager.debug.on) {
      write('[mgr] poping $activeMenuRunner from ${menuManager.stackMenus}');
    }
    final poped = _pop(count);
    if (poped && activeMenuRunner != null) {
      await activeMenuRunner.leave();
      if (MenuManager.debug.on) {
        write('[mgr] pop presenting ${this.activeMenuRunner!.menu}');
      }
      presenter.presentMenu(this.activeMenuRunner!.menu);
    }
    return poped;
  }

  /*
  @deprecated
  bool pop([int count = 1]) {
    if (_pop(count)) {
      presentMenu(activeMenu);
      return true;
    }
    return false;
  }
  */

  bool _pop([int count = 1]) {
    if (MenuManager.debug.on) {
      write('$stackMenus poping $count');
    }

    if (stackMenus.length > count) {
      if (MenuManager.debug.on) {
        write('$stackMenus after poping $count');
      }
      // Remove and clear menuRunners
      final start = stackMenus.length - count;
      final end = stackMenus.length;
      final removedRunner = stackMenus.sublist(start, end);
      for (final menuRunner in removedRunner) {
        menuRunners.remove(menuRunner.menu);
      }
      stackMenus.removeRange(start, end);

      if (MenuManager.debug.on) {
        write('$stackMenus after poping $count');
      }
      return true;
    }
    return false;
  }

  /// The active depth.
  int get activeDepth {
    return stackMenus.length - 1;
  }

  /// Get or create the runner for a given item
  MenuRunner getRunner(WithParent item) {
    if (item.parent is! RootMenu) {
      getRunner(item.parent!);
    }
    var runner = menuRunners[item.parent];
    if (runner == null) {
      //devPrint('getRunner $item');

      _push(item.parent!);
      runner = menuRunners[item.parent];
    }
    return runner!;
  }

  /// make sure the menu is entered first
  Future runItem(DevMenuItem item) async {
    // await _enterMenu(item.parent);
    final runner = getRunner(item);
    //await runner.enter();
    if (item is MenuMenuItem) {
      await pushMenu(item.menu);
    } else {
      // Update hash in browser for example
      await menuPresenter.preProcessItem(item);
      await runner.run(item);
    }
  }

  /// Commands executed on startup
  List<String>? initCommands;

  /// Stop.
  void stop() {
    // _inCommandSubscription.cancel();
  }

  /// Process a command line
  Future processLine(String line) async {
    final menu = activeMenu;
    //devPrint('Line: $line / Menu $menu');

    var value = int.tryParse(line);
    if (value == null) {
      if (line == '-') {
        // ignore: avoid_print
        // print('pop');

        value = -1;
      }
      //         if (textValue == '.') {
      //           _displayMenu(menu);
      //           return null;
      //         }
      //         print('errorValue: $textValue');
      //         print('- exit');
      //         print('. display menu again');
    }
    if (value == -1) {
      if (!await popMenu()) {
        stop();
      }
    } else {
      if (value != null) {
        if (value >= 0 && value < menu!.length) {
          return runItem(menu[value]);
          // }
          //        if (value == -1) {
          //          break;
          //        };
        }
      }
    }
  }

  bool _initCommandHandled = false;

  /// Process current menu.
  /// Run initial commands if needed first

  Future processMenu(DevMenu menu) async {
    if (!_initCommandHandled) {
      _initCommandHandled = true;

      final initCommands = this.initCommands;
      if (initCommands != null) {
        for (final initCommand in initCommands) {
          await processLine(initCommand);
        }
      }
    }
  }

  /*
  @deprecated
  void onProcessMenu(Menu menu) {
    if (!_initCommandHandled) {
      _initCommandHandled = true;

      List<String> initCommands = this.initCommands;
      Future _processLine(int index) {
        if (initCommands != null && index < initCommands.length) {
          return processLine(initCommands[index]).then((_) {
            return _processLine(index + 1);
          });
        }
        return new Future.value();
      }

      _processLine(0);
    }
  }
  */

  //void onProcessItem(MenuItem item) {}
}
