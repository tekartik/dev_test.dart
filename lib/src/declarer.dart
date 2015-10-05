library tekartik_dev_test.src.declare;

import 'package:test/test.dart' as _test;
import 'dart:async';
import 'meta.dart';

class Declarer {
  // with true it prints add (our wrapped calls to test and group), declare (when it calls test group for real)
  // and run (when it runs the body)
  bool debug = false;
  bool dryRun = false;

  final Root root = new Root();

  // curent group declared
  var _group;

  Declarer() {
    _group = root;
  }

  // Current running item;
  Callback currentItem;

  void _wrapBody(Callback callback) {
    Function body = callback.body;
    // Wrap the body to know the current running item
    _bodyWrapper() {
      currentItem = callback;
      if (debug) {
        _printCallback("run: ", currentItem);
      }
      var result = body();

      if (debug) {
        if (result is Future) {
          result.then((_) {
            _printCallback("adone: ", currentItem);
          });
        } else {
          _printCallback("done: ", currentItem);
        }
      }
      return result;
    }
    callback.body = _bodyWrapper;
  }

  _addTest(Test test) {
    _wrapBody(test);
    _group.add(test);
    if (debug) {
      _printCallback("add: ", test);
    }
  }

  _addGroup(Group group) {
    // wrap the body to make sure to call everything once before returning from the body

    _group.add(group);
    if (debug) {
      _printCallback("add: ", group);
    }

    // Let's allow for null for group body
    // change the current group when calling group
    Group _previousGroup = _group;
    _group = group;
    if (group.body != null) {
      group.body();
    }
    _group = _previousGroup;

    // change the body then
    group.body = () {
      _declareGroup(group);
    };
  }

  Test test(String description, body(),
      {String testOn,
      _test.Timeout timeout,
      skip,
      Map<String, dynamic> onPlatform,
      bool devSkip,
      bool devSolo}) {
    Test test = new Test()
      ..description = description
      ..body = body
      ..testOn = testOn
      ..timeout = timeout
      ..skip = skip
      ..onPlatform = onPlatform
      ..devSkip = devSkip == true
      ..devSolo = devSolo == true;
    _addTest(test);
    return test;
  }

  Group group(String description, void body(),
      {String testOn,
      _test.Timeout timeout,
      skip,
      Map<String, dynamic> onPlatform,
      bool devSkip,
      bool devSolo}) {
    Group group = new Group()
      ..description = description
      ..body = body
      ..testOn = testOn
      ..timeout = timeout
      ..skip = skip
      ..onPlatform = onPlatform
      ..devSkip = devSkip == true
      ..devSolo = devSolo == true;

    _addGroup(group);

    return group;
  }

  SetUp setUp(body()) {
    SetUp setUp = new SetUp()..body = body;
    _wrapBody(setUp);
    _group.setUp = setUp;
    return setUp;
  }

  TearDown tearDown(body()) {
    TearDown tearDown = new TearDown()..body = body;
    _wrapBody(tearDown);
    _group.tearDown = tearDown;
    return tearDown;
  }

  void _declareGroup(Group group) {
    // setUp
    if (group.setUp != null) {
      _declare(group.setUp);
    }

    // handle all tiem
    for (Item item in group.children) {
      // skip any to skip item
      if (item.devSkip) {
        continue;
      }

      // for test simply declare it
      _declare(item);
    }

    // tearDown
    if (group.tearDown != null) {
      _declare(group.tearDown);
    }
  }

  _declare(Callback callback) {
    if (debug) {
      _printCallback("declare: ", callback);
    }
    if (!dryRun) {
      callback.declare();
    }
    if (debug) {
      _printCallback("done declare: ", callback);
    }
  }

  /// return true if it has solo
  bool _fixSolo() {
    bool hasSolo = false;
    for (Item item in _group.children) {
      if (item.devSolo) {
        hasSolo = true;
        // mark ourself as solo so that other group get skipped
        _group.devSolo = true;
        break;
      }
    }
    _fixGroup(Group group) {
      for (Item item in group.children) {
        if (item.devSolo != true) {
          item.devSkip = true;
        }
      }
      // and parent recursively
      // Somehow this only fails in a case unit test...
      if (group.parent != null) {
        _fixGroup(group.parent);
      }
    }
    // Mark other items as skipped
    if (_group.devSolo == true) {
      _fixGroup(_group);
    }

    return hasSolo;
  }

  _printTree(Group group) {
    _print(int level, Group group) {
      if (group.setUp != null) {
        _printCallback("#", group.setUp);
      }
      if (group.tearDown != null) {
        _printCallback("#", group.tearDown);
      }
      for (Item item in group.children) {
        if (item.devSkip != true) {
          _printCallback("#", item);
          if (item is Group) {
            _print(level + 1, item);
          }
        }
      }
    }
    _print(0, group);
  }

  _printCallback(String msg, Callback callback) {
    // find level
    int level = 0;
    Group parent = callback.parent;
    while (parent != null) {
      level++;
      parent = parent.parent;
    }
    StringBuffer sb = new StringBuffer();
    for (int i = 0; i < level; i++) {
      sb.write("  ");
    }
    sb.write(msg);
    sb.write(callback);
    print(sb.toString());
  }

  /// Go through all groups
  _fixTree(Group group) {
    if (debug) {
      _printCallback("fixing ", group);
    }
    _fix(Group group) {
      for (Item item in group.children) {
        if (item is Group) {
          _fix(item);
        }
      }

      /// any solo test?
      bool hasSolo = false;
      for (Item item in group.children) {
        if (item.devSolo) {
          hasSolo = true;
          // mark ourself as solo so that other group get skipped
          group.devSolo = true;
          break;
        }
      }

      /// fix others
      if (hasSolo) {
        for (Item item in group.children) {
          if (item.devSolo != true) {
            if (debug) {
              print("skipping ${item}");
            }
            item.devSkip = true;
          }
        }
      }
    }
    _fix(group);
  }

  void run() {
    if (debug) {
      _printTree(root);
    }
    _fixTree(root);
    if (debug) {
      _printTree(root);
    }

    _declareGroup(root);
    return;

    // run all groups to find solo tests
    // handle all tiem
    for (Item item in _group.children) {
      if (item is Group) {
        // change the current group when calling group
        Group _previousGroup = _group;
        _group = item;
        _declare(item);
        _group = _previousGroup;
      }
    }

    // If there is a solo test, skip the others
    // also mark is parent as solo
    _fixSolo();

    // if need skip the group
    if (_group.devSkip == true) {
      return;
    }

    // setUp
    if (_group.setUp != null) {
      _declare(_group.setUp);
    }

    // handle all tiem
    for (Item item in _group.children) {
      // skip any to skip item
      if (item.devSkip) {
        continue;
      }

      if (!(item is Group)) {
        // for test simply declare it
        _declare(item);
      }
    }

    // tearDown
    if (_group.tearDown != null) {
      _declare(_group.tearDown);
    }
  }
}
