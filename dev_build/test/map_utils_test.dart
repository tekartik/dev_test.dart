@TestOn('vm')
library;

import 'package:dev_build/src/map_utils.dart';
import 'package:test/test.dart';

void main() {
  group('map_utils', () {
    test('mapPartsExists', () {
      expect(mapPartsExists({'test': 1}, ['test']), isTrue);
      expect(mapPartsExists({'test': null}, ['test']), isTrue);
      expect(mapPartsExists({'_test': null}, ['test']), isFalse);
      expect(
          mapPartsExists({
            'sub': {'test': null}
          }, [
            'sub',
            'test'
          ]),
          isTrue);
      expect(
          mapPartsExists({
            'sub': {
              'sub_test': {'test': null}
            }
          }, [
            'sub',
            'sub_test',
            'test'
          ]),
          isTrue);
    });
  });
}
