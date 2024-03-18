import 'package:dev_build/src/menu/menu_presenter.dart';

import 'declarer.dart';
import 'dev_menu.dart';

import 'menu_manager.dart';

/// Test runner.
class Runner {
  /// Test menu declarer.
  Declarer declarer;

  /// Test menu presenter.
  Runner(this.declarer);

  /// run.
  Future<void> run() async {
    final menu = declarer.devMenu;
    if (MenuManager.debug.on) {
      // ignore: avoid_print
      print('[Runner] menu $menu');
    }
    if (menu.length == 0 && menu.enters.isEmpty) {
      write('No menu or item declared');
      // no longer exit, so that we handle the enter/leave
      //return;
    } else {
      /*
      if (menu.length == 1 && (menu[0] is MenuMenuItem)) {
        if (MenuManager.debug.on) {
          print('[Runner] single main menu');
        }
        MenuMenuItem item = menu[0] as MenuMenuItem;
        menu = item.menu;
      }
      */
    }

    //List<List<MenuItem> >
    final tree = <DevMenu>[];
    List<DevMenu>? soloTree;
    RunnableMenuItem? soloMenuItem;
    Future handleSolo(DevMenu menu) async {
      tree.add(menu);

      // handle solo_menu
      if (menu.solo == true) {
        soloTree = List.from(tree);
      }

      for (final item in menu.items) {
        if (item is RunnableMenuItem) {
          // handle solo_item
          if (item.solo == true) {
            soloMenuItem = item;
            soloTree = List.from(tree);
            //        await menuManager.runItem(item);

            //await item.run();
          }
        } else if (item is MenuMenuItem) {
          await handleSolo(item.menu);
        }
      }
      tree.remove(menu);
    }

    // look for solo stuff
    await handleSolo(menu);

    final hasSolo = soloTree != null;
    if (!hasSolo) {
      await pushMenu(menu);
    } else {
      for (var menu in soloTree!) {
        await pushMenu(menu);
      }
      try {
        if (soloMenuItem != null) {
          await menuManager.runItem(soloMenuItem!);
        }
      } catch (e, st) {
        // ignore: avoid_print
        print(e);
        // ignore: avoid_print
        print(st);
      }
    }
  }

  /// Write a line on the presenter.
  void write(Object message) {
    menuPresenter.write(message);
  }
}

/// current runner
Runner? runner;
