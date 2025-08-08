# Dosifi - Personal Medication Manager

Dosifi is a comprehensive medication management Flutter application designed to help users track, manage, and optimize their medication schedules. The app features advanced tools including a reconstitution calculator for lyophilized medications, inventory management, and personalized medication tracking.

## Features

### Core Features
1. **Medication Management**
   - Add, edit, and delete medications with comprehensive forms
   - Track medication details including dosage, frequency, and instructions
   - Search and filter medications with real-time results
   - Support for various medication types (tablets, capsules, liquids, injections, etc.)
   - Automatic dose calculations based on medication strength
   - Medication schedule tracking with tabs for different time periods

2. **Supply Inventory Management**
   - Comprehensive inventory tracking with category-based organization
   - Search and filter supplies by name and category
   - Visual stats cards displaying total supplies, low stock alerts, and categories
   - Edit, adjust quantities, and delete supplies with intuitive popup menus
   - Color-coded categories (Medication, Equipment, Supplements)
   - Stock level monitoring with visual indicators

3. **Reconstitution Calculator**
   - Calculate reconstitution volumes for lyophilized medications
   - Support for different concentration options (concentrated, average, diluted)
   - Flexible unit support (mg, mcg, Units, IU)
   - Syringe size calculations with multiple size options
   - Optional vial size specifications
   - Clear step-by-step calculation results

4. **Enhanced Dashboard**
   - Welcome card with personalized greeting
   - Today's medication schedule overview
   - Quick statistics cards (medications, supplies, schedules)
   - Recent activities timeline
   - Smart alerts and notifications
   - Quick action buttons for common tasks
   - Bottom navigation bar for seamless app navigation
   - System-level back button handling with exit confirmation

5. **Analytics & Insights**
   - Medication adherence tracking and visualization
   - Usage pattern analysis with charts and graphs
   - Supply consumption tracking
   - Personalized insights and recommendations
   - Export capabilities for healthcare providers

### Planned/Partial Features
- **Notifications action handling (Partial)**: Notifications are scheduled; action routing and deep-link navigation to app screens to be finalized
- **Analytics (Partial)**: Adherence and usage visualization present; needs real data population and more reports
- **Settings**: Expand preferences, including configurable snooze durations and privacy settings

### Automatic Dose Calculations
The app now supports automatic dose calculations to ensure users enter correct dosage based on the medication's strength. Users can select the medication and adjust the dose unit, and the app will accurately convert dose amounts between tablets/capsules and mg as necessary.
For example, selecting a 2mg medication with 1 tablet as a dose will automatically update to 2mg. Changing to "mg" will convert the dose to the equivalent in tablets if applicable.

## Reconstitution Calculator

### Input Parameters
- **Strength of Lyophilized Powder**: The total amount of medication in the vial (mg or mcg)
- **Desired Dose**: The dose you want to administer (mg, mcg, Units, or IU)
- **Syringe Size**: Available sizes: 0.3mL, 0.5mL, 1mL, 3mL, 5mL
- **Target Vial Size** (Optional): 1mL, 3mL, 5mL, 10mL, 20mL

### Calculation Examples

#### Example 1: With Vial (10mg powder, 1000mcg dose, 1mL syringe, 5mL vial)
- **Concentrated Option**: 1mL reconstitution → 10 IU on syringe
- **Average Option**: 3mL reconstitution → 30 IU on syringe
- **Diluted Option**: 5mL reconstitution → 50 IU on syringe

#### Example 2: Without Vial (10mg powder, 1000mcg dose, 1mL syringe)
- **Concentrated Option**: 1mL reconstitution → 10 IU on syringe
- **Average Option**: 5mL reconstitution → 50 IU on syringe
- **Diluted Option**: 9mL reconstitution → 90 IU on syringe

## Recent Improvements

