// public export of the test item to allow for a given presenter

import 'dev_menu.dart';
import 'menu_manager.dart';

/// What to implement.
abstract class MenuPresenter {
  /// show the menu
  void presentMenu(DevMenu menu);

  /// prompt
  Future<String> prompt(Object? message);

  /// write the console
  void writeln(Object message);

  /// Compat - DEPRECATED prefer writeln
  void write(Object message);

  /// pre process item.
  Future preProcessItem(DevMenuItem item);

  /// pre process menu.
  Future preProcessMenu(DevMenu menu);
}

/// Test menu presenter mixin.
abstract mixin class MenuPresenterMixin implements MenuPresenter {
  @override
  Future preProcessItem(DevMenuItem item) async {}

  @override
  Future preProcessMenu(DevMenu menu) async {}

  @override
  void writeln(Object message) {
    write(message);
  }
}

/// Default null presenter, not event a print.
class _NullMenuPresenter extends Object
    with MenuPresenterMixin
    implements MenuPresenter {
  @override
  void presentMenu(DevMenu menu) {}

  @override
  Future<String> prompt(Object? message) async {
    return '';
  }

  @override
  void writeln(Object message) {}

  @override
  void write(Object message) {}
}

class _PrintMenuPresenter with MenuPresenterMixin implements MenuPresenter {
  @override
  void presentMenu(DevMenu menu) {}

  @override
  Future<String> prompt(Object? message) async {
    writeln(message ?? '');
    return '';
  }

  @override
  void write(Object message) {
    writeln(message);
  }

  @override
  void writeln(Object message) {
    // ignore: avoid_print
    print(message);
  }
}

/// Default null presenter, not event a print.
class NullMenuPresenter extends _NullMenuPresenter {
  /// Default null presenter, not event a print.
  NullMenuPresenter() {
    // set as presenter
    menuPresenter = this;
    menuManager = null;
  }
}

/// Default null presenter, not event a print.
NullMenuPresenter nullMenuPresenter = NullMenuPresenter();
MenuPresenter? _menuPresenter;

/// Default test menu presenter.
MenuPresenter? get menuPresenterOrNull => _menuPresenter;

final _printPresenter = _PrintMenuPresenter();

/// Default test menu presenter, ensure write is printed
MenuPresenter get menuPresenter => _menuPresenter ?? _printPresenter;

/// Change default test menu presenter.
set menuPresenter(MenuPresenter menuPresenter) =>
    _menuPresenter = menuPresenter;
