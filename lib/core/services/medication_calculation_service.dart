import 'package:flutter/foundation.dart';
import '../../data/models/medication.dart';

/// Service for advanced medication calculations and type-specific operations
class MedicationCalculationService {
  
  /// Calculate exact dose deduction amount based on medication type and dose parameters
  static double calculateDoseDeduction(Medication medication, double doseAmount, String doseUnit) {
    debugPrint('🧮 Calculating dose deduction for ${medication.name}: $doseAmount $doseUnit');
    
    switch (medication.type) {
      case MedicationType.tablet:
      case MedicationType.capsule:
        return _calculateSolidDosageDeduction(medication, doseAmount, doseUnit);
      
      case MedicationType.liquid:
        return _calculateLiquidDeduction(medication, doseAmount, doseUnit);
      
      case MedicationType.preFilledSyringe:
      case MedicationType.readyMadeVial:
        return _calculateInjectableDeduction(medication, doseAmount, doseUnit);
      
      case MedicationType.lyophilizedVial:
        return _calculateLyophilizedDeduction(medication, doseAmount, doseUnit);
      
      case MedicationType.cream:
      case MedicationType.ointment:
        return _calculateTopicalDeduction(medication, doseAmount, doseUnit);
      
      case MedicationType.drops:
        return _calculateDropsDeduction(medication, doseAmount, doseUnit);
      
      case MedicationType.inhaler:
        return _calculateInhalerDeduction(medication, doseAmount, doseUnit);
      
      case MedicationType.patch:
        return _calculatePatchDeduction(medication, doseAmount, doseUnit);
      
      case MedicationType.suppository:
        return _calculateSuppositoryDeduction(medication, doseAmount, doseUnit);
      
      case MedicationType.other:
        return _calculateGenericDeduction(medication, doseAmount, doseUnit);
    }
  }

  /// Calculate days of supply remaining for a medication given current usage
  static double calculateDaysOfSupply(Medication medication, double dailyUsage, String usageUnit) {
    if (dailyUsage <= 0) return double.infinity;
    
    final currentStock = medication.stockQuantity;
    
    switch (medication.type) {
      case MedicationType.tablet:
      case MedicationType.capsule:
        // Daily usage is in tablets/capsules, stock is in tablets/capsules
        return currentStock / dailyUsage;
      
      case MedicationType.liquid:
      case MedicationType.drops:
        // Convert usage to mL if needed
        double usageInMl = dailyUsage;
        if (usageUnit == 'tsp') usageInMl = dailyUsage * 5.0;
        if (usageUnit == 'tbsp') usageInMl = dailyUsage * 15.0;
        if (usageUnit == 'drops') usageInMl = dailyUsage / 20.0; // ~20 drops per mL
        return currentStock / usageInMl;
      
      case MedicationType.preFilledSyringe:
      case MedicationType.readyMadeVial:
      case MedicationType.lyophilizedVial:
        // Usage is in mL, stock is in mL
        return currentStock / dailyUsage;
      
      case MedicationType.cream:
      case MedicationType.ointment:
        // Usage might be in applications or grams
        double usageInGrams = dailyUsage;
        if (usageUnit == 'applications') {
          // Estimate: 1 application ≈ 0.5g for creams, 1g for ointments
          final gramsPerApplication = medication.type == MedicationType.cream ? 0.5 : 1.0;
          usageInGrams = dailyUsage * gramsPerApplication;
        }
        return currentStock / usageInGrams;
      
      case MedicationType.inhaler:
        // Stock is in doses, usage is in puffs/doses
        return currentStock / dailyUsage;
      
      case MedicationType.patch:
        // Each patch lasts a certain number of days
        final patchDuration = _getPatchDurationDays(medication);
        final patchesNeeded = 1.0 / patchDuration; // Patches needed per day
        return currentStock / patchesNeeded;
      
      case MedicationType.suppository:
        // Stock is in suppositories, usage is in suppositories
        return currentStock / dailyUsage;
      
      case MedicationType.other:
        return currentStock / dailyUsage;
    }
  }

