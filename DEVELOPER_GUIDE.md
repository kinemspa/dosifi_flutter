# Dosifi Developer Guide

This guide onboards developers quickly and provides day-90 operational know-how. It replaces prior scattered developer docs.

Contents
- Quick start
- Environment setup
- Build and run
- Testing, linting, formatting
- Configuration and secrets
- Database: migrations/seed
- Troubleshooting (common issues)
- Tooling and scripts

Quick start
- Requirements: Flutter stable, Android SDK/Emulator, Java JDK, VS Code/Android Studio.
- Clone and bootstrap:
  - flutter pub get
  - dart run build_runner build --delete-conflicting-outputs (if using codegen)
- Run: flutter run -d <device>

Environment setup
- Flutter: use the project’s tested channel (flutter --version)
- Android: install a recent emulator (x86_64) and platform tools.
- iOS/macOS: optional for now; primary target is Android.
- Node tooling: present for end-to-end tests (Appium) if you run E2E.

Build and run
- Android: flutter run -d emulator-5554
- Web (for quick UI checks): flutter run -d chrome (not all features supported)
- Release builds: flutter build apk --release (ensure signing configs if distributing)

Testing, linting, formatting
- Unit tests: flutter test
- Static analysis: flutter analyze
- Format: dart format .
- E2E (if enabled): see docs/ANDROID_E2E_TESTING.md and Appium setup

Configuration and secrets
- Use .env or --dart-define for flags. Do not commit secrets.
- Example: flutter run --dart-define=FEATURE_SCHED_GEN_V2=true

Database: migrations/seed
- If using SQLite/Isar, keep migration scripts versioned in tool/migrations/.
- On schema changes, increment version and supply up/down migrations.

Troubleshooting (common issues)
- Emulator not detected: flutter devices; ensure adb devices lists emulator.
- Build fails after dependency updates: flutter clean; flutter pub get.
- App freezes on hot reload: use hot restart; if persistent, flutter clean and rebuild.
- Notifications not firing: verify OS notification permission and background restrictions.
- MCP screenshot tool:
  - Ensure debug/profile mode.
  - Confirm VM service URL from flutter run output.
  - Run: dart tool/mcp_capture.dart --vm-service-url ws://... --out screenshots/home.png

Tooling and scripts
- Scripts under tool/ for capture, migrations, or data export.
- VS Code launch configs can target frequently used routes for faster iteration.

