import 'package:flutter/foundation.dart';
import 'package:dosifi_flutter/core/services/database_service.dart';
import 'package:dosifi_flutter/data/models/medication.dart';

/// Comprehensive stock management service for medications and supplies
class StockManagementService {
  static const String _logTag = 'StockManagement';

  /// Stock change reasons for logging
  static const String reasonAdministered = 'ADMINISTERED';
  static const String reasonWasted = 'WASTED';
  static const String reasonExpired = 'EXPIRED';
  static const String reasonRestocked = 'RESTOCKED';
  static const String reasonAdjustment = 'ADJUSTMENT';
  static const String reasonTransfer = 'TRANSFER';
  static const String reasonReconstitution = 'RECONSTITUTION';

  /// Record medication dose administration and update stock
  static Future<StockUpdateResult> recordDoseAdministration({
    required Medication medication,
    required double doseAmount,
    String? notes,
  }) async {
    try {
      // Convert dose amount to medication units for stock tracking
      double unitsConsumed;

      switch (medication.type) {
        case MedicationType.tablet:
        case MedicationType.capsule:
          unitsConsumed = doseAmount; // Direct unit consumption
          break;
        case MedicationType.liquid:
        case MedicationType.drops:
          unitsConsumed = doseAmount; // mL consumed from liquid stock
          break;
        case MedicationType.preFilledSyringe:
        case MedicationType.singleUsePen:
          unitsConsumed = 1.0; // One unit per dose (full syringe/pen)
          break;
        case MedicationType.readyMadeVial:
          unitsConsumed = doseAmount; // mL consumed from vial
          break;
        case MedicationType.lyophilizedVial:
          // For lyophilized vials, we need to calculate from final concentration
          if (medication.finalConcentration != null &&
              medication.finalConcentration! > 0) {
            unitsConsumed =
                doseAmount /
                medication.finalConcentration!; // mL from reconstituted vial
          } else {
            unitsConsumed = doseAmount;
          }
          break;
        default:
          unitsConsumed = doseAmount;
      }

      // Lightweight unit check: for liquid/vial types, we work in mL
      if (_requiresMlStock(medication) &&
          medication.stockUnit != null &&
          medication.stockUnit != StrengthUnit.ml) {
        return StockUpdateResult.failure(
          code: StockUpdateFailureCode.invalidOperation,
          message:
              'Medication ${medication.name} expects stock in mL for ${medication.type.displayName}. Found ${medication.stockUnit?.displayName}.',
        );
      }

      // Log the stock change
      final result = await medication.logStockChange(
        changeAmount: -unitsConsumed, // Negative for consumption
        reason: reasonAdministered,
        notes:
            notes ??
            'Dose administration: $doseAmount ${medication.strengthUnit.displayName}',
      );
      if (!result.ok) return result;

      debugPrint(
        '$_logTag: Recorded dose administration for ${medication.name}: -$unitsConsumed units',
      );
      return result;
    } catch (e) {
      debugPrint('$_logTag: Error recording dose administration: $e');
      rethrow;
    }
  }

  /// Record medication wastage
  static Future<StockUpdateResult> recordWastage({
    required Medication medication,
    required double wastedAmount,
    required String reason,
    String? notes,
  }) async {
    try {
      final result = await medication.logStockChange(
        changeAmount: -wastedAmount,
        reason: reasonWasted,
        notes: 'Wastage: $reason ${notes != null ? '- $notes' : ''}',
      );
      if (!result.ok) return result;

      debugPrint(
        '$_logTag: Recorded wastage for ${medication.name}: -$wastedAmount units',
      );
      return result;
    } catch (e) {
      debugPrint('$_logTag: Error recording wastage: $e');
      rethrow;
    }
  }

  /// Record medication expiration/disposal
  static Future<StockUpdateResult> recordExpiration({
    required Medication medication,
    required double expiredAmount,
    String? notes,
  }) async {
    try {
      final result = await medication.logStockChange(
        changeAmount: -expiredAmount,
        reason: reasonExpired,
        notes: 'Expired medication disposal${notes != null ? ' - $notes' : ''}',
      );
      if (!result.ok) return result;

      debugPrint(
        '$_logTag: Recorded expiration for ${medication.name}: -$expiredAmount units',
      );
      return result;
    } catch (e) {
      debugPrint('$_logTag: Error recording expiration: $e');
      rethrow;
    }
  }

