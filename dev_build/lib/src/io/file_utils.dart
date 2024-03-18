import 'dart:io';

/// Directory extension
extension DevDirectoryExt on Directory {
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
