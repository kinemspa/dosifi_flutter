const { expect } = require('chai');
const { createSession, deleteSession } = require('../helpers/httpClient');
const { tapByText, tapFabNearBottomRight, wait } = require('../helpers/ui');

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

describe('Medications flow', function () {
  this.timeout(240000);
  let sessionId;

  before(async () => {
    const { ensureBottomNavVisible } = require('../helpers/ui');
    const s = await createSession(caps());
    sessionId = s.sessionId;
    await wait(1500);
    await ensureBottomNavVisible(sessionId, 5);
  });

  after(async () => { if (sessionId) await deleteSession(sessionId); });

  it('navigates to Medications tab', async () => {
    await tapByText(sessionId, 'Menu');
    await wait(300);
    await tapByText(sessionId, 'Medications');
    await wait(1000);
  });

  it('opens Add Medication and then backs out', async () => {
    // Prefer tapping by tooltip/label
    try {
      await tapByText(sessionId, 'Add Medication');
    } catch {
      await tapFabNearBottomRight(sessionId);
    }
    await wait(1000);
  });
});

