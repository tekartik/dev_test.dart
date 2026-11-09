/// Drop-in replacement for `package:test/test.dart`: the same API (`test`,
/// `group`, `setUp`, `expect`, the matchers...) plus [solo_test],
/// [solo_group], [skip_test], [skip_group] (deprecated on purpose, remove
/// them before committing) and [testDescriptions].
///
/// ```dart
/// import 'package:dev_test/test.dart';
///
/// void main() {
///   group('group', () {
///     test('test', () {
///       expect(testDescriptions, ['group', 'test']);
///     });
///   });
/// }
/// ```
///
/// Run with `dart test`, `package:test` must be a dev dependency too.
library;

export 'package:dev_test/src/import_test.dart'
    hide expect, test, group, setUp, tearDown, setUpAll, tearDownAll;
export 'package:matcher/expect.dart' hide expect;

export 'src/dev_test.dart'
    show
        expect,
        // redefined
        test,
        group,
        setUp,
        setUpAll,
        tearDown,
        tearDownAll,
        //expect,
        // Added
        testDescriptions,
        // ignore: deprecated_member_use, deprecated_member_use_from_same_package
        solo_test,
        // ignore: deprecated_member_use, deprecated_member_use_from_same_package
        solo_group,
        // ignore: deprecated_member_use, deprecated_member_use_from_same_package
        skip_test,
        // ignore: deprecated_member_use, deprecated_member_use_from_same_package
        skip_group;
