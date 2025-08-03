# Dosifi - Personal Medication Manager

Dosifi is a comprehensive medication management Flutter application designed to help users track, manage, and optimize their medication schedules. The app features advanced tools including a reconstitution calculator for lyophilized medications, inventory management, and personalized medication tracking.

## Features

### Core Features
1. **Medication Management**
   - Add, edit, and delete medications
   - Track medication details including dosage, frequency, and instructions
   - Search and filter medications
   - Support for various medication types (tablets, capsules, liquids, injections, etc.)

2. **Reconstitution Calculator**
   - Calculate reconstitution volumes for lyophilized medications
   - Support for different concentration options (concentrated, average, diluted)
   - Flexible unit support (mg, mcg, Units, IU)
   - Syringe size calculations
   - Optional vial size specifications

3. **Dashboard**
   - Quick access to all features
   - Visual overview of medication status
   - Easy navigation between features

### Planned Features
- **Schedule Management**: Set reminders and track medication schedules
- **Inventory Tracking**: Monitor medication stock levels
- **Analytics**: View medication adherence and usage patterns
- **Settings**: Customize app preferences and notifications

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

## Technical Stack

- **Framework**: Flutter (Dart)
- **State Management**: Riverpod
- **Database**: SQLite with SQLCipher encryption
- **Navigation**: GoRouter
- **Storage**: Flutter Secure Storage
- **UI**: Material Design 3

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
git clone https://github.com/yourusername/dosifi_flutter.git
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
