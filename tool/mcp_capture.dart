// One-shot VM service extension caller to capture a Flutter screenshot
// Usage examples:
//   dart run tool/mcp_capture.dart --vm-service-url=ws://127.0.0.1:<port>/<path>= --out=screenshots/home.png
//   dart run tool/mcp_capture.dart --vm-service-file=.dart_tool/vmservice.json --out=screenshots/home.png
// The app under test must register the `ext.dosifi.screenshot` extension that returns
// JSON with `{ "ok": true, "pngBase64": "..." }`.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

Future<void> main(List<String> args) async {
  String? wsUrl;
  String? vmFile;
  String outPath = 'screenshots/home.png';

  for (final a in args) {
    if (a.startsWith('--vm-service-url=')) {
      wsUrl = a.substring(a.indexOf('=') + 1);
    } else if (a.startsWith('--vm-service-file=')) {
      vmFile = a.substring(a.indexOf('=') + 1);
    } else if (a.startsWith('--out=')) {
      outPath = a.substring(a.indexOf('=') + 1);
    }
  }

  wsUrl ??= Platform.environment['FLUTTER_VM_SERVICE_URL'];

  if (wsUrl == null && vmFile != null) {
    final file = File(vmFile);
    if (await file.exists()) {
      final text = await file.readAsString();
      if (text.trim().startsWith('{')) {
        final m = json.decode(text) as Map<String, dynamic>;
        wsUrl = (m['wsUri'] ?? m['uri'] ?? m['wsUrl']) as String?;
      } else {
        wsUrl = text.trim();
      }
    }
  }

  if (wsUrl == null) {
    stderr.writeln('No VM service URL found. Provide --vm-service-url or --vm-service-file or set FLUTTER_VM_SERVICE_URL.');
    exit(2);
  }

  // Connect websocket
  final ws = await WebSocket.connect(wsUrl!);
  final pending = <int, Completer<Map<String, dynamic>>>{};
  int nextId = 1;
  String? isolateId;

  final sub = ws.listen((data) {
    try {
      final msg = json.decode(data as String) as Map<String, dynamic>;
      final id = msg['id'];
      if (id is int && pending.containsKey(id)) {
        pending.remove(id)!.complete(msg);
      }
    } catch (_) {}
  }, onDone: () {
    for (final c in pending.values) {
      if (!c.isCompleted) c.completeError('VM service closed');
    }
    pending.clear();
  }, onError: (err) {
    for (final c in pending.values) {
      if (!c.isCompleted) c.completeError(err);
    }
    pending.clear();
  });

  Future<Map<String, dynamic>> send(String method, [Map<String, dynamic>? params]) async {
    final id = nextId++;
    final c = Completer<Map<String, dynamic>>();
    pending[id] = c;
    ws.add(json.encode({
      'jsonrpc': '2.0',
      'id': id,
      'method': method,
      if (params != null) 'params': params,
    }));
    return c.future.timeout(const Duration(seconds: 5));
  }

  // Query VM to get isolate id
  final vm = await send('getVM');
  final isolates = (vm['result']?['isolates'] as List?) ?? const [];
  if (isolates.isEmpty) {
    stderr.writeln('No isolates present in VM service');
    await sub.cancel();
    await ws.close();
    exit(3);
  }
  isolateId = (isolates.first as Map)['id'] as String;

  // Call extension
  final resp = await send('callServiceExtension', {
    'isolateId': isolateId,
    'method': 'ext.dosifi.screenshot',
  });
  final result = resp['result'] as Map<String, dynamic>?;
  if (result == null) {
    stderr.writeln('Bad VM response (no result)');
    await sub.cancel();
    await ws.close();
    exit(4);
  }
  final jsonStr = result['json'] as String?;
  if (jsonStr == null) {
    stderr.writeln('Extension result had no json field.');
    await sub.cancel();
    await ws.close();
    exit(5);
  }
  final ext = json.decode(jsonStr) as Map<String, dynamic>;
  if (ext['ok'] != true || (ext['pngBase64'] as String?) == null) {
    stderr.writeln('Extension reported error or missing pngBase64: ${ext}');
    await sub.cancel();
    await ws.close();
    exit(6);
  }

  final bytes = base64Decode(ext['pngBase64'] as String);
  final outFile = File(outPath);
  await outFile.parent.create(recursive: true);
  await outFile.writeAsBytes(bytes);
  stdout.writeln('Saved screenshot to ${outFile.path}');

  await sub.cancel();
  await ws.close();
}

