# WARP.md

This file provides guidance to WARP (warp.dev) when working with code in this repository.

Project: Dosifi (Flutter/Dart)
Repository root: F:\Android Apps\dosifi\dosifi_flutter
Primary shell: PowerShell (pwsh 7+)

Quick commands
- Setup
  - flutter --version
  - flutter pub get
- Analyze and format
  - flutter analyze
  - dart format .
- Test
  - flutter test
  - flutter test --coverage
  - Run a single test file: flutter test test/services/notification_action_parser_test.dart
  - Run a single test by name: flutter test --name "parses JSON payload with action field"
- Build
  - Android debug: flutter build apk
  - Android release: flutter build apk --release
  - Android bundle: flutter build appbundle --release
  - iOS (on macOS): flutter build ios --release
- Run
  - flutter run
  - Choose a device: flutter devices, then flutter run -d <device_id>
- Dependency hygiene
  - Check outdated: flutter pub outdated
  - Upgrade: flutter pub upgrade
- Codegen (if annotations are added later)
  - dart run build_runner build --delete-conflicting-outputs

CI reference
- GitHub Actions workflow runs on Flutter stable 3.22.0 with:
  - flutter pub get
  - flutter analyze
  - flutter test --coverage
- File: .github/workflows/ci.yaml

Development context (what matters to agents)
- Frameworks and key packages
  - Flutter (Dart SDK >= 3.8), Riverpod (manual providers; riverpod_annotation present but codegen not used yet), GoRouter for navigation
  - Data: sqflite_sqlcipher for encrypted SQLite, flutter_secure_storage for key storage
  - Notifications: flutter_local_notifications with action payload parsing in core/services/notification_action_handler.dart
- Project structure (high-level)
  - lib/
    - data/              Domain models and repositories (encrypted DB via SQLCipher)
    - core/              Services, utilities, theming, widgets (e.g., notification, stock, calculation)
    - presentation/      UI/screens/widgets; navigation via GoRouter; Riverpod providers for state
    - main.dart          App entry
  - test/                Unit tests covering services (notification parsing, stock management)
  - android/, ios/       Platform code; standard Flutter setup
- Architecture overview
  - Clean layering: presentation (Flutter UI + Riverpod) -> services/business logic (core/services) -> repositories/data (encrypted SQLite via sqflite_sqlcipher)
  - Navigation uses GoRouter with top-level routes; avoid redundant manual back buttons to let the router/system handle back navigation
  - Business-critical flows:
    - Notification action handling: NotificationActionHandler.parseNotificationInput supports structured JSON payloads and a legacy underscore format; standardize on JSON
    - Stock management: StockManagementService adjusts inventory on dose events with guard rails to prevent negative stock; supports lyophilized reconstitution flows
    - Reconstitution calculator (presentation + services) provides concentrated/average/diluted options and syringe math; ensure units are consistent

Gotchas and conventions
- Timezone in notifications: Prefer device local timezone; avoid hard-coding regions
- Database backup: Ensure the encrypted DB filename is used (dosifi_encrypted.db) when implementing backup/restore flows
- Dependencies: Avoid mixing plain sqflite with sqflite_sqlcipher to prevent accidental plaintext DB creation
- Lint rules are defined in analysis_options.yaml (based on flutter_lints with stricter rules like prefer_single_quotes, always_use_package_imports)
- If introducing Riverpod codegen, add riverpod_generator and run build_runner; otherwise keep manual providers consistent

Running a focused workflow
- Before coding: flutter pub get && flutter analyze
- While adding tests: flutter test --name "<substring>"
- Before PR: dart format . && flutter analyze && flutter test
- Verify CI parity locally: Use Flutter 3.22.0 stable to match .github/workflows/ci.yaml

Release builds
- Android APK (release): flutter build apk --release
- Android App Bundle (Play Store): flutter build appbundle --release
- iOS (macOS only): flutter build ios --release

Files worth reading first
- README.md: feature overview and recent implementation notes
- TECHNICAL_DESIGN.md
- MEDICATION_TRACKING_MATRIX.md
- DOSIFI_ARCHITECTURE_MATRIX.md

- analysis_options.yaml: project lint policy
- test/services/*: examples of business-logic expectations (notification parsing, stock behavior)
- .github/workflows/ci.yaml: source of truth for baseline checks

