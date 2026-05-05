library;

import 'package:dev_build/menu/menu.dart';
import 'package:test/test.dart';

void main() {
  group('test_menu', () {
    //MenuManager.debug.on
    test('solo', () async {
      var ran = false;

      // ignore: invalid_use_of_do_not_submit_member
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

    test('enterItem and leaveItem called around solo item', () async {
      var log = <String>[];

      menu('main', () {
        enterItem(() async {
          log.add('enter_item');
          await Future<void>.delayed(const Duration(milliseconds: 1));
        });
        enterItem(() {
          log.add('enter_item_2');
        });
        leaveItem(() async {
          log.add('leave_item');
          await Future<void>.delayed(const Duration(milliseconds: 1));
        });
        leaveItem(() {
          log.add('leave_item_2');
        });
        // ignore: invalid_use_of_do_not_submit_member
        solo_item('test', () {
          log.add('item');
        });
      });

      await menuRun();
      expect(log, [
        'enter_item',
        'enter_item_2',
        'item',
        'leave_item',
        'leave_item_2',
      ]);
    });

    test('leaveItem called even when item throws', () async {
      var log = <String>[];
      menu('main', () {
        leaveItem(() {
          log.add('leave_item');
        });
        // ignore: invalid_use_of_do_not_submit_member
        solo_item('test', () {
          log.add('test');
          throw 'boom';
        });
      });

      await menuRun();
      expect(log, ['test', 'leave_item']);
    });
  });
}
