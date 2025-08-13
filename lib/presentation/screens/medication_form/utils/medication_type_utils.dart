import 'package:flutter/material.dart';
import 'package:dosifi_flutter/data/models/medication.dart';

class MedicationTypeUtils {
  // Get color for medication type
  static Color getMedicationTypeColor(MedicationType type) {
    switch (type) {
      case MedicationType.tablet:
        return Colors.blue;
      case MedicationType.capsule:
        return Colors.green;
      case MedicationType.liquid:
        return Colors.cyan;
      case MedicationType.preFilledSyringe:
      case MedicationType.readyMadeVial:
        return Colors.purple;
      case MedicationType.lyophilizedVial:
        return Colors.indigo;
      case MedicationType.cream:
      case MedicationType.ointment:
        return Colors.orange;
      case MedicationType.drops:
        return Colors.lightBlue;
      case MedicationType.inhaler:
        return Colors.teal;
      case MedicationType.patch:
        return Colors.amber;
      case MedicationType.suppository:
        return Colors.pink;
      case MedicationType.singleUsePen:
      case MedicationType.multiUsePen:
        return Colors.deepPurple;
      case MedicationType.spray:
        return Colors.lime;
      case MedicationType.gel:
        return Colors.tealAccent;
      case MedicationType.other:
        return Colors.grey;
    }
  }

  // Get icon for medication type
  static IconData getMedicationTypeIcon(MedicationType type) {
    switch (type) {
      case MedicationType.tablet:
      case MedicationType.capsule:
        return Icons.medication;
      case MedicationType.liquid:
      case MedicationType.drops:
        return Icons.water_drop;
      case MedicationType.preFilledSyringe:
      case MedicationType.readyMadeVial:
      case MedicationType.lyophilizedVial:
      case MedicationType.singleUsePen:
      case MedicationType.multiUsePen:
        return Icons.vaccines;
      case MedicationType.cream:
      case MedicationType.ointment:
      case MedicationType.gel:
        return Icons.healing;
      case MedicationType.inhaler:
      case MedicationType.spray:
        return Icons.air;
      case MedicationType.patch:
        return Icons.medical_services;
      case MedicationType.suppository:
        return Icons.medication_liquid;
      case MedicationType.other:
        return Icons.medical_information;
    }
  }

  // Get default strength unit for medication type
  static StrengthUnit getDefaultStrengthUnit(MedicationType type) {
    switch (type) {
      case MedicationType.tablet:
      case MedicationType.capsule:
        return StrengthUnit.mg;
      case MedicationType.liquid:
      case MedicationType.drops:
      case MedicationType.preFilledSyringe:
      case MedicationType.readyMadeVial:
      case MedicationType.lyophilizedVial:
      case MedicationType.singleUsePen:
      case MedicationType.multiUsePen:
        return StrengthUnit.mg; // Will use concentration per volume
      case MedicationType.cream:
      case MedicationType.ointment:
      case MedicationType.gel:
        return StrengthUnit.percent;
      case MedicationType.inhaler:
      case MedicationType.spray:
        return StrengthUnit.mcg;
      case MedicationType.patch:
        return StrengthUnit.mg;
      case MedicationType.suppository:
        return StrengthUnit.mg;
      case MedicationType.other:
        return StrengthUnit.mg;
    }
  }

  // Get available strength units for medication type
  static List<StrengthUnit> getAvailableStrengthUnits(MedicationType? type) {
    if (type == null) return StrengthUnit.values;

    switch (type) {
      case MedicationType.tablet:
      case MedicationType.capsule:
        return [StrengthUnit.mg, StrengthUnit.mcg, StrengthUnit.g];
      case MedicationType.liquid:
      case MedicationType.drops:
        return [StrengthUnit.mg, StrengthUnit.mcg, StrengthUnit.percent];
      case MedicationType.preFilledSyringe:
        return [StrengthUnit.mg, StrengthUnit.mcg, StrengthUnit.percent, StrengthUnit.iu, StrengthUnit.units];
      case MedicationType.readyMadeVial:
      case MedicationType.lyophilizedVial:
      case MedicationType.singleUsePen:
      case MedicationType.multiUsePen:
        return [StrengthUnit.mg, StrengthUnit.mcg, StrengthUnit.percent, StrengthUnit.iu];
      case MedicationType.cream:
      case MedicationType.ointment:
      case MedicationType.gel:
        return [StrengthUnit.percent, StrengthUnit.mg];
      case MedicationType.inhaler:
      case MedicationType.spray:
        return [StrengthUnit.mcg, StrengthUnit.mg];
      case MedicationType.patch:
        return [StrengthUnit.mg, StrengthUnit.mcg];
      case MedicationType.suppository:
        return [StrengthUnit.mg, StrengthUnit.mcg];
      case MedicationType.other:
        return StrengthUnit.values;
    }
  }

  // Get stock unit label for medication type (display-only default)
  static String getStockUnit(MedicationType type) {
    switch (type) {
      case MedicationType.tablet:
        return 'tablets';
      case MedicationType.capsule:
        return 'capsules';
      case MedicationType.liquid:
      case MedicationType.drops:
        return 'mL';
      case MedicationType.preFilledSyringe:
      case MedicationType.readyMadeVial:
      case MedicationType.lyophilizedVial:
        return 'mL';
      case MedicationType.cream:
      case MedicationType.ointment:
      case MedicationType.gel:
        return 'g';
      case MedicationType.inhaler:
      case MedicationType.spray:
        return 'doses';
      case MedicationType.patch:
        return 'patches';
      case MedicationType.suppository:
        return 'pieces';
      case MedicationType.singleUsePen:
      case MedicationType.multiUsePen:
        return 'pens';
      case MedicationType.other:
        return 'units';
    }
  }