  /// Record medication restocking
  static Future<StockUpdateResult> recordRestock({
    required Medication medication,
    required double restockAmount,
    String? lotNumber,
    DateTime? expirationDate,
    String? notes,
  }) async {
    try {
      final stockNotes = StringBuffer('Restock');
      if (lotNumber != null) stockNotes.write(' - Lot: $lotNumber');
      if (expirationDate != null)
        stockNotes.write(
          ' - Exp: ${expirationDate.toLocal().toString().split(' ')[0]}',
        );
      if (notes != null) stockNotes.write(' - $notes');

      final result = await medication.logStockChange(
        changeAmount: restockAmount,
        reason: reasonRestocked,
        notes: stockNotes.toString(),
      );
      if (!result.ok) return result;

      debugPrint(
        '$_logTag: Recorded restock for ${medication.name}: +$restockAmount units',
      );
      return result;
    } catch (e) {
      debugPrint('$_logTag: Error recording restock: $e');
      rethrow;
    }
  }

  /// Record stock adjustment (manual correction)
  static Future<StockUpdateResult> recordAdjustment({
    required Medication medication,
    required double adjustmentAmount,
    required String reason,
    String? notes,
  }) async {
    try {
      final result = await medication.logStockChange(
        changeAmount: adjustmentAmount,
        reason: reasonAdjustment,
        notes: 'Adjustment: $reason${notes != null ? ' - $notes' : ''}',
      );
      if (!result.ok) return result;

      debugPrint(
        '$_logTag: Recorded adjustment for ${medication.name}: ${adjustmentAmount >= 0 ? '+' : ''}$adjustmentAmount units',
      );
      return result;
    } catch (e) {
      debugPrint('$_logTag: Error recording adjustment: $e');
      rethrow;
    }
  }

  /// Record vial reconstitution
  static Future<StockUpdateResult> recordReconstitution({
    required Medication medication,
    required double diluentVolume,
    String? diluentType,
    String? notes,
  }) async {
    try {
      final reconstitutionNotes = StringBuffer('Reconstitution');
      reconstitutionNotes.write(' - Added ${diluentVolume}mL');
      if (diluentType != null) reconstitutionNotes.write(' of $diluentType');
      if (notes != null) reconstitutionNotes.write(' - $notes');

      if (medication.type == MedicationType.lyophilizedVial) {
        // Safety: ensure we have a dry vial available
        final currentVials = (medication.vialsInStock ?? 0);
        if (currentVials <= 0) {
          debugPrint(
            '$_logTag: Cannot reconstitute ${medication.name}: no dry vials available',
          );
          return StockUpdateResult.failure(
            code: StockUpdateFailureCode.invalidOperation,
            message: 'No dry vials remaining to reconstitute.',
          );
        }
        // Convert one dry vial to reconstituted volume in mL
        final addedVolume = medication.reconstitutionVolume ?? diluentVolume;
        final newVials = currentVials - 1;
        final updated = medication.copyWith(
          // Do not pre-increment stockQuantity here; let the logStockChange apply the increment once
          vialsInStock: newVials,
        );
        final result = await updated.logStockChange(
          changeAmount: addedVolume,
          reason: reasonReconstitution,
          notes: reconstitutionNotes.toString(),
        );
        if (!result.ok) return result;
        debugPrint(
          '$_logTag: Reconstituted ${medication.name}: +${addedVolume}mL, vials now ${newVials.toStringAsFixed(0)}',
        );
        return result;
      } else {
        // Non-lyophilized: just log a no-op
        final result = await medication.logStockChange(
          changeAmount: 0.0,
          reason: reasonReconstitution,
          notes: reconstitutionNotes.toString(),
        );
        return result;
      }
    } catch (e) {
      debugPrint('$_logTag: Error recording reconstitution: $e');
      rethrow;
    }
  }

  /// Get low stock medications
  static Future<List<Medication>> getLowStockMedications() async {
    try {
      final db = await DatabaseService.database;
      final results = await db.query(
        'medications',
        where: 'is_active = ?',
        whereArgs: [1],
      );

      final medications = results
          .map((map) => Medication.fromMap(map))
          .toList();
      return medications.where((med) => med.isLowStock).toList();
    } catch (e) {
      debugPrint('$_logTag: Error getting low stock medications: $e');
      return [];
    }
  }

  /// Get expired medications
  static Future<List<Medication>> getExpiredMedications() async {
    try {
      final db = await DatabaseService.database;
      final today = DateTime.now().toIso8601String().split('T')[0];

      final results = await db.query(
        'medications',
        where:
            'is_active = ? AND expiration_date IS NOT NULL AND expiration_date < ?',
        whereArgs: [1, today],
      );

      return results.map((map) => Medication.fromMap(map)).toList();
    } catch (e) {
      debugPrint('$_logTag: Error getting expired medications: $e');
      return [];
    }
  }

