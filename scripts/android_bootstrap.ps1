param(
  [string]$DeviceId = "emulator-5554",
  [string]$Package = "com.dosifi.dosifi_flutter",
  [string]$Activity = ".MainActivity"
)

$ErrorActionPreference = "Stop"

function Wait-ForDevice {
  param([string]$id)
  Write-Host "[bootstrap] Waiting for device $id..."
  adb -s $id wait-for-device | Out-Null
  adb -s $id shell getprop sys.boot_completed | Out-Null
}

function Ensure-AppInstalled {
  param([string]$id,[string]$pkg)
  $out = adb -s $id shell pm list packages $pkg
  if (-not ($out -match $pkg)) {
    Write-Host "[bootstrap] Package $pkg not installed on $id. Attempting to install latest debug APK..."
    $apk = Join-Path -Path (Resolve-Path .) -ChildPath "build/app/outputs/flutter-apk/app-debug.apk"
    if (-not (Test-Path $apk)) { throw "Debug APK not found at $apk. Build it with: flutter build apk --debug" }
    adb -s $id install -r $apk | Out-Null
  }
}

function Launch-App {
  param([string]$id,[string]$pkg,[string]$activity)
  Write-Host "[bootstrap] Launching $pkg/$activity..."
  adb -s $id shell am start -n "$pkg/$activity" | Out-Null
}

Wait-ForDevice -id $DeviceId
Ensure-AppInstalled -id $DeviceId -pkg $Package
Launch-App -id $DeviceId -pkg $Package -activity $Activity

Write-Host "[bootstrap] Emulator/app ready."

