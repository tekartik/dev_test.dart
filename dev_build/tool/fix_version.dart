import 'package:process_run/process_run.dart';

Future<void> main() async {
  await run('dart run build_runner build');
}
