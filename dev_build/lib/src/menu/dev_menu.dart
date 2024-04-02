import 'dart:async';

import 'menu_manager.dart';

/// A menu child.
abstract class WithParent {
  /// The parent menu.
  DevMenu? get parent;

  set parent(DevMenu? parent);
}

mixin class _WithParentMixin implements WithParent {
  @override
  DevMenu? parent;
}

/// MenuItem Base.
abstract class MenuItemBase {
  /// The command to trigger this item.
  String? get cmd;

  /// The name of the item.
  String get name;
}

/// A menu item.
abstract class DevMenuItem
    with DevMenuOrItemMixin
    implements Runnable, WithParent, MenuItemBase {
  /// The command to trigger this item.
  @override
  String? get cmd;

  /// The name of the item.
  @override
  String get name;

  /// A menu item.
  factory DevMenuItem.fn(String name, MenuItemFn fn,
      {String? cmd, bool? solo}) {
    return RunnableMenuItem(name, fn, cmd: cmd, solo: solo);
  }

  /// A menu item as a sub menu.
  factory DevMenuItem.menu(DevMenu menu) {
    return MenuMenuItem(menu);
  }
}

/// A test item function.
typedef MenuItemFn<R> = R? Function();

/// A test command function.
typedef TestCommandFn<R> = R Function(String command);

abstract class _BaseMenuItem {
  final bool? solo;
  String name;

  String? get cmd;

  _BaseMenuItem(this.name, this.solo);

  @override
  String toString() {
    return name;
  }
}

/// A runnable item.
abstract class Runnable {
  /// Run the item.
  Object? run();
}

mixin class _RunnableMixin implements Runnable {
  late MenuItemFn fn;

  @override
  Object? run() {
    return fn();
  }
}

/// Menu enter.
class MenuEnter extends Object with _RunnableMixin, _WithParentMixin {
  /// The enter function.
  MenuEnter(MenuItemFn fn) {
    this.fn = fn;
  }

  @override
  String toString() {
    return 'enter';
  }
}

/// Menu command (?, ., -)
class MenuCommand extends Object with _WithParentMixin {
  /// The command function.
  final TestCommandFn fn;

  /// Menu command.
  MenuCommand(this.fn);

  @override
  String toString() {
    return 'command';
  }
}

/// Menu leave.
class MenuLeave extends Object with _RunnableMixin, _WithParentMixin {
  /// The leave function.
  MenuLeave(MenuItemFn fn) {
    this.fn = fn;
  }

  @override
  String toString() {
    return 'leave';
  }
}

/// A runnable test item.
class RunnableMenuItem extends _BaseMenuItem
    with _RunnableMixin, _WithParentMixin
    implements DevMenuItem {
  @override
  String? cmd;

  /// A runnable test item.
  RunnableMenuItem(String name, MenuItemFn fn, {this.cmd, bool? solo})
      : super(name, solo) {
    this.fn = fn;
  }

  /// If the item is test (if its parent is a group)
  bool? get test => parent?.group == true;
}

/// A menu test item.
class MenuMenuItem extends _BaseMenuItem
    with _WithParentMixin
    implements DevMenuItem {
  /// The menu.
  DevMenu menu;

  @override
  String? get cmd => menu.cmd;

  /// A menu test item.
  MenuMenuItem(this.menu) : super(menu.name, menu.solo);

  @override
  Future run() async {
    await menuManager.pushMenu(menu);
  }

  @override
  String toString() {
    return 'menu ${super.toString()}';
  }
}

/// The root test menu.
class RootMenu extends DevMenu {
  /// The root test menu.
  RootMenu() : super('_root_');
}

/// A test object.
abstract class TestObject {}

/// A menu or item mixin.
mixin DevMenuOrItemMixin implements MenuItemBase {}

/// A test menu.
class DevMenu extends Object
    with _WithParentMixin, DevMenuOrItemMixin
    implements TestObject {
  @override
  final String? cmd;
  @override
  final String name;

  /// The group flag.
  final bool? group;

  /// The solo flag.
  final bool? solo;
  final _items = <DevMenuItem>[];

  /// The items.
  List<DevMenuItem> get items => _items;

  /// The length of the items.
  int get length => _items.length;

  /// A test menu.
  DevMenu(this.name, {this.cmd, this.group, this.solo});

  final _enters = <MenuEnter>[];
  final _leaves = <MenuLeave>[];
  MenuCommand? _command;

  /// The menu enters.
  Iterable<MenuEnter> get enters => _enters;

  /// The menu leaves.
  Iterable<MenuLeave> get leaves => _leaves;

  /// The default command handlers.
  MenuCommand? get command => _command;

  /// Add a test item.
  void add(String name, MenuItemFn fn) => addItem(DevMenuItem.fn(name, fn));

  /// fix a parent.
  void fixParent(WithParent child) {
    child.parent = this;
  }

  /// Add a menu enter.
  void addEnter(MenuEnter menuEnter) {
    fixParent(menuEnter);
    _enters.add(menuEnter);
  }

  /// Add a menu leave.
  void addLeave(MenuLeave menuLeave) {
    fixParent(menuLeave);
    _leaves.add(menuLeave);
  }

  /// Add a menu.
  void addMenu(DevMenu menu) {
    fixParent(menu);
    addItem(DevMenuItem.menu(menu));
  }

  /// Add a test item.
  void addItem(DevMenuItem item) {
    fixParent(item);
    _items.add(item);
  }

  /// Set the default command handler.
  void setCommand(MenuCommand menuCommand) {
    fixParent(menuCommand);
    _command = menuCommand;
  }

  /// Add all items.
  void addAll(List<DevMenuItem> items) {
    for (var item in items) {
      addItem(item);
    }
  }

  /// Get the item at index.
  DevMenuItem operator [](int index) => _items[index];

  /// Get the item by command.
  DevMenuItem? byCmd(String cmd) {
    for (final item in _items) {
      if (item.cmd == cmd) {
        return item;
      }
    }
    final value = int.tryParse(cmd) ?? -1;

    if (value >= 0 && value < length) {
      return _items[value];
    }
    return null;
  }

  @override
  String toString() {
    return "tm'$name'";
  }

  /// Get the index of the item.
  int indexOfItem(DevMenuItem item) {
    return _items.indexOf(item);
  }

  /// Get the index of the menu.
  int indexOfMenu(DevMenu menu) {
    for (var i = 0; i < _items.length; i++) {
      final item = _items[i];
      if (item is MenuMenuItem) {
        if (item.menu == menu) {
          return i;
        }
      }
    }
    return -1;
  }
}
