# Dosifi Technical Design and Implementation Guide

Last updated: 2025-08-18

This is the single canonical technical document for the Dosifi Flutter app. It consolidates the previous technical design, architecture matrix, medication tracking matrix, types breakdown, developer guide, navigation/accessibility notes, troubleshooting, security, and build/CI guidance.

Table of contents
- 1. Overview
- 2. Architecture and Component Matrix
- 3. Data Model and Database Schema
- 4. Medication Types, Tracking Matrix, and Calculations
- 5. Scheduling, Notifications, and Dose Logging
- 6. State Management and Navigation
- 7. Developer Workflow and Commands
- 8. Troubleshooting and Maintenance
- 9. Security, Privacy, and Compliance
- 10. Performance and Scalability
- 11. Build, CI/CD, and Release

## 1. Overview
Dosifi is a comprehensive medication management mobile application built with Flutter. The application provides tools to manage medications, calculate reconstitution formulas, track inventory, and maintain medication schedules. Data is stored locally in an encrypted SQLCipher database. Riverpod drives state management; GoRouter provides navigation.

## 2. Architecture and Component Matrix

### 2.1 Layered architecture
```
┌─────────────────────────────────────────────────────────────┐
│                    Presentation Layer                        │
│  (Screens, Widgets, State Management with Riverpod)         │
├─────────────────────────────────────────────────────────────┤
│                      Domain Layer                            │
│          (Business Logic, Use Cases, Services)              │
├─────────────────────────────────────────────────────────────┤
│                       Data Layer                             │
│     (Repositories, Data Sources, Models, Database)          │
└─────────────────────────────────────────────────────────────┘
```

### 2.2 Folder structure (high level)
```
lib/
├── config/                 # App config and routing (GoRouter)
├── core/                   # Services, utils, theme, widgets
├── data/                   # Models and repositories
├── presentation/           # UI (screens, widgets), providers
└── main.dart               # App entry point
```

### 2.3 Architecture integration matrix (consolidated)
- Foundation services: DatabaseService (SQLCipher), NotificationService (flutter_local_notifications), ErrorHandler, AppTheme
- Data models: Medication → Schedules, DoseLogs; Supply; ReconstitutionRecipe
- Repositories: MedicationRepository, ScheduleRepository, DoseLogRepository, SupplyRepository
- Business services: DoseSchedulingService (generate/mark dose logs), NotificationService (schedule reminders)
- Riverpod providers: StateNotifier (lists/editors), FutureProvider (async loads), Provider (service/repo singletons)
- UI screens: Dashboard, Inventory (Medications + Supplies tabs), Schedule (Today/All), Tools (Reconstitution, Analytics), Management (Add/Edit forms)

Data flows
- Taking a dose: UI → DoseSchedulingService → DoseLogRepository (update) + MedicationRepository (stock deduction) → UI refresh via providers
- Adding medication: UI → MedicationRepository → DB → Providers refresh → UI updates across Dashboard/Inventory/Schedule
- Automated scheduling: App launch → DoseSchedulingService generate today/upcoming → mark overdue → providers refresh → dashboard shows state

## 3. Data Model and Database Schema
Database: SQLite with SQLCipher encryption; keys in FlutterSecureStorage; foreign keys enforced.

Core tables (simplified, current app-aligned)
- medications: id, name, type, strength_per_unit, strength_unit, stock_quantity, reconstitution_volume, final_concentration, notes, lot_batch_number, expiration_date, is_active, created_at, updated_at
- schedules: id, medication_id, schedule_type (daily/weekly/cycling), time_of_day, days_of_week, start_date, end_date, cycle_days_on/off, dose_amount, dose_unit, dose_form, strength_per_unit, is_active, created_at, updated_at
- dose_logs: id, medication_id, schedule_id?, scheduled_time, taken_time?, status (pending/taken/missed/skipped), dose_amount?, notes?, created_at
- supplies: id, name, type (item/fluid/diluent), quantity, unit, reorder_level, expiration_date?, notes?, created_at, updated_at
- medication_stock_logs (optional/expandable): id, medication_id, timestamp, change_amount, new_total, reason, notes, created_at
- reminders (optional/expandable): id, schedule_id, reminder_time, notification_id, is_active, created_at

