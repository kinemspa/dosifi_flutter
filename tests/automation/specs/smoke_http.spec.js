const { expect } = require('chai');
const { createSession, deleteSession, getSource } = require('../helpers/httpClient');

function w3cCaps() {
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

describe('Smoke (HTTP): App launch', function () {
  this.timeout(180000);
  let sessionId;

  afterEach(async () => {
    if (sessionId) {
      await deleteSession(sessionId);
      sessionId = undefined;
    }
  });

  it('creates session and fetches page source', async () => {
    const { sessionId: sid } = await createSession(w3cCaps());
    sessionId = sid;
    const source = await getSource(sessionId);
    expect(source).to.be.a('string');
    expect(source.length).to.be.greaterThan(100);
  });
});

