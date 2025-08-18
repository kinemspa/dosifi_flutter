// Minimal MCP-like server for Flutter via VM Service
// Usage:
//   dart tool/flutter_mcp.dart --vm-service-url=ws://127.0.0.1:xxxxx/xxxxx=
//   or
//   dart tool/flutter_mcp.dart --vm-service-file=.dart_tool/vmservice.json
//
// Protocol (very simple JSON over stdin/stdout, one JSON per line):
//   Request: {"id":1, "method":"tools/list"}
//   Request: {"id":2, "method":"tools/call", "params": {"name":"flutter.screenshot"}}
//   Response: {"id":2, "result": { ... }}
//
// Exposed tools:
//   - flutter.screenshot -> { ok, pngBase64 }
//   - flutter.dumpRenderTree -> { ok, renderTree }
//   - flutter.dumpSemantics -> { ok, semantics }
//   - flutter.dumpApp -> { ok, widgetTree }

import 'dart:async';
import 'dart:convert';
import 'dart:io';

class VmServiceClient {
  final Uri wsUri;
  WebSocket? _ws;
  int _nextId = 1;
  final Map<int, Completer<Map<String, dynamic>>> _pending = {};
  String? _isolateId;

  VmServiceClient(this.wsUri);

  Future<void> connect() async {
    _ws = await WebSocket.connect(wsUri.toString());
    _ws!.listen((data) {
      try {
        final msg = json.decode(data as String) as Map<String, dynamic>;
        final id = msg['id'];
        if (id is int && _pending.containsKey(id)) {
          _pending.remove(id)!.complete(msg);
        }
      } catch (_) {}
    }, onDone: () {
      for (final c in _pending.values) {
        if (!c.isCompleted) c.completeError('VM service closed');
      }
      _pending.clear();
    }, onError: (err) {
      for (final c in _pending.values) {
        if (!c.isCompleted) c.completeError(err);
      }
      _pending.clear();
    });

    // Get VM and isolate id
    final vm = await _send('getVM');
    final isolates = (vm['result']?['isolates'] as List?) ?? const [];
    if (isolates.isEmpty) throw 'No isolates in VM service';
    _isolateId = (isolates.first as Map)['id'] as String;
  }

  Future<Map<String, dynamic>> _send(String method, [Map<String, dynamic>? params]) async {
    final id = _nextId++;
    final c = Completer<Map<String, dynamic>>();
    _pending[id] = c;
    final payload = {
      'jsonrpc': '2.0',
      'id': id,
      'method': method,
      if (params != null) 'params': params,
    };
    _ws!.add(json.encode(payload));
    return await c.future.timeout(const Duration(seconds: 5));
  }

  Future<Map<String, dynamic>> callExtension(String extName) async {
    if (_isolateId == null) throw 'Isolate not ready';
    final resp = await _send('callServiceExtension', {
      'isolateId': _isolateId,
      'method': extName,
    });
    final result = resp['result'] as Map<String, dynamic>?;
    if (result == null) throw 'Bad VM response';
    // ServiceExtension returns JSON string under key 'json'
    final jsonStr = result['json'] as String?;
    if (jsonStr == null) return {'ok': false, 'error': 'No json in extension result'};
    return json.decode(jsonStr) as Map<String, dynamic>;
  }
}

class McpServer {
  final VmServiceClient vm;
  McpServer(this.vm);

  Future<void> serve() async {
    final input = stdin.transform(utf8.decoder).transform(const LineSplitter());
    await for (final line in input) {
      if (line.trim().isEmpty) continue;
      try {
        final req = json.decode(line) as Map<String, dynamic>;
        final id = req['id'];
        final method = req['method'] as String?;
        if (method == 'tools/list') {
          final tools = [
            {'name': 'flutter.screenshot', 'description': 'Capture UI screenshot (base64 PNG)'},
            {'name': 'flutter.dumpRenderTree', 'description': 'Dump render tree text'},
            {'name': 'flutter.dumpSemantics', 'description': 'Dump semantics tree'},
            {'name': 'flutter.dumpApp', 'description': 'Dump widget tree'},
          ];
          _write({'id': id, 'result': {'tools': tools}});
        } else if (method == 'tools/call') {
          final params = (req['params'] as Map?) ?? {};
          final name = params['name'] as String?;
          Map<String, dynamic> result;
          switch (name) {
            case 'flutter.screenshot':
              result = await vm.callExtension('ext.dosifi.screenshot');
              break;
            case 'flutter.dumpRenderTree':
              result = await vm.callExtension('ext.dosifi.dumpRenderTree');
              break;
            case 'flutter.dumpSemantics':
              result = await vm.callExtension('ext.dosifi.dumpSemantics');
              break;
            case 'flutter.dumpApp':
              result = await vm.callExtension('ext.dosifi.dumpApp');
              break;
            default:
              result = {'ok': false, 'error': 'Unknown tool: $name'};
          }
          _write({'id': id, 'result': result});
        } else {
          _write({'id': id, 'error': {'message': 'Unknown method'}});
        }
      } catch (e) {
        _write({'error': {'message': e.toString()}});
      }
    }
  }

  void _write(Map<String, dynamic> obj) {
    stdout.writeln(json.encode(obj));
  }
}

Future<void> main(List<String> args) async {
  String? wsUrl = Platform.environment['FLUTTER_VM_SERVICE_URL'];
  String? vmFile;
  for (final a in args) {
    if (a.startsWith('--vm-service-url=')) {
      final idx = a.indexOf('=');
      if (idx != -1 && idx + 1 < a.length) {
        wsUrl = a.substring(idx + 1);
      }
    } else if (a.startsWith('--vm-service-file=')) {
      final idx = a.indexOf('=');
      if (idx != -1 && idx + 1 < a.length) {
        vmFile = a.substring(idx + 1);
      }
    }
  }
  if (wsUrl == null && vmFile != null) {
    try {
      final text = await File(vmFile).readAsString();
      // Accept either plain ws URL or JSON with a "wsUri" field
      if (text.trim().startsWith('{')) {
        final m = json.decode(text) as Map<String, dynamic>;
        wsUrl = (m['wsUri'] ?? m['uri'] ?? m['wsUrl']) as String?;
      } else {
        wsUrl = text.trim();
      }
    } catch (e) {
      stderr.writeln('Failed to read vm-service file: $e');
    }
  }
  if (wsUrl == null) {
    stderr.writeln('Missing VM Service URL. Provide --vm-service-url or --vm-service-file or set FLUTTER_VM_SERVICE_URL.');
    exit(2);
  }
  final client = VmServiceClient(Uri.parse(wsUrl));
  await client.connect();
  final server = McpServer(client);
  await server.serve();
}

