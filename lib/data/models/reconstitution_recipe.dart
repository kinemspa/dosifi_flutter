import 'package:flutter/foundation.dart';

@immutable
class ReconstitutionRecipe {
  final int? id;
  final String name;
  final double powderAmount;
  final String powderUnit;
  final double solventVolume;
  final String solventUnit;
  final double finalConcentration;
  final String concentrationUnit;
  final String? instructions;
  final bool isFavorite;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ReconstitutionRecipe({
    this.id,
    required this.name,
    required this.powderAmount,
    required this.powderUnit,
    required this.solventVolume,
    required this.solventUnit,
    required this.finalConcentration,
    required this.concentrationUnit,
    this.instructions,
    this.isFavorite = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ReconstitutionRecipe.create({
    required String name,
    required double powderAmount,
    required String powderUnit,
    required double solventVolume,
    required String solventUnit,
    required double finalConcentration,
    required String concentrationUnit,
    String? instructions,
  }) {
    final now = DateTime.now();
    return ReconstitutionRecipe(
      name: name,
      powderAmount: powderAmount,
      powderUnit: powderUnit,
      solventVolume: solventVolume,
      solventUnit: solventUnit,
      finalConcentration: finalConcentration,
      concentrationUnit: concentrationUnit,
      instructions: instructions,
      createdAt: now,
      updatedAt: now,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'powder_amount': powderAmount,
      'powder_unit': powderUnit,
      'solvent_volume': solventVolume,
      'solvent_unit': solventUnit,
      'final_concentration': finalConcentration,
      'concentration_unit': concentrationUnit,
      'instructions': instructions,
      'is_favorite': isFavorite ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory ReconstitutionRecipe.fromMap(Map<String, dynamic> map) {
    return ReconstitutionRecipe(
      id: map['id'] as int?,
      name: map['name'] as String,
      powderAmount: (map['powder_amount'] as num).toDouble(),
      powderUnit: map['powder_unit'] as String,
      solventVolume: (map['solvent_volume'] as num).toDouble(),
      solventUnit: map['solvent_unit'] as String,
      finalConcentration: (map['final_concentration'] as num).toDouble(),
      concentrationUnit: map['concentration_unit'] as String,
      instructions: map['instructions'] as String?,
      isFavorite: (map['is_favorite'] as int) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  ReconstitutionRecipe copyWith({
    int? id,
    String? name,
    double? powderAmount,
    String? powderUnit,
    double? solventVolume,
    String? solventUnit,
    double? finalConcentration,
    String? concentrationUnit,
    String? instructions,
    bool? isFavorite,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ReconstitutionRecipe(
      id: id ?? this.id,
      name: name ?? this.name,
      powderAmount: powderAmount ?? this.powderAmount,
      powderUnit: powderUnit ?? this.powderUnit,
      solventVolume: solventVolume ?? this.solventVolume,
      solventUnit: solventUnit ?? this.solventUnit,
      finalConcentration: finalConcentration ?? this.finalConcentration,
      concentrationUnit: concentrationUnit ?? this.concentrationUnit,
      instructions: instructions ?? this.instructions,
      isFavorite: isFavorite ?? this.isFavorite,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  // Helper methods for reconstitution calculations
  
  // Calculate volume needed for a specific dose
  double calculateVolumeForDose(double desiredDose, String desiredDoseUnit) {
    // Convert units if necessary (simplified version)
    double convertedDose = desiredDose;
    if (desiredDoseUnit != concentrationUnit) {
      // Add unit conversion logic here
      // For now, assuming same units
    }
    
    return convertedDose / finalConcentration;
  }

  // Calculate dose from volume
  double calculateDoseFromVolume(double volume, String volumeUnit) {
    // Convert units if necessary
    double convertedVolume = volume;
    if (volumeUnit != solventUnit) {
      // Add unit conversion logic here
    }
    
    return convertedVolume * finalConcentration;
  }

  // Get concentration type (concentrated, standard, diluted)
  String get concentrationType {
    // These thresholds can be adjusted based on medication type
    if (finalConcentration >= 10) {
      return 'Concentrated';
    } else if (finalConcentration >= 1) {
      return 'Standard';
    } else {
      return 'Diluted';
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ReconstitutionRecipe && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

// Common concentration units
enum ConcentrationUnit {
  mgPerMl('mg/ml'),
  mcgPerMl('mcg/ml'),
  unitsPerMl('units/ml'),
  iuPerMl('IU/ml');

  final String displayName;
  const ConcentrationUnit(this.displayName);

  static ConcentrationUnit fromString(String unit) {
    return ConcentrationUnit.values.firstWhere(
      (e) => e.displayName.toLowerCase() == unit.toLowerCase(),
      orElse: () => ConcentrationUnit.mgPerMl,
    );
  }
}
