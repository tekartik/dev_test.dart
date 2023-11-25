import 'dart:convert';

import 'package:path/path.dart';

String caseNamePath(String name) {
  return join('test', 'multiplatform', 'case', name);
}

/// result must be run with reporter:json
bool? pubRunTestJsonIsSuccess(String stdout) {
  try {
    var map = json.decode(LineSplitter.split(stdout).last) as Map;
    return map['success'] as bool?;
  } catch (_) {
    return false;
  }
}

int pubRunTestJsonSuccessCount(String stdout) {
  //int _warn;
  //print('# ${processResultToDebugString(result)}');
  var count = 0;
  for (var line in LineSplitter.split(stdout)) {
    try {
      var map = json.decode(line);
      //print(map);
      if (map is Map) {
        // {testID: 0, result: success, hidden: true, type: testDone, time: 199}
        // {testID: 2, result: success, hidden: false, type: testDone, time: 251}
        //
        // {protocolVersion: 0.1.0, runnerVersion: 0.12.6+2, type: start, time: 0}
        // {test: {id: 0, name: loading test/data/success_test_.dart, groupIDs: [], metadata: {skip: false, skipReason: null}}, type: testStart, time: 0}
        // {testID: 0, result: success, hidden: true, type: testDone, time: 224}
        // {group: {id: 1, parentID: null, name: null, metadata: {skip: false, skipReason: null}}, type: group, time: 227}
        // {test: {id: 2, name: success, groupIDs: [1], metadata: {skip: false, skipReason: null}}, type: testStart, time: 227}
        // {testID: 2, result: success, hidden: false, type: testDone, time: 251}
        if (map['testID'] != null) {
          //print('1 $map');
          if ((map['result'] == 'success') && (map['hidden'] != true)) {
            // Handle skipped
            // {"testID":3,"result":"success","skipped":true,"hidden":false,"type":"testDone","time":789}
            if (map['skipped'] != true) {
              count++;
            }
          }
        }
      }
    } catch (_) {}
  }

  return count;
}

/*
{"protocolVersion":"0.1.0","runnerVersion":"0.12.6+2","type":"start","time":0}
{"test":{"id":0,"name":"loading test/data/fail_test_.dart","groupIDs":[],"metadata":{"skip":false,"skipReason":null}},"type":"testStart","time":0}
{"testID":0,"result":"success","hidden":true,"type":"testDone","time":180}
{"group":{"id":1,"parentID":null,"name":null,"metadata":{"skip":false,"skipReason":null}},"type":"group","time":182}
{"test":{"id":2,"name":"failed","groupIDs":[1],"metadata":{"skip":false,"skipReason":null}},"type":"testStart","time":183}
{"testID":2,"error":"will fail","stackTrace":"package:test                   fail\ntest/data/fail_test_.dart 7:5  main.<fn>.<async>\n===== asynchronous gap ===========================\ndart:async                     _Completer.completeError\ntest/data/fail_test_.dart 8:4  main.<fn>.<async>\n===== asynchronous gap ===========================\ndart:async                     Future.Future.microtask\ntest/data/fail_test_.dart      main.<fn>\n","isFailure":true,"type":"error","time":345}
{"testID":2,"result":"failure","hidden":false,"type":"testDone","time":346}
{"success":false,"type":"done","time":348}
 */
int pubRunTestJsonFailureCount(String stdout) {
  var count = 0;
  for (var line in LineSplitter.split(stdout)) {
    try {
      var map = json.decode(line);
      //print(map);
      if (map is Map) {
        // {"testID":2,"result":"failure","hidden":false,"type":"testDone","time":346}
        if (map['testID'] != null) {
          if ((map['result'] == 'failure') && (map['hidden'] != true)) {
            count++;
          }
        }
      }
    } catch (_) {}
  }

  return count;
}
