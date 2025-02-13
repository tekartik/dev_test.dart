import 'package:dev_build/package.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:test/test.dart';

void main() {
  group('filter_dart_project_options', () {
    test('filter_dart_project_options', () async {
      var options = FilterDartProjectOptions();
      expect(options.matchesBoundaries(null), isFalse);
      expect(
        options.matchesBoundaries(VersionBoundaries.version(Version(1, 0, 0))),
        isTrue,
      );
      expect(
        options.matchesBoundaries(VersionBoundaries.version(Version(0, 0, 0))),
        isFalse,
      );
      options = FilterDartProjectOptions(ignoreSdkConstraints: true);
      expect(
        options.matchesBoundaries(VersionBoundaries.version(Version(0, 0, 0))),
        isTrue,
      );
      options = FilterDartProjectOptions(
        minSdk: VersionBoundaries.version(Version(1, 0, 0)),
      );
      expect(
        options.matchesBoundaries(VersionBoundaries.version(Version(1, 0, 0))),
        isTrue,
      );
      expect(
        options.matchesBoundaries(VersionBoundaries.version(Version(2, 0, 0))),
        isFalse,
      );
      options = FilterDartProjectOptions(
        maxSdk: VersionBoundaries.version(Version(1, 0, 0)),
      );
      expect(
        options.matchesBoundaries(VersionBoundaries.version(Version(1, 0, 0))),
        isTrue,
      );
      expect(
        options.matchesBoundaries(VersionBoundaries.version(Version(2, 0, 0))),
        isFalse,
      );
      options = FilterDartProjectOptions(
        minSdk: VersionBoundaries(
          VersionBoundary(Version(1, 0, 0), true),
          VersionBoundary(Version(2, 0, 0), false),
        ),
        maxSdk: VersionBoundaries(
          VersionBoundary(Version(3, 0, 0), false),
          VersionBoundary(Version(4, 0, 0), true),
        ),
      );
      expect(
        options.matchesBoundaries(VersionBoundaries.parse('>=1.0.0 <=4.0.0')),
        isTrue,
      );
      expect(
        options.matchesBoundaries(VersionBoundaries.parse('>=2.0.0-0 <=3.0.1')),
        isTrue,
      );
      expect(
        options.matchesBoundaries(VersionBoundaries.parse('>=2.0.0 <=3.0.1')),
        isFalse,
      );
      expect(
        options.matchesBoundaries(VersionBoundaries.parse('>=2.0.0-0 <=3.0.0')),
        isFalse,
      );
    });
  });
}
