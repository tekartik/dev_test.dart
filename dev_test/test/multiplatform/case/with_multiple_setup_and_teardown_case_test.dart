import 'package:dev_test/test.dart';

void main() {
  var setUp1Called = false;
  var setUp2Called = false;
  var tearDown1Called = false;

  setUp(() {
    expect(setUp1Called, isFalse);
    setUp1Called = true;
  });

  setUp(() {
    expect(setUp2Called, isFalse);
    expect(setUp1Called, isTrue);
    setUp2Called = true;
  });

  test('test', () {
    expect(setUp1Called, isTrue);
    expect(setUp2Called, isTrue);
  });

  tearDown(() {
    // Weird this tearDown is called after the other one
    expect(tearDown1Called, isTrue);
  });

  tearDown(() {
    expect(tearDown1Called, isFalse);
    tearDown1Called = true;
  });
}
