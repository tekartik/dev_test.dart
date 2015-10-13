library tekartik_dev_test.src.declare;

import 'package:test/test.dart' as _test;
import 'dart:async';
import 'meta.dart';
import 'package:stack_trace/stack_trace.dart';

///
/// current item description
/// abstract it so that developer do not get acces to any meta information
/// other than descriptions
///
List<String> get currentTestDescriptions => _currentCallback.descriptions;

Callback _currentCallback;

///
/// The declarer class handling the logic
///
class Declarer {
  // with true it prints add (our wrapped calls to test and group), declare (when it calls test group for real)
  // and run (when it runs the body)
  bool debug = false;
  bool dryRun = false;

  final Root root = new Root();

  // curent group declared
  Group _group;

  Declarer() {
    _group = root;
  }

  // Current running item;

  // Stats
  int testCount;
  int skipTestCount;

  void _wrapBody(Callback callback) {
    Function body = callback.body;
    // Wrap the body to know the current running item
    _bodyWrapper() {
      Callback previousCallback = _currentCallback;
      _currentCallback = callback;
      if (debug) {
        _printCallback("run: ", _currentCallback);
      }
      if (body == null) {
        // only allow null body for dry run
        if (dryRun) {
          body = () {};
        } else {
          throw "body() cannot be null for ${_currentCallback}";
        }
      }
      var result = body();

      if (result is Future) {
        result.then((_) {
          if (debug) {
            _printCallback("adone: ", _currentCallback);
          }
          _currentCallback = previousCallback;
        });
      } else {
        if (debug) {
          _printCallback("done: ", _currentCallback);
          _currentCallback = previousCallback;
        }
      }

      return result;
    }
    callback.body = _bodyWrapper;
  }

  _addItem(Item item) {
    _wrapBody(item);
    _group.add(item);
    if (debug) {
      _printCallback("add: ", item);
    }
  }

  _addGroup(Group group) {
    // For group this is different as we are going to call the body right away
    // and create new body for when test.group is called for real
    _addItem(group);

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
      ..devSolo = devSolo == true
      ..declareStackTrace = new Trace.current(2);

    _addItem(test);
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
      ..devSolo = devSolo == true
      ..declareStackTrace = new Trace.current(2);

    _addGroup(group);

    return group;
  }

  SetUp setUp(body()) {
    SetUp setUp = new SetUp()
      ..body = body
      ..declareStackTrace = new Trace.current(2);
    _wrapBody(setUp);
    _group.add(setUp);
    return setUp;
  }

  TearDown tearDown(body()) {
    TearDown tearDown = new TearDown()
      ..body = body
      ..declareStackTrace = new Trace.current(2);
    _wrapBody(tearDown);
    _group.add(tearDown);
    return tearDown;
  }

  SetUpAll setUpAll(body()) {
    SetUpAll setUpAll = new SetUpAll()
      ..body = body
      ..declareStackTrace = new Trace.current(2);
    _wrapBody(setUpAll);
    _group.add(setUpAll);
    return setUpAll;
  }

  TearDownAll tearDownAll(body()) {
    TearDownAll tearDownAll = new TearDownAll()
      ..body = body
      ..declareStackTrace = new Trace.current(2);
    _wrapBody(tearDownAll);
    _group.add(tearDownAll);
    return tearDownAll;
  }

  // Call all the original declarations
  void _declareGroup(Group group) {
    // handle all tiem
    for (Callback callback in group.children) {
      // handle group and test differently
      if (callback is Item) {
        // skip any to skip item
        if (callback.devSkip == true) {
          continue;
        }
      }

      // for test simply declare it
      _declare(callback);
    }
  }

  _declare(Callback callback) {
    if (debug) {
      _printCallback("declare: ", callback);
    }
    if (!dryRun) {
      try {
        callback.declare();
      } catch (e) {
        throw new UnsupportedError(
            "${e.toString()}\n${callback}\n${callback.declareStackTrace}");
      }
    }
    if (debug) {
      _printCallback("done declare: ", callback);
    }
  }

  _printTree(Group group) {
    _print(int level, Group group) {
      for (Callback callback in group.children) {
        if (callback is Item) {
          if (callback.devSkip == true) {
            _printCallback("#", callback);
            if (callback is Group) {
              _print(level + 1, callback);
            }
          }
        } else {
          _printCallback("#", callback);
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

  // Go through all groups
  _fixTree(Group group) {
    testCount = 0;
    skipTestCount = 0;

    if (debug) {
      _printCallback("fixing ", group);
    }
    _fix(Group group) {
      // Fix the group below first
      for (Callback callback in group.groups) {
        if (callback is Group) {
          _fix(callback);
        }
      }

      // any solo test?
      bool hasSolo = false;
      for (Item item in group.items) {
        if (item.devSolo) {
          hasSolo = true;
          // mark ourself as solo so that other group get skipped
          group.devSolo = true;
          break;
        }
      }

      for (Item item in group.items) {
        // fix others
        if (hasSolo) {
          if (item.devSolo != true) {
            if (debug) {
              print("skipping ${item}");
            }
            skipTestCount++;
            item.devSkip = true;
          }
        } else if (item.devSkip == true) {
          // stat
          skipTestCount++;
        }
      }
    }
    _fix(group);
    if (skipTestCount > 0) {
      // Add a special test item
      Test report = new Test()
        ..description = "dev_test report"
        ..skip =
            "[dev_test] ${skipTestCount} test${skipTestCount > 1 ? "s" :""} skipped";
      group.add(report);
    }
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
  }
}
