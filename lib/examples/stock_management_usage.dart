import '../data/models/medication.dart';
import '../data/models/dose_log.dart';
import '../data/models/schedule.dart';
import '../core/services/stock_management_service.dart';
import '../core/services/database_service.dart';

/// Comprehensive examples of the enhanced stock management system usage
class StockManagementUsageExamples {
  
  /// Example 1: Complete dose administration with automatic stock tracking
  static Future<void> administerDoseWithStockTracking({
    required Medication medication,
    required Schedule schedule,
    required double doseAmount,
    String? notes,
  }) async {
    try {
      // 1. Create dose log entry
      final doseLog = DoseLog.taken(
        medicationId: medication.id!,
        scheduleId: schedule.id,
        scheduledTime: schedule.timeOfDay,
        doseAmount: doseAmount,
        notes: notes,
      );

      // 2. Save dose log to database
      final db = await DatabaseService.database;
      await db.insert('dose_logs', doseLog.toMap());

      // 3. Automatically update medication stock
      await StockManagementService.recordDoseAdministration(
        medication: medication,
        doseAmount: doseAmount,
        notes: notes,
      );

      print('Dose administered and stock updated successfully');
    } catch (e) {
      print('Error administering dose: $e');
      rethrow;
    }
  }

  /// Example 2: Handle different medication types with type-specific stock tracking
  static Future<void> handleVariousMedicationTypes() async {
    // Tablet medication
    final tabletMed = Medication.create(
      name: "Aspirin 325mg",
      type: MedicationType.tablet,
      strengthPerUnit: 325.0,
      strengthUnit: StrengthUnit.mg,
      stockQuantity: 30.0, // 30 tablets
      expirationDate: DateTime.now().add(Duration(days: 365)),
    );

    // Administer 1 tablet (1 unit consumed)
    await StockManagementService.recordDoseAdministration(
      medication: tabletMed,
      doseAmount: 1.0, // 1 tablet
      notes: 'Morning dose',
    );

    // Liquid medication
    final liquidMed = Medication.create(
      name: "Amoxicillin Suspension 250mg/5mL",
      type: MedicationType.liquid,
      strengthPerUnit: 50.0, // 50mg per mL
      strengthUnit: StrengthUnit.mg,
      stockQuantity: 150.0, // 150 mL total
      expirationDate: DateTime.now().add(Duration(days: 14)),
    );

    // Administer 10mL (10mL consumed from stock)
    await StockManagementService.recordDoseAdministration(
      medication: liquidMed,
      doseAmount: 10.0, // 10 mL
      notes: 'Pediatric dose',
    );

    // Lyophilized vial
    final lyophilizedVial = Medication.create(
      name: "Ceftriaxone 1g Vial",
      type: MedicationType.lyophilizedVial,
      strengthPerUnit: 1000.0, // 1000mg per vial
      strengthUnit: StrengthUnit.mg,
      stockQuantity: 10.0, // 10mL per vial when reconstituted
      reconstitutionVolume: 10.0, // 10mL diluent
      finalConcentration: 100.0, // 100mg/mL after reconstitution
      expirationDate: DateTime.now().add(Duration(days: 730)),
    );

    // Record reconstitution
    await StockManagementService.recordReconstitution(
      medication: lyophilizedVial,
      diluentVolume: 10.0,
      diluentType: 'Sterile Water for Injection',
      notes: 'Reconstituted for immediate use',
    );

    // Administer 500mg dose (5mL from reconstituted vial)
    await StockManagementService.recordDoseAdministration(
      medication: lyophilizedVial,
      doseAmount: 500.0, // 500mg
      notes: 'IV administration',
    );
  }

  /// Example 3: Stock monitoring and alerts
  static Future<void> monitorStockStatus() async {
    // Get comprehensive stock status
    final stockStatus = await StockManagementService.getStockStatus();

    if (stockStatus.hasAlerts) {
      print('Stock Alerts Found: ${stockStatus.totalAlerts}');
      
      // Handle low stock medications
      if (stockStatus.lowStockCount > 0) {
        print('\nLow Stock Medications (${stockStatus.lowStockCount}):');
        for (final med in stockStatus.lowStockMedications) {
          print('- ${med.name}: ${med.stockDisplay}');
        }
      }

      // Handle expired medications
      if (stockStatus.expiredCount > 0) {
        print('\nExpired Medications (${stockStatus.expiredCount}):');
        for (final med in stockStatus.expiredMedications) {
          print('- ${med.name}: Expired ${med.daysUntilExpiration! * -1} days ago');
          
          // Record expiration disposal
          await StockManagementService.recordExpiration(
            medication: med,
            expiredAmount: med.stockQuantity,
            notes: 'Automatic disposal of expired medication',
          );
        }
      }

      // Handle medications expiring soon
      if (stockStatus.expiringSoonCount > 0) {
        print('\nMedications Expiring Soon (${stockStatus.expiringSoonCount}):');
        for (final med in stockStatus.expiringSoonMedications) {
          print('- ${med.name}: Expires in ${med.daysUntilExpiration} days');
        }
      }
    } else {
      print('All medications are adequately stocked and not expired.');
    }
  }

