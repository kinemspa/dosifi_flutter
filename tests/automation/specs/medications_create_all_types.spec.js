const { expect } = require('chai');
const { createSession, deleteSession } = require('../helpers/httpClient');
const { tapByText, tapFabNearBottomRight, wait, findElements, setValue, tapBottomNavByIndex } = require('../helpers/ui');

function caps() {
  return {
    alwaysMatch: {
      platformName: 'Android',
      'appium:automationName': 'UiAutomator2',
      'appium:deviceName': process.env.DEVICE_NAME || 'emulator-5554',
      'appium:appPackage': process.env.APP_PKG || 'com.dosifi.dosifi_flutter',
      'appium:appActivity': process.env.APP_ACTIVITY || '.MainActivity',
      'appium:noReset': true,
      'appium:newCommandTimeout': 180,
    },
    firstMatch: [{}],
  };
}

// Map enum names to UI display names
const typeDisplayNames = [
  'Tablet',
  'Capsule',
  'Liquid',
  'Pre-filled Syringe',
  'Ready Made Vial',
  'Lyophilized Vial',
  'Single-Use Pen',
  'Multi-Use Pen',
  'Drops',
  'Inhaler',
  'Patch',
  'Suppository',
  'Other',
];

async function enterNameInFirstField(sessionId, name) {
  // Find first EditText on the form and enter a name
  const inputs = await findElements(sessionId, 'class name', 'android.widget.EditText');
  if (!inputs || inputs.length === 0) throw new Error('No text input fields found');
  await setValue(sessionId, inputs[0], name);
}

describe('Create one of each Medication type', function () {
  this.timeout(600000);
  let sessionId;

  before(async () => {
    const s = await createSession(caps());
    sessionId = s.sessionId;
    await wait(1200);
    const { ensureBottomNavVisible, tapBottomNavByIndex } = require('../helpers/ui');
    await ensureBottomNavVisible(sessionId, 5);
    // Open drawer and navigate to Medications
    await tapByText(sessionId, 'Menu');
    await wait(300);
    await tapByText(sessionId, 'Medications');
    await wait(800);
  });

  after(async () => { if (sessionId) await deleteSession(sessionId); });

  for (const typeName of typeDisplayNames) {
    it(`adds ${typeName}`, async () => {
      // Open Add Medication
      await tapFabNearBottomRight(sessionId);
      await wait(800);

      // Open type selector (by descriptionContains)
      await tapByText(sessionId, 'Medication Type');
      await wait(500);

      // Select desired type by textContains
      await tapByText(sessionId, typeName);
      await wait(600);

      // Enter a name
      await enterNameInFirstField(sessionId, `Auto ${typeName}`);
      await wait(300);

      // Save (there is a confirmation dialog followed by final save)
      await tapByText(sessionId, 'Save Medication');
      await wait(400);
      // Confirm dialog also has 'Save Medication'
      await tapByText(sessionId, 'Save Medication');
      await wait(800);
    });
  }
});

