const wd = require('wd');
const { expect } = require('chai');

const SERVER_URL = process.env.APPIUM_SERVER_URL || 'http://127.0.0.1:4723/wd/hub';
const DEVICE_NAME = process.env.DEVICE_NAME || 'emulator-5554';
const APP_PKG = process.env.APP_PKG || 'com.dosifi.dosifi_flutter';
const APP_ACTIVITY = process.env.APP_ACTIVITY || '.MainActivity';

function buildCaps() {
  return {
    capabilities: {
      alwaysMatch: {
        platformName: 'Android',
        'appium:automationName': 'UiAutomator2',
        'appium:deviceName': DEVICE_NAME,
        'appium:appPackage': APP_PKG,
        'appium:appActivity': APP_ACTIVITY,
        'appium:noReset': true,
        'appium:newCommandTimeout': 120,
      },
      firstMatch: [{}],
    },
    desiredCapabilities: {
      platformName: 'Android',
      automationName: 'UiAutomator2',
      deviceName: DEVICE_NAME,
      appPackage: APP_PKG,
      appActivity: APP_ACTIVITY,
      noReset: true,
      newCommandTimeout: 120,
    },
  };
}

function createDriver() {
  const driver = wd.promiseChainRemote(SERVER_URL);
  return driver;
}

module.exports = { buildCaps, createDriver, SERVER_URL, DEVICE_NAME, APP_PKG, APP_ACTIVITY, expect };

