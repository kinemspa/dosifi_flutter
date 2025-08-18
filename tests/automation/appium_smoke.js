const wd = require('wd');

(async () => {
  const serverUrl = 'http://127.0.0.1:4723/wd/hub';
  const w3cCaps = {
    alwaysMatch: {
      platformName: 'Android',
      'appium:automationName': 'UiAutomator2',
      'appium:deviceName': 'emulator-5554',
      'appium:appPackage': 'com.dosifi.dosifi_flutter',
      'appium:appActivity': '.MainActivity',
      'appium:noReset': true,
      'appium:newCommandTimeout': 120,
      'appium:unicodeKeyboard': true,
      'appium:resetKeyboard': true,
    },
    firstMatch: [{}],
  };

  const driver = wd.promiseChainRemote(serverUrl);
  driver.on('status', info => console.log(info));
  driver.on('command', (meth, path, data) => console.log(' >', meth, path, data || ''));
  driver.on('http', (meth, path, data) => console.log('   > HTTP', meth, path));

  try {
    const legacyCaps = {
      platformName: 'Android',
      automationName: 'UiAutomator2',
      deviceName: 'emulator-5554',
      appPackage: 'com.dosifi.dosifi_flutter',
      appActivity: '.MainActivity',
      noReset: true,
      newCommandTimeout: 120,
      unicodeKeyboard: true,
      resetKeyboard: true,
    };
    await driver.init({
      capabilities: w3cCaps,
      desiredCapabilities: legacyCaps,
    });
    const sessionId = await driver.sessionID();
    console.log('SESSION OK:', sessionId);

    // Small wait to let the UI settle
    await new Promise(r => setTimeout(r, 1500));

    // Fetch and log a shortened page source to verify UI is accessible
    const src = await driver.source();
    console.log('PAGE SOURCE LENGTH:', src?.length || 0);

    await driver.quit();
    console.log('SESSION CLOSED');
    process.exit(0);
  } catch (e) {
    console.error('SESSION FAILED:', e && e.message ? e.message : e);
    try { await driver.quit(); } catch {}
    process.exit(1);
  }
})();