  /// Example 4: Stock adjustment and wastage tracking
  static Future<void> handleStockAdjustments(Medication medication) async {
    // Record stock adjustment (manual count correction)
    await StockManagementService.recordAdjustment(
      medication: medication,
      adjustmentAmount: -2.0, // Found 2 units less than expected
      reason: 'Physical inventory count correction',
      notes: 'Annual inventory audit adjustment',
    );

    // Record wastage due to contamination
    await StockManagementService.recordWastage(
      medication: medication,
      wastedAmount: 5.0,
      reason: 'Contamination during preparation',
      notes: 'Vial dropped and contaminated during preparation',
    );

    // Record restocking
    await StockManagementService.recordRestock(
      medication: medication,
      restockAmount: 50.0,
      lotNumber: 'LOT123456',
      expirationDate: DateTime.now().add(Duration(days: 730)),
      notes: 'Monthly supplier delivery',
    );
  }

  /// Example 5: Inventory reporting and analytics
  static Future<void> generateInventoryReports() async {
    // Get basic inventory statistics
    final stats = await StockManagementService.calculateInventoryStats();
    
    print('=== Inventory Statistics ===');
    print('Total Medications: ${stats['total_medications']}');
    print('Total Units in Stock: ${stats['total_units']}');
    print('Low Stock Items: ${stats['low_stock_count']}');
    print('Expired Items: ${stats['expired_count']}');

    // Get recent stock activities
    final recentActivities = await StockManagementService.getRecentStockActivities(20);
    
    print('\n=== Recent Stock Activities (Last 20) ===');
    for (final activity in recentActivities) {
      if (activity is StockLogEntryWithName) {
        print('${activity.timestamp.toLocal()} - ${activity.medicationName}:');
        print('  ${activity.reason} ${activity.displayAmount} (Total: ${activity.displayTotal})');
        if (activity.notes != null) {
          print('  Notes: ${activity.notes}');
        }
        print('');
      }
    }
  }

  /// Example 6: Complete medication lifecycle management
  static Future<void> completeMedicationLifecycle() async {
    // 1. Add new medication to inventory
    final insulin = Medication.create(
      name: "Insulin Glargine 100 units/mL",
      type: MedicationType.preFilledSyringe,
      strengthPerUnit: 100.0,
      strengthUnit: StrengthUnit.units,
      stockQuantity: 5.0, // 5 pre-filled pens
      expirationDate: DateTime.now().add(Duration(days: 365)),
      requiresRefrigeration: true,
      storageTemperature: "2-8°C",
      lowStockThreshold: 2.0, // Alert when less than 2 pens remain
    );

    // Save to database
    final db = await DatabaseService.database;
    final insulinId = await db.insert('medications', insulin.toMap());
    final savedInsulin = insulin.copyWith(id: insulinId);

    // 2. Regular dose administrations
    for (int day = 1; day <= 10; day++) {
      await StockManagementService.recordDoseAdministration(
        medication: savedInsulin,
        doseAmount: 20.0, // 20 units per dose
        notes: 'Day $day morning dose',
      );
    }

    // 3. Check stock status after usage
    final currentStock = await StockManagementService.getLowStockMedications();
    if (currentStock.any((med) => med.id == insulinId)) {
      print('Insulin is running low - time to reorder');
      
      // 4. Restock when low
      await StockManagementService.recordRestock(
        medication: savedInsulin,
        restockAmount: 10.0, // 10 new pens
        lotNumber: 'INS789012',
        expirationDate: DateTime.now().add(Duration(days: 365)),
        notes: 'Monthly insulin supply replenishment',
      );
    }

    // 5. Handle expiration (when medication expires)
    final expiredMedications = await StockManagementService.getExpiredMedications();
    for (final expired in expiredMedications) {
      await StockManagementService.recordExpiration(
        medication: expired,
        expiredAmount: expired.stockQuantity,
        notes: 'End-of-life disposal following protocol',
      );
    }
  }

  /// Example 7: Integration with scheduling system
  static Future<void> integrateWithScheduling(
    Medication medication,
    Schedule schedule,
  ) async {
    final now = DateTime.now();
    
    // Check if it's time to take medication
    if (schedule.isTimeForDose(now)) {
      // Validate sufficient stock before administration
      final doseAmount = schedule.doseAmount;
      
      if (medication.stockQuantity >= doseAmount) {
        // Create and save dose log
        final doseLog = DoseLog.taken(
          medicationId: medication.id!,
          scheduleId: schedule.id,
          scheduledTime: now,
          doseAmount: doseAmount,
          notes: 'Scheduled dose via app',
        );

        final db = await DatabaseService.database;
        await db.insert('dose_logs', doseLog.toMap());

        // Update stock automatically
        await StockManagementService.recordDoseAdministration(
          medication: medication,
          doseAmount: doseAmount,
          notes: 'Scheduled administration',
        );

        print('Dose taken and recorded successfully');
      } else {
        print('Insufficient stock for scheduled dose');
        // Could trigger low stock alert or notification
      }
    }
  }
}
