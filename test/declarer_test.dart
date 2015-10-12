library tekartik_dev_test.descriptions_test;

import 'package:dev_test/test.dart';
import 'package:dev_test/src/meta.dart';
import 'package:dev_test/src/declarer.dart';

void main() {
  // test descriptions
  group('declarer', () {
    setUp(() {});

    test('root', () async {
      Declarer declarer = new Declarer();
      declarer.dryRun = true;
      SetUp setUp = declarer.setUp(null);
      Test test1 = declarer.test("test1", null);
      Test test2 = declarer.test("test2", null);
      Group group = declarer.group("group", null);
      TearDown tearDown = declarer.tearDown(null);
      expect(declarer.root.children, [test1, test2, group]);
      expect(declarer.root.setUp, setUp);
      expect(declarer.root.tearDown, tearDown);
      declarer.run();
      expect(test1, declarer.root.children[0]);
      expect(test2, declarer.root.children[1]);
    });

    test('in_group', () async {
      Declarer declarer = new Declarer();
      declarer.dryRun = true;
      SetUp setUp = declarer.setUp(null);
      Test test1 = declarer.test("test1", null);
      Test test2 = declarer.test("test2", null);
      TearDown tearDown = declarer.tearDown(null);
      expect(declarer.root.children, [test1, test2]);
      expect(declarer.root.setUps, [setUp]);
      expect(declarer.root.tearDown, tearDown);
      declarer.run();
      expect(test1, declarer.root.children[0]);
      expect(test2, declarer.root.children[1]);
    });

    test('solo_test', () async {
      Declarer declarer = new Declarer();
      declarer.dryRun = true;
      Test test1 = declarer.test("solo_test", null, devSolo: true);
      Test test2 = declarer.test("test", null);
      declarer.run();
      expect(test1.devSolo, isTrue);
      expect(test2.devSolo, isFalse);
    });

    test('solo_group', () async {
      Declarer declarer = new Declarer();
      declarer.dryRun = true;
      Group group1 = declarer.group("solo_group", null, devSolo: true);
      Group group2 = declarer.group("group", null);
      // Check that we indeed run lazily
      declarer.run();

      // make sure first test is solo but the other one is skipped
      expect(group1.description, "solo_group");
      expect(group1.devSolo, isTrue);
      expect(group2.description, "group");
      expect(group2.devSolo, isFalse);
    });

    test('test_in_group', () async {
      Declarer declarer = new Declarer();
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
      Declarer declarer = new Declarer();
      declarer.dryRun = true;
      Test test2;
      Group firstGroup = declarer.group("first_group", null);
      Group group = declarer.group("group", () {
        declarer.test("test", null, devSolo: true);
        test2 = declarer.test("test", null);
      });
      Test other = declarer.test("other", null);
      Group otherGroup = declarer.group("other_group", () {
        declarer.test("other", null);
      });
      // group should become solo
      expect(group.devSolo, isFalse);
      expect(firstGroup.devSkip, isFalse);
      expect(otherGroup.devSkip, isFalse);
      // Check that we indeed run lazily
      declarer.run();
      expect(firstGroup.devSkip, isTrue);
      expect(group.devSolo, isTrue);
      expect(test2.devSkip, isTrue);
      expect(other.devSkip, isTrue);
      expect(otherGroup.devSkip, isTrue);
    });

    test('solo_test_in_sub_group', () async {
      Declarer declarer = new Declarer();
      declarer.dryRun = true;
      Group sub;
      Group group = declarer.group("group", () {
        sub = declarer.group("sub", () {
          declarer.test("test", null, devSolo: true);
        });
      });
      Test other = declarer.test("other", null);

      // group should become solo
      expect(group.devSolo, isFalse);
      // Check that we indeed run lazily
      declarer.run();
      expect(group.devSolo, isTrue);
      expect(sub.devSolo, isTrue);
      expect(other.devSkip, isTrue);
    });

    solo_test('setUp', () {
      Declarer declarer = new Declarer()..dryRun = true;
      SetUp setUp = declarer.setUp(null);
      expect(declarer.root.setUps, [setUp]);
    });

    solo_test('tearDown', () {
      Declarer declarer = new Declarer()..dryRun = true;
      TearDown tearDown = declarer.tearDown(null);
      expect(declarer.root.tearDown, tearDown);
    });

    solo_test('setUpAll', () {
      Declarer declarer = new Declarer()..dryRun = true;
      SetUpAll setUpAll = declarer.setUpAll(null);
      expect(declarer.root.setUpAll, setUpAll);
    });

    solo_test('tearDown', () {
      Declarer declarer = new Declarer()..dryRun = true;
      TearDownAll tearDownAll = declarer.tearDownAll(null);
      expect(declarer.root.tearDownAll, tearDownAll);
    });
  });
}
