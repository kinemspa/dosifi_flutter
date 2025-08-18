#!/usr/bin/env node
/*
  Minimal MCP server that proxies to an Appium server (uiautomator2) over stdio.
  Requires appium installed globally and a running device/emulator.
*/
const { spawn } = require('child_process');
const readline = require('readline');

function run(cmd, args = [], opts = {}) {
  return new Promise((resolve) => {
    const proc = spawn(cmd, args, { shell: process.platform === 'win32', ...opts });
    let out = '', err = '';
    proc.stdout.on('data', (d) => (out += d.toString()))
    proc.stderr.on('data', (d) => (err += d.toString()))
    proc.on('close', (code) => resolve({ code, out, err }));
  });
}

// --- MCP glue ---
const serverInfo = { name: 'dosifi-appium-mcp', version: '0.1.0' };

const tools = [
  {
    name: 'appium.version',
    description: 'Report Appium CLI version',
    inputSchema: { type: 'object', additionalProperties: false, properties: {} },
  },
  {
    name: 'appium.doctor',
    description: 'Run appium doctor --android to validate environment',
    inputSchema: { type: 'object', additionalProperties: false, properties: {} },
  },
  {
    name: 'appium.startSession',
    description: 'Placeholder note instructing to run a long-lived Appium server',
    inputSchema: { type: 'object', additionalProperties: true, properties: { caps: { type: 'object' } } },
  }
];

async function callTool(name, args) {
  switch (name) {
    case 'appium.version': {
      const r = await run('appium', ['--version']);
      if (r.code !== 0) throw new Error(r.err || 'appium --version failed');
      return { mimeType: 'text/plain', text: r.out.trim() };
    }
    case 'appium.doctor': {
      const r = await run('appium', ['doctor', '--android']);
      if (r.code !== 0) throw new Error(r.err || 'appium doctor failed');
      return { mimeType: 'text/plain', text: r.out };
    }
    case 'appium.startSession': {
      return { mimeType: 'application/json', text: JSON.stringify({ note: 'Run `appium` in another terminal and we can extend this server to create sessions over HTTP next.' }) };
    }
    default:
      throw new Error(`Unknown tool: ${name}`);
  }
}

function send(res) { process.stdout.write(JSON.stringify(res) + '\n'); }

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
      return send({ jsonrpc: '2.0', id, error: { code: -32601, message: `Unknown method: ${method}` } });
    } catch (e) {
      return send({ jsonrpc: '2.0', id, error: { code: -32000, message: e?.message || String(e) } });
    }
  });
})();

