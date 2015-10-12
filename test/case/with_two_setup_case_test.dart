import 'package:dev_test/test.dart';

main() {
  bool setUp1Called = false;
  bool setUp2Called = false;

  setUp(() {
    expect(setUp1Called, isFalse);
    setUp1Called = true;
  });

  setUp(() {
    expect(setUp2Called, isFalse);
    setUp2Called = true;
  });

  test('test', () {
    expect(setUp1Called, isTrue);
    expect(setUp2Called, isTrue);
  });
}
