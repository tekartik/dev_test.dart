library tekartik_dev_test.src.item;

import 'package:test/test.dart' as _test;
import 'package:collection/equality.dart';

abstract class Callback {
  Group parent;
  Function body;

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

class SetUp extends Callback {
  declare() {
    _test.setUp(body);
  }
}

class TearDown extends Callback {
  declare() {
    _test.tearDown(body);
  }
}

abstract class Item extends Callback {
  String description;
  List<String> get descriptions {
    List<String> descriptions = super.descriptions;
    if (description != null) {
      descriptions..add(description);
    }
    return descriptions;
  }

  String testOn;
  _test.Timeout timeout;
  var skip; // String or true if skipped
  Map<String, dynamic> onPlatform;

  bool devSkip;
  bool devSolo;

  @override
  String toString() {
    String text = super.toString();
    if (devSkip == true || devSolo == true) {
      text += " (${devSolo == true ? "solo" : "skip"})";
    }
    return text;
  }
}

class Group extends Item {
  Group();

  SetUp _setUp;
  SetUp get setUp => _setUp;
  set setUp(SetUp callback) {
    _setUp = callback;
    callback.parent = this;
  }

  TearDown _tearDown;
  TearDown get tearDown => _tearDown;
  set tearDown(TearDown callback) {
    _tearDown = callback;
    callback.parent = this;
  }

  List<Item> _children = [];
  List<Item> get children => _children;

  add(Item item) {
    _children.add(item);
    item.parent = this;
  }

  String get type => 'group';

  declare() {
    _test.group(description, body,
        testOn: testOn, timeout: timeout, skip: skip, onPlatform: onPlatform);
  }
}

///
/// The test definition
///
class Test extends Item {
  String get type => 'test';
  declare() {
    _test.test(description, body,
        testOn: testOn, timeout: timeout, skip: skip, onPlatform: onPlatform);
  }
}
