# Maintenance Playbooks (Archived)

Archived from: /fix_issues.md
Archived on: 2025-08-18

---

# Maintenance Playbooks (Stub)

Content was moved to docs/DEVELOPER_GUIDE.md. See docs/INDEX.md for the canonical documentation map.

## 🔴 Critical Fixes Applied

### 1. ✅ Fixed Duplicate == Operator (medication.dart)
- **Issue**: `==` operator defined twice in medication.dart
- **Fix**: Removed duplicate at line 633, kept original at line 528
- **Status**: COMPLETED

### 2. ✅ Fixed Non-Exhaustive Switch Statements (medication.dart)
- **Issue**: Missing cases for `singleUsePen`, `multiUsePen`, `spray`, `gel`
- **Files Fixed**: medication.dart (all switch statements)
- **Status**: COMPLETED

## 🟡 Remaining Critical Issues to Fix

### 3. Fix Stock Management Service Invalid Constants
**File**: `lib/core/services/stock_management_service.dart`
**Lines**: 371-378

```dart
// CURRENT (BROKEN)
class StockLogEntryWithName extends StockLogEntry {
  final String medicationName;

  const StockLogEntryWithName({
    required StockLogEntry entry,
    required this.medicationName,
  }) : super(
         id: entry.id,              // ❌ Invalid constant
         medicationId: entry.medicationId,
         // ... more invalid constants
       );
}

// FIX: Remove const keyword
class StockLogEntryWithName extends StockLogEntry {
  final String medicationName;

  StockLogEntryWithName({  // ✅ Remove const
    required StockLogEntry entry,
    required this.medicationName,
  }) : super(
         id: entry.id,
         medicationId: entry.medicationId,
         timestamp: entry.timestamp,
         changeAmount: entry.changeAmount,
         newTotal: entry.newTotal,
         reason: entry.reason,
         notes: entry.notes,
         createdAt: entry.createdAt,
       );
}
```

### 4. Fix Non-Exhaustive Switch Statements in Other Files
**Files to fix**:
- `lib/core/services/medication_calculation_service.dart`
- `lib/core/utils/medication_utils.dart`
- `lib/presentation/screens/medication_form_screen.dart`
- `lib/presentation/screens/medication_view_screen.dart`
- `lib/presentation/screens/medications_list_screen.dart`

**Pattern to add**:
```dart
case MedicationType.singleUsePen:
  // Handle single use pen
case MedicationType.multiUsePen:  
  // Handle multi use pen
case MedicationType.spray:
  // Handle spray
case MedicationType.gel:
  // Handle gel
```

### 5. Fix String Interpolation Brace Issue
**File**: `lib/core/services/stock_management_service.dart`
**Line**: 60

```dart
// CURRENT
notes: notes ?? 'Dose administration: ${doseAmount} ${medication.strengthUnit.displayName}',

// FIX (already correct, but analyzer flags it)
notes: notes ?? 'Dose administration: $doseAmount ${medication.strengthUnit.displayName}',
```

### 6. Fix Examples File Issues
**File**: `lib/examples/stock_management_usage.dart`
**Issues**:
- DateTime/String parameter mismatch (line 22)
- Undefined parameters in Medication.create()

```dart
// FIX: Remove or update examples file
// This file should be deleted or moved to a separate examples directory
```

## 🔧 Code Quality Improvements

### 7. Replace Deprecated .withOpacity() Methods
**Global find and replace**:
```dart
// Find: .withOpacity(alpha)
// Replace: .withValues(alpha: alpha)
```

**Files affected** (25+ instances):
- All screen files in `lib/presentation/screens/`
- Widget files in `lib/presentation/widgets/`

### 8. Remove Unused Imports
**Run command**: `dart fix --apply`

**Manual cleanup needed in**:
- `lib/main.dart` - Remove unused error_handler import
- `lib/core/utils/error_handler.dart` - Remove unnecessary foundation import
- Multiple screen files with unused go_router, intl imports

### 9. Replace Print Statements with Proper Logging
**Pattern**:
```dart
// Replace: print('message')
// With: debugPrint('message')

// Or implement proper logging service:
import 'package:logging/logging.dart';
final _logger = Logger('ClassName');
_logger.info('message');
```

### 10. Clean Up Unused Code Elements
**Remove unused**:
- Private methods marked as unused by analyzer
- Unused local variables
- Unnecessary underscores in method names

## 🚀 Quick Fix Script

### Run These Commands:

1. **Apply automatic fixes**:
   ```bash
   cd "F:\Android Apps\dosifi\dosifi_flutter"
   dart fix --apply
   flutter pub get
   ```

2. **Check remaining issues**:
   ```bash
   flutter analyze
   ```

3. **Format code**:
   ```bash
   dart format .
   ```

4. **Test compilation**:
   ```bash
   flutter build apk --debug
   ```

## 📋 Manual Fixes Checklist

- [ ] Fix StockLogEntryWithName const constructor
- [ ] Add missing switch cases in medication_calculation_service.dart
- [ ] Add missing switch cases in medication_utils.dart  
- [ ] Add missing switch cases in medication_form_screen.dart
- [ ] Add missing switch cases in medication_view_screen.dart
- [ ] Add missing switch cases in medications_list_screen.dart
- [ ] Remove or fix examples/stock_management_usage.dart
- [ ] Replace all .withOpacity() with .withValues()
- [ ] Remove unused imports
- [ ] Replace print statements with debugPrint
- [ ] Clean up unused code elements

## 📈 Expected Results After Fixes

- ✅ Zero compilation errors
- ✅ Significant reduction in warnings (from 75+ to ~10)
- ✅ Clean flutter analyze output
- ✅ Successful debug build
- ✅ Improved code quality score

## 🎯 Priority Order

1. **Fix const constructor** (Critical - prevents compilation)
2. **Fix switch statements** (Critical - prevents compilation)  
3. **Remove/fix examples** (Critical - prevents compilation)
4. **Replace deprecated methods** (High - future compatibility)
5. **Clean up imports** (Medium - code quality)
6. **Replace prints** (Low - best practices)

## 💡 Pro Tips

- Use VS Code with Flutter extension for automatic fixes
- Enable "Format on Save" to maintain code consistency
- Run `flutter analyze` before each commit
- Use `flutter test` to ensure fixes don't break functionality

---

**Total estimated fix time**: 2-3 hours for manual fixes
**Automated fixes**: ~15 minutes with dart fix --apply