  // Options for selecting stock unit per type (controls persistence for applicable cases)
  static List<String> getStockUnitOptions(MedicationType? type) {
    if (type == null) return const ['units'];
    switch (type) {
      case MedicationType.liquid:
      case MedicationType.drops:
        return const ['mL'];
      case MedicationType.preFilledSyringe:
      case MedicationType.readyMadeVial:
      case MedicationType.lyophilizedVial:
        // For injectables we may track in mL or Units/IU after reconstitution
        return const ['mL', 'Units', 'IU'];
      case MedicationType.cream:
      case MedicationType.ointment:
      case MedicationType.gel:
        return const ['g', 'mL'];
      case MedicationType.inhaler:
      case MedicationType.spray:
        return const ['doses'];
      case MedicationType.patch:
        return const ['patches'];
      case MedicationType.tablet:
        return const ['tablets'];
      case MedicationType.capsule:
        return const ['capsules'];
      case MedicationType.suppository:
        return const ['pieces'];
      case MedicationType.singleUsePen:
      case MedicationType.multiUsePen:
        return const ['pens'];
      case MedicationType.other:
        return const ['units'];
    }
  }

  // Get stock label for medication type
  static String getStockLabel(MedicationType? type) {
    if (type == null) return 'Stock Quantity';

    switch (type) {
      case MedicationType.tablet:
        return 'Number of Tablets';
      case MedicationType.capsule:
        return 'Number of Capsules';
      case MedicationType.liquid:
      case MedicationType.drops:
        return 'Volume in Stock';
      case MedicationType.preFilledSyringe:
      case MedicationType.readyMadeVial:
      case MedicationType.lyophilizedVial:
        return 'Number of Vials';
      case MedicationType.cream:
      case MedicationType.ointment:
      case MedicationType.gel:
        return 'Weight in Stock';
      case MedicationType.inhaler:
      case MedicationType.spray:
        return 'Number of Devices';
      case MedicationType.patch:
        return 'Number of Patches';
      case MedicationType.singleUsePen:
      case MedicationType.multiUsePen:
        return 'Number of Pens';
      case MedicationType.suppository:
        return 'Number of Pieces';
      case MedicationType.other:
        return 'Stock Quantity';
    }
  }

  // Get stock hint text for medication type
  static String getStockHint(MedicationType? type) {
    if (type == null) return '';

    switch (type) {
      case MedicationType.tablet:
      case MedicationType.capsule:
        return 'e.g., 30';
      case MedicationType.liquid:
      case MedicationType.drops:
        return 'e.g., 100.0';
      case MedicationType.preFilledSyringe:
      case MedicationType.readyMadeVial:
      case MedicationType.lyophilizedVial:
      case MedicationType.singleUsePen:
      case MedicationType.multiUsePen:
        return 'e.g., 1';
      case MedicationType.cream:
      case MedicationType.ointment:
      case MedicationType.gel:
        return 'e.g., 30.0';
      default:
        return '';
    }
  }

  // Shorter hints for tight layouts
  static String getStockHintShort(MedicationType? type) {
    if (type == null) return '';
    switch (type) {
      case MedicationType.tablet:
      case MedicationType.capsule:
        return 'e.g., 30';
      case MedicationType.liquid:
      case MedicationType.drops:
        return 'e.g., 100';
      case MedicationType.preFilledSyringe:
      case MedicationType.readyMadeVial:
      case MedicationType.lyophilizedVial:
      case MedicationType.singleUsePen:
      case MedicationType.multiUsePen:
        return 'e.g., 1';
      case MedicationType.cream:
      case MedicationType.ointment:
      case MedicationType.gel:
        return 'e.g., 30';
      default:
        return '';
    }
  }

  // Get stock helper text for medication type
  static String getStockHelperText(MedicationType? type) {
    if (type == null) return '';

    switch (type) {
      case MedicationType.tablet:
      case MedicationType.capsule:
        return 'Enter the total number of individual ${type.displayName.toLowerCase()}s you have';
      case MedicationType.liquid:
      case MedicationType.drops:
        return 'Enter the total volume in milliliters (mL)';
      case MedicationType.preFilledSyringe:
      case MedicationType.readyMadeVial:
      case MedicationType.lyophilizedVial:
        return 'Enter the number of vials/syringes, not the total volume';
      case MedicationType.cream:
      case MedicationType.ointment:
      case MedicationType.gel:
        return 'Enter the total weight in grams';
      case MedicationType.inhaler:
      case MedicationType.spray:
        return 'Enter the number of inhaler devices';
      case MedicationType.patch:
        return 'Enter the number of individual patches';
      case MedicationType.singleUsePen:
      case MedicationType.multiUsePen:
        return 'Enter the number of pen devices';
      case MedicationType.suppository:
        return 'Enter the number of individual pieces';
      case MedicationType.other:
        return 'Enter the quantity in stock';
    }
  }

  // Check if stock should be integer for medication type
  static bool isStockInteger(MedicationType? type) {
    if (type == null) return false;

    switch (type) {
      case MedicationType.tablet:
      case MedicationType.capsule:
      case MedicationType.preFilledSyringe:
      case MedicationType.readyMadeVial:
      case MedicationType.lyophilizedVial:
      case MedicationType.inhaler:
      case MedicationType.patch:
      case MedicationType.suppository:
      case MedicationType.singleUsePen:
      case MedicationType.multiUsePen:
      case MedicationType.spray:
        return true;
      case MedicationType.liquid:
      case MedicationType.drops:
      case MedicationType.cream:
      case MedicationType.ointment:
      case MedicationType.gel:
      case MedicationType.other:
        return false;
    }
  }
}
