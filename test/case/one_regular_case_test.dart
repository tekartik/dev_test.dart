import 'package:test/test.dart';

main() {
  test('regular_test', () {
    expect(true, isTrue);
  });
  group('regular_group', () {
    setUp(() {
      expect(true, isTrue);
    });
    test('test', () {
      expect(true, isTrue);
    });
  });
}