  /// Calculate total active ingredient remaining
  static double calculateTotalActiveIngredient(Medication medication) {
    switch (medication.type) {
      case MedicationType.tablet:
      case MedicationType.capsule:
      case MedicationType.suppository:
        // strength_per_unit × unit_count
        return medication.strengthPerUnit * medication.stockQuantity;
      
      case MedicationType.liquid:
      case MedicationType.drops:
        // concentration × volume
        return medication.strengthPerUnit * medication.stockQuantity;
      
      case MedicationType.preFilledSyringe:
      case MedicationType.readyMadeVial:
        // concentration × total_volume
        return medication.strengthPerUnit * medication.stockQuantity;
      
      case MedicationType.lyophilizedVial:
        // For lyophilized: depends on whether it's reconstituted
        if (medication.finalConcentration != null) {
          // Post-reconstitution: final_concentration × available_volume
          return medication.finalConcentration! * medication.stockQuantity;
        } else {
          // Pre-reconstitution: strength_per_vial × vial_count
          return medication.strengthPerUnit * medication.stockQuantity;
        }
      
      case MedicationType.cream:
      case MedicationType.ointment:
        // concentration × weight
        if (medication.strengthUnit == StrengthUnit.percent) {
          // Percentage: (percentage/100) × weight × 1000 (to get mg)
          return (medication.strengthPerUnit / 100.0) * medication.stockQuantity * 1000.0;
        }
        return medication.strengthPerUnit * medication.stockQuantity;
      
      case MedicationType.inhaler:
        // strength_per_dose × doses_remaining
        return medication.strengthPerUnit * medication.stockQuantity;
      
      case MedicationType.patch:
        // For patches: strength_per_patch × patch_count
        return medication.strengthPerUnit * medication.stockQuantity;
      
      case MedicationType.other:
        return medication.strengthPerUnit * medication.stockQuantity;
    }
  }

  /// Validate dose amount against medication constraints
  static String? validateDoseAmount(Medication medication, double doseAmount, String doseUnit) {
    // Check minimum precision
    final precision = medication.dosePrecision;
    if (doseAmount % precision != 0) {
      return 'Dose must be in increments of $precision for ${medication.type.displayName}s';
    }

    // Check if dose unit is allowed for this medication type
    if (!medication.allowedDoseUnits.contains(doseUnit)) {
      return 'Unit "$doseUnit" is not allowed for ${medication.type.displayName}s. Allowed units: ${medication.allowedDoseUnits.join(", ")}';
    }

    // Type-specific validations
    switch (medication.type) {
      case MedicationType.capsule:
      case MedicationType.suppository:
      case MedicationType.patch:
        if (doseAmount != doseAmount.round()) {
          return '${medication.type.displayName}s cannot be split - use whole units only';
        }
        break;
      
      case MedicationType.tablet:
        if (doseAmount < 0.25) {
          return 'Tablets cannot be split smaller than 1/4 tablet';
        }
        break;
      
      case MedicationType.lyophilizedVial:
        if (medication.reconstitutionVolume == null || medication.finalConcentration == null) {
          return 'Lyophilized vial must be reconstituted before use';
        }
        break;
      
      case MedicationType.liquid:
      case MedicationType.preFilledSyringe:
      case MedicationType.readyMadeVial:
      case MedicationType.cream:
      case MedicationType.ointment:
      case MedicationType.drops:
      case MedicationType.inhaler:
      case MedicationType.other:
        // No specific validation constraints for these types
        break;
    }

    // Check against available stock
    final deductionAmount = calculateDoseDeduction(medication, doseAmount, doseUnit);
    if (deductionAmount > medication.stockQuantity) {
      return 'Insufficient stock. Requested: $deductionAmount, Available: ${medication.stockQuantity}';
    }

    return null; // No validation errors
  }

