import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:pub_semver/pub_semver.dart';

/// Parse the first version from a text.
Version? parseFirstVersion(String text) {
  var tokens = LineSplitter.split(text)
      .map((line) => line.trim())
      .whereNot((line) => line.isEmpty)
      .join(' ')
      .split(' ')
      .map((line) => line.trim())
      .whereNot((token) => token.isEmpty);
  for (var token in tokens) {
    if (token.startsWith('v') || token.startsWith('V')) {
      token = token.substring(1);
    }
    try {
      return Version.parse(token);
    } catch (_) {}
  }
  return null;
}
