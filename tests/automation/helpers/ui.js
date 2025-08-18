const BASE_URL = process.env.APPIUM_SERVER_URL || 'http://127.0.0.1:4723/wd/hub';

async function request(path, options = {}) {
  const res = await fetch(`${BASE_URL}${path}`, options);
  if (!res.ok) {
    const text = await res.text();
    throw new Error(`${options.method || 'GET'} ${path} -> HTTP ${res.status} ${text}`);
  }
  return res.json();
}

async function findElement(sessionId, using, value) {
  const data = await request(`/session/${sessionId}/element`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ using, value }),
  });
  return data.value.ELEMENT || data.value["element-6066-11e4-a52e-4f735466cecf"];
}

async function findElementOrNull(sessionId, using, value) {
  try {
    return await findElement(sessionId, using, value);
  } catch {
    return null;
  }
}

async function click(sessionId, elementId) {
  await request(`/session/${sessionId}/element/${elementId}/click`, { method: 'POST' });
}

async function setValue(sessionId, elementId, text) {
  await request(`/session/${sessionId}/element/${elementId}/clear`, { method: 'POST' });
  await request(`/session/${sessionId}/element/${elementId}/value`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ text: `${text}`, value: [...`${text}`] }),
  });
}

async function deviceBack(sessionId) {
  // UiAutomator2 endpoint
  await request(`/session/${sessionId}/appium/device/press_keycode`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ keycode: 4 }),
  });
}

async function findByText(sessionId, text) {
  // Try accessibility id (content-desc) exact
  let el = await findElementOrNull(sessionId, 'accessibility id', text);
  if (el) return el;
  // Try descriptionContains
  el = await findElementOrNull(sessionId, '-android uiautomator', `new UiSelector().descriptionContains(\"${text}\")`);
  if (el) return el;
  // Try exact text via UiSelector
  el = await findElementOrNull(sessionId, '-android uiautomator', `new UiSelector().text(\"${text}\")`);
  if (el) return el;
  // Try contains text
  el = await findElementOrNull(sessionId, '-android uiautomator', `new UiSelector().textContains(\"${text}\")`);
  if (el) return el;
  return null;
}

async function tapByText(sessionId, text) {
  const el = await findByText(sessionId, text);
  if (!el) throw new Error(`Element with text or content-desc '${text}' not found`);
  await click(sessionId, el);
}

async function getRect(sessionId, elementId) {
  const res = await request(`/session/${sessionId}/element/${elementId}/rect`);
  return res.value;
}

async function findButtons(sessionId) {
  const data = await request(`/session/${sessionId}/elements`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ using: 'class name', value: 'android.widget.Button' }),
  });
  const ids = (data.value || []).map(v => v.ELEMENT || v["element-6066-11e4-a52e-4f735466cecf"]);
  return ids;
}

async function findElementsByDescContains(sessionId, needle) {
  const data = await request(`/session/${sessionId}/elements`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ using: '-android uiautomator', value: `new UiSelector().descriptionContains(\"${needle}\")` }),
  });
  return (data.value || []).map(v => v.ELEMENT || v["element-6066-11e4-a52e-4f735466cecf"]);
}

async function findElementsByDescExact(sessionId, needle) {
  const data = await request(`/session/${sessionId}/elements`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ using: '-android uiautomator', value: `new UiSelector().description(\"${needle}\")` }),
  });
  return (data.value || []).map(v => v.ELEMENT || v["element-6066-11e4-a52e-4f735466cecf"]);
}

async function tapFabNearBottomRight(sessionId) {
  // Try by known accessibility labels first
  const labels = ['Add Medication','Add a new schedule','Add Supply'];
  for (const label of labels) {
    const el = await findByText(sessionId, label);
    if (el) {
      await click(sessionId, el);
      return;
    }
  }
  const btns = await findButtons(sessionId);
  let candidate = null;
  let bestScore = -Infinity;
  for (const id of btns) {
    try {
      const r = await getRect(sessionId, id);
      // Heuristic: within lower area but above bottom nav, and towards right
      const yMid = r.y + r.height / 2;
      const xMid = r.x + r.width / 2;
      const score = xMid + yMid;
      if (yMid > 1400 && xMid > 400 && score > bestScore) {
        bestScore = score;
        candidate = id;
      }
    } catch {}
  }
  if (!candidate) throw new Error('FAB candidate (bottom-right) not found');
  await click(sessionId, candidate);
}

