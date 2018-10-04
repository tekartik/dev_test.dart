library tekartik_dev_test.descriptions_test;

import 'package:test/test.dart';
import 'package:dev_test/src/meta.dart';
import 'package:dev_test/src/declarer.dart';

void main() {
  // test descriptions
  group('declarer', () {
    setUp(() {});

    test('root', () async {
      var declarer = DeclarerImpl();
      declarer.dryRun = true;
      SetUp setUp = declarer.setUp(null);
      Test test1 = declarer.test("test1", null);
      Test test2 = declarer.test("test2", null);
      Group group = declarer.group("group", null);
      TearDown tearDown = declarer.tearDown(null);
      expect(declarer.root.children, [setUp, test1, test2, group, tearDown]);
      declarer.run();
    });

    test('in_group', () async {
      var declarer = DeclarerImpl();
      declarer.dryRun = true;
      SetUp setUp = declarer.setUp(null);
      Test test1 = declarer.test("test1", null);
      Test test2 = declarer.test("test2", null);
      TearDown tearDown = declarer.tearDown(null);
      expect(declarer.root.children, [setUp, test1, test2, tearDown]);
      declarer.run();
    });

    test('solo_test', () async {
      var declarer = DeclarerImpl()..dryRun = true;
      declarer.dryRun = true;
      Test test1 = declarer.test("solo_test", null, solo: true);
      Test test2 = declarer.test("test", null);
      declarer.run();
      expect(test1.solo, isTrue);
      expect(test2.solo, isFalse);
    });

    test('solo_group', () async {
      var declarer = DeclarerImpl();
      declarer.dryRun = true;
      Group group1 = declarer.group("solo_group", null, solo: true);
      Group group2 = declarer.group("group", null);
      // Check that we indeed run lazily
      declarer.run();

      // make sure first test is solo but the other one is skipped
      expect(group1.description, "solo_group");
      expect(group1.solo, isTrue);
      expect(group2.description, "group");
      expect(group2.solo, isFalse);
    });

    test('test_in_group', () async {
      var declarer = DeclarerImpl();
      declarer.dryRun = true;
      Test test;
      declarer.group("group", () {
        test = declarer.test("test", null);
      });
      // Check that we indeed run lazily
      declarer.run();
      expect(test.descriptions, ['group', 'test']);
    });

    test('solo_test_in_group', () async {
      var declarer = DeclarerImpl();
      declarer.dryRun = true;
      Test test2;
      Group firstGroup = declarer.group("first_group", null);
      Group group = declarer.group("group", () {
        declarer.test("test", null, solo: true);
        test2 = declarer.test("test", null);
      });
      Test other = declarer.test("other", null);
      Group otherGroup = declarer.group("other_group", () {
        declarer.test("other", null);
      });
      // group should become solo
      expect(group.solo, isFalse);
      expect(firstGroup.devSkip, isFalse);
      expect(otherGroup.devSkip, isFalse);
      // Check that we indeed run lazily
      declarer.run();
      expect(firstGroup.devSkip, isTrue);
      expect(group.solo, isTrue);
      expect(test2.devSkip, isTrue);
      expect(other.devSkip, isTrue);
      expect(otherGroup.devSkip, isTrue);
    });

    test('solo_test_in_sub_group', () async {
      var declarer = DeclarerImpl();
      declarer.dryRun = true;
      Group sub;
      Group group = declarer.group("group", () {
        sub = declarer.group("sub", () {
          declarer.test("test", null, solo: true);
        });
      });
      Test other = declarer.test("other", null);

      // group should become solo
      expect(group.solo, isFalse);
      // Check that we indeed run lazily
      declarer.run();
      expect(group.solo, isTrue);
      expect(sub.solo, isTrue);
      expect(other.devSkip, isTrue);
    });

    test('setUp', () {
      var declarer = DeclarerImpl()..dryRun = true;
      SetUp setUp = declarer.setUp(null);
      SetUp setUp2 = declarer.setUp(null);
      expect(declarer.root.children, [setUp, setUp2]);
    });

    test('tearDown', () {
      var declarer = DeclarerImpl()..dryRun = true;
      TearDown tearDown = declarer.tearDown(null);
      TearDown tearDown2 = declarer.tearDown(null);
      expect(declarer.root.children, [tearDown, tearDown2]);
    });

    test('setUpAll', () {
      var declarer = DeclarerImpl()..dryRun = true;
      SetUpAll setUpAll = declarer.setUpAll(null);
      SetUpAll setUpAll2 = declarer.setUpAll(null);
      expect(declarer.root.children, [setUpAll, setUpAll2]);
    });

    test('tearDown', () {
      var declarer = DeclarerImpl()..dryRun = true;
      TearDownAll tearDownAll = declarer.tearDownAll(null);
      TearDownAll tearDownAll2 = declarer.tearDownAll(null);
      expect(declarer.root.children, [tearDownAll, tearDownAll2]);
    });
  });
}