Indexes: medications(name), schedules(medication_id), dose_logs(medication_id), dose_logs(scheduled_time)

Storage rules
- Date/time stored as ISO8601 strings; app uses device local time for notifications, UTC internally for analytics where needed.
- Strength/dose units persisted as strings.

## 4. Medication Types, Tracking Matrix, and Calculations

Supported medication types (13)
- tablet, capsule, liquid, preFilledSyringe, readyMadeVial, lyophilizedVial, cream, ointment, drops, inhaler, patch, suppository, other

Strength units
- mg, mcg, g, mL, IU/Units, %, mg/mL, mcg/mL, mcg/dose, mg/dose, mcg/hr, mg/hr

Tracking matrix summary (by type)
- Tablet: per-tablet stock, dose as full/half/quarter tablets; track total tablets and total active ingredient
- Capsule: per-capsule stock, whole units only
- Liquid: volume-based (mL/L), conversions (tsp, tbsp, drops)
- Pre-filled syringe: syringe count + mL per syringe; units per mL
- Ready-made vial: vial count + mL per vial; units per mL
- Lyophilized vial: vial count (powder), reconstitution required; post-reconstitution concentration tracked
- Cream/Ointment: weight-based (g/oz), application estimates
- Drops: volume-based with drop conversions (≈20–25 drops/mL)
- Inhaler: dose counter (puffs)
- Patch: patch count + delivery rate (mcg/hr)
- Suppository: unit count (whole only)
- Other: flexible unit count/strength

Universal calculations
- Stock deduction: newStock = max(0.0, currentStock - doseAmount)
- Days of supply: daysRemaining = currentStock / dailyUsageRate
- Compliance: complianceRate = (dosesTaken / dosesScheduled) × 100
- Reorder forecast: reorderDate = today + (currentStock / averageDailyUsage)

Reconstitution (lyophilized)
- finalConcentration = totalActive / totalVolume
- volumeNeededForDose = desiredDose / finalConcentration
- Track unreconstituted vials, reconstituted volume, stability window

Examples
- Insulin 100 U/mL: 15 U dose → 0.15 mL deducted
- Amoxicillin 125mg/5mL: 10 mL dose → 250 mg active; 10 mL deducted
- Botox 100 U reconstituted to 2.5 mL → 40 U/mL; 20 U dose → 0.5 mL

## 5. Scheduling, Notifications, and Dose Logging
Scheduling
- Types: daily, weekly (daysOfWeek), cycling (daysOn/daysOff)
- Stored on schedules; DoseSchedulingService generates today/upcoming dose logs

Dose logs
- Status: pending, taken, missed, skipped
- On mark taken: update dose_logs, adjust medication stock, append stock log (optional)

Notifications
- flutter_local_notifications; device local timezone
- Android 12+: exact alarms capability handled; iOS: categories registered
- Payloads standardized as JSON; deep-link to schedule/medication detail on tap

## 6. State Management and Navigation
State (Riverpod)
- Providers: medicationListProvider, scheduleProvider, doseLogProvider, supplyListProvider, databaseProvider
- Use StateNotifier for editable lists; FutureProvider for async queries

Navigation (GoRouter)
- Root tabs: Dashboard (/), Inventory (/inventory), Schedule (/schedule), Settings (/settings)
- Tools: /analytics, /reconstitution
- UX: Avoid redundant back arrows on root tabs; smart back between tabs; add reconstitution entry point via Dashboard quick action if not present

Accessibility quick rules
- Tooltips for IconButtons/FABs; Semantics on custom tappables; avoid color-only signals; test TalkBack/VoiceOver on critical flows

## 7. Developer Workflow and Commands
Versions
- Flutter 3.32.8 stable; Dart 3.8+

Core commands
- flutter pub get
- flutter analyze; dart format .
- flutter test [--coverage]
- Build Android: flutter build apk --release
- Web preview: flutter run -d web-server --web-hostname localhost --web-port 7357

