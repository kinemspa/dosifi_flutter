# Android UI E2E Testing (Appium)

This guide explains how to run Android UI end-to-end tests for the Dosifi Flutter app using Appium v2, UiAutomator2, and Mocha.

Prerequisites
- Node.js and npm on your machine (already used by this repo)
- Android emulator running (e.g., emulator-5554) or a connected device with adb
- Flutter debug APK built: flutter build apk --debug

Install dev dependencies
- npm install

Start Appium and run tests
- Option 1: Full workflow (bootstrap emulator/app, start Appium, run tests)
  npm run e2e:all
- Option 2: Manual control
  1) Prepare device/emulator and app:
     npm run e2e:bootstrap
  2) In one terminal, start Appium:
     npm run appium:start
  3) In another terminal, run tests:
     npm run e2e:test

Environment variables (optional)
- APPIUM_SERVER_URL: default http://127.0.0.1:4723/wd/hub
- DEVICE_NAME: default emulator-5554
- APP_PKG: default com.dosifi.dosifi_flutter
- APP_ACTIVITY: default .MainActivity

Project layout added
- scripts/android_bootstrap.ps1: Prepares the emulator/device and launches the app.
- tests/automation/helpers/appium.js: Builds capabilities and creates the driver.
- tests/automation/specs/smoke.spec.js: Smoke test that verifies the app UI is accessible.

Notes
- Tests use W3C capabilities (with JSONWP for compatibility) and UiAutomator2 driver.
- If you change the app package or activity, update environment variables or helper constants.
- For CI, ensure an emulator is started and a debug APK is built before running npm run e2e.

