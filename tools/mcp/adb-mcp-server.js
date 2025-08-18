#!/usr/bin/env node
/*
  Minimal MCP server that exposes common ADB operations over stdio.
  Tools required: adb on PATH.
*/
const { spawn } = require('child_process');
const readline = require('readline');

function run(cmd, args = []) {
  return new Promise((resolve) => {
    const proc = spawn(cmd, args, { shell: process.platform === 'win32' });
    let out = '', err = '';
    proc.stdout.on('data', (d) => (out += d.toString()));
    proc.stderr.on('data', (d) => (err += d.toString()));
    proc.on('close', (code) => resolve({ code, out, err }));
  });
}

// --- MCP glue ---
const serverInfo = { name: 'dosifi-adb-mcp', version: '0.1.0' };

const tools = [
  {
    name: 'adb.devices',
    description: 'List connected Android devices (adb devices -l)',
    inputSchema: { type: 'object', additionalProperties: false, properties: {} },
  },
  {
    name: 'adb.screencap',
    description: 'Take a screenshot via adb exec-out screencap -p and return base64 PNG',
    inputSchema: {
      type: 'object',
      additionalProperties: false,
      properties: {
        serial: { type: 'string', description: 'Device serial (optional)' },
        dest: { type: 'string', description: 'Suggested filename (optional)' },
      },
    },
  },
  {
    name: 'adb.launchApp',
    description: 'Launch an Android activity (am start -n <pkg>/<activity>)',
    inputSchema: {
      type: 'object',
      required: ['pkg', 'activity'],
      additionalProperties: false,
      properties: {
        serial: { type: 'string' },
        pkg: { type: 'string' },
        activity: { type: 'string' },
      },
    },
  },
  {
    name: 'adb.inputTap',
    description: 'Simulate a tap at screen coordinates (input tap x y)',
    inputSchema: {
      type: 'object',
      required: ['x', 'y'],
      additionalProperties: false,
      properties: {
        serial: { type: 'string' },
        x: { type: 'number' },
        y: { type: 'number' },
      },
    },
  },
];

async function callTool(name, args) {
  switch (name) {
    case 'adb.devices': {
      const r = await run('adb', ['devices', '-l']);
      if (r.code !== 0) throw new Error(r.err || 'adb devices failed');
      return { mimeType: 'text/plain', text: r.out };
    }
    case 'adb.screencap': {
      const serial = args?.serial;
      const dest = args?.dest || `screenshot-${Date.now()}.png`;
      const adbArgs = [];
      if (serial) adbArgs.push('-s', serial);
      adbArgs.push('exec-out', 'screencap', '-p');
      const r = await run('adb', adbArgs);
      if (r.code !== 0 || !r.out) throw new Error(r.err || 'screencap failed');
      const b64 = Buffer.from(r.out, 'binary').toString('base64');
      return { mimeType: 'application/json', text: JSON.stringify({ filename: dest, pngBase64: b64 }) };
    }
    case 'adb.launchApp': {
      const { serial, pkg, activity } = args || {};
      if (!pkg || !activity) throw new Error('pkg and activity required');
      const adbArgs = [];
      if (serial) adbArgs.push('-s', serial);
      adbArgs.push('shell', 'am', 'start', '-n', `${pkg}/${activity}`);
      const r = await run('adb', adbArgs);
      if (r.code !== 0) throw new Error(r.err || 'launch failed');
      return { mimeType: 'text/plain', text: r.out };
    }
    case 'adb.inputTap': {
      const { serial, x, y } = args || {};
      if (x == null || y == null) throw new Error('x and y required');
      const adbArgs = [];
      if (serial) adbArgs.push('-s', serial);
      adbArgs.push('shell', 'input', 'tap', String(x), String(y));
      const r = await run('adb', adbArgs);
      if (r.code !== 0) throw new Error(r.err || 'tap failed');
      return { mimeType: 'text/plain', text: 'ok' };
    }
    default:
      throw new Error(`Unknown tool: ${name}`);
  }
}

function send(res) {
  process.stdout.write(JSON.stringify(res) + '\n');
}

(async function main() {
  const rl = readline.createInterface({ input: process.stdin });
  rl.on('line', async (line) => {
    let msg; try { msg = JSON.parse(line); } catch { return; }
    const { id, method, params } = msg;
    try {
      if (method === 'initialize') {
        return send({ jsonrpc: '2.0', id, result: { protocolVersion: params?.protocolVersion || '2024-11-05', serverInfo, capabilities: { tools: {} } } });
      }
      if (method === 'tools/list') {
        return send({ jsonrpc: '2.0', id, result: { tools } });
      }
      if (method === 'tools/call') {
        const { name, arguments: args } = params || {};
        const content = await callTool(name, args);
        return send({ jsonrpc: '2.0', id, result: { content: [content] } });
      }
      // Fallback: unknown method
      return send({ jsonrpc: '2.0', id, error: { code: -32601, message: `Unknown method: ${method}` } });
    } catch (e) {
      return send({ jsonrpc: '2.0', id, error: { code: -32000, message: e?.message || String(e) } });
    }
  });
})();

