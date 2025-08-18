const BASE_URL = process.env.APPIUM_SERVER_URL || 'http://127.0.0.1:4723/wd/hub';

async function createSession(capabilities) {
  const res = await fetch(`${BASE_URL}/session`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ capabilities }),
  });
  if (!res.ok) {
    const text = await res.text();
    throw new Error(`Session create failed: HTTP ${res.status} ${text}`);
  }
  const data = await res.json();
  return { sessionId: data.value.sessionId || data.sessionId, caps: data.value.capabilities || data.value };
}

async function deleteSession(sessionId) {
  await fetch(`${BASE_URL}/session/${sessionId}`, { method: 'DELETE' });
}

async function getSource(sessionId) {
  const res = await fetch(`${BASE_URL}/session/${sessionId}/source`);
  if (!res.ok) throw new Error(`Get source failed: ${res.status}`);
  const data = await res.json();
  return data.value || '';
}

module.exports = { createSession, deleteSession, getSource, BASE_URL };

