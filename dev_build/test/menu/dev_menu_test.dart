import 'package:dev_build/src/menu/dev_menu.dart';
import 'package:test/test.dart';

void main() {
  group('src_test_menu', () {
    test('function', () {
      var ran = false;
      final item = DevMenuItem.fn('test', () {
        ran = true;
      });
      expect(item.name, 'test');
      expect(ran, false);
      item.run();
      expect(ran, true);
    });

    test('enter', () {
      var ran = false;
      final enter = MenuEnter(() {
        ran = true;
      });
      expect(ran, false);
      enter.run();
      expect(ran, true);
    });

    test('leave', () {
      var ran = false;
      final leave = MenuLeave(() {
        ran = true;
      });
      expect(ran, false);
      leave.run();
      expect(ran, true);
    });

    test('menu', () {
      final menu = DevMenu('menu');
      final item = DevMenuItem.menu(menu);
      expect(item.name, 'menu');
    });
  });

  group('test menu', () {
    test('list', () {
      final menu = DevMenu('menu');
      expect(menu.name, 'menu');
      final item = DevMenuItem.fn('test', () => null);
      menu.addItem(item);
      expect(menu[0], item);
    });
  });
}
