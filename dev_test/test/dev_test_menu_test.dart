@TestOn('vm')
library;

// ignore_for_file: implementation_imports
import 'package:dev_build/src/menu/dev_menu.dart';
import 'package:dev_build/src/menu/menu.dart' show menuNewDeclarer;
import 'package:dev_build/src/menu/menu_manager.dart';
import 'package:dev_build/src/menu/menu_presenter.dart';
import 'package:dev_test/src/dev_test_menu.dart' show DevTestMenu;
import 'package:test/test.dart';

/// The item named [name] of [menu].
DevMenuItem menuItem(DevMenu menu, String name) =>
    menu.items.firstWhere((item) => item.name == name);

/// The menu of the sub menu named [name] of [menu].
DevMenu subMenu(DevMenu menu, String name) =>
    (menuItem(menu, name) as MenuMenuItem).menu;

void main() {
  group('dev_test_menu', () {
    late DevMenu root;
    late DevTestMenu devTest;
    late List<String> calls;

    setUp(() {
      // No output, a new menu manager.
      NullMenuPresenter();
      root = menuNewDeclarer().devMenu;
      devTest = DevTestMenu();
      calls = <String>[];
    });

    test('setUp and tearDown of the parent groups', () async {
      devTest.setUp(() => calls.add('root setUp'));
      devTest.tearDown(() => calls.add('root tearDown'));
      devTest.group('outer', () {
        devTest.setUp(() => calls.add('outer setUp 1'));
        devTest.setUp(() async => calls.add('outer setUp 2'));
        devTest.tearDown(() => calls.add('outer tearDown 1'));
        devTest.tearDown(() async => calls.add('outer tearDown 2'));
        devTest.test('direct', () => calls.add('direct'));
        devTest.group('inner', () {
          devTest.setUp(() => calls.add('inner setUp'));
          devTest.tearDown(() => calls.add('inner tearDown'));
          devTest.test('nested', () async => calls.add('nested'));
        });
      });
      var outer = subMenu(root, 'outer');
      await menuManager.runItem(menuItem(subMenu(outer, 'inner'), 'nested'));
      // Same order as package:test.
      expect(calls, [
        'root setUp',
        'outer setUp 1',
        'outer setUp 2',
        'inner setUp',
        'nested',
        'inner tearDown',
        'outer tearDown 2',
        'outer tearDown 1',
        'root tearDown',
      ]);
      calls.clear();
      await menuManager.runItem(menuItem(outer, 'direct'));
      expect(calls, [
        'root setUp',
        'outer setUp 1',
        'outer setUp 2',
        'direct',
        'outer tearDown 2',
        'outer tearDown 1',
        'root tearDown',
      ]);
    });

    test('setUp declared after the test', () async {
      devTest.group('group', () {
        devTest.test('test', () => calls.add('test'));
        devTest.setUp(() => calls.add('setUp'));
      });
      await menuManager.runItem(menuItem(subMenu(root, 'group'), 'test'));
      expect(calls, ['setUp', 'test']);
    });

    test('tearDowns run after a failing setUp', () async {
      devTest.tearDown(() => calls.add('root tearDown'));
      devTest.group('group', () {
        devTest.setUp(() => throw StateError('setUp failed'));
        devTest.tearDown(() => calls.add('tearDown'));
        devTest.test('test', () => calls.add('test'));
      });
      await expectLater(
        menuManager.runItem(menuItem(subMenu(root, 'group'), 'test')),
        throwsStateError,
      );
      expect(calls, ['tearDown', 'root tearDown']);
      expect(menuManager.lastRunFailed, isTrue);
    });

    test('a failing test still runs the tearDowns', () async {
      devTest.group('group', () {
        devTest.tearDown(() => calls.add('tearDown'));
        devTest.test('test', () async {
          await Future<void>.value();
          throw StateError('test failed');
        });
      });
      await expectLater(
        menuManager.runItem(menuItem(subMenu(root, 'group'), 'test')),
        throwsStateError,
      );
      expect(calls, ['tearDown']);
    });
  });
}
