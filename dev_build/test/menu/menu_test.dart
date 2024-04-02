library test_menu_test;

import 'package:dev_build/menu/menu.dart';
import 'package:test/test.dart';

void main() {
  group('test_menu', () {
    //MenuManager.debug.on
    test('solo', () async {
      var ran = false;

      // ignore: deprecated_member_use, deprecated_member_use_from_same_package
      solo_item('test', () {
        ran = true;
      });

      await menuRun();
      expect(ran, isTrue);
    });

    test('enter', () async {
      var ran = false;

      enter(() {
        ran = true;
      });

      await menuRun();
      expect(ran, isTrue);
    });
  });
}
