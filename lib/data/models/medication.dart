import 'package:flutter/foundation.dart';

@immutable
class Medication {
  final int? id;
  final String name;
  final String type;
  final double dosageAmount;
  final String dosageUnit;
  final String? frequency;
  final String? instructions;
  final String? barcode;
  final String? batchNumber;
  final DateTime? expiryDate;
  final String? notes;
  final String? photoPath;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Medication({
    this.id,
    required this.name,
    required this.type,
    required this.dosageAmount,
    required this.dosageUnit,
    this.frequency,
    this.instructions,
    this.barcode,
    this.batchNumber,
    this.expiryDate,
    this.notes,
    this.photoPath,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Medication.create({
    required String name,
    required String type,
    required double dosageAmount,
    required String dosageUnit,
    String? frequency,
    String? instructions,
    String? barcode,
    String? batchNumber,
    DateTime? expiryDate,
    String? notes,
    String? photoPath,
  }) {
    final now = DateTime.now();
    return Medication(
      name: name,
      type: type,
      dosageAmount: dosageAmount,
      dosageUnit: dosageUnit,
      frequency: frequency,
      instructions: instructions,
      barcode: barcode,
      batchNumber: batchNumber,
      expiryDate: expiryDate,
      notes: notes,
      photoPath: photoPath,
      createdAt: now,
      updatedAt: now,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'dosage_amount': dosageAmount,
      'dosage_unit': dosageUnit,
      'frequency': frequency,
      'instructions': instructions,
      'barcode': barcode,
      'batch_number': batchNumber,
      'expiry_date': expiryDate?.toIso8601String(),
      'notes': notes,
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
      type: map['type'] as String,
      dosageAmount: (map['dosage_amount'] as num).toDouble(),
      dosageUnit: map['dosage_unit'] as String,
      frequency: map['frequency'] as String?,
      instructions: map['instructions'] as String?,
      barcode: map['barcode'] as String?,
      batchNumber: map['batch_number'] as String?,
      expiryDate: map['expiry_date'] != null 
          ? DateTime.parse(map['expiry_date'] as String)
          : null,
      notes: map['notes'] as String?,
      photoPath: map['photo_path'] as String?,
      isActive: (map['is_active'] as int) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Medication copyWith({
    int? id,
    String? name,
    String? type,
    double? dosageAmount,
    String? dosageUnit,
    String? frequency,
    String? instructions,
    String? barcode,
    String? batchNumber,
    DateTime? expiryDate,
    String? notes,
    String? photoPath,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Medication(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      dosageAmount: dosageAmount ?? this.dosageAmount,
      dosageUnit: dosageUnit ?? this.dosageUnit,
      frequency: frequency ?? this.frequency,
      instructions: instructions ?? this.instructions,
      barcode: barcode ?? this.barcode,
      batchNumber: batchNumber ?? this.batchNumber,
      expiryDate: expiryDate ?? this.expiryDate,
      notes: notes ?? this.notes,
      photoPath: photoPath ?? this.photoPath,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Medication && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

// Medication types enum
enum MedicationType {
  tablet('Tablet'),
  capsule('Capsule'),
  liquid('Liquid'),
  injection('Injection'),
  peptide('Peptide'),
  powder('Powder'),
  cream('Cream'),
  patch('Patch'),
  inhaler('Inhaler'),
  drops('Drops'),
  other('Other');

  final String displayName;
  const MedicationType(this.displayName);

  static MedicationType fromString(String type) {
    return MedicationType.values.firstWhere(
      (e) => e.displayName.toLowerCase() == type.toLowerCase(),
      orElse: () => MedicationType.other,
    );
  }
}

// Dosage units enum
enum DosageUnit {
  mg('mg'),
  g('g'),
  mcg('mcg'),
  ml('ml'),
  l('l'),
  iu('IU'),
  units('units'),
  tablets('tablets'),
  capsules('capsules'),
  drops('drops'),
  puffs('puffs'),
  patches('patches');

  final String displayName;
  const DosageUnit(this.displayName);

  static DosageUnit fromString(String unit) {
    return DosageUnit.values.firstWhere(
      (e) => e.displayName.toLowerCase() == unit.toLowerCase(),
      orElse: () => DosageUnit.mg,
    );
  }
}
