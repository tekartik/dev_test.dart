//import 'test_menu.dart';

//import '../common.dart';

/*
abstract class Callback {
  Menu parent;
  _Body body;
  var declareStackTrace;

  /// test group setUp or tearDown
  String get type {
    String type = runtimeType.toString();
    type = "${type[0].toLowerCase()}${type.substring(1)}";
    return type;
  }

  /// base implementation return the parent description
  List<String> get descriptions {
    if (parent != null) {
      return parent.descriptions;
    } else {
      return [];
    }
  }

  @override
  String toString() => '$type: $descriptions';

  @override
  int get hashCode => descriptions.length;

  // This is for testing mainly
  // 2 tests are the same if they have the same description
  @override
  bool operator ==(o) =>
      const ListEquality().equals(descriptions, o.descriptions);

  void declare();
}

*/

import 'dev_menu.dart';
// Not public
import 'runner.dart';

/// Test menu declarer.
class Declarer {
  /// current test menu
  DevMenu devMenu = RootMenu();

  /// Menu, running body.
  void menu(String name, void Function() body,
      {String? cmd, bool? group, bool? solo}) {
    final parentMenu = devMenu;

    final newMenu = DevMenu(name, cmd: cmd, group: group, solo: solo);
    parentMenu.addMenu(newMenu);

    devMenu = newMenu;
    body();
    devMenu = parentMenu;
  }

  /// Run a command.
  void command(dynamic Function(String command) body) {
    final command = MenuCommand(body);
    devMenu.setCommand(command);
  }

  /// Enter a menu.
  void enter(dynamic Function() body) {
    final enter = MenuEnter(body);
    devMenu.addEnter(enter);
  }

  /// Leave a menu.
  void leave(dynamic Function() body) {
    final leave = MenuLeave(body);
    devMenu.addLeave(leave);
  }

  /// Menu item.
  void item(String name, dynamic Function() body, {String? cmd, bool? solo}) {
    final item = DevMenuItem.fn(name, body, cmd: cmd, solo: solo);
    devMenu.addItem(item);
    //_menu.add("print hi", () => print('hi'));
  }

  /// Run the menu.
  Future<void> run() async {
    // simply show top menu, if empty exit, other go directly in sub menu
    //_menu.length

    var newRunner = runner = Runner(this);
    await newRunner.run();

    //TODO wait for completion
    // return runner;
  }
}
