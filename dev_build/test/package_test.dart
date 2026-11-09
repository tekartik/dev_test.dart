@TestOn('vm')
library;

import 'package:dev_build/build_support.dart' show PubDependencyKind;
import 'package:dev_build/package.dart';
import 'package:test/test.dart';

void main() {
  test('DartPackage', () async {
    var package = DartPackageReader.pubspecString('''
name: dart_package_io
version: 1.0.0
environment:
  sdk: 1
dependencies:
  path:
  http: any
  gitdep:
    git:
      url: git://github.com/dart-lang/git.git
      ref: 1.0.0
''');
    expect(package.getVersion(), Version(1, 0, 0));
    expect(package.getDependencyObject(dependency: 'path'), {'path': null});
    expect(package.getDependencyObject(dependency: 'http'), {'http': 'any'});
    expect(package.getDependencyObject(dependency: 'gitdep'), {
      'gitdep': {
        'git': {'url': 'git://github.com/dart-lang/git.git', 'ref': '1.0.0'},
      },
    });
  });
  test('getDependencyObject kind', () async {
    var package = DartPackageReader.pubspecString('''
name: dart_package_io
dependencies:
  path: any
dev_dependencies:
  test: any
dependency_overrides:
  path: ^1.8.0
''');
    expect(
      package.getDependencyObject(
        dependency: 'test',
        kind: PubDependencyKind.dev,
      ),
      {'test': 'any'},
    );
    expect(package.getDependencyObject(dependency: 'test'), isNull);
    expect(
      package.getDependencyObject(
        dependency: 'path',
        kind: PubDependencyKind.override,
      ),
      {'path': '^1.8.0'},
    );
    expect(package.getDependencyObject(dependency: 'path'), {'path': 'any'});
  });
}
