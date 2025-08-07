import 'package:flutter/foundation.dart';

/// Enumeration of all 15 supported medication types
enum MedicationType {
  tablet('Tablet'),
  capsule('Capsule'), 
  syringe('Pre-Filled Syringe'),
  vial('Ready-Made Vial'),
  lyophilizedVial('Lyophilized Vial'),
  singleUsePen('Single-Use Pen'),
  multiUsePen('Multi-Use Pen'),
  liquid('Liquid'),
  inhaler('Inhaler'),
  cream('Cream'),
  patch('Patch'),
  drop('Drop'),
  suppository('Suppository'),
  spray('Spray'),
  gel('Gel');

  const MedicationType(this.displayName);
  final String displayName;

  static MedicationType fromString(String type) {
    return MedicationType.values.firstWhere(
      (e) => e.displayName.toLowerCase() == type.toLowerCase(),
      orElse: () => MedicationType.tablet,
    );
  }
}

/// Common strength units for medications
enum StrengthUnit {
  mcg('mcg'),
  mg('mg'),
  g('g'),
  units('Units'),
  iu('IU'),
  ml('mL'),
  percent('%');

  const StrengthUnit(this.displayName);
  final String displayName;

  static StrengthUnit fromString(String unit) {
    return StrengthUnit.values.firstWhere(
      (e) => e.displayName.toLowerCase() == unit.toLowerCase(),
      orElse: () => StrengthUnit.mg,
    );
  }
}

/// Base abstract class for all medication stock types
abstract class MedicationStock {
  final String medName;
  final DateTime expiryDate;
  final String batchId;
  final int lowStockThreshold;
  final DateTime createdAt;
  final DateTime updatedAt;

