library test_menu_test;

import 'package:dev_build/src/menu/dev_menu.dart';
import 'package:dev_build/src/menu/menu.dart';
import 'package:dev_build/src/menu/menu_manager.dart';
import 'package:dev_build/src/menu/menu_presenter.dart';
import 'package:test/test.dart';

class MenuPresenter1 extends Object
    with MenuPresenterMixin
    implements MenuPresenter {
  String? text;

  MenuPresenter1() {
    // set as presenter
    menuPresenter = this;
  }

  late DevMenu menu;

  @override
  void presentMenu(DevMenu menu) {
    this.menu = menu;
  }

  @override
  Future<String?> prompt(Object? message) async {
    return null;
  }

  @override
  void write(Object message) {
    text = message.toString();
  }
}

void main() {
  group('test_menu_presenter', () {
    test('test_menu', () async {
      var presenter = MenuPresenter1();
      //menu('test', () {});
      await menuRun();
      write('some text');

      // presenter is still null
      expect(presenter.menu.name, '_root_');
      expect(presenter.text, 'some text');
      //expect(presenter.menu.name, 'test');
      //expect(presenter.text, 'some text');
    });

    test('enter_only', () async {
      var ran = false;

      // We always need a presenter
      NullMenuPresenter();
      enter(() {
        ran = true;
      });

      await menuRun();
      expect(ran, isTrue);
    });

    test('enter_then_item', () async {
      var ran = false;
      var ranEnter = false;

      // We always need a presenter
      NullMenuPresenter();
      enter(() async {
        await Future<void>.delayed(const Duration(milliseconds: 1));
        ranEnter = true;
      });
      item('test', () {
        expect(ranEnter, isTrue);
        ran = true;
      });

      menuManager.initCommands = ['0'];
      await menuRun();
      expect(ran, isTrue);
    });
  });

  /*
      MenuItem item = new MenuItem.fn('test', () {
        ran = true;
      });
      expect(item.name, 'test');
      expect(ran, false);
      item.run();
      expect(ran, true);
    });

    test('menu', () {
      Menu menu = new Menu('menu');
      MenuItem item = new MenuItem.menu(menu);
      expect(item.name, 'menu');
    });
  });

  group('test menu', () {
    test('list', () {
      Menu menu = new Menu('menu');
      expect(menu.name, 'menu');
      MenuItem item = new MenuItem.fn('test', () => null);
      menu.addItem(item);
      expect(menu[0], item);
    });
  });
  */
}