async function wait(ms) { return new Promise((r) => setTimeout(r, ms)); }

async function findElements(sessionId, using, value) {
  const data = await request(`/session/${sessionId}/elements`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ using, value }),
  });
  return (data.value || []).map(v => v.ELEMENT || v["element-6066-11e4-a52e-4f735466cecf"]);
}

async function getText(sessionId, elementId) {
  const res = await request(`/session/${sessionId}/element/${elementId}/text`);
  return res.value || '';
}

async function tapBottomNavByIndex(sessionId, zeroBasedIndex) {
  // Try mapping index to visible label first
  const labels = ['Home','Medications','Meds','Schedule','Calendar','Supplies','Settings'];
  if (zeroBasedIndex >= 0 && zeroBasedIndex < labels.length) {
    try {
      // Try exact/contains on accessibility id / text
      await tapByText(sessionId, labels[zeroBasedIndex]);
      return;
    } catch {
      // Try exact description selector
      const els = await findElementsByDescExact(sessionId, labels[zeroBasedIndex]);
      if (els && els.length) { await click(sessionId, els[0]); return; }
    }
  }
  // Fallback to existing heuristics
  // Prefer elements whose content-desc contains 'Tab '
  let candidates = await findElementsByDescContains(sessionId, 'Tab ');
  if (!candidates || candidates.length === 0) {
    // Fallback: any views with description matching known labels
    const descMatches = [];
    for (const label of labels) {
      const els = await findElementsByDescExact(sessionId, label);
      for (const id of els) {
        try { const r = await getRect(sessionId, id); descMatches.push({id, x: r.x, y: r.y}); } catch {}
      }
    }
    if (descMatches.length) {
      descMatches.sort((a,b) => a.x - b.x);
      candidates = descMatches.map(e => e.id);
    } else {
      // Last resort: buttons near bottom (less strict threshold)
      const btns = await findButtons(sessionId);
      const bottom = [];
      for (const id of btns) {
        try {
          const r = await getRect(sessionId, id);
          const yMid = r.y + r.height / 2;
          if (yMid > 1800) bottom.push({ id, x: r.x });
        } catch {}
      }
      if (bottom.length === 0) throw new Error('Bottom nav buttons not found');
      bottom.sort((a,b) => a.x - b.x);
      candidates = bottom.map(b => b.id);
    }
  } else {
    // Sort by x position left->right
    const withRect = [];
    for (const id of candidates) {
      try { const r = await getRect(sessionId, id); withRect.push({id, x: r.x}); } catch {}
    }
    withRect.sort((a,b) => a.x - b.x);
    candidates = withRect.map(w => w.id);
  }
  if (candidates.length < zeroBasedIndex + 1) throw new Error('Bottom nav buttons not enough');
  await click(sessionId, candidates[zeroBasedIndex]);
}

async function ensureBottomNavVisible(sessionId, attempts = 3) {
  for (let i = 0; i < attempts; i++) {
    // Look for buttons near the very bottom
    const btns = await findButtons(sessionId);
    for (const id of btns) {
      try {
        const r = await getRect(sessionId, id);
        const yMid = r.y + r.height / 2;
        if (yMid > 2120) return true;
      } catch {}
    }
    await deviceBack(sessionId);
    await wait(500);
  }
  return false;
}

module.exports = { request, findElement, findElementOrNull, findElements, click, setValue, deviceBack, findByText, tapByText, getRect, findButtons, tapFabNearBottomRight, getText, tapBottomNavByIndex, ensureBottomNavVisible, wait };

