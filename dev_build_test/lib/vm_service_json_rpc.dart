/// A minimal client of the Dart VM service (json-rpc 2.0 over a dart:io web
/// socket), enough to call service extensions without `package:vm_service`.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// The web socket uri of the VM service [uri] as printed
/// (`http://127.0.0.1:<port>/<token>=/`).
Uri vmServiceWebSocketUri(Uri uri) {
  final path = uri.path.endsWith('/') ? uri.path : '${uri.path}/';
  return uri.replace(scheme: 'ws', path: '${path}ws');
}

/// A json-rpc connection to a VM service.
class VmServiceJsonRpc {
  VmServiceJsonRpc._(this._socket) {
    _subscription = _socket.listen((data) {
      final message = (jsonDecode(data as String) as Map)
          .cast<String, Object?>();
      final completer = _pending.remove(message['id']);
      if (completer != null) {
        final error = message['error'];
        if (error != null) {
          completer.completeError(StateError('$error'));
        } else {
          completer.complete(
            (message['result'] as Map).cast<String, Object?>(),
          );
        }
      }
    });
  }

  /// Connects to the VM service [uri] (http or ws).
  static Future<VmServiceJsonRpc> connect(Uri uri) async {
    final wsUri = uri.scheme == 'ws' ? uri : vmServiceWebSocketUri(uri);
    return VmServiceJsonRpc._(await WebSocket.connect(wsUri.toString()));
  }

  final WebSocket _socket;
  late final StreamSubscription<Object?> _subscription;
  final _pending = <String, Completer<Map<String, Object?>>>{};
  var _id = 0;

  /// Calls [method] with [params], its result (or a [StateError]).
  Future<Map<String, Object?>> call(
    String method, [
    Map<String, Object?> params = const {},
    Duration timeout = const Duration(seconds: 30),
  ]) {
    final id = '${++_id}';
    final completer = _pending[id] = Completer<Map<String, Object?>>();
    _socket.add(
      jsonEncode({
        'jsonrpc': '2.0',
        'id': id,
        'method': method,
        'params': params,
      }),
    );
    return completer.future.timeout(timeout);
  }

  /// The id of the first isolate that registered the service extension
  /// [extension], null if none within [timeout].
  Future<String?> findIsolateWithExtension(
    String extension, {
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final stopwatch = Stopwatch()..start();
    while (true) {
      final vm = await call('getVM');
      for (final ref in (vm['isolates'] as List).cast<Map>()) {
        final isolate = await call('getIsolate', {'isolateId': ref['id']});
        final extensions = (isolate['extensionRPCs'] as List?) ?? const [];
        if (extensions.contains(extension)) {
          return ref['id'] as String;
        }
      }
      if (stopwatch.elapsed > timeout) {
        return null;
      }
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
  }

  /// Closes the connection.
  Future<void> close() async {
    await _subscription.cancel();
    await _socket.close();
  }
}