Focused workflows
- Before coding: flutter pub get && flutter analyze
- Before PR: dart format . && flutter analyze && flutter test

## 8. Troubleshooting and Maintenance
Common issues
- Notifications not firing: check permission status (notifications + exact alarms), tz initialization, ensure scheduled time > now, DND mode, channel settings
- Compliance stats: validate COUNT typing; ensure null-safe aggregation
- Excessive prints: replace print with debugPrint or logging

Maintenance checklist
- Replace deprecated .withOpacity() with .withValues(alpha: ...)
- Remove unused imports (dart fix --apply)
- Clean unused code and examples not referenced by app
- Keep database filename consistent (dosifi_encrypted.db)

Cleanup outcomes (recent)
- Removed unused screens/services/widgets and examples; consolidated routing; reduced dead code; verified imports and navigation

## 9. Security, Privacy, and Compliance
Database encryption
- SQLCipher at rest; keys in FlutterSecureStorage; PRAGMA foreign_keys = ON

Privacy
- Local-only by default; no analytics without consent; backups copy encrypted DB file

Secrets
- Never log sensitive data; avoid plaintext keys; treat notification payloads carefully

## 10. Performance and Scalability
- DB indexes for common queries; paginate long lists
- Riverpod-driven minimal rebuilds; widget/list optimizations
- Clear extension points for new medication types, providers, screens, and automation tasks

## 11. Build, CI/CD, and Release
Build
- Android: flutter build apk --release (or appbundle)
- iOS (macOS): flutter build ios --release

CI/CD
- GitHub Actions on stable Flutter; steps: pub get, analyze, test (coverage)

Release
- Signing (Android keystore); versioning in pubspec; ensure permission manifests are correct; prepare release notes

## 1. Overview

Dosifi is a comprehensive medication management mobile application built with Flutter. The application provides users with tools to manage their medications, calculate reconstitution formulas, track inventory, and maintain medication schedules.

## 2. Architecture

### 2.1 Application Architecture

The application follows a clean architecture pattern with clear separation of concerns:

```
┌─────────────────────────────────────────────────────────────┐
│                    Presentation Layer                        │
│  (Screens, Widgets, State Management with Riverpod)         │
├─────────────────────────────────────────────────────────────┤
│                      Domain Layer                            │
│          (Business Logic, Use Cases, Entities)              │
├─────────────────────────────────────────────────────────────┤
│                       Data Layer                             │
│     (Repositories, Data Sources, Models, Database)          │
└─────────────────────────────────────────────────────────────┘
```

### 2.2 Folder Structure

```
lib/
├── config/
│   └── app_router.dart          # GoRouter configuration
├── core/
│   ├── constants/               # App constants
│   ├── theme/                   # Material 3 theme configuration
│   └── utils/                   # Utility functions
├── data/
│   ├── models/                  # Data models
│   ├── repositories/            # Repository implementations
│   └── services/                # External services (DB, API)
├── presentation/
│   ├── providers/               # Riverpod providers
│   ├── screens/                 # App screens
│   └── widgets/                 # Reusable widgets
└── main.dart                    # Application entry point
```

## 3. Key Components

### 3.1 Database Design

The application uses SQLite with SQLCipher encryption for secure local storage.

#### Tables

**medications**
```sql
CREATE TABLE medications (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  type TEXT NOT NULL,
  dosage_amount REAL NOT NULL,
  dosage_unit TEXT NOT NULL,
  frequency TEXT,
  instructions TEXT,
  barcode TEXT,
  batch_number TEXT,
  expiry_date TEXT,
  notes TEXT,
  photo_path TEXT,
  is_active INTEGER DEFAULT 1,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
);
```

**schedules**
```sql
CREATE TABLE schedules (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  medication_id INTEGER NOT NULL,
  scheduled_time TEXT NOT NULL,
  repeat_pattern TEXT,
  days_of_week TEXT,
  start_date TEXT NOT NULL,
  end_date TEXT,
  reminder_enabled INTEGER DEFAULT 1,
  notes TEXT,
  is_active INTEGER DEFAULT 1,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  FOREIGN KEY (medication_id) REFERENCES medications (id)
);
```