  // Private calculation methods for each medication type

  static double _calculateSolidDosageDeduction(Medication medication, double doseAmount, String doseUnit) {
    switch (doseUnit) {
      case 'tablet':
      case 'tablets':
      case 'capsule':
      case 'capsules':
        return doseAmount; // Direct deduction in units
      
      case 'mg':
      case 'mcg':
      case 'g':
        // Convert strength amount to units needed
        final strengthInSameUnit = _convertToSameUnit(medication.strengthPerUnit, medication.strengthUnit.displayName, doseUnit);
        return doseAmount / strengthInSameUnit;
      
      default:
        return doseAmount;
    }
  }

  static double _calculateLiquidDeduction(Medication medication, double doseAmount, String doseUnit) {
    switch (doseUnit) {
      case 'mL':
        return doseAmount;
      
      case 'L':
        return doseAmount * 1000.0; // Convert to mL
      
      case 'tsp':
        return doseAmount * 5.0; // tsp to mL
      
      case 'tbsp':
        return doseAmount * 15.0; // tbsp to mL
      
      case 'mg':
      case 'mcg':
      case 'g':
        // Calculate volume needed: dose_amount / concentration
        final concentrationInSameUnit = _convertToSameUnit(medication.strengthPerUnit, medication.strengthUnit.displayName, doseUnit);
        return doseAmount / concentrationInSameUnit;
      
      default:
        return doseAmount;
    }
  }

  static double _calculateInjectableDeduction(Medication medication, double doseAmount, String doseUnit) {
    switch (doseUnit) {
      case 'mL':
        return doseAmount;
      
      case 'Units':
      case 'IU':
      case 'mg':
      case 'mcg':
        // Calculate volume needed: dose_units / concentration
        final concentrationInSameUnit = _convertToSameUnit(medication.strengthPerUnit, medication.strengthUnit.displayName, doseUnit);
        return doseAmount / concentrationInSameUnit;
      
      default:
        return doseAmount;
    }
  }

  static double _calculateLyophilizedDeduction(Medication medication, double doseAmount, String doseUnit) {
    if (medication.finalConcentration == null) {
      debugPrint('⚠️ Lyophilized vial not reconstituted - cannot calculate dose');
      return 0.0;
    }

    switch (doseUnit) {
      case 'mL':
        return doseAmount;
      
      case 'Units':
      case 'IU':
      case 'mg':
      case 'mcg':
        // Use final concentration after reconstitution
        return doseAmount / medication.finalConcentration!;
      
      default:
        return doseAmount;
    }
  }

  static double _calculateTopicalDeduction(Medication medication, double doseAmount, String doseUnit) {
    switch (doseUnit) {
      case 'g':
        return doseAmount;
      
      case 'applications':
        // Estimate grams per application based on medication type
        final gramsPerApplication = medication.type == MedicationType.cream ? 0.5 : 1.0;
        return doseAmount * gramsPerApplication;
      
      case 'mg':
      case 'mcg':
        // Calculate weight needed: dose_amount / concentration
        final concentrationInSameUnit = _convertToSameUnit(medication.strengthPerUnit, medication.strengthUnit.displayName, doseUnit);
        return doseAmount / concentrationInSameUnit;
      
      default:
        return doseAmount;
    }
  }

  static double _calculateDropsDeduction(Medication medication, double doseAmount, String doseUnit) {
    switch (doseUnit) {
      case 'drops':
        return doseAmount / 20.0; // Convert drops to mL (~20 drops per mL)
      
      case 'mL':
        return doseAmount;
      
      case 'mg':
      case 'mcg':
        // Calculate volume needed: dose_amount / concentration
        final concentrationInSameUnit = _convertToSameUnit(medication.strengthPerUnit, medication.strengthUnit.displayName, doseUnit);
        final volumeNeeded = doseAmount / concentrationInSameUnit;
        return volumeNeeded;
      
      default:
        return doseAmount;
    }
  }

