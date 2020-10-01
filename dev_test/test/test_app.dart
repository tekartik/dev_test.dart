import 'package:dev_test/package.dart';
import 'package:fs_shim/fs_io.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart';
import 'package:process_run/shell.dart';

export 'package:path/path.dart';

extension _DirectoryExt on Directory {
  /// Create if needed
  Future<void> prepare() async {
    if (await exists()) {
      try {
        await delete(recursive: true);
      } catch (_) {}
    }
    await parent.create(recursive: true);
  }
}

Future<void> main() async {
  var path = '.dart_tool/dev_test/test_exp/test_io_app';

  await generateAndRunCi(path: path, template: 'console-simple');
}

Future<void> generateAndRunCi(
    {@required String template, @required String path}) async {
  await Directory(path).prepare();

  var shell = Shell().cd(dirname(path));
  await shell
      .run('dart create --template $template ${shellArgument(basename(path))}');
  await packageRunCi(path);
}

Future<void> flutterGenerateAndRunCi({
  @required String path,
  @required String template,
  bool noAnalyze,
}) async {
  await Directory(path).prepare();

  var shell = Shell().cd(dirname(path));

  await shell.run(
      'flutter create --template $template ${shellArgument(basename(path))}');
  await packageRunCi(path, noAnalyze: noAnalyze);
}
