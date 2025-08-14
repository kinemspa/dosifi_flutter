import 'package:flutter_test/flutter_test.dart';
import 'package:dosifi_flutter/data/models/medication.dart';
import 'package:dosifi_flutter/core/services/stock_management_service.dart';

/// A fake Medication that avoids DB calls and lets us observe stock changes
class TestMedicationFake extends Medication {
  double mutableStock;
  double? mutableVials;

  TestMedicationFake({
    int? id,
    required String name,
    required MedicationType type,
    String? brandManufacturer,
    required double strengthPerUnit,
    required StrengthUnit strengthUnit,
    required double stockQuantity,
    StrengthUnit? stockUnit,
    double? vialsInStock,
    double? packageSize,
    double? reconstitutionVolume,
    double? finalConcentration,
    bool requiresRefrigeration = false,
  })  : mutableStock = stockQuantity,
        mutableVials = vialsInStock,
        super(
          id: id,
          name: name,
          type: type,
          brandManufacturer: brandManufacturer,
          strengthPerUnit: strengthPerUnit,
          strengthUnit: strengthUnit,
          stockQuantity: stockQuantity,
          stockUnit: stockUnit,
          vialsInStock: vialsInStock,
          packageSize: packageSize,
          reconstitutionVolume: reconstitutionVolume,
          finalConcentration: finalConcentration,
          requiresRefrigeration: requiresRefrigeration,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

  @override
  Future<StockUpdateResult> logStockChange({
    required double changeAmount,
    required String reason,
    String? notes,
  }) async {
    final proposed = mutableStock + changeAmount;
    if (proposed < 0) {
      return StockUpdateResult.failure(
        code: StockUpdateFailureCode.insufficientStock,
        message: 'Insufficient stock',
      );
    }
    mutableStock = proposed;
    return StockUpdateResult.success(newTotal: mutableStock);
  }

  @override
  TestMedicationFake copyWith({
    int? id,
    String? name,
    MedicationType? type,
    String? brandManufacturer,
    double? strengthPerUnit,
    StrengthUnit? strengthUnit,
    double? stockQuantity,
    String? lotBatchNumber,
    DateTime? expirationDate,
    double? vialsInStock,
    double? packageSize,
    double? reconstitutionVolume,
    double? finalConcentration,
    String? reconstitutionNotes,
    String? description,
    String? instructions,
    String? notes,
    String? barcode,
    String? photoPath,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? themeColor,
  }) {
    // Mutate this fake to reflect changes and return itself
    mutableStock = stockQuantity ?? mutableStock;
    mutableVials = vialsInStock ?? mutableVials;
    return this;
  }
}

void main() {
  group('StockManagementService', () {
    test('dose administration subtracts units for tablets', () async {
      final med = TestMedicationFake(
        name: 'Test Tab',
        type: MedicationType.tablet,
        strengthPerUnit: 500,
        strengthUnit: StrengthUnit.mg,
        stockQuantity: 10,
      );
      final res = await StockManagementService.recordDoseAdministration(
        medication: med,
        doseAmount: 2, // 2 tablets
      );
      expect(res.ok, true);
      expect(med.mutableStock, 8);
    });

    test('prevents negative stock on large dose', () async {
      final med = TestMedicationFake(
        name: 'Test Tab',
        type: MedicationType.tablet,
        strengthPerUnit: 500,
        strengthUnit: StrengthUnit.mg,
        stockQuantity: 1,
      );
      final res = await StockManagementService.recordDoseAdministration(
        medication: med,
        doseAmount: 2,
      );
      expect(res.ok, false);
      expect(res.code, StockUpdateFailureCode.insufficientStock);
      expect(med.mutableStock, 1);
    });

    test('unit mismatch guard for liquid expects mL', () async {
      final med = TestMedicationFake(
        name: 'Syrup',
        type: MedicationType.liquid,
        strengthPerUnit: 100, // mg/mL or similar
        strengthUnit: StrengthUnit.mg,
        stockQuantity: 100,
        stockUnit: StrengthUnit.units, // wrong unit
      );
      final res = await StockManagementService.recordDoseAdministration(
        medication: med,
        doseAmount: 5,
      );
      expect(res.ok, false);
      expect(res.code, StockUpdateFailureCode.invalidOperation);
      expect(med.mutableStock, 100);
    });

    test('lyophilized reconstitution adds volume and decrements vials', () async {
      final med = TestMedicationFake(
        name: 'Lyoph',
        type: MedicationType.lyophilizedVial,
        strengthPerUnit: 1,
        strengthUnit: StrengthUnit.units,
        stockQuantity: 0,
        vialsInStock: 2,
        reconstitutionVolume: 10,
        finalConcentration: 100,
      );
      final res = await StockManagementService.recordReconstitution(
        medication: med,
        diluentVolume: 10,
      );
      expect(res.ok, true);
      expect(med.mutableStock, 10);
      // vials decremented by one
      expect(med.mutableVials, 1);
    });

    test('lyophilized reconstitution fails when no vials remain', () async {
      final med = TestMedicationFake(
        name: 'Lyoph',
        type: MedicationType.lyophilizedVial,
        strengthPerUnit: 1,
        strengthUnit: StrengthUnit.units,
        stockQuantity: 0,
        vialsInStock: 0,
        reconstitutionVolume: 10,
        finalConcentration: 100,
      );
      final res = await StockManagementService.recordReconstitution(
        medication: med,
        diluentVolume: 10,
      );
      expect(res.ok, false);
      expect(res.code, StockUpdateFailureCode.invalidOperation);
      expect(med.mutableStock, 0);
    });
  });
}

