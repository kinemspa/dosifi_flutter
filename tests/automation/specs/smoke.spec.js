const { expect } = require('chai');
const { createSession, deleteSession, getSource } = require('../helpers/httpClient');

describe('Smoke: App launch and basic UI (wd fallback disabled)', function () {
  this.timeout(180000);
  let sessionId;

  after(async () => {
    if (sessionId) {
      try { await deleteSession(sessionId); } catch {}
    }
  });

  it('loads main activity and has UI elements', async () => {
    const caps = {
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
    const { sessionId: sid } = await createSession(caps);
    sessionId = sid;
    // Give the app a moment to settle
    await new Promise(r => setTimeout(r, 2000));
    const source = await getSource(sessionId);
    expect(source).to.be.a('string');
    expect(source.length).to.be.greaterThan(100);
  });
});
