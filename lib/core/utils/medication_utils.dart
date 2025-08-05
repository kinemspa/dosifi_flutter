import '../../data/models/medication.dart';

/// Utility functions for medication type-specific logic
class MedicationUtils {
  /// Get available strength units for a specific medication type
  static List<StrengthUnit> getAvailableStrengthUnits(MedicationType type) {
    switch (type) {
      case MedicationType.tablet:
      case MedicationType.capsule:
        return [StrengthUnit.mcg, StrengthUnit.mg];
      
      case MedicationType.preFilledSyringe:
      case MedicationType.readyMadeVial:
      case MedicationType.lyophilizedVial:
        return [StrengthUnit.mcg, StrengthUnit.mg, StrengthUnit.g, StrengthUnit.iu, StrengthUnit.units];
      
      case MedicationType.liquid:
      case MedicationType.drops:
        return [StrengthUnit.mg, StrengthUnit.mcg, StrengthUnit.g, StrengthUnit.ml, StrengthUnit.percent];
      
      case MedicationType.cream:
      case MedicationType.ointment:
        return [StrengthUnit.mg, StrengthUnit.mcg, StrengthUnit.g, StrengthUnit.percent];
      
      case MedicationType.patch:
        return [StrengthUnit.mg, StrengthUnit.mcg, StrengthUnit.iu];
      
      case MedicationType.inhaler:
        return [StrengthUnit.mcg, StrengthUnit.mg];
      
      case MedicationType.suppository:
        return [StrengthUnit.mg, StrengthUnit.mcg, StrengthUnit.g];
      
      case MedicationType.other:
        return StrengthUnit.values;
    }
  }

  /// Get the strength label for a specific medication type
  static String getStrengthLabel(MedicationType type) {
    switch (type) {
      case MedicationType.tablet:
        return 'Strength per Tablet';
      case MedicationType.capsule:
        return 'Strength per Capsule';
      case MedicationType.preFilledSyringe:
        return 'Strength per Syringe';
      case MedicationType.readyMadeVial:
      case MedicationType.lyophilizedVial:
        return 'Strength per Vial';
      case MedicationType.liquid:
        return 'Concentration';
      case MedicationType.cream:
      case MedicationType.ointment:
        return 'Strength per Gram';
      case MedicationType.drops:
        return 'Strength per Drop';
      case MedicationType.inhaler:
        return 'Strength per Dose';
      case MedicationType.patch:
        return 'Strength per Patch';
      case MedicationType.suppository:
        return 'Strength per Suppository';
      case MedicationType.other:
        return 'Strength per Unit';
    }
  }

  /// Get the inventory label for a specific medication type
  static String getInventoryLabel(MedicationType type) {
    switch (type) {
      case MedicationType.tablet:
        return 'Number of Tablets';
      case MedicationType.capsule:
        return 'Number of Capsules';
      case MedicationType.preFilledSyringe:
        return 'Number of Syringes';
      case MedicationType.readyMadeVial:
      case MedicationType.lyophilizedVial:
        return 'Liquid Volume per Vial (mL)';
      case MedicationType.liquid:
        return 'Total Volume (mL)';
      case MedicationType.cream:
      case MedicationType.ointment:
        return 'Volume/Weight (g or mL)';
      case MedicationType.drops:
        return 'Total Volume (mL)';
      case MedicationType.inhaler:
        return 'Number of Doses';
      case MedicationType.patch:
        return 'Number of Patches';
      case MedicationType.suppository:
        return 'Number of Suppositories';
      case MedicationType.other:
        return 'Number of Units';
    }
  }

  /// Check if a medication type requires reconstitution calculator
  static bool requiresReconstitution(MedicationType type) {
    return type == MedicationType.lyophilizedVial;
  }

