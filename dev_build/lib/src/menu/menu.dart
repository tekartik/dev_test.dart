library;

import 'dart:async';

import 'package:meta/meta.dart';

import 'declarer.dart';
import 'menu_controller.dart';
import 'menu_manager.dart';
import 'menu_presenter.dart';

export 'menu_manager.dart' show MenuManager;

///
/// The declarer class handling the logic
///
Declarer? __declarer;

Declarer? get _declarer {
  if (__declarer == null) {
    __declarer = Declarer();
    if (__declarer!.autoRun) {
      scheduleMicrotask(() {
        if (__declarer!.autoRun) {
          // An automatic microtask is run after the menu is declarer
          menuRun();
        }
      });
    }
  }
  return __declarer;
}

/// New test menu declarer
Declarer menuNewDeclarer() {
  var declarer = __declarer = Declarer();
  return declarer;
}

///
/// Declare a menu
///
/// declaration must be sync
///
void menu(
  String name,
  void Function() body, {
  String? cmd,
  bool? group,
  @doNotSubmit bool? solo,
}) {
  _declarer!.menu(name, body, cmd: cmd, group: group, solo: solo);
}

///
/// Declare a menu item
///
/// can return a future
///
/// @param cmd command shortcut (instead of incremental number)
void item(
  String name,
  dynamic Function() body, {
  String? cmd,
  @doNotSubmit bool? solo,
}) {
  _declarer!.item(name, body, cmd: cmd, solo: solo);
}

///
/// Declare function called when we enter a menu
///
void enter(dynamic Function() body) {
  _declarer!.enter(body);
}

///
/// Declare function called when we leave a menu
///
void leave(dynamic Function() body) {
  _declarer!.leave(body);
}

///
/// Declare function called when we enter a menu
///
void enterItem(dynamic Function() body) {
  _declarer!.enterItem(body);
}

///
/// Declare function called when we leave a menu
///
void leaveItem(dynamic Function() body) {
  _declarer!.leaveItem(body);
}

///
/// Declare function called when we enter a non handled command
///
void command(dynamic Function(String command) body) {
  _declarer!.command(body);
}

/// Unless [solo] is set to false, will run as solo.
///
/// Deprecated for temp usage only.
@doNotSubmit
// ignore: non_constant_identifier_names
void solo_item(
  String name,
  dynamic Function() body, {
  String? cmd,
  bool? solo,
}) {
  // ignore: invalid_use_of_do_not_submit_member
  item(name, body, cmd: cmd, solo: solo ?? true);
}

/// Unless [solo] is set to false, will run as solo.
///
/// Deprecated for temp usage only.
@doNotSubmit
// ignore: non_constant_identifier_names
void solo_menu(String name, void Function() body, {String? cmd, bool? solo}) {
  // ignore: invalid_use_of_do_not_submit_member
  menu(name, body, cmd: cmd, solo: solo ?? true);
}

/// Write a line on the presenter
void write(Object? message) {
  menuPresenter.write(message ?? '<null>');
}

/// Show a new menu.
///
/// wait for completion.
Future<void> showMenu(void Function() declare) async {
  var controller = DevMenuController(declare);
  await menuManager.showMenu(controller.menu);
}

/// Pop the current menu.
///
/// Return true if the menu was popped, false if it was the last menu.
Future<bool> popMenu() async {
  return menuManager.popMenu();
}

/// Write a line on the presenter, deprecated to make it a temp debug call
@doNotSubmit
void devWrite(Object? message) {
  write(message);
}

/// Prompt for a string.
Future<String> prompt([Object? message]) {
  //return menuManager.prompt(message);
  return menuPresenter.prompt(message);
}

/// run the last declared menu/items
Future<void> menuRun() async {
  var declarer = _declarer;
  if (declarer != null) {
    declarer.autoRun = false;
    await declarer.run();
    __declarer = null;
  }
}