  /// Get medications expiring soon (within specified days)
  static Future<List<Medication>> getMedicationsExpiringSoon([
    int days = 30,
  ]) async {
    try {
      final db = await DatabaseService.database;
      final futureDate = DateTime.now()
          .add(Duration(days: days))
          .toIso8601String()
          .split('T')[0];
      final today = DateTime.now().toIso8601String().split('T')[0];

      final results = await db.query(
        'medications',
        where:
            'is_active = ? AND expiration_date IS NOT NULL AND expiration_date > ? AND expiration_date <= ?',
        whereArgs: [1, today, futureDate],
      );

      return results.map((map) => Medication.fromMap(map)).toList();
    } catch (e) {
      debugPrint('$_logTag: Error getting medications expiring soon: $e');
      return [];
    }
  }

  /// Get comprehensive stock status
  static Future<StockStatus> getStockStatus() async {
    try {
      final lowStockMeds = await getLowStockMedications();
      final expiredMeds = await getExpiredMedications();
      final expiringSoonMeds = await getMedicationsExpiringSoon();

      return StockStatus(
        lowStockCount: lowStockMeds.length,
        expiredCount: expiredMeds.length,
        expiringSoonCount: expiringSoonMeds.length,
        lowStockMedications: lowStockMeds,
        expiredMedications: expiredMeds,
        expiringSoonMedications: expiringSoonMeds,
      );
    } catch (e) {
      debugPrint('$_logTag: Error getting stock status: $e');
      return StockStatus.empty();
    }
  }

  /// Get recent stock activities across all medications
  static Future<List<StockLogEntry>> getRecentStockActivities([
    int limit = 50,
  ]) async {
    try {
      final db = await DatabaseService.database;

      final results = await db.rawQuery(
        '''
        SELECT msl.*, m.name as medication_name 
        FROM medication_stock_logs msl
        JOIN medications m ON msl.medication_id = m.id
        ORDER BY msl.timestamp DESC
        LIMIT ?
      ''',
        [limit],
      );

      return results
          .map((map) {
            final entry = StockLogEntry.fromMap(map);
            return StockLogEntryWithName(
              entry: entry,
              medicationName: map['medication_name'] as String,
            );
          })
          .cast<StockLogEntry>()
          .toList();
    } catch (e) {
      debugPrint('$_logTag: Error getting recent stock activities: $e');
      return [];
    }
  }

  /// Calculate total medication value (if cost information available)
  static Future<Map<String, dynamic>> calculateInventoryStats() async {
    try {
      final db = await DatabaseService.database;

      final results = await db.rawQuery('''
        SELECT 
          COUNT(*) as total_medications,
          SUM(stock_quantity) as total_units,
          COUNT(CASE WHEN stock_quantity <= 
            CASE 
              WHEN type IN ('tablet', 'capsule') THEN 7
              WHEN type IN ('liquid', 'drops') THEN 30
              ELSE 5
            END THEN 1 END) as low_stock_count,
          COUNT(CASE WHEN expiration_date <= date('now') THEN 1 END) as expired_count
        FROM medications
        WHERE is_active = 1
      ''');

      final result = results.first;
      return {
        'total_medications': result['total_medications'] ?? 0,
        'total_units': result['total_units'] ?? 0.0,
        'low_stock_count': result['low_stock_count'] ?? 0,
        'expired_count': result['expired_count'] ?? 0,
      };
    } catch (e) {
      debugPrint('$_logTag: Error calculating inventory stats: $e');
      return {
        'total_medications': 0,
        'total_units': 0.0,
        'low_stock_count': 0,
        'expired_count': 0,
      };
    }
  }

  static bool _requiresMlStock(Medication m) {
    return m.type == MedicationType.liquid ||
        m.type == MedicationType.readyMadeVial ||
        m.type == MedicationType.lyophilizedVial;
  }
}

/// Comprehensive stock status information
class StockStatus {
  final int lowStockCount;
  final int expiredCount;
  final int expiringSoonCount;
  final List<Medication> lowStockMedications;
  final List<Medication> expiredMedications;
  final List<Medication> expiringSoonMedications;

  const StockStatus({
    required this.lowStockCount,
    required this.expiredCount,
    required this.expiringSoonCount,
    required this.lowStockMedications,
    required this.expiredMedications,
    required this.expiringSoonMedications,
  });

  factory StockStatus.empty() {
    return const StockStatus(
      lowStockCount: 0,
      expiredCount: 0,
      expiringSoonCount: 0,
      lowStockMedications: <Medication>[],
      expiredMedications: <Medication>[],
      expiringSoonMedications: <Medication>[],
    );
  }

  bool get hasAlerts =>
      lowStockCount > 0 || expiredCount > 0 || expiringSoonCount > 0;
  int get totalAlerts => lowStockCount + expiredCount + expiringSoonCount;
}

/// Extended stock log entry with medication name
class StockLogEntryWithName extends StockLogEntry {
  final String medicationName;

  StockLogEntryWithName({
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
