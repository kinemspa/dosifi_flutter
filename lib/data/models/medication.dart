import 'package:flutter/foundation.dart';
import '../../core/services/database_service.dart';

// Medication Types
enum MedicationType {
  tablet,
  capsule,
  liquid,
  preFilledSyringe,
  readyMadeVial,
  lyophilizedVial,
  singleUsePen,
  multiUsePen,
  cream,
  ointment,
  drops,
  inhaler,
  patch,
  suppository,
  spray,
  gel,
  other;

  String get displayName {
    switch (this) {
      case MedicationType.tablet:
        return 'Tablet';
      case MedicationType.capsule:
        return 'Capsule';
      case MedicationType.liquid:
        return 'Liquid';
      case MedicationType.preFilledSyringe:
        return 'Pre-filled Syringe';
      case MedicationType.readyMadeVial:
        return 'Ready Made Vial';
      case MedicationType.lyophilizedVial:
        return 'Lyophilized Vial';
      case MedicationType.cream:
        return 'Cream';
      case MedicationType.ointment:
        return 'Ointment';
      case MedicationType.drops:
        return 'Drops';
      case MedicationType.inhaler:
        return 'Inhaler';
      case MedicationType.patch:
        return 'Patch';
      case MedicationType.suppository:
        return 'Suppository';
      case MedicationType.singleUsePen:
        return 'Single-Use Pen';
      case MedicationType.multiUsePen:
        return 'Multi-Use Pen';
      case MedicationType.spray:
        return 'Spray';
      case MedicationType.gel:
        return 'Gel';
      case MedicationType.other:
        return 'Other';
    }
  }

  static MedicationType fromString(String type) {
    return MedicationType.values.firstWhere(
      (e) => e.displayName.toLowerCase() == type.toLowerCase(),
      orElse: () => MedicationType.other,
    );
  }
}

// Strength Units
enum StrengthUnit {
  mg,
  mcg,
  g,
  ml,
  percent,
  iu,
  units; // For specific vials and others

  String get displayName {
    switch (this) {
      case StrengthUnit.mg:
        return 'mg';
      case StrengthUnit.mcg:
        return 'mcg';
      case StrengthUnit.g:
        return 'g';
      case StrengthUnit.ml:
        return 'ml';
      case StrengthUnit.percent:
        return '%';
      case StrengthUnit.iu:
        return 'IU';
      case StrengthUnit.units:
        return 'Units';
    }
  }

  static StrengthUnit fromString(String unit) {
    return StrengthUnit.values.firstWhere(
      (e) => e.displayName.toLowerCase() == unit.toLowerCase(),
      orElse: () => StrengthUnit.mg,
    );
  }
}

@immutable
class Medication {
  final int? id;
  final String name;
  final MedicationType type;
  final String? brandManufacturer;
  final double strengthPerUnit;
  final StrengthUnit strengthUnit;
  // Stock - for vials, this represents liquid volume per vial in mL
  // for tablets/capsules, this represents number of units
  final double stockQuantity;
  final StrengthUnit? stockUnit; // Unit for stock quantity (mL, IU, Units)
  final String? lotBatchNumber;
  final DateTime? expirationDate;
  
  // Alerts and Notifications
  final bool alertOnLowStock;
  final String? notificationSet;
  final double? lowStockThreshold; // Type-specific threshold
  
  // Storage Information
  final String? storageInstructions;
  final bool requiresRefrigeration;
  final String? storageTemperature; // Specific temperature requirements
  
  // Reconstitution Info (for lyophilized vials)
  final double? reconstitutionVolume; // mL of diluent added
  final double? finalConcentration; // units per mL after reconstitution
  final String? reconstitutionNotes;
  final String? reconstitutionFluid; // Supply item for reconstitution
  