  /// Get professional medication categories for better organization
  static Map<String, List<MedicationType>> getMedicationCategories() {
    return {
      'Oral Medications': [
        MedicationType.tablet,
        MedicationType.capsule,
        MedicationType.liquid,
      ],
      'Injectable Medications': [
        MedicationType.preFilledSyringe,
        MedicationType.readyMadeVial,
        MedicationType.lyophilizedVial,
      ],
      'Topical Medications': [
        MedicationType.cream,
        MedicationType.ointment,
        MedicationType.patch,
      ],
      'Other Forms': [
        MedicationType.drops,
        MedicationType.inhaler,
        MedicationType.suppository,
        MedicationType.other,
      ],
    };
  }

  /// Get common dosage forms for each type
  static List<String> getCommonDosageForms(MedicationType type) {
    switch (type) {
      case MedicationType.tablet:
        return ['Standard Tablet', 'Extended-Release', 'Chewable', 'Sublingual', 'Orally Disintegrating'];
      case MedicationType.capsule:
        return ['Hard Capsule', 'Soft Capsule', 'Extended-Release', 'Enteric-Coated'];
      case MedicationType.liquid:
        return ['Solution', 'Suspension', 'Syrup', 'Elixir'];
      case MedicationType.preFilledSyringe:
        return ['Auto-injector', 'Pre-filled Syringe', 'Pen Injector'];
      case MedicationType.readyMadeVial:
        return ['Single-dose Vial', 'Multi-dose Vial'];
      case MedicationType.lyophilizedVial:
        return ['Freeze-dried Powder', 'Lyophilized Cake'];
      case MedicationType.cream:
        return ['Topical Cream', 'Emulsion', 'Gel-Cream'];
      case MedicationType.ointment:
        return ['Petroleum Base', 'Water-washable', 'Absorption Base'];
      case MedicationType.drops:
        return ['Eye Drops', 'Ear Drops', 'Nasal Drops', 'Oral Drops'];
      case MedicationType.inhaler:
        return ['MDI', 'DPI', 'Nebulizer Solution'];
      case MedicationType.patch:
        return ['Transdermal Patch', 'Matrix Patch', 'Reservoir Patch'];
      case MedicationType.suppository:
        return ['Rectal', 'Vaginal'];
      case MedicationType.other:
        return ['Custom Form'];
    }
  }

  /// Validate strength value based on medication type
  static String? validateStrength(MedicationType type, double? strength, StrengthUnit unit) {
    if (strength == null || strength <= 0) {
      return 'Please enter a valid strength';
    }

    // Type-specific validations
    switch (type) {
      case MedicationType.tablet:
      case MedicationType.capsule:
        if (unit == StrengthUnit.mcg && strength > 10000) {
          return 'Strength seems too high for mcg unit';
        }
        if (unit == StrengthUnit.mg && strength > 1000) {
          return 'Strength seems too high for mg unit';
        }
        break;
      
      case MedicationType.liquid:
      case MedicationType.drops:
        if (unit == StrengthUnit.percent && strength > 100) {
          return 'Percentage cannot exceed 100%';
        }
        break;
      
      default:
        break;
    }

    return null;
  }

  /// Get default strength unit for a medication type
  static StrengthUnit getDefaultStrengthUnit(MedicationType type) {
    switch (type) {
      case MedicationType.tablet:
      case MedicationType.capsule:
      case MedicationType.preFilledSyringe:
      case MedicationType.readyMadeVial:
      case MedicationType.lyophilizedVial:
        return StrengthUnit.mg;
      
      case MedicationType.liquid:
      case MedicationType.drops:
        return StrengthUnit.mg;
      
      case MedicationType.cream:
      case MedicationType.ointment:
        return StrengthUnit.percent;
      
      case MedicationType.patch:
      case MedicationType.inhaler:
        return StrengthUnit.mcg;
      
      case MedicationType.suppository:
        return StrengthUnit.mg;
      
      case MedicationType.other:
        return StrengthUnit.mg;
    }
  }
}
