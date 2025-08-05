// Comprehensive test suite for Dosifi app

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dosifi_flutter/main.dart';
import 'package:dosifi_flutter/presentation/screens/splash_screen.dart';
import 'package:dosifi_flutter/presentation/screens/dashboard_screen.dart';
import 'package:dosifi_flutter/data/models/medication.dart';
import 'package:dosifi_flutter/core/utils/medication_utils.dart';

void main() {
  group('Dosifi App Tests', () {
    testWidgets('App initializes correctly', (WidgetTester tester) async {
      // Build the app
      await tester.pumpWidget(const ProviderScope(child: DosifiApp()));
      
      // Verify MaterialApp is created
      expect(find.byType(MaterialApp), findsOneWidget);
      
      // Should start with splash screen
      expect(find.byType(SplashScreen), findsOneWidget);
      expect(find.text('Dosifi'), findsOneWidget);
    });

    testWidgets('Splash screen navigates to dashboard', (WidgetTester tester) async {
      await tester.pumpWidget(const ProviderScope(child: DosifiApp()));
      
      // Fast forward through splash screen delay
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();
      
      // Should now be on dashboard
      expect(find.byType(DashboardScreen), findsOneWidget);
    });
  });

  group('Business Logic Tests', () {
    test('MedicationType enum has correct display names', () {
      expect(MedicationType.tablet.displayName, equals('Tablet'));
      expect(MedicationType.lyophilizedVial.displayName, equals('Lyophilized Vial'));
      expect(MedicationType.preFilledSyringe.displayName, equals('Pre-filled Syringe'));
    });

    test('StrengthUnit enum has correct display names', () {
      expect(StrengthUnit.mg.displayName, equals('mg'));
      expect(StrengthUnit.mcg.displayName, equals('mcg'));
      expect(StrengthUnit.iu.displayName, equals('IU'));
    });

    test('MedicationUtils provides correct strength units for types', () {
      final tabletUnits = MedicationUtils.getAvailableStrengthUnits(MedicationType.tablet);
      expect(tabletUnits, contains(StrengthUnit.mg));
      expect(tabletUnits, contains(StrengthUnit.mcg));
      
      final vialUnits = MedicationUtils.getAvailableStrengthUnits(MedicationType.lyophilizedVial);
      expect(vialUnits, contains(StrengthUnit.iu));
      expect(vialUnits, contains(StrengthUnit.units));
    });

    test('MedicationUtils validates strength correctly', () {
      // Valid strength
      expect(
        MedicationUtils.validateStrength(MedicationType.tablet, 10.0, StrengthUnit.mg),
        isNull,
      );
      
      // Invalid strength (too high for mcg)
      expect(
        MedicationUtils.validateStrength(MedicationType.tablet, 50000.0, StrengthUnit.mcg),
        contains('too high'),
      );
      
      // Percentage over 100
      expect(
        MedicationUtils.validateStrength(MedicationType.liquid, 150.0, StrengthUnit.percent),
        contains('cannot exceed 100'),
      );
    });
  });

  group('Widget Tests', () {
    testWidgets('SplashScreen displays correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: SplashScreen()),
      );
      
      expect(find.text('Dosifi'), findsOneWidget);
      expect(find.text('Your Personal Medication Manager'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}
