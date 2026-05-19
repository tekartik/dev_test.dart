bool? _isDebug;

/// True if debug mode is enabled.
bool get isDebug => _isDebug ??= () {
  var debug = false;
  assert(() {
    debug = true;
    return true;
  }());
  return debug;
}();
