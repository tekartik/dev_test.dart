import 'package:dev_build/menu/menu.dart';
import 'package:dev_build/src/import.dart';
import 'package:dev_build/src/menu/menu_presenter.dart';

import 'dev_menu.dart';
import 'menu_manager.dart';

/// Test menu runner.
class MenuRunner {
  /// The menu.
  final DevMenu menu;

  /// The parent menu.
  final MenuRunner? parent;
  final _doneCompleter = Completer<void>.sync();

  /// Completed when poped
  Future<void> get done => _doneCompleter.future;

  void _complete() {
    if (!_doneCompleter.isCompleted) {
      _doneCompleter.complete();
    }
  }

  @override
  String toString() => menu.toString();

  /// Entered.
  bool entered = false;

  /// Test menu runner.
  MenuRunner(this.parent, this.menu);

  /// Enter the menu.
  Future<void> enter() async {
    if (!entered) {
      entered = true;
      await parent?.enter();
      for (var enter in menu.enters) {
        await run(enter);
      }
    }
  }

  /// Run a runnable.
  Future<void> run(Runnable runnable) async {
    if (debugMenuManager) {
      write("[run] running '$runnable'");
    }
    try {
      var result = runnable.run();
      if (result is Future) {
        await result;
      }
    } catch (e, st) {
      menuPresenter.write('ERROR CAUGHT $e $st');

      rethrow;
    } finally {
      if (debugMenuManager) {
        write("[run] done '$runnable'");
      }
    }
  }

  /// when the menu is left.
  Future leave() async {
    if (debugMenuManager) {
      write('[leave]  ${menu.leaves} $entered');
    }
    //devWrite('leave');
    if (entered) {
      entered = false;
      for (var leave in menu.leaves) {
        await run(leave);
      }
      _complete();
    }
  }
}
