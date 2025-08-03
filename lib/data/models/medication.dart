import 'package:flutter/foundation.dart';

// Medication Types
enum MedicationType {
  tablet,
  capsule,
  liquid,
  injection,
  preFilledSyringe,
  readyMadeVial,
  lyophilizedVial,
  cream,
  ointment,
  drops,
  inhaler,
  patch,
  suppository,
  other;

  String get displayName {
    switch (this) {
      case MedicationType.tablet:
        return 'Tablet';
      case MedicationType.capsule:
        return 'Capsule';
      case MedicationType.liquid:
        return 'Liquid';
      case MedicationType.injection:
        return 'Injection';
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
  // Stock
  final int numberOfUnits;
  final String? lotBatchNumber;
  final DateTime? expirationDate;
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
    required this.numberOfUnits,
    this.lotBatchNumber,
    this.expirationDate,
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
    required int numberOfUnits,
    String? lotBatchNumber,
    DateTime? expirationDate,
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
      numberOfUnits: numberOfUnits,
      lotBatchNumber: lotBatchNumber,
      expirationDate: expirationDate,
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
      'number_of_units': numberOfUnits,
      'lot_batch_number': lotBatchNumber,
      'expiration_date': expirationDate?.toIso8601String(),
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
      numberOfUnits: map['number_of_units'] as int,
      lotBatchNumber: map['lot_batch_number'] as String?,
      expirationDate: map['expiration_date'] != null 
          ? DateTime.parse(map['expiration_date'] as String)
          : null,
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
    int? numberOfUnits,
    String? lotBatchNumber,
    DateTime? expirationDate,
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
      numberOfUnits: numberOfUnits ?? this.numberOfUnits,
      lotBatchNumber: lotBatchNumber ?? this.lotBatchNumber,
      expirationDate: expirationDate ?? this.expirationDate,
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
        return '$numberOfUnits tablets';
      case MedicationType.capsule:
        return '$numberOfUnits capsules';
      case MedicationType.preFilledSyringe:
      case MedicationType.injection:
        return '$numberOfUnits syringes';
      case MedicationType.readyMadeVial:
      case MedicationType.lyophilizedVial:
        return '$numberOfUnits vials';
      default:
        return '$numberOfUnits units';
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

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Medication && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
