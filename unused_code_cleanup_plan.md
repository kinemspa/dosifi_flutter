# Unused Code Cleanup Plan - Dosifi Flutter

## Summary
After analyzing the codebase, I found significant unused code that can be safely removed to improve maintainability and reduce project size.

## 🗑️ Files to Delete (Completely Unused)

### 1. **Empty/Placeholder Screens**
- `lib/presentation/screens/dose_activity_screen.dart`
  - **Status**: Just a placeholder with "Dose Activity Screen" text
  - **Impact**: Referenced in router but serves no functional purpose
  - **Action**: Delete file and remove router references

- `lib/presentation/screens/notification_settings_screen.dart`
  - **Status**: Complete implementation but not referenced anywhere
  - **Impact**: 426 lines of unused code with providers and UI
  - **Action**: Safe to delete entirely

- `lib/presentation/screens/home_screen.dart`
  - **Status**: Alternative home screen that's not used
  - **Impact**: Dashboard functionality is handled by `dashboard_screen.dart`
  - **Action**: Safe to delete if not referenced

### 2. **Examples and Documentation**
- `lib/examples/stock_management_usage.dart`
  - **Status**: 300+ lines of example code for stock management
  - **Impact**: Not used in actual application, just documentation
  - **Action**: Move to documentation or delete

### 3. **Duplicate Services**
- `lib/services/medication_calculation_service.dart`
  - **Status**: Older, simpler version
  - **Lines**: 82 lines
  - **Duplicate of**: `lib/core/services/medication_calculation_service.dart` (more comprehensive)
  - **Action**: Delete the simpler version and update imports

### 4. **Duplicate Widgets**
- `lib/presentation/widgets/animated_gradient_card.dart`
  - **Status**: Simple gradient card (37 lines)
  - **Lines**: 37 lines
  - **Duplicate of**: `lib/core/widgets/animated_gradient_card.dart` (126 lines, more featured)
  - **Action**: Delete simple version and update imports

### 5. **Old Medication Form (After Migration)**
- `lib/presentation/screens/medication_form_screen.dart`
  - **Status**: Original large file (1661 lines) - now replaced by refactored version
  - **Impact**: Should be deleted after migration to refactored version
  - **Action**: Delete after confirming refactored version works

## 📝 Router Updates Required

After deleting unused screens, update `lib/config/app_router.dart`:

### Remove Routes:
```dart
// Remove dose-activity route (lines 96-106)
GoRoute(
  path: '/dose-activity',
  name: 'dose-activity',
  // ... entire route block
),

// Remove navigation extension (line 221)
void navigateToDoseActivity() => go('/dose-activity');

// Remove from smart back navigation (lines 248-249)
} else if (currentLocation.startsWith('/dose-activity')) {
  navigateToDoseActivity();
```

### Remove from Navigation Drawer:
In `lib/presentation/screens/main_shell_screen.dart`, remove:
```dart
// Remove dose activity drawer item (lines 237-246)
_buildDrawerItem(
  context,
  icon: Icons.analytics,
  title: 'Dose Activity',
  subtitle: 'Track dose history',
  onTap: () {
    Navigator.pop(context);
    context.go('/dose-activity');
  },
),
```

## 🔄 Import Updates Required

### Files importing duplicate services:
1. `lib/presentation/screens/medication_view_screen.dart`
   - Change: `import '../../core/services/medication_calculation_service.dart';`
   - To: Keep as is (already using correct one)

2. `lib/data/repositories/dose_log_repository.dart`
   - Change: `import '../../services/medication_calculation_service.dart';`
   - To: `import '../../core/services/medication_calculation_service.dart';`

### Files importing duplicate widgets:
1. `lib/presentation/screens/home_screen.dart`
   - Currently imports: `import '../../core/widgets/animated_gradient_card.dart';`
   - Status: Correct import (home_screen may be deleted anyway)

## 📊 Cleanup Impact

| Category | Files | Lines Saved |
|----------|-------|-------------|
| Placeholder screens | 2 | ~450 lines |
| Unused screens | 1 | ~108 lines |
| Examples | 1 | ~300 lines |
| Duplicate services | 1 | ~82 lines |
| Duplicate widgets | 1 | ~37 lines |
| **Total** | **6** | **~977 lines** |

## 🚀 Benefits of Cleanup

1. **Reduced Bundle Size**: Removing unused code reduces app size
2. **Improved Build Times**: Fewer files to process during compilation
3. **Better Maintainability**: Less confusion about which files to use
4. **Cleaner Navigation**: Remove unused routes and menu items
5. **Developer Experience**: Clearer project structure

## 📋 Cleanup Execution Order

1. **Phase 1**: Remove completely unused files
   - Delete `dose_activity_screen.dart`
   - Delete `notification_settings_screen.dart`
   - Delete `home_screen.dart` (if confirmed unused)

2. **Phase 2**: Remove duplicates
   - Delete `services/medication_calculation_service.dart`
   - Update import in `dose_log_repository.dart`
   - Delete `presentation/widgets/animated_gradient_card.dart`

3. **Phase 3**: Clean router and navigation
   - Remove dose-activity route from `app_router.dart`
   - Remove dose-activity from navigation drawer
   - Update navigation extensions

4. **Phase 4**: Remove examples (optional)
   - Move `stock_management_usage.dart` to docs or delete

5. **Phase 5**: Post-refactoring cleanup
   - Delete original `medication_form_screen.dart` after migration

## ⚠️ Pre-cleanup Verification

Before executing cleanup:
1. **Search for any missed references** to files being deleted
2. **Run tests** to ensure no broken dependencies  
3. **Check imports** for any circular dependencies
4. **Verify routing** still works after route removal
5. **Test navigation drawer** functionality

## 🔍 Additional Investigation Needed

1. **Verify home_screen.dart usage** - may still be used somewhere
2. **Check if notification settings** will be implemented later
3. **Confirm stock management examples** aren't needed for documentation
4. **Double-check dose_log_repository.dart** import usage

This cleanup will significantly improve code organization and reduce technical debt while maintaining all functional features.
