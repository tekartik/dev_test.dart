library tekartik_dev_test.src.declare;

import 'package:test/test.dart' as _test;
import 'dart:async';
import 'meta.dart';

// with true it prints add (our wrapped calls to test and group), declare (when it calls test group for real)
// and run (when it runs the body)
bool debug = false;

class Declarer {
  // curent group declared
  var _group = new Group(); // root group has no parent

  // Current running item;
  Callback currentItem;

  void _wrapBody(Callback callback) {
    Function body = callback.body;
    // Wrap the body to know the current running item
    _bodyWrapper() {
      currentItem = callback;
      if (debug) {
        print("run: ${currentItem}");
      }
      var result = body();

      if (debug) {
        if (result is Future) {
          result.then((_) {
            print("adone: ${currentItem}");
          });
        } else {
          print("done: ${currentItem}");
        }
      }
      return result;
    }
    callback.body = _bodyWrapper;
  }

  _add(Item item) {
    _wrapBody(item);
    _group.add(item);
    if (debug) {
      print("add: ${item}");
    }
  }

  void test(String description, body(),
      {String testOn,
      _test.Timeout timeout,
      skip,
      Map<String, dynamic> onPlatform,
      bool devSkip,
      bool devSolo}) {
    _add(new Test()
      ..description = description
      ..body = body
      ..testOn = testOn
      ..timeout = timeout
      ..skip = skip
      ..onPlatform = onPlatform
      ..devSkip = devSkip == true
      ..devSolo = devSolo == true);
  }

  void group(String description, void body(),
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

    // wrap the body to make sure to call everything once before returning from the body
    body = group.body;
    void bodyWrapper() {
      body();
      run();
    }
    group.body = bodyWrapper;

    _add(group);
  }

  void setUp(body()) {
    SetUp setUp = new SetUp()..body = body;
    _wrapBody(setUp);
    _group.setUp = setUp;
  }

  void tearDown(body()) {
    TearDown tearDown = new TearDown()..body = body;
    _wrapBody(tearDown);
    _group.tearDown = tearDown;
  }

  _declare(Callback callback) {
    if (debug) {
      print("declare: ${callback}");
    }
    callback.declare();
  }

  void run() {
    // If there is a solo test, skip the others
    bool hasSolo = false;
    for (Item item in _group.children) {
      if (item.devSolo) {
        hasSolo = true;
        break;
      }
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
      if (hasSolo && !item.devSolo) {
        continue;
      }

      if (item is Group) {
        // change the current group when calling group
        Group _previousGroup = _group;
        _group = item;
        _declare(item);

        // handle it recursively
        //run();
        _group = _previousGroup;
      } else {
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
/*
abstract class _Def {
  _Def parent;
  String description;
  Function body;
  String testOn;
  _test.Timeout timeout;
  var skip; // String or true if skipped
  Map<String, dynamic> onPlatform;

  // call the base
  call();

  // to set to true for solo test
  bool tmpSolo;
  bool tmpSkip;
  bool get isSolo => tmpSolo == true;
  bool get isSkip => tmpSkip != null && tmpSkip != false;

  void add() {
    if (soloTestDisabled) {
      call();
    } else {
      _stack.add(this);
    }
  }

  String get type => this is TestDefinition ? "test" : "group";
  @override
  toString() {
    List<String> parents = [];
    _Def parent = this;
    while (parent != null) {
      parents.insert(0, parent.description == null ? '' : parent.description);
      parent = parent.parent;
    }

    return "${type}: '${parents.join('/')}'${isSolo ? " solo" : ""}${isSkip ? " skip": ""}";
  }
}

class TestDefinition extends _Def {
  call() {
    _test.test(description, body,
    testOn: testOn, timeout: timeout, skip: skip, onPlatform: onPlatform);
  }
  String get type => "test";
}

class GroupDefinition extends _Def {
  List<_Def> children = [];

  call() {
    _test.group(description, body,
    testOn: testOn, timeout: timeout, skip: skip, onPlatform: onPlatform);
  }
  String get type => "group";
}

bool _shouldPrint = false;
_print(msg) {
  if (_shouldPrint) {
    print(msg);
  }
}

class _Stack {
  // all definition are stored here
  Map<String, _Def> defs = {};
  // there is always a group
  final GroupDefinition topGroup = new GroupDefinition();
  GroupDefinition currentGroup;
  GroupDefinition currentRunningGroup;

  _Stack() {
    currentGroup = topGroup;
    currentRunningGroup = topGroup;
  }
  Future _lazy;
  bool running = false;

  _fixGroup(GroupDefinition group) {
    // Check for any solo test here
    bool hasSolo = false;
    for (_Def def in group.children) {
      if (def.isSolo) {
        hasSolo = true;
        break;
      }
    }
    // If yes mark other tested as skipped
    // and mark parent as solo as well
    if (hasSolo) {
      for (_Def def in group.children) {
        if (!def.isSolo) {
          _print("skipping ${def}");
          def.tmpSkip = true;
        }
      }

      if (!group.isSolo) {
        _print("soloing ${group}");
        group.tmpSolo = true;
      }
    }
  }

  run() {
    _fixGroup(topGroup);
    running = true;

    for (_Def def in topGroup.children) {
      call(def);
    }
  }

  call(_Def def) {
    // Find def in current running group children
    _Def foundDef;
    for (_Def child in currentRunningGroup.children) {
      if (child.description == def.description) {
        foundDef = child;
        break;
      }
    }
    if (!foundDef.isSkip) {
      if (foundDef is GroupDefinition) {
        GroupDefinition previous = currentRunningGroup;
        currentRunningGroup = foundDef;
        foundDef.call();
        currentRunningGroup = previous;
      } else {
        // run test

        foundDef.call();
      }
    }
  }

  add(_Def def) {
    // Either we run it directly
    // Either we add it
    if (running) {
      call(def);
    } else {
      // Make sure it'll get call at some point
      if (_lazy == null) {
        _lazy = new Future.value().then((_) {
          run();
        });
      }

      currentGroup.children.add(def);
      def.parent = currentGroup;

      // Propagate changes
      if (def is GroupDefinition) {
        // Call the body once to get the sub definition
        GroupDefinition previous = currentGroup;
        currentGroup = def;
        def.body();

        _fixGroup(currentGroup);

        currentGroup = previous;
      }
    }
  }
}

_Stack _stack = new _Stack();
*/