  const MedicationStock({
    required this.medName,
    required this.expiryDate,
    required this.batchId,
    required this.lowStockThreshold,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Get the medication type for this stock
  MedicationType get medicationType;

  /// Get the total remaining units in stock
  double get totalRemainingUnits;

  /// Check if this medication is low on stock
  bool isLowStock(double unitsPerDose, double dosesPerDay) {
    final threshold = lowStockThreshold * unitsPerDose * dosesPerDay;
    return totalRemainingUnits < threshold;
  }

  /// Calculate days remaining given usage
  int calculateDaysRemaining(double unitsPerDose, double dosesPerDay) {
    if (unitsPerDose <= 0 || dosesPerDay <= 0) return 0;
    return (totalRemainingUnits / (unitsPerDose * dosesPerDay)).floor();
  }

  /// Check if medication is expired
  bool get isExpired => DateTime.now().isAfter(expiryDate);

  /// Check if medication is expiring soon (within 30 days)
  bool get isExpiringSoon {
    final daysUntilExpiry = expiryDate.difference(DateTime.now()).inDays;
    return daysUntilExpiry <= 30 && daysUntilExpiry >= 0;
  }

  /// Update stock quantity (positive for add, negative for consume)
  MedicationStock updateStock(double changeAmount);

  /// Convert to map for database storage
  Map<String, dynamic> toMap();

  /// Create from map for database retrieval
  static MedicationStock fromMap(Map<String, dynamic> map) {
    throw UnimplementedError('Subclasses must implement fromMap');
  }
}

/// Stock for tablet medications
@immutable
class TabletStock extends MedicationStock {
  final String strengthPerTablet;
  final double totalTablets;

  const TabletStock({
    required super.medName,
    required this.strengthPerTablet,
    required this.totalTablets,
    required super.expiryDate,
    required super.batchId,
    required super.lowStockThreshold,
    required super.createdAt,
    required super.updatedAt,
  });

  @override
  MedicationType get medicationType => MedicationType.tablet;

  @override
  double get totalRemainingUnits => totalTablets;

  @override
  TabletStock updateStock(double changeAmount) {
    return TabletStock(
      medName: medName,
      strengthPerTablet: strengthPerTablet,
      totalTablets: totalTablets + changeAmount,
      expiryDate: expiryDate,
      batchId: batchId,
      lowStockThreshold: lowStockThreshold,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'med_name': medName,
      'med_type': medicationType.displayName,
      'strength_per_tablet': strengthPerTablet,
      'total_tablets': totalTablets,
      'expiry_date': expiryDate.toIso8601String(),
      'batch_id': batchId,
      'low_stock_threshold': lowStockThreshold,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory TabletStock.fromMap(Map<String, dynamic> map) {
    return TabletStock(
      medName: map['med_name'] as String,
      strengthPerTablet: map['strength_per_tablet'] as String,
      totalTablets: (map['total_tablets'] as num).toDouble(),
      expiryDate: DateTime.parse(map['expiry_date'] as String),
      batchId: map['batch_id'] as String,
      lowStockThreshold: map['low_stock_threshold'] as int,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  TabletStock copyWith({
    String? medName,
    String? strengthPerTablet,
    double? totalTablets,
    DateTime? expiryDate,
    String? batchId,
    int? lowStockThreshold,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TabletStock(
      medName: medName ?? this.medName,
      strengthPerTablet: strengthPerTablet ?? this.strengthPerTablet,
      totalTablets: totalTablets ?? this.totalTablets,
      expiryDate: expiryDate ?? this.expiryDate,
      batchId: batchId ?? this.batchId,
      lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}

/// Stock for syringe medications
@immutable
class SyringeStock extends MedicationStock {
  final String strengthPerSyringe;
  final double totalSyringes;

  const SyringeStock({
    required super.medName,
    required this.strengthPerSyringe,
    required this.totalSyringes,
    required super.expiryDate,
    required super.batchId,
    required super.lowStockThreshold,
    required super.createdAt,
    required super.updatedAt,
  });

  @override
  MedicationType get medicationType => MedicationType.syringe;

  @override
  double get totalRemainingUnits => totalSyringes;

  @override
  SyringeStock updateStock(double changeAmount) {
    return SyringeStock(
      medName: medName,
      strengthPerSyringe: strengthPerSyringe,
      totalSyringes: totalSyringes + changeAmount,
      expiryDate: expiryDate,
      batchId: batchId,
      lowStockThreshold: lowStockThreshold,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'med_name': medName,
      'med_type': medicationType.displayName,
      'strength_per_syringe': strengthPerSyringe,
      'total_syringes': totalSyringes,
      'expiry_date': expiryDate.toIso8601String(),
      'batch_id': batchId,
      'low_stock_threshold': lowStockThreshold,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory SyringeStock.fromMap(Map<String, dynamic> map) {
    return SyringeStock(
      medName: map['med_name'] as String,
      strengthPerSyringe: map['strength_per_syringe'] as String,
      totalSyringes: (map['total_syringes'] as num).toDouble(),
      expiryDate: DateTime.parse(map['expiry_date'] as String),
      batchId: map['batch_id'] as String,
      lowStockThreshold: map['low_stock_threshold'] as int,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  SyringeStock copyWith({
    String? medName,
    String? strengthPerSyringe,
    double? totalSyringes,
    DateTime? expiryDate,
    String? batchId,
    int? lowStockThreshold,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SyringeStock(
      medName: medName ?? this.medName,
      strengthPerSyringe: strengthPerSyringe ?? this.strengthPerSyringe,
      totalSyringes: totalSyringes ?? this.totalSyringes,
      expiryDate: expiryDate ?? this.expiryDate,
      batchId: batchId ?? this.batchId,
      lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}

/// Stock for vial medications
@immutable
class VialStock extends MedicationStock {
  final String concentration;
  final double volumePerVialMl;
  final int totalVials;
  final double totalRemainingVolumeMl;

  const VialStock({
    required super.medName,
    required this.concentration,
    required this.volumePerVialMl,
    required this.totalVials,
    required this.totalRemainingVolumeMl,
    required super.expiryDate,
    required super.batchId,
    required super.lowStockThreshold,
    required super.createdAt,
    required super.updatedAt,
  });

  @override
  MedicationType get medicationType => MedicationType.vial;

  @override
  double get totalRemainingUnits => totalRemainingVolumeMl;

  @override
  VialStock updateStock(double changeAmount) {
    return VialStock(
      medName: medName,
      concentration: concentration,
      volumePerVialMl: volumePerVialMl,
      totalVials: totalVials,
      totalRemainingVolumeMl: totalRemainingVolumeMl + changeAmount,
      expiryDate: expiryDate,
      batchId: batchId,
      lowStockThreshold: lowStockThreshold,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'med_name': medName,
      'med_type': medicationType.displayName,
      'concentration': concentration,
      'volume_per_vial_ml': volumePerVialMl,
      'total_vials': totalVials,
      'total_remaining_volume_ml': totalRemainingVolumeMl,
      'expiry_date': expiryDate.toIso8601String(),
      'batch_id': batchId,
      'low_stock_threshold': lowStockThreshold,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory VialStock.fromMap(Map<String, dynamic> map) {
    return VialStock(
      medName: map['med_name'] as String,
      concentration: map['concentration'] as String,
      volumePerVialMl: (map['volume_per_vial_ml'] as num).toDouble(),
      totalVials: map['total_vials'] as int,
      totalRemainingVolumeMl: (map['total_remaining_volume_ml'] as num).toDouble(),
      expiryDate: DateTime.parse(map['expiry_date'] as String),
      batchId: map['batch_id'] as String,
      lowStockThreshold: map['low_stock_threshold'] as int,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  VialStock copyWith({
    String? medName,
    String? concentration,
    double? volumePerVialMl,
    int? totalVials,
    double? totalRemainingVolumeMl,
    DateTime? expiryDate,
    String? batchId,
    int? lowStockThreshold,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return VialStock(
      medName: medName ?? this.medName,
      concentration: concentration ?? this.concentration,
      volumePerVialMl: volumePerVialMl ?? this.volumePerVialMl,
      totalVials: totalVials ?? this.totalVials,
      totalRemainingVolumeMl: totalRemainingVolumeMl ?? this.totalRemainingVolumeMl,
      expiryDate: expiryDate ?? this.expiryDate,
      batchId: batchId ?? this.batchId,
      lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}

/// Stock for lyophilized vial medications
@immutable
class LyophilizedVialStock extends MedicationStock {
  final String powderStrengthPerVial;
  final double reconstitutionVolumeMl;
  final String concentrationAfterReconstitution;
  final int totalVials;
  final double reconstitutedVolumeRemainingMl;

  const LyophilizedVialStock({
    required super.medName,
    required this.powderStrengthPerVial,
    required this.reconstitutionVolumeMl,
    required this.concentrationAfterReconstitution,
    required this.totalVials,
    required this.reconstitutedVolumeRemainingMl,
    required super.expiryDate,
    required super.batchId,
    required super.lowStockThreshold,
    required super.createdAt,
    required super.updatedAt,
  });

  @override
  MedicationType get medicationType => MedicationType.lyophilizedVial;

  @override
  double get totalRemainingUnits => reconstitutedVolumeRemainingMl + (totalVials * reconstitutionVolumeMl);

  @override
  LyophilizedVialStock updateStock(double changeAmount) {
    return LyophilizedVialStock(
      medName: medName,
      powderStrengthPerVial: powderStrengthPerVial,
      reconstitutionVolumeMl: reconstitutionVolumeMl,
      concentrationAfterReconstitution: concentrationAfterReconstitution,
      totalVials: totalVials,
      reconstitutedVolumeRemainingMl: reconstitutedVolumeRemainingMl + changeAmount,
      expiryDate: expiryDate,
      batchId: batchId,
      lowStockThreshold: lowStockThreshold,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'med_name': medName,
      'med_type': medicationType.displayName,
      'powder_strength_per_vial': powderStrengthPerVial,
      'reconstitution_volume_ml': reconstitutionVolumeMl,
      'concentration_after_reconstitution': concentrationAfterReconstitution,
      'total_vials': totalVials,
      'reconstituted_volume_remaining_ml': reconstitutedVolumeRemainingMl,
      'expiry_date': expiryDate.toIso8601String(),
      'batch_id': batchId,
      'low_stock_threshold': lowStockThreshold,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory LyophilizedVialStock.fromMap(Map<String, dynamic> map) {
    return LyophilizedVialStock(
      medName: map['med_name'] as String,
      powderStrengthPerVial: map['powder_strength_per_vial'] as String,
      reconstitutionVolumeMl: (map['reconstitution_volume_ml'] as num).toDouble(),
      concentrationAfterReconstitution: map['concentration_after_reconstitution'] as String,
      totalVials: map['total_vials'] as int,
      reconstitutedVolumeRemainingMl: (map['reconstituted_volume_remaining_ml'] as num).toDouble(),
      expiryDate: DateTime.parse(map['expiry_date'] as String),
      batchId: map['batch_id'] as String,
      lowStockThreshold: map['low_stock_threshold'] as int,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  /// Reconstitute a vial (convert from unreconstituted to reconstituted)
  LyophilizedVialStock reconstitute() {
    if (totalVials <= 0) return this;
    
    return LyophilizedVialStock(
      medName: medName,
      powderStrengthPerVial: powderStrengthPerVial,
      reconstitutionVolumeMl: reconstitutionVolumeMl,
      concentrationAfterReconstitution: concentrationAfterReconstitution,
      totalVials: totalVials - 1,
      reconstitutedVolumeRemainingMl: reconstitutedVolumeRemainingMl + reconstitutionVolumeMl,
      expiryDate: expiryDate,
      batchId: batchId,
      lowStockThreshold: lowStockThreshold,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}

/// Stock for single-use pen medications
@immutable
class SingleUsePenStock extends MedicationStock {
  final String strengthPerPen;
  final int totalPens;

  const SingleUsePenStock({
    required super.medName,
    required this.strengthPerPen,
    required this.totalPens,
    required super.expiryDate,
    required super.batchId,
    required super.lowStockThreshold,
    required super.createdAt,
    required super.updatedAt,
  });

  @override
  MedicationType get medicationType => MedicationType.singleUsePen;

  @override
  double get totalRemainingUnits => totalPens.toDouble();

  @override
  SingleUsePenStock updateStock(double changeAmount) {
    return SingleUsePenStock(
      medName: medName,
      strengthPerPen: strengthPerPen,
      totalPens: (totalPens + changeAmount).round(),
      expiryDate: expiryDate,
      batchId: batchId,
      lowStockThreshold: lowStockThreshold,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'med_name': medName,
      'med_type': medicationType.displayName,
      'strength_per_pen': strengthPerPen,
      'total_pens': totalPens,
      'expiry_date': expiryDate.toIso8601String(),
      'batch_id': batchId,
      'low_stock_threshold': lowStockThreshold,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory SingleUsePenStock.fromMap(Map<String, dynamic> map) {
    return SingleUsePenStock(
      medName: map['med_name'] as String,
      strengthPerPen: map['strength_per_pen'] as String,
      totalPens: map['total_pens'] as int,
      expiryDate: DateTime.parse(map['expiry_date'] as String),
      batchId: map['batch_id'] as String,
      lowStockThreshold: map['low_stock_threshold'] as int,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }
}

/// Stock for multi-use pen medications
@immutable
class MultiUsePenStock extends MedicationStock {
  final String strengthPerCartridge;
  final int dosesPerCartridge;
  final int totalPens;
  final int totalCartridges;
  final int remainingDosesInCurrentCartridge;

  const MultiUsePenStock({
    required super.medName,
    required this.strengthPerCartridge,
    required this.dosesPerCartridge,
    required this.totalPens,
    required this.totalCartridges,
    required this.remainingDosesInCurrentCartridge,
    required super.expiryDate,
    required super.batchId,
    required super.lowStockThreshold,
    required super.createdAt,
    required super.updatedAt,
  });

  @override
  MedicationType get medicationType => MedicationType.multiUsePen;

  @override
  double get totalRemainingUnits => remainingDosesInCurrentCartridge + (totalCartridges * dosesPerCartridge).toDouble();

  @override
  MultiUsePenStock updateStock(double changeAmount) {
    int newRemaining = (remainingDosesInCurrentCartridge - changeAmount).round();
    int newCartridges = totalCartridges;
    
    // Handle cartridge replacement
    if (newRemaining <= 0 && newCartridges > 0) {
      newCartridges -= 1;
      newRemaining = dosesPerCartridge + newRemaining; // newRemaining is negative here
    }
    
    return MultiUsePenStock(
      medName: medName,
      strengthPerCartridge: strengthPerCartridge,
      dosesPerCartridge: dosesPerCartridge,
      totalPens: totalPens,
      totalCartridges: newCartridges,
      remainingDosesInCurrentCartridge: newRemaining,
      expiryDate: expiryDate,
      batchId: batchId,
      lowStockThreshold: lowStockThreshold,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'med_name': medName,
      'med_type': medicationType.displayName,
      'strength_per_cartridge': strengthPerCartridge,
      'doses_per_cartridge': dosesPerCartridge,
      'total_pens': totalPens,
      'total_cartridges': totalCartridges,
      'remaining_doses_in_current_cartridge': remainingDosesInCurrentCartridge,
      'expiry_date': expiryDate.toIso8601String(),
      'batch_id': batchId,
      'low_stock_threshold': lowStockThreshold,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory MultiUsePenStock.fromMap(Map<String, dynamic> map) {
    return MultiUsePenStock(
      medName: map['med_name'] as String,
      strengthPerCartridge: map['strength_per_cartridge'] as String,
      dosesPerCartridge: map['doses_per_cartridge'] as int,
      totalPens: map['total_pens'] as int,
      totalCartridges: map['total_cartridges'] as int,
      remainingDosesInCurrentCartridge: map['remaining_doses_in_current_cartridge'] as int,
      expiryDate: DateTime.parse(map['expiry_date'] as String),
      batchId: map['batch_id'] as String,
      lowStockThreshold: map['low_stock_threshold'] as int,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }
}

/// Stock for capsule medications (similar to tablets but distinct type)
@immutable
class CapsuleStock extends MedicationStock {
  final String strengthPerCapsule;
  final double totalCapsules;

  const CapsuleStock({
    required super.medName,
    required this.strengthPerCapsule,
    required this.totalCapsules,
    required super.expiryDate,
    required super.batchId,
    required super.lowStockThreshold,
    required super.createdAt,
    required super.updatedAt,
  });

  @override
  MedicationType get medicationType => MedicationType.capsule;

  @override
  double get totalRemainingUnits => totalCapsules;

  @override
  CapsuleStock updateStock(double changeAmount) {
    return CapsuleStock(
      medName: medName,
      strengthPerCapsule: strengthPerCapsule,
      totalCapsules: totalCapsules + changeAmount,
      expiryDate: expiryDate,
      batchId: batchId,
      lowStockThreshold: lowStockThreshold,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'med_name': medName,
      'med_type': medicationType.displayName,
      'strength_per_capsule': strengthPerCapsule,
      'total_capsules': totalCapsules,
      'expiry_date': expiryDate.toIso8601String(),
      'batch_id': batchId,
      'low_stock_threshold': lowStockThreshold,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory CapsuleStock.fromMap(Map<String, dynamic> map) {
    return CapsuleStock(
      medName: map['med_name'] as String,
      strengthPerCapsule: map['strength_per_capsule'] as String,
      totalCapsules: (map['total_capsules'] as num).toDouble(),
      expiryDate: DateTime.parse(map['expiry_date'] as String),
      batchId: map['batch_id'] as String,
      lowStockThreshold: map['low_stock_threshold'] as int,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }
}

/// Stock for liquid medications
@immutable
class LiquidStock extends MedicationStock {
  final String concentration;
  final double totalVolumeMl;

  const LiquidStock({
    required super.medName,
    required this.concentration,
    required this.totalVolumeMl,
    required super.expiryDate,
    required super.batchId,
    required super.lowStockThreshold,
    required super.createdAt,
    required super.updatedAt,
  });

  @override
  MedicationType get medicationType => MedicationType.liquid;

  @override
  double get totalRemainingUnits => totalVolumeMl;

  @override
  LiquidStock updateStock(double changeAmount) {
    return LiquidStock(
      medName: medName,
      concentration: concentration,
      totalVolumeMl: totalVolumeMl + changeAmount,
      expiryDate: expiryDate,
      batchId: batchId,
      lowStockThreshold: lowStockThreshold,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'med_name': medName,
      'med_type': medicationType.displayName,
      'concentration': concentration,
      'total_volume_ml': totalVolumeMl,
      'expiry_date': expiryDate.toIso8601String(),
      'batch_id': batchId,
      'low_stock_threshold': lowStockThreshold,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory LiquidStock.fromMap(Map<String, dynamic> map) {
    return LiquidStock(
      medName: map['med_name'] as String,
      concentration: map['concentration'] as String,
      totalVolumeMl: (map['total_volume_ml'] as num).toDouble(),
      expiryDate: DateTime.parse(map['expiry_date'] as String),
      batchId: map['batch_id'] as String,
      lowStockThreshold: map['low_stock_threshold'] as int,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }
}

/// Stock for inhaler medications
@immutable
class InhalerStock extends MedicationStock {
  final String strengthPerPuff;
  final int totalPuffsRemaining;

  const InhalerStock({
    required super.medName,
    required this.strengthPerPuff,
    required this.totalPuffsRemaining,
    required super.expiryDate,
    required super.batchId,
    required super.lowStockThreshold,
    required super.createdAt,
    required super.updatedAt,
  });

  @override
  MedicationType get medicationType => MedicationType.inhaler;

  @override
  double get totalRemainingUnits => totalPuffsRemaining.toDouble();

  @override
  InhalerStock updateStock(double changeAmount) {
    return InhalerStock(
      medName: medName,
      strengthPerPuff: strengthPerPuff,
      totalPuffsRemaining: (totalPuffsRemaining - changeAmount).round(),
      expiryDate: expiryDate,
      batchId: batchId,
      lowStockThreshold: lowStockThreshold,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'med_name': medName,
      'med_type': medicationType.displayName,
      'strength_per_puff': strengthPerPuff,
      'total_puffs_remaining': totalPuffsRemaining,
      'expiry_date': expiryDate.toIso8601String(),
      'batch_id': batchId,
      'low_stock_threshold': lowStockThreshold,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory InhalerStock.fromMap(Map<String, dynamic> map) {
    return InhalerStock(
      medName: map['med_name'] as String,
      strengthPerPuff: map['strength_per_puff'] as String,
      totalPuffsRemaining: map['total_puffs_remaining'] as int,
      expiryDate: DateTime.parse(map['expiry_date'] as String),
      batchId: map['batch_id'] as String,
      lowStockThreshold: map['low_stock_threshold'] as int,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }
}

/// Stock for cream medications
@immutable
class CreamStock extends MedicationStock {
  final String concentration;
  final double totalGramsRemaining;

  const CreamStock({
    required super.medName,
    required this.concentration,
    required this.totalGramsRemaining,
    required super.expiryDate,
    required super.batchId,
    required super.lowStockThreshold,
    required super.createdAt,
    required super.updatedAt,
  });

  @override
  MedicationType get medicationType => MedicationType.cream;

  @override
  double get totalRemainingUnits => totalGramsRemaining;

  @override
  CreamStock updateStock(double changeAmount) {
    return CreamStock(
      medName: medName,
      concentration: concentration,
      totalGramsRemaining: totalGramsRemaining + changeAmount,
      expiryDate: expiryDate,
      batchId: batchId,
      lowStockThreshold: lowStockThreshold,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'med_name': medName,
      'med_type': medicationType.displayName,
      'concentration': concentration,
      'total_grams_remaining': totalGramsRemaining,
      'expiry_date': expiryDate.toIso8601String(),
      'batch_id': batchId,
      'low_stock_threshold': lowStockThreshold,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory CreamStock.fromMap(Map<String, dynamic> map) {
    return CreamStock(
      medName: map['med_name'] as String,
      concentration: map['concentration'] as String,
      totalGramsRemaining: (map['total_grams_remaining'] as num).toDouble(),
      expiryDate: DateTime.parse(map['expiry_date'] as String),
      batchId: map['batch_id'] as String,
      lowStockThreshold: map['low_stock_threshold'] as int,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }
}

/// Stock for patch medications
@immutable
class PatchStock extends MedicationStock {
  final String strengthPerPatch;
  final int totalPatches;

  const PatchStock({
    required super.medName,
    required this.strengthPerPatch,
    required this.totalPatches,
    required super.expiryDate,
    required super.batchId,
    required super.lowStockThreshold,
    required super.createdAt,
    required super.updatedAt,
  });

  @override
  MedicationType get medicationType => MedicationType.patch;

  @override
  double get totalRemainingUnits => totalPatches.toDouble();

  @override
  PatchStock updateStock(double changeAmount) {
    return PatchStock(
      medName: medName,
      strengthPerPatch: strengthPerPatch,
      totalPatches: (totalPatches + changeAmount).round(),
      expiryDate: expiryDate,
      batchId: batchId,
      lowStockThreshold: lowStockThreshold,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'med_name': medName,
      'med_type': medicationType.displayName,
      'strength_per_patch': strengthPerPatch,
      'total_patches': totalPatches,
      'expiry_date': expiryDate.toIso8601String(),
      'batch_id': batchId,
      'low_stock_threshold': lowStockThreshold,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory PatchStock.fromMap(Map<String, dynamic> map) {
    return PatchStock(
      medName: map['med_name'] as String,
      strengthPerPatch: map['strength_per_patch'] as String,
      totalPatches: map['total_patches'] as int,
      expiryDate: DateTime.parse(map['expiry_date'] as String),
      batchId: map['batch_id'] as String,
      lowStockThreshold: map['low_stock_threshold'] as int,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }
}

/// Stock for drop medications
@immutable
class DropStock extends MedicationStock {
  final String concentration;
  final int totalDropsRemaining;

  const DropStock({
    required super.medName,
    required this.concentration,
    required this.totalDropsRemaining,
    required super.expiryDate,
    required super.batchId,
    required super.lowStockThreshold,
    required super.createdAt,
    required super.updatedAt,
  });

  @override
  MedicationType get medicationType => MedicationType.drop;

  @override
  double get totalRemainingUnits => totalDropsRemaining.toDouble();

  @override
  DropStock updateStock(double changeAmount) {
    return DropStock(
      medName: medName,
      concentration: concentration,
      totalDropsRemaining: (totalDropsRemaining - changeAmount).round(),
      expiryDate: expiryDate,
      batchId: batchId,
      lowStockThreshold: lowStockThreshold,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'med_name': medName,
      'med_type': medicationType.displayName,
      'concentration': concentration,
      'total_drops_remaining': totalDropsRemaining,
      'expiry_date': expiryDate.toIso8601String(),
      'batch_id': batchId,
      'low_stock_threshold': lowStockThreshold,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory DropStock.fromMap(Map<String, dynamic> map) {
    return DropStock(
      medName: map['med_name'] as String,
      concentration: map['concentration'] as String,
      totalDropsRemaining: map['total_drops_remaining'] as int,
      expiryDate: DateTime.parse(map['expiry_date'] as String),
      batchId: map['batch_id'] as String,
      lowStockThreshold: map['low_stock_threshold'] as int,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }
}

/// Stock for suppository medications
@immutable
class SuppositoryStock extends MedicationStock {
  final String strengthPerSuppository;
  final int totalSuppositories;

  const SuppositoryStock({
    required super.medName,
    required this.strengthPerSuppository,
    required this.totalSuppositories,
    required super.expiryDate,
    required super.batchId,
    required super.lowStockThreshold,
    required super.createdAt,
    required super.updatedAt,
  });

  @override
  MedicationType get medicationType => MedicationType.suppository;

  @override
  double get totalRemainingUnits => totalSuppositories.toDouble();

  @override
  SuppositoryStock updateStock(double changeAmount) {
    return SuppositoryStock(
      medName: medName,
      strengthPerSuppository: strengthPerSuppository,
      totalSuppositories: (totalSuppositories + changeAmount).round(),
      expiryDate: expiryDate,
      batchId: batchId,
      lowStockThreshold: lowStockThreshold,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'med_name': medName,
      'med_type': medicationType.displayName,
      'strength_per_suppository': strengthPerSuppository,
      'total_suppositories': totalSuppositories,
      'expiry_date': expiryDate.toIso8601String(),
      'batch_id': batchId,
      'low_stock_threshold': lowStockThreshold,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory SuppositoryStock.fromMap(Map<String, dynamic> map) {
    return SuppositoryStock(
      medName: map['med_name'] as String,
      strengthPerSuppository: map['strength_per_suppository'] as String,
      totalSuppositories: map['total_suppositories'] as int,
      expiryDate: DateTime.parse(map['expiry_date'] as String),
      batchId: map['batch_id'] as String,
      lowStockThreshold: map['low_stock_threshold'] as int,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }
}

/// Stock for spray medications
@immutable
class SprayStock extends MedicationStock {
  final String strengthPerSpray;
  final int totalSpraysRemaining;

  const SprayStock({
    required super.medName,
    required this.strengthPerSpray,
    required this.totalSpraysRemaining,
    required super.expiryDate,
    required super.batchId,
    required super.lowStockThreshold,
    required super.createdAt,
    required super.updatedAt,
  });

  @override
  MedicationType get medicationType => MedicationType.spray;

  @override
  double get totalRemainingUnits => totalSpraysRemaining.toDouble();

  @override
  SprayStock updateStock(double changeAmount) {
    return SprayStock(
      medName: medName,
      strengthPerSpray: strengthPerSpray,
      totalSpraysRemaining: (totalSpraysRemaining - changeAmount).round(),
      expiryDate: expiryDate,
      batchId: batchId,
      lowStockThreshold: lowStockThreshold,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'med_name': medName,
      'med_type': medicationType.displayName,
      'strength_per_spray': strengthPerSpray,
      'total_sprays_remaining': totalSpraysRemaining,
      'expiry_date': expiryDate.toIso8601String(),
      'batch_id': batchId,
      'low_stock_threshold': lowStockThreshold,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory SprayStock.fromMap(Map<String, dynamic> map) {
    return SprayStock(
      medName: map['med_name'] as String,
      strengthPerSpray: map['strength_per_spray'] as String,
      totalSpraysRemaining: map['total_sprays_remaining'] as int,
      expiryDate: DateTime.parse(map['expiry_date'] as String),
      batchId: map['batch_id'] as String,
      lowStockThreshold: map['low_stock_threshold'] as int,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }
}

/// Stock for gel medications
@immutable
class GelStock extends MedicationStock {
  final String concentration;
  final double totalGramsRemaining;

  const GelStock({
    required super.medName,
    required this.concentration,
    required this.totalGramsRemaining,
    required super.expiryDate,
    required super.batchId,
    required super.lowStockThreshold,
    required super.createdAt,
    required super.updatedAt,
  });

  @override
  MedicationType get medicationType => MedicationType.gel;

  @override
  double get totalRemainingUnits => totalGramsRemaining;

  @override
  GelStock updateStock(double changeAmount) {
    return GelStock(
      medName: medName,
      concentration: concentration,
      totalGramsRemaining: totalGramsRemaining + changeAmount,
      expiryDate: expiryDate,
      batchId: batchId,
      lowStockThreshold: lowStockThreshold,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'med_name': medName,
      'med_type': medicationType.displayName,
      'concentration': concentration,
      'total_grams_remaining': totalGramsRemaining,
      'expiry_date': expiryDate.toIso8601String(),
      'batch_id': batchId,
      'low_stock_threshold': lowStockThreshold,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory GelStock.fromMap(Map<String, dynamic> map) {
    return GelStock(
      medName: map['med_name'] as String,
      concentration: map['concentration'] as String,
      totalGramsRemaining: (map['total_grams_remaining'] as num).toDouble(),
      expiryDate: DateTime.parse(map['expiry_date'] as String),
      batchId: map['batch_id'] as String,
      lowStockThreshold: map['low_stock_threshold'] as int,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }
}