**supplies**
```sql
CREATE TABLE supplies (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  category TEXT NOT NULL,
  current_stock REAL NOT NULL,
  unit TEXT NOT NULL,
  minimum_stock REAL DEFAULT 0,
  expiration_date TEXT,
  cost_per_unit REAL,
  supplier TEXT,
  location TEXT,
  notes TEXT,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
);
```

**dose_logs**
```sql
CREATE TABLE dose_logs (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  schedule_id INTEGER NOT NULL,
  medication_id INTEGER NOT NULL,
  scheduled_time TEXT NOT NULL,
  actual_time TEXT,
  status TEXT NOT NULL, -- 'taken', 'missed', 'skipped'
  notes TEXT,
  created_at TEXT NOT NULL,
  FOREIGN KEY (schedule_id) REFERENCES schedules (id),
  FOREIGN KEY (medication_id) REFERENCES medications (id)
);
```

**reconstitution_recipes**
```sql
CREATE TABLE reconstitution_recipes (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  medication_id INTEGER NOT NULL,
  powder_amount REAL NOT NULL,
  powder_unit TEXT NOT NULL,
  solvent_volume REAL NOT NULL,
  solvent_unit TEXT NOT NULL,
  final_concentration REAL NOT NULL,
  concentration_unit TEXT NOT NULL,
  storage_instructions TEXT,
  stability_days INTEGER,
  notes TEXT,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  FOREIGN KEY (medication_id) REFERENCES medications (id)
);
```

### 3.2 State Management

The application uses Riverpod for state management, providing:
- Reactive state updates
- Dependency injection
- Scoped state management
- Easy testing

Key providers:
- `medicationListProvider`: Manages the list of medications
- `scheduleProvider`: Handles medication schedules
- `supplyListProvider`: Manages supply inventory
- `doseLogProvider`: Tracks dose taking history
- `databaseProvider`: Provides database access

### 3.3 Navigation

GoRouter is used for declarative navigation with support for:
- Deep linking
- Route guards
- Nested navigation
- Custom transitions

## 4. Feature Specifications

### 4.1 Reconstitution Calculator

The reconstitution calculator uses the following algorithm:

```dart
// Input parameters
double strength;          // Total medication strength (mg/mcg)
double desiredDose;      // Desired dose per administration
double syringeVolume;    // Syringe size (mL)
double? vialVolume;      // Optional vial size (mL)

// Calculations
if (vialVolume != null) {
  // With vial
  concentrated = strength / 1.0mL
  average = strength / (vialVolume * 0.6)
  diluted = strength / vialVolume
} else {
  // Without vial
  concentrated = strength / 1.0mL
  average = strength / 5.0mL
  diluted = strength / 9.0mL
}

// Dose on syringe calculation
doseOnSyringe = (desiredDose / concentration) * syringeVolume
```

### 4.2 Medication Management

Features:
- CRUD operations for medications
- Search and filter capabilities
- Barcode scanning support (future)
- Photo attachment for medications
- Batch tracking
- Expiry date monitoring

### 4.3 Schedule Management

Features:
- Flexible scheduling patterns (daily, weekly, custom)
- Multiple doses per day
- Reminder notifications
- Schedule history tracking
- Missed dose tracking

### 4.4 Supply Management

Features:
- Stock level tracking for medical supplies
- Category-based organization
- Expiry date warnings
- Location tracking
- Cost tracking per unit
- Supplier information management
- Integrated with medication screen via tabbed interface

### 4.5 Dose Logging

Features:
- Track when medications are taken
- Record missed or skipped doses
- Historical dose tracking
- Schedule adherence analytics
- Integration with medication schedules

## 5. Security Considerations

### 5.1 Data Encryption
- SQLCipher for database encryption
- Flutter Secure Storage for sensitive data
- No cloud sync without user consent

### 5.2 Privacy
- All data stored locally
- No analytics without consent
- Optional cloud backup with encryption

## 6. Performance Optimizations

