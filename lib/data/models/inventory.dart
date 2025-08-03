import 'package:flutter/foundation.dart';

@immutable
class Inventory {
  final int? id;
  final int medicationId;
  final double quantity;
  final String unit;
  final double? reorderLevel;
  final String? batchNumber;
  final DateTime? expiryDate;
  final String? location;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Inventory({
    this.id,
    required this.medicationId,
    required this.quantity,
    required this.unit,
    this.reorderLevel,
    this.batchNumber,
    this.expiryDate,
    this.location,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  factory Inventory.create({
    required int medicationId,
    required double quantity,
    required String unit,
    double? reorderLevel,
    String? batchNumber,
    DateTime? expiryDate,
    String? location,
    String? notes,
  }) {
    return Inventory(
      medicationId: medicationId,
      quantity: quantity,
      unit: unit,
      reorderLevel: reorderLevel,
      batchNumber: batchNumber,
      expiryDate: expiryDate,
      location: location,
      notes: notes,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'medication_id': medicationId,
      'quantity': quantity,
      'unit': unit,
      'reorder_level': reorderLevel,
      'batch_number': batchNumber,
      'expiry_date': expiryDate?.toIso8601String(),
      'location': location,
      'notes': notes,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory Inventory.fromMap(Map<String, dynamic> map) {
    return Inventory(
      id: map['id'] as int?,
      medicationId: map['medication_id'] as int,
      quantity: (map['quantity'] as num).toDouble(),
      unit: map['unit'] as String,
      reorderLevel: map['reorder_level'] != null 
          ? (map['reorder_level'] as num).toDouble()
          : null,
      batchNumber: map['batch_number'] as String?,
      expiryDate: map['expiry_date'] != null
          ? DateTime.parse(map['expiry_date'] as String)
          : null,
      location: map['location'] as String?,
      notes: map['notes'] as String?,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
    );
  }

  Inventory copyWith({
    int? id,
    int? medicationId,
    double? quantity,
    String? unit,
    double? reorderLevel,
    String? batchNumber,
    DateTime? expiryDate,
    String? location,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Inventory(
      id: id ?? this.id,
      medicationId: medicationId ?? this.medicationId,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      reorderLevel: reorderLevel ?? this.reorderLevel,
      batchNumber: batchNumber ?? this.batchNumber,
      expiryDate: expiryDate ?? this.expiryDate,
      location: location ?? this.location,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  // Helper methods
  bool get isLowStock => reorderLevel != null && quantity <= reorderLevel!;
  
  bool get isOutOfStock => quantity <= 0;
  
  double get totalValue => 0.0; // Can be extended if cost tracking is added

  // Calculate days until stock runs out based on usage rate
  int? calculateDaysUntilEmpty(double dailyUsageRate) {
    if (dailyUsageRate <= 0) return null;
    return (quantity / dailyUsageRate).ceil();
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Inventory && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