### Navigation & UX Enhancements (Latest Update)
- **Restructured Router Configuration**: Fixed child routes as top-level routes for proper back button functionality
- **Consistent Navigation Flow**: Removed redundant manual back buttons, allowing Flutter's default navigation to work seamlessly
- **System Back Button Handling**: Added exit confirmation dialog on dashboard for better UX
- **Bottom Navigation Bar**: Implemented intuitive navigation between main app sections
- **Proper AppBar Implementation**: Consistent AppBars across all screens with appropriate titles and controls

### UI & Theme Consistency
- **Color Scheme Compliance**: Fixed text/background color mismatches across all screens
- **Theme Integration**: All UI elements now use consistent theme colors and gradients
- **Visual Polish**: Enhanced cards, buttons, and layout spacing for professional appearance
- **Icon Consistency**: Standardized icons across the app with proper sizing and colors
- **Responsive Design**: Improved layout adaptability across different screen sizes

### Code Quality Improvements
- **Route Optimization**: Eliminated duplicate routes and streamlined navigation paths
- **Component Reusability**: Enhanced widget modularity and reusability
- **Performance Optimization**: Reduced unnecessary rebuilds and improved app responsiveness
- **Clean Architecture**: Better separation of concerns and code organization

## Technical Stack

- **Framework**: Flutter (Dart)
- **State Management**: Riverpod
- **Database**: SQLite with SQLCipher encryption
- **Navigation**: GoRouter with optimized route configuration
- **Storage**: Flutter Secure Storage
- **UI**: Material Design 3 with custom theming

## Technical Documentation

### Internal Documentation (Confidential)
The following documentation files contain proprietary algorithms, business logic, and detailed medication tracking specifications. These files are excluded from public repositories for confidentiality:

- **`DOSIFI_ARCHITECTURE_MATRIX.md`** - Complete system architecture and component integration
- **`MEDICATION_TYPES_BREAKDOWN.md`** - Comprehensive medication type specifications and calculations
- **`MEDICATION_TRACKING_MATRIX.md`** - Detailed tracking matrix for all 13 medication types
- **`Dosifi_Medication_Tracking_Matrix.csv`** - Excel-compatible tracking specifications
- **`Dosifi_Tracking_Calculations.csv`** - Mathematical formulas and calculation methods

**Note**: These files are available to authorized developers and contain sensitive intellectual property related to medication management algorithms.

## Project Structure

```
dosifi_flutter/
├── lib/
│   ├── config/          # App configuration and routing
│   ├── core/            # Core utilities and theme
│   ├── data/            # Data layer (models, repositories)
│   ├── presentation/    # UI layer (screens, widgets, providers)
│   └── main.dart        # App entry point
├── android/             # Android platform code
├── ios/                 # iOS platform code
└── test/               # Test files
```

## Getting Started

### Prerequisites
- Flutter SDK (3.0.0 or later)
- Dart SDK
- Android Studio / Xcode for platform-specific development

### Installation

1. Clone the repository
```bash
git clone https://github.com/kinemspa/dosifi_flutter.git
```

2. Install dependencies
```bash
flutter pub get
```

3. Run the app
```bash
flutter run
```

### Building for Release

**Android**
```bash
flutter build apk --release
```

**iOS**
```bash
flutter build ios --release
```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the LICENSE file for details.

---

2025-08-08 Review Addendum (Code-Verified Notes)

- Notifications: Implemented scheduling with actions; need to wire onDidReceiveNotificationResponse to NotificationActionHandler and standardize payloads (recommend JSON). Use device local timezone instead of hard-coded AU.
- Database: Encrypted via SQLCipher. backupDatabase should copy dosifi_encrypted.db (current code copies dosifi.db). Replace timestamp-based key generation with cryptographically secure random key generation stored in FlutterSecureStorage.
- Dependencies: Prefer only sqflite_sqlcipher for DB. Decide on Riverpod code generation or remove riverpod_annotation.
- Documentation: This README now reflects implemented schedule and inventory features; analytics remains partial.
