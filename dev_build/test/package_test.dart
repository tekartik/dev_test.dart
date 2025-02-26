@TestOn('vm')
library;

import 'package:dev_build/package.dart';
import 'package:pub_semver/pub_semver.dart';
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
}
