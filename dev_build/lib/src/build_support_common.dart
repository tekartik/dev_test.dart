import 'dart:convert';

/// Add a dependency in a brut force way
///
String pubspecStringAddDependency(String content, String dependency,
    {List<String>? dependencyLines}) {
  var lines = LineSplitter.split(content).toList();
  var index = lines.indexOf('dependencies:');
  if (index < 0) {
    // The template might create it commented out
    index = lines.indexOf('#dependencies:');
    if (index < 0) {
      lines.add('\ndependencies:');
      index = lines.length;
    } else {
      lines[index] = 'dependencies:';
      index = index + 1;
    }
  } else {
    index = index + 1;
  }
  lines.insert(index, '  $dependency:');
  if (dependencyLines != null) {
    for (var line in dependencyLines) {
      lines.insert(++index, '    $line');
    }
  }
  return '${lines.join('\n')}\n';
}

/// Remove a dependency in a brut force way
///
String pubspecStringRemoveDependency(String content, String dependency) {
  var lines = LineSplitter.split(content).toList();
  int? deleteStartIndex;
  int? deleteEndIndex;
  var readLines = lines;
  for (var i = 0; i < readLines.length; i++) {
    var line = readLines[i];
    if (deleteStartIndex != null) {
      if (line.startsWith('    ')) {
        deleteEndIndex = deleteEndIndex! + 1;
      } else {
        break;
      }
    } else if (line.startsWith('  $dependency:')) {
      deleteStartIndex = i;
      deleteEndIndex = i + 1;
    }
  }
  if (deleteStartIndex != null) {
    lines.removeRange(deleteStartIndex, deleteEndIndex!);
  }

  return '${lines.join('\n')}\n';
}
