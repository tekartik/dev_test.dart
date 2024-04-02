import 'package:dev_build/menu/menu.dart';

/// Dev flag.
/// Simple class to add a debug flag
/// off by default
/// turning it on raises a warning so that you don't checkin code like that.
class DevFlag {
  /// Optional explanation.
  final String? explanation;

  /// Create a DevFlag.
  DevFlag([this.explanation]);

  /// Is the flag on?
  bool get on => _on ?? false;
  bool? _on;

  @Deprecated('Dev only')
  set on(bool on) {
    _on = on;

    write('Turning $this');
  }

  @override
  String toString() => "DevFlag($explanation) ${on ? "on" : "off"}";
}