  static double _calculateInhalerDeduction(Medication medication, double doseAmount, String doseUnit) {
    switch (doseUnit) {
      case 'puffs':
      case 'doses':
        return doseAmount; // Direct deduction in doses
      
      case 'mg':
      case 'mcg':
        // Calculate puffs needed: dose_amount / strength_per_puff
        final strengthInSameUnit = _convertToSameUnit(medication.strengthPerUnit, medication.strengthUnit.displayName, doseUnit);
        return doseAmount / strengthInSameUnit;
      
      default:
        return doseAmount;
    }
  }

  static double _calculatePatchDeduction(Medication medication, double doseAmount, String doseUnit) {
    switch (doseUnit) {
      case 'patches':
        return doseAmount; // Direct deduction in patches
      
      case 'mcg/hr':
      case 'mg/hr':
        // Calculate patches needed: dose_rate / patch_delivery_rate
        final rateInSameUnit = _convertToSameUnit(medication.strengthPerUnit, medication.strengthUnit.displayName, doseUnit);
        return doseAmount / rateInSameUnit;
      
      default:
        return doseAmount;
    }
  }

  static double _calculateSuppositoryDeduction(Medication medication, double doseAmount, String doseUnit) {
    switch (doseUnit) {
      case 'suppository':
      case 'suppositories':
        return doseAmount; // Direct deduction in suppositories
      
      case 'mg':
      case 'mcg':
      case 'g':
        // Calculate suppositories needed: dose_amount / strength_per_suppository
        final strengthInSameUnit = _convertToSameUnit(medication.strengthPerUnit, medication.strengthUnit.displayName, doseUnit);
        return doseAmount / strengthInSameUnit;
      
      default:
        return doseAmount;
    }
  }

  static double _calculateGenericDeduction(Medication medication, double doseAmount, String doseUnit) {
    // Generic calculation for "other" medication types
    if (doseUnit == 'units') {
      return doseAmount;
    }
    
    // Try to convert based on strength
    final strengthInSameUnit = _convertToSameUnit(medication.strengthPerUnit, medication.strengthUnit.displayName, doseUnit);
    if (strengthInSameUnit > 0) {
      return doseAmount / strengthInSameUnit;
    }
    
    return doseAmount;
  }

  /// Helper method to convert between units
  static double _convertToSameUnit(double value, String fromUnit, String toUnit) {
    if (fromUnit == toUnit) return value;
    
    // Weight conversions
    if (fromUnit == 'mg' && toUnit == 'mcg') return value * 1000.0;
    if (fromUnit == 'mcg' && toUnit == 'mg') return value / 1000.0;
    if (fromUnit == 'g' && toUnit == 'mg') return value * 1000.0;
    if (fromUnit == 'mg' && toUnit == 'g') return value / 1000.0;
    if (fromUnit == 'g' && toUnit == 'mcg') return value * 1000000.0;
    if (fromUnit == 'mcg' && toUnit == 'g') return value / 1000000.0;
    
    // Volume conversions
    if (fromUnit == 'L' && toUnit == 'mL') return value * 1000.0;
    if (fromUnit == 'mL' && toUnit == 'L') return value / 1000.0;
    
    // No conversion available
    return value;
  }

  /// Get patch duration in days based on medication details
  static double _getPatchDurationDays(Medication medication) {
    // Parse duration from instructions or notes, default to 1 day
    if (medication.instructions != null) {
      final instructions = medication.instructions!.toLowerCase();
      if (instructions.contains('24 hour')) return 1.0;
      if (instructions.contains('3 day') || instructions.contains('72 hour')) return 3.0;
      if (instructions.contains('7 day') || instructions.contains('week')) return 7.0;
    }
    
    // Default assumption: most patches are daily
    return 1.0;
  }
}
