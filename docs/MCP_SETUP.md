# MCP Setup for Dosifi (Android)

This guide explains how to use Model Context Protocol (MCP) servers with Warp to accelerate development of the Dosifi Flutter app—enabling live device screenshots, app control, diagnostics, and (optionally) Appium UI automation.

Prerequisites
- Windows with PowerShell
- Android SDK Platform-Tools (adb) on PATH
- Node.js LTS
- Flutter SDK
- Appium CLI (optional, for UI automation)

Repo-provided MCP servers
- ADB MCP server: tools/mcp/adb-mcp-server.js
  - Tools:
    - adb.devices
    - adb.screencap (returns base64 PNG)
    - adb.launchApp (pkg/activity)
    - adb.inputTap (x,y)
- Appium MCP helper: tools/mcp/appium-mcp-server.js
  - Tools:
    - appium.version
    - appium.doctor
    - appium.startSession (placeholder note)

Install/check prerequisites
- adb: verify with `adb version`
- Node: verify with `node -v` and ensure Node is visible to Warp (see config PATH below)
- Flutter: `flutter --version`
- Appium (optional): `npm i -g appium && appium driver install uiautomator2`

Warp MCP configuration (Windows)
Add servers to Warp’s MCP settings. Recommend pointing the PATH to Node and platform-tools so Warp can locate commands.

Example config snippet:

{
  "servers": {
    "android-adb": {
      "command": "node",
      "args": [
        "F:\\Android Apps\\dosifi\\dosifi_flutter\\tools\\mcp\\adb-mcp-server.js"
      ],
      "env": {
        "ANDROID_HOME": "C:\\Users\\kook1\\AppData\\Local\\Android\\Sdk",
        "ANDROID_SDK_ROOT": "C:\\Users\\kook1\\AppData\\Local\\Android\\Sdk",
        "PATH": "C:\\Program Files\\nodejs;C:\\Users\\kook1\\AppData\\Local\\Android\\Sdk\\platform-tools;${PATH}"
      },
      "timeoutMs": 60000
    },
    "android-appium": {
      "command": "node",
      "args": [
        "F:\\Android Apps\\dosifi\\dosifi_flutter\\tools\\mcp\\appium-mcp-server.js"
      ],
      "env": {
        "ANDROID_HOME": "C:\\Users\\kook1\\AppData\\Local\\Android\\Sdk",
        "ANDROID_SDK_ROOT": "C:\\Users\\kook1\\AppData\\Local\\Android\\Sdk",
        "PATH": "C:\\Program Files\\nodejs;${PATH}"
      },
      "timeoutMs": 120000
    }
  }
}

Notes
- If quoting issues occur for `C:\\Program Files`, keep `command: "node"` and set PATH as above. Alternatively, use `C:\\Progra~1\\nodejs` if 8.3 short names are enabled.
- After editing, restart Warp or toggle the servers.

Using the ADB MCP tools
- List devices:
  tools/call name=adb.devices
- Take screenshot (replace serial):
  tools/call name=adb.screencap arguments.serial=emulator-5554
  The response includes `pngBase64`. Save to a file (PowerShell):
  $o = '<JSON string from result>' | ConvertFrom-Json
  [IO.File]::WriteAllBytes($o.filename, [Convert]::FromBase64String($o.pngBase64))
- Launch Dosifi app:
  tools/call name=adb.launchApp arguments.serial=emulator-5554 arguments.pkg=com.dosifi.dosifi_flutter arguments.activity=.MainActivity
- Tap coordinates:
  tools/call name=adb.inputTap arguments.serial=emulator-5554 arguments.x=200 arguments.y=400

Using the Appium MCP helpers (optional)
- Validate environment:
  tools/call name=appium.doctor
- Show Appium version:
  tools/call name=appium.version
- Start an Appium server in another terminal:
  appium
  (We can extend the MCP server to create/manage WebDriver sessions on demand.)

Recommended dev workflows
- Live UI review while coding:
  - Run flutter run on a device/emulator
  - Use adb.screencap to quickly capture current screen states for documentation or bug reports
- Smoke navigation checks:
  - adb.launchApp to jump into the app and test cold start
  - adb.inputTap to simulate simple taps (for “next” or “open menu”) when verifying layouts
- CI ideas:
  - Add a small script to call adb.screencap on failure and archive the screenshot artifact

Troubleshooting
- MCP initialize fails with "node is not recognized": Ensure PATH includes `C:\\Program Files\\nodejs` in the server’s env
- No devices:
  - Start an emulator: `emulator -list-avds`, then `emulator -avd <name>`
  - Or connect a physical device with USB debugging
  - Verify: `adb devices`
- Screenshot empty/black: ensure the app is in foreground; try `adb shell input keyevent 82` to wake the device

Security notes
- Do not expose ADB over network; these servers are intended for local development
- Screenshots may contain sensitive information—store or share accordingly

Next steps
- If you want element-level automation, I can extend tools/mcp/appium-mcp-server.js to manage sessions and expose find/click/type/screenshot via WebDriver.

