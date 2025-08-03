# Dosifi Technical Design Document

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