  // Additional Info
  final String? description;
  final String? instructions;
  final String? notes;
  final String? barcode;
  final String? photoPath;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Medication({
    this.id,
    required this.name,
    required this.type,
    this.brandManufacturer,
    required this.strengthPerUnit,
    required this.strengthUnit,
    required this.stockQuantity,
    this.stockUnit,
    this.lotBatchNumber,
    this.expirationDate,
    this.alertOnLowStock = false,
    this.notificationSet,
    this.lowStockThreshold,
    this.storageInstructions,
    this.requiresRefrigeration = false,
    this.storageTemperature,
    this.reconstitutionVolume,
    this.finalConcentration,
    this.reconstitutionNotes,
    this.reconstitutionFluid,
    this.description,
    this.instructions,
    this.notes,
    this.barcode,
    this.photoPath,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Medication.create({
    required String name,
    required MedicationType type,
    String? brandManufacturer,
    required double strengthPerUnit,
    required StrengthUnit strengthUnit,
    required double stockQuantity,
    StrengthUnit? stockUnit,
    String? lotBatchNumber,
    DateTime? expirationDate,
    bool alertOnLowStock = false,
    String? notificationSet,
    String? storageInstructions,
    bool requiresRefrigeration = false,
    double? reconstitutionVolume,
    double? finalConcentration,
    String? reconstitutionNotes,
    String? reconstitutionFluid,
    String? description,
    String? instructions,
    String? notes,
    String? barcode,
    String? photoPath,
  }) {
    final now = DateTime.now();
    return Medication(
      name: name,
      type: type,
      brandManufacturer: brandManufacturer,
      strengthPerUnit: strengthPerUnit,
      strengthUnit: strengthUnit,
      stockQuantity: stockQuantity,
      stockUnit: stockUnit,
      lotBatchNumber: lotBatchNumber,
      expirationDate: expirationDate,
      alertOnLowStock: alertOnLowStock,
      notificationSet: notificationSet,
      storageInstructions: storageInstructions,
      requiresRefrigeration: requiresRefrigeration,
      reconstitutionVolume: reconstitutionVolume,
      finalConcentration: finalConcentration,
      reconstitutionNotes: reconstitutionNotes,
      reconstitutionFluid: reconstitutionFluid,
      description: description,
      instructions: instructions,
      notes: notes,
      barcode: barcode,
      photoPath: photoPath,
      createdAt: now,
      updatedAt: now,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type.displayName,
      'brand_manufacturer': brandManufacturer,
      'strength_per_unit': strengthPerUnit,
      'strength_unit': strengthUnit.displayName,
      'stock_quantity': stockQuantity,
      'lot_batch_number': lotBatchNumber,
      'expiration_date': expirationDate?.toIso8601String(),
      'reconstitution_volume': reconstitutionVolume,
      'final_concentration': finalConcentration,
      'reconstitution_notes': reconstitutionNotes,
      'description': description,
      'instructions': instructions,
      'notes': notes,
      'barcode': barcode,
      'photo_path': photoPath,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Medication.fromMap(Map<String, dynamic> map) {
    return Medication(
      id: map['id'] as int?,
      name: map['name'] as String,
      type: MedicationType.fromString(map['type'] as String),
      brandManufacturer: map['brand_manufacturer'] as String?,
      strengthPerUnit: (map['strength_per_unit'] as num).toDouble(),
      strengthUnit: StrengthUnit.fromString(map['strength_unit'] as String),
      stockQuantity: (map['stock_quantity'] ?? map['number_of_units'] ?? 0).toDouble(),
      lotBatchNumber: map['lot_batch_number'] as String?,
      expirationDate: map['expiration_date'] != null 
          ? DateTime.parse(map['expiration_date'] as String)
          : null,
      reconstitutionVolume: map['reconstitution_volume'] != null 
          ? (map['reconstitution_volume'] as num).toDouble() 
          : null,
      finalConcentration: map['final_concentration'] != null 
          ? (map['final_concentration'] as num).toDouble() 
          : null,
      reconstitutionNotes: map['reconstitution_notes'] as String?,
      description: map['description'] as String?,
      instructions: map['instructions'] as String?,
      notes: map['notes'] as String?,
      barcode: map['barcode'] as String?,
      photoPath: map['photo_path'] as String?,
      isActive: (map['is_active'] as int) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Medication copyWith({
    int? id,
    String? name,
    MedicationType? type,
    String? brandManufacturer,
    double? strengthPerUnit,
    StrengthUnit? strengthUnit,
    double? stockQuantity,
    String? lotBatchNumber,
    DateTime? expirationDate,
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
  }) {
    return Medication(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      brandManufacturer: brandManufacturer ?? this.brandManufacturer,
      strengthPerUnit: strengthPerUnit ?? this.strengthPerUnit,
      strengthUnit: strengthUnit ?? this.strengthUnit,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      lotBatchNumber: lotBatchNumber ?? this.lotBatchNumber,
      expirationDate: expirationDate ?? this.expirationDate,
      reconstitutionVolume: reconstitutionVolume ?? this.reconstitutionVolume,
      finalConcentration: finalConcentration ?? this.finalConcentration,
      reconstitutionNotes: reconstitutionNotes ?? this.reconstitutionNotes,
      description: description ?? this.description,
      instructions: instructions ?? this.instructions,
      notes: notes ?? this.notes,
      barcode: barcode ?? this.barcode,
      photoPath: photoPath ?? this.photoPath,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  // Helper getters
  String get displayStrength => '${strengthPerUnit.toStringAsFixed(strengthPerUnit.truncateToDouble() == strengthPerUnit ? 0 : 2)} ${strengthUnit.displayName}';
  
  String get stockDisplay {
    switch (type) {
      case MedicationType.tablet:
        return '${stockQuantity.toStringAsFixed(stockQuantity.truncateToDouble() == stockQuantity ? 0 : 1)} tablets';
      case MedicationType.capsule:
        return '${stockQuantity.toStringAsFixed(stockQuantity.truncateToDouble() == stockQuantity ? 0 : 1)} capsules';
      case MedicationType.preFilledSyringe:
        return '${stockQuantity.toStringAsFixed(stockQuantity.truncateToDouble() == stockQuantity ? 0 : 1)} syringes';
      case MedicationType.readyMadeVial:
      case MedicationType.lyophilizedVial:
        return '${stockQuantity.toStringAsFixed(1)} mL per vial';
      case MedicationType.liquid:
        return '${stockQuantity.toStringAsFixed(1)} mL';
      default:
        return '${stockQuantity.toStringAsFixed(stockQuantity.truncateToDouble() == stockQuantity ? 0 : 1)} units';
    }
  }

  bool get isExpired {
    if (expirationDate == null) return false;
    return DateTime.now().isAfter(expirationDate!);
  }

  bool get isExpiringSoon {
    if (expirationDate == null) return false;
    final daysUntilExpiration = expirationDate!.difference(DateTime.now()).inDays;
    return daysUntilExpiration <= 30 && daysUntilExpiration >= 0;
  }

  int? get daysUntilExpiration {
    if (expirationDate == null) return null;
    return expirationDate!.difference(DateTime.now()).inDays;
  }

  // Advanced type-specific calculations
  bool get isLowStock {
    final threshold = lowStockThreshold ?? _getDefaultLowStockThreshold();
    return stockQuantity <= threshold;
  }

  double _getDefaultLowStockThreshold() {
    switch (type) {
      case MedicationType.tablet:
      case MedicationType.capsule:
        return 7.0; // 7 tablets/capsules (week supply)
      case MedicationType.liquid:
      case MedicationType.drops:
        return 30.0; // 30 mL
      case MedicationType.preFilledSyringe:
        return 3.0; // 3 syringes
      case MedicationType.readyMadeVial:
        return 5.0; // 5 mL
      case MedicationType.lyophilizedVial:
        return 1.0; // 1 vial
      case MedicationType.singleUsePen:
        return 2.0; // 2 single-use pens
      case MedicationType.multiUsePen:
        return 1.0; // 1 multi-use pen
      case MedicationType.cream:
      case MedicationType.ointment:
      case MedicationType.gel:
        return 15.0; // 15 grams
      case MedicationType.patch:
        return 3.0; // 3 patches
      case MedicationType.inhaler:
        return 20.0; // 20 doses remaining
      case MedicationType.suppository:
        return 3.0; // 3 suppositories
      case MedicationType.spray:
        return 10.0; // 10 sprays remaining
      case MedicationType.other:
        return 5.0; // 5 units
    }
  }

  // Type-specific dose precision
  double get dosePrecision {
    switch (type) {
      case MedicationType.tablet:
        return 0.25; // Quarter tablet precision
      case MedicationType.capsule:
      case MedicationType.suppository:
      case MedicationType.patch:
      case MedicationType.inhaler:
      case MedicationType.singleUsePen:
      case MedicationType.multiUsePen:
      case MedicationType.spray:
        return 1.0; // Whole units only
      case MedicationType.liquid:
        return 0.1; // 0.1 mL precision
      case MedicationType.preFilledSyringe:
      case MedicationType.readyMadeVial:
      case MedicationType.lyophilizedVial:
        return 0.01; // 0.01 mL precision
      case MedicationType.cream:
      case MedicationType.ointment:
      case MedicationType.gel:
        return 0.5; // 0.5g precision for applications
      case MedicationType.drops:
        return 1.0; // Individual drop precision
      case MedicationType.other:
        return 1.0; // Default to whole units
    }
  }

  // Calculate volume needed for a given dose amount
  double calculateVolumeForDose(double doseAmount) {
    switch (type) {
      case MedicationType.liquid:
      case MedicationType.drops:
        // For liquids: volume = dose_amount / concentration
        if (strengthUnit == StrengthUnit.percent) {
          // Handle percentage concentrations
          final concentrationMgPerMl = strengthPerUnit * 10; // 1% = 10mg/mL
          return doseAmount / concentrationMgPerMl;
        }
        return doseAmount / strengthPerUnit;
      
      case MedicationType.preFilledSyringe:
      case MedicationType.readyMadeVial:
        // For injectables: volume = dose_units / concentration
        return doseAmount / strengthPerUnit;
      
      case MedicationType.lyophilizedVial:
        // For reconstituted vials: volume = dose_units / final_concentration
        if (finalConcentration != null && finalConcentration! > 0) {
          return doseAmount / finalConcentration!;
        }
        return 0.0;
      
      case MedicationType.tablet:
      case MedicationType.capsule:
        // For solid dosage forms: return number of units needed
        return doseAmount / strengthPerUnit;
      
      default:
        return doseAmount;
    }
  }

  // Get allowed dose units for this medication type
  List<String> get allowedDoseUnits {
    switch (type) {
      case MedicationType.tablet:
        return ['tablet', 'tablets', 'mg', 'mcg', 'g'];
      case MedicationType.capsule:
        return ['capsule', 'capsules', 'mg', 'mcg', 'g'];
      case MedicationType.liquid:
        return ['mL', 'L', 'tsp', 'tbsp', 'mg', 'mcg', 'g'];
      case MedicationType.preFilledSyringe:
      case MedicationType.readyMadeVial:
        return ['mL', 'Units', 'mg', 'mcg', 'IU'];
      case MedicationType.lyophilizedVial:
        return ['mL', 'Units', 'mg', 'mcg', 'IU'];
      case MedicationType.singleUsePen:
        return ['pen', 'units', 'mg', 'mcg', 'IU'];
      case MedicationType.multiUsePen:
        return ['doses', 'units', 'mg', 'mcg', 'IU'];
      case MedicationType.drops:
        return ['drops', 'mL', 'mg', 'mcg'];
      case MedicationType.cream:
      case MedicationType.ointment:
      case MedicationType.gel:
        return ['g', 'applications', 'mg', 'mcg'];
      case MedicationType.inhaler:
        return ['puffs', 'doses', 'mcg', 'mg'];
      case MedicationType.patch:
        return ['patches', 'mcg/hr', 'mg/hr'];
      case MedicationType.suppository:
        return ['suppository', 'suppositories', 'mg', 'mcg'];
      case MedicationType.spray:
        return ['sprays', 'doses', 'mg', 'mcg'];
      case MedicationType.other:
        return ['units', 'mg', 'mcg', 'g'];
    }
  }

  // Convert between common units for this medication type
  double convertDoseUnit(double amount, String fromUnit, String toUnit) {
    // Volume conversions
    if (fromUnit == 'tsp' && toUnit == 'mL') return amount * 5.0;
    if (fromUnit == 'mL' && toUnit == 'tsp') return amount / 5.0;
    if (fromUnit == 'tbsp' && toUnit == 'mL') return amount * 15.0;
    if (fromUnit == 'mL' && toUnit == 'tbsp') return amount / 15.0;
    if (fromUnit == 'L' && toUnit == 'mL') return amount * 1000.0;
    if (fromUnit == 'mL' && toUnit == 'L') return amount / 1000.0;
    
    // Weight conversions
    if (fromUnit == 'g' && toUnit == 'mg') return amount * 1000.0;
    if (fromUnit == 'mg' && toUnit == 'g') return amount / 1000.0;
    if (fromUnit == 'mg' && toUnit == 'mcg') return amount * 1000.0;
    if (fromUnit == 'mcg' && toUnit == 'mg') return amount / 1000.0;
    
    // Drop conversions (approximate)
    if (type == MedicationType.drops) {
      if (fromUnit == 'drops' && toUnit == 'mL') {
        return amount / 20.0; // Standard: ~20 drops = 1 mL
      }
      if (fromUnit == 'mL' && toUnit == 'drops') {
        return amount * 20.0;
      }
    }
    
    // No conversion needed or unsupported
    return amount;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Medication && other.id == id;
  }

  /// Comprehensive dose validation with type-specific constraints
  ValidationResult validateDoseAmount(double unitsPerDose) {
    switch (type) {
      case MedicationType.tablet:
      case MedicationType.capsule:
        // Allow full, half, or quarter units (n, n.5, n.25)
        final remainder = unitsPerDose % 0.25;
        if (remainder < 0.001) { // Allow for floating point precision
          return ValidationResult.valid();
        }
        return ValidationResult.invalid('${type.displayName} must be in increments of 0.25 (quarter units)');
        
      case MedicationType.preFilledSyringe:
      case MedicationType.singleUsePen:
      case MedicationType.patch:
      case MedicationType.suppository:
      case MedicationType.inhaler:
      case MedicationType.drops:
      case MedicationType.spray:
        // Must be whole numbers (integers)
        if (unitsPerDose == unitsPerDose.roundToDouble()) {
          return ValidationResult.valid();
        }
        return ValidationResult.invalid('${type.displayName} must use whole units only');
        
      case MedicationType.readyMadeVial:
      case MedicationType.lyophilizedVial:
      case MedicationType.liquid:
      case MedicationType.cream:
      case MedicationType.gel:
      case MedicationType.ointment:
        // Allow arbitrary decimals
        return ValidationResult.valid();
        
      case MedicationType.multiUsePen:
        // Must be integers (doses per cartridge)
        if (unitsPerDose == unitsPerDose.roundToDouble()) {
          return ValidationResult.valid();
        }
        return ValidationResult.invalid('Multi-use pen doses must be whole numbers');
        
      case MedicationType.other:
        // Default validation - allow arbitrary amounts
        return ValidationResult.valid();
    }
  }

  /// Convert strength per dose to units per dose
  double convertStrengthToUnits(String strengthPerDose) {
    final doseValue = _parseStrengthValue(strengthPerDose);
    
    if (doseValue == null || strengthPerUnit == 0) {
      return 0.0;
    }
    
    return doseValue / strengthPerUnit;
  }

  /// Convert units per dose to strength per dose
  String convertUnitsToStrength(double unitsPerDose) {
    if (strengthPerUnit == 0) {
      return '0${strengthUnit.displayName}';
    }
    
    final totalStrength = unitsPerDose * strengthPerUnit;
    
    return '${totalStrength.toStringAsFixed(totalStrength.truncateToDouble() == totalStrength ? 0 : 2)}${strengthUnit.displayName}';
  }

  /// Parse numeric value from strength string (e.g., "500mg" -> 500.0)
  static double? _parseStrengthValue(String strength) {
    final regex = RegExp(r'^([0-9]*\.?[0-9]+)');
    final match = regex.firstMatch(strength);
    if (match != null) {
      return double.tryParse(match.group(1)!);
    }
    return null;
  }

  /// Calculate days remaining given usage
  int calculateDaysRemaining(double unitsPerDose, double dosesPerDay) {
    if (unitsPerDose <= 0 || dosesPerDay <= 0) return 0;
    return (stockQuantity / (unitsPerDose * dosesPerDay)).floor();
  }

  /// Check if this medication is low on stock for given usage
  bool isLowStockForUsage(double unitsPerDose, double dosesPerDay) {
    final threshold = (lowStockThreshold ?? _getDefaultLowStockThreshold()) * unitsPerDose * dosesPerDay;
    return stockQuantity < threshold;
  }

  /// Update stock quantity and return new medication instance
  Medication updateStockQuantity(double changeAmount) {
    return copyWith(
      stockQuantity: stockQuantity + changeAmount,
      updatedAt: DateTime.now(),
    );
  }

  @override
  int get hashCode => id.hashCode;

  // Stock logging methods
  Future<void> logStockChange({
    required double changeAmount,
    required String reason,
    String? notes,
  }) async {
    if (id == null) {
      throw Exception('Cannot log stock change for unsaved medication');
    }
    
    final db = await DatabaseService.database;
    final now = DateTime.now().toIso8601String();
    
    await db.insert('medication_stock_logs', {
      'medication_id': id,
      'timestamp': now,
      'change_amount': changeAmount,
      'new_total': stockQuantity + changeAmount,
      'reason': reason,
      'notes': notes,
      'created_at': now,
    });
    
    // Update the stock quantity in the database
    await db.update(
      'medications',
      {
        'stock_quantity': stockQuantity + changeAmount,
        'updated_at': now,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }
  
  Future<List<StockLogEntry>> getStockHistory([int? limit]) async {
    if (id == null) return [];
    
    final db = await DatabaseService.database;
    
    final query = '''
      SELECT * FROM medication_stock_logs 
      WHERE medication_id = ?
      ORDER BY timestamp DESC
      ${limit != null ? 'LIMIT $limit' : ''}
    ''';
    
    final results = await db.rawQuery(query, [id]);
    return results.map((map) => StockLogEntry.fromMap(map)).toList();
  }
  
  Future<double> getStockChangesSince(DateTime since) async {
    if (id == null) return 0.0;
    
    final db = await DatabaseService.database;
    
    final results = await db.rawQuery('''
      SELECT SUM(change_amount) as total_change
      FROM medication_stock_logs
      WHERE medication_id = ? AND timestamp >= ?
    ''', [id, since.toIso8601String()]);
    
    return (results.first['total_change'] as double?) ?? 0.0;
  }
}

/// Validation result for dose constraints
class ValidationResult {
  final bool isValid;
  final String? message;

  const ValidationResult._(this.isValid, this.message);

  factory ValidationResult.valid() => const ValidationResult._(true, null);
  factory ValidationResult.invalid(String message) => ValidationResult._(false, message);

  @override
  String toString() => isValid ? 'Valid' : 'Invalid: $message';
}

/// Stock log entry for tracking medication stock changes
class StockLogEntry {
  final int id;
  final int medicationId;
  final DateTime timestamp;
  final double changeAmount;
  final double newTotal;
  final String reason;
  final String? notes;
  final DateTime createdAt;

  const StockLogEntry({
    required this.id,
    required this.medicationId,
    required this.timestamp,
    required this.changeAmount,
    required this.newTotal,
    required this.reason,
    this.notes,
    required this.createdAt,
  });

  factory StockLogEntry.fromMap(Map<String, dynamic> map) {
    return StockLogEntry(
      id: map['id'] as int,
      medicationId: map['medication_id'] as int,
      timestamp: DateTime.parse(map['timestamp'] as String),
      changeAmount: (map['change_amount'] as num).toDouble(),
      newTotal: (map['new_total'] as num).toDouble(),
      reason: map['reason'] as String,
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'medication_id': medicationId,
      'timestamp': timestamp.toIso8601String(),
      'change_amount': changeAmount,
      'new_total': newTotal,
      'reason': reason,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  bool get isAddition => changeAmount > 0;
  bool get isSubtraction => changeAmount < 0;
  
  String get displayAmount {
    final amount = changeAmount.abs();
    final sign = isAddition ? '+' : '-';
    return '$sign${amount.toStringAsFixed(amount.truncateToDouble() == amount ? 0 : 2)}';
  }

  String get displayTotal => newTotal.toStringAsFixed(newTotal.truncateToDouble() == newTotal ? 0 : 2);
}
