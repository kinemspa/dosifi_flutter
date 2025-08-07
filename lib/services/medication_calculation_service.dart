import '../data/models/medication.dart';

/// Service for advanced medication dosage calculations
class MedicationCalculationService {
  /// Comprehensive dose validation using medication type constraints
  static String? validateDoseAmount(Medication medication, double doseAmount, String doseUnit) {
    if (doseAmount <= 0) {
      return 'Dose amount must be greater than 0';
    }
    
    // Use the medication's comprehensive dose validation
    final validation = medication.validateDoseAmount(doseAmount);
    if (!validation.isValid) {
      return validation.message;
    }
    
    // Check if we have enough stock
    final deduction = calculateDoseDeduction(medication, doseAmount, doseUnit);
    if (deduction > medication.stockQuantity) {
      return 'Insufficient stock. Required: $deduction, Available: ${medication.stockQuantity}';
    }
    
    // Check for reasonable dose limits based on medication type
    if (doseUnit == 'tablet' || doseUnit == 'capsule') {
      if (doseAmount > 10) {
        return 'Dose amount seems unusually high for tablets/capsules';
      }
    }
    
    if (doseUnit == 'ml' || doseUnit == 'mL') {
      if (doseAmount > 100) {
        return 'Dose amount seems unusually high for liquid medication';
      }
    }
    
    return null; // Valid
  }

  /// Calculate the exact deduction amount from stock based on medication type and dose
  static double calculateDoseDeduction(dynamic medication, double doseAmount, String doseUnit) {
    // For liquid medications, deduction is direct (1:1 ratio)
    if (medication.type.toString().contains('liquid') || 
        medication.type.toString().contains('syringe') ||
        doseUnit == 'ml' || 
        doseUnit == 'mL') {
      return doseAmount;
    }
    
    // For tablets/capsules, deduction is direct count
    if (doseUnit == 'tablet' || doseUnit == 'capsule' || doseUnit == 'pill') {
      return doseAmount;
    }
    
    // For mg doses, convert based on strength per unit
    if (doseUnit == 'mg' && medication.strengthPerUnit > 0) {
      return doseAmount / medication.strengthPerUnit;
    }
    
    // For drops, apply conversion factor (typically 20 drops = 1ml)
    if (doseUnit == 'drop' || doseUnit == 'drops') {
      return doseAmount / 20.0; // Standard conversion
    }
    
    // For units (like insulin), direct deduction
    if (doseUnit == 'unit' || doseUnit == 'units' || doseUnit == 'IU') {
      return doseAmount;
    }
    
    // For patches, direct count
    if (doseUnit == 'patch') {
      return doseAmount;
    }
    
    // For inhalations/puffs from inhalers
    if (doseUnit == 'puff' || doseUnit == 'inhalation') {
      return doseAmount;
    }
    
    // Default: assume direct deduction
    return doseAmount;
  }
}
