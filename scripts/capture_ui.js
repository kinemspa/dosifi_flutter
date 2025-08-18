const { createSession, deleteSession, getSource } = require('../tests/automation/helpers/httpClient');
const { request } = require('../tests/automation/helpers/ui');
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
  try {
    // Ensure output dir
    fs.mkdirSync('tmp', { recursive: true });

    // Create session
    const { sessionId } = await createSession(caps());

    // Page source
    const source = await getSource(sessionId);
    fs.writeFileSync('tmp/page_source.xml', source, 'utf8');

    // Screenshot
    const res = await request(`/session/${sessionId}/screenshot`);
    const b64 = res.value;
    fs.writeFileSync('tmp/appium_screenshot.png', Buffer.from(b64, 'base64'));

    // Quit session
    await deleteSession(sessionId);

    console.log('Saved tmp/page_source.xml and tmp/appium_screenshot.png');
    process.exit(0);
  } catch (e) {
    console.error('Capture failed:', e.message || e);
    process.exit(1);
  }
})();