### 6.1 Database
- Indexed columns for fast queries
- Lazy loading for large datasets
- Pagination for list views

### 6.2 UI
- Image caching and optimization
- Lazy loading of screens
- Efficient state management with Riverpod

## 7. Testing Strategy

### 7.1 Unit Tests
- Model serialization/deserialization
- Business logic validation
- Calculator algorithms

### 7.2 Widget Tests
- Screen rendering
- User interactions
- Navigation flows

### 7.3 Integration Tests
- Database operations
- Full user workflows
- Performance benchmarks

## 8. Recent UI Improvements (v1.1.0)

### 8.1 Medication Screen Enhancements

**Tabbed Interface Implementation:**
- Integrated medications and supplies into a single screen with Material 3 tabs
- Consistent navigation and state management across both tabs
- Unified floating action button for adding both medications and supplies

**Supplies Tab Integration:**
- Replaced placeholder "Coming Soon" message with fully functional supply management
- Real-time data loading using `supplyListProvider`
- Card-based layout showing supply details (name, category, stock, expiration)
- Integrated CRUD operations with confirmation dialogs
- Error handling and loading states
- Pull-to-refresh functionality
- Empty state handling with user guidance

**Navigation Improvements:**
- Removed duplicate "Dose Schedules" button from home dashboard
- Streamlined navigation flow to reduce user confusion
- Maintained consistency with existing UI patterns

### 8.2 Data Model Enhancements

**New Models Added:**
- `DoseLog`: Tracks medication taking history with status tracking
- Enhanced `Supply` model with comprehensive fields for inventory management

**Repository Pattern:**
- Implemented consistent repository pattern for data access
- Added proper error handling and data validation
- Standardized CRUD operations across all entities

### 8.3 State Management Improvements

**Provider Architecture:**
- Added `doseLogProvider` for tracking medication adherence
- Enhanced `supplyListProvider` with full CRUD capabilities
- Improved error handling across all providers
- Consistent loading and error states

### 8.4 Technical Debt Reduction

**Code Organization:**
- Standardized widget structure and naming conventions
- Improved separation of concerns between UI and business logic
- Enhanced error handling patterns
- Consistent Material 3 design language implementation

**Performance Optimizations:**
- Efficient state updates using Riverpod's reactive patterns
- Reduced unnecessary widget rebuilds
- Optimized database queries with proper indexing

## 9. Future Enhancements

### 9.1 Cloud Sync
- Firebase integration
- Real-time synchronization
- Multi-device support

### 9.2 Advanced Features
- AI-powered medication recommendations
- Drug interaction warnings
- Healthcare provider integration
- Export/import functionality

### 9.3 Platform Extensions
- Wear OS support
- iOS widgets
- Android widgets
- Desktop applications

## 10. Development Guidelines

### 10.0 Accessibility Guidelines
- Provide tooltip text for all IconButtons and FABs that trigger primary actions.
- Wrap custom tappables with Semantics where needed and ensure button roles are set.
- Avoid using color alone to convey status; pair with icons or labels.
- Ensure focus order is logical; prefer standard Material widgets to inherit accessibility.
- Prefer descriptive labels: e.g., 'Add Medication' over 'Add'.
- Test with TalkBack/VoiceOver for critical flows (dashboard quick actions, schedule dose actions, supplies add/edit).

### 10.1 Code Style
- Follow Dart style guide
- Use meaningful variable names
- Comment complex logic
- Keep functions small and focused

### 10.2 Git Workflow
- Feature branches
- Meaningful commit messages
- Code reviews
- Automated testing

### 10.3 Documentation
- Inline code documentation
- API documentation
- User guides
- Release notes

## 11. Deployment

### 11.1 Android
- Minimum SDK: 21 (Android 5.0)
- Target SDK: Latest stable
- ProGuard rules for release builds

### 11.2 iOS
- Minimum iOS: 11.0
- Swift version: Latest stable
- App Store guidelines compliance

### 11.3 CI/CD
- GitHub Actions for automated builds
- Automated testing on PR
- Release builds on tags
- Beta distribution via Firebase App Distribution
