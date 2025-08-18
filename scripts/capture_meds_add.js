const { createSession, deleteSession } = require('../tests/automation/helpers/httpClient');
const { tapByText, tapFabNearBottomRight, wait, request } = require('../tests/automation/helpers/ui');
const fs = require('fs');

function caps() {
  return {
    alwaysMatch: {
      platformName: 'Android',
      'appium:automationName': 'UiAutomator2',
      'appium:deviceName': process.env.DEVICE_NAME || 'emulator-5554',
      'appium:appPackage': process.env.APP_PKG || 'com.dosifi.dosifi_flutter',
      'appium:appActivity': process.env.APP_ACTIVITY || '.MainActivity',
      'appium:noReset': true,
      'appium:newCommandTimeout': 120,
    },
    firstMatch: [{}],
  };
}

(async () => {
  fs.mkdirSync('tmp', { recursive: true });
  let sessionId;
  try {
    const s = await createSession(caps());
    sessionId = s.sessionId;
    await wait(1200);
    // Navigate to Medications (content-desc 'Meds')
    await tapByText(sessionId, 'Meds');
    await wait(800);
    // Tap FAB to open Add Medication
    await tapFabNearBottomRight(sessionId);
    await wait(1200);
    // Capture page source and screenshot
    const srcRes = await request(`/session/${sessionId}/source`);
    fs.writeFileSync('tmp/page_source_meds_add.xml', srcRes.value || '', 'utf8');
    const shot = await request(`/session/${sessionId}/screenshot`);
    fs.writeFileSync('tmp/meds_add.png', Buffer.from(shot.value, 'base64'));
    console.log('Saved tmp/page_source_meds_add.xml and tmp/meds_add.png');
    process.exit(0);
  } catch (e) {
    console.error('Capture Meds Add failed:', e.message || e);
    process.exit(1);
  } finally {
    try { if (sessionId) await deleteSession(sessionId); } catch {}
  }
})();

