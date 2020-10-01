import 'package:dev_test/package.dart';
import 'package:fs_shim/fs_io.dart';
import 'package:meta/meta.dart';
import 'package:process_run/shell.dart';
import 'package:process_run/which.dart';

export 'package:path/path.dart';

extension _DirectoryExt on Directory {
  /// Create if needed
  Future<void> clear() async {
    if (await exists()) {
      try {
        await delete(recursive: true);
      } catch (_) {}
    }
    await create(recursive: true);
  }
}

Future<void> main() async {
  var path = '.dart_tool/dev_test/test_exp/test_io_app';

  await generateAndRunCi(path: path, stagehandTemplate: 'console-simple');
}

Future<void> generateAndRunCi(
    {@required String stagehandTemplate, @required String path}) async {
  await Directory(path).clear();

  var shell = Shell().cd(path);
  if ((await which('stagehand')) == null) {
    await shell.run('pub global activate stagehand');
  }
  await shell.run('pub global run stagehand $stagehandTemplate');
  await packageRunCi(path);
}

Future<void> flutterGenerateAndRunCi({@required String path}) async {
  await Directory(path).clear();

  var shell = Shell().cd(path);
  if ((await which('flutter')) == null) {
    await shell.run('flutter create .');
    await packageRunCi(path);
  }
}
