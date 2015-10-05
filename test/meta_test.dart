library tekartik_dev_test.descriptions_test;

import 'package:dev_test/test.dart';
import 'package:dev_test/src/meta.dart';

void main() {
  // test descriptions
  group('meta', () {
    setUp(() {});

    test('group', () {
      Group group = new Group();
      expect(group.descriptions, []);
      expect(group.type, "group");
      group.description = "my_group";
      expect(group.descriptions, ["my_group"]);
    });

    test('item', () {
      Test test = new Test();
      expect(test.descriptions, []);
      expect(test.type, "test");
      test.description = "my_test";
      expect(test.descriptions, ["my_test"]);
    });

    test('callback', () {
      SetUp setUp = new SetUp();
      TearDown tearDown = new TearDown();
      expect(setUp.type, "setUp");
      expect(tearDown.type, "tearDown");
    });

    test('parent', () {
      Group group = new Group()..description = "my_group";

      Test test = new Test()..parent = group;
      expect(test.descriptions, ["my_group"]);
      test.description = "my_test";
      expect(test.descriptions, ["my_group", "my_test"]);

      Group parent = new Group();
      group.parent = parent;
      expect(test.descriptions, ["my_group", "my_test"]);
      parent.description = "my_parent";
      expect(test.descriptions, ["my_parent", "my_group", "my_test"]);
    });

    test('equals', () {
      Test test1 = new Test();
      Test test2 = new Test();
      expect(test1, test2);
      test1.description = "test";
      expect(test1, isNot(test2));
      test2.description = "test";
      expect(test1, test2);
      Group group = new Group()..description = "group";
      test1.parent = group;
      expect(test1, isNot(test2));
      test2.parent = group;
      expect(test1, test2);
    });
  });
}
