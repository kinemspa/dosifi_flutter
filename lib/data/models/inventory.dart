import 'package:flutter/foundation.dart';

@immutable
class Inventory {
  final int? id;
  final int medicationId;
  final double currentStock;
  final String unit;
  final double? reorderLevel;
  final String? supplierName;
  final String? supplierContact;
  final double? costPerUnit;
  final DateTime lastUpdated;

  const Inventory({
    this.id,
    required this.medicationId,
    required this.currentStock,
    required this.unit,
    this.reorderLevel,
    this.supplierName,
    this.supplierContact,
    this.costPerUnit,
    required this.lastUpdated,
  });

  factory Inventory.create({
    required int medicationId,
    required double currentStock,
    required String unit,
    double? reorderLevel,
    String? supplierName,
    String? supplierContact,
    double? costPerUnit,
  }) {
    return Inventory(
      medicationId: medicationId,
      currentStock: currentStock,
      unit: unit,
      reorderLevel: reorderLevel,
      supplierName: supplierName,
      supplierContact: supplierContact,
      costPerUnit: costPerUnit,
      lastUpdated: DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'medication_id': medicationId,
      'current_stock': currentStock,
      'unit': unit,
      'reorder_level': reorderLevel,
      'supplier_name': supplierName,
      'supplier_contact': supplierContact,
      'cost_per_unit': costPerUnit,
      'last_updated': lastUpdated.toIso8601String(),
    };
  }

  factory Inventory.fromMap(Map<String, dynamic> map) {
    return Inventory(
      id: map['id'] as int?,
      medicationId: map['medication_id'] as int,
      currentStock: (map['current_stock'] as num).toDouble(),
      unit: map['unit'] as String,
      reorderLevel: map['reorder_level'] != null 
          ? (map['reorder_level'] as num).toDouble()
          : null,
      supplierName: map['supplier_name'] as String?,
      supplierContact: map['supplier_contact'] as String?,
      costPerUnit: map['cost_per_unit'] != null 
          ? (map['cost_per_unit'] as num).toDouble()
          : null,
      lastUpdated: DateTime.parse(map['last_updated'] as String),
    );
  }

  Inventory copyWith({
    int? id,
    int? medicationId,
    double? currentStock,
    String? unit,
    double? reorderLevel,
    String? supplierName,
    String? supplierContact,
    double? costPerUnit,
    DateTime? lastUpdated,
  }) {
    return Inventory(
      id: id ?? this.id,
      medicationId: medicationId ?? this.medicationId,
      currentStock: currentStock ?? this.currentStock,
      unit: unit ?? this.unit,
      reorderLevel: reorderLevel ?? this.reorderLevel,
      supplierName: supplierName ?? this.supplierName,
      supplierContact: supplierContact ?? this.supplierContact,
      costPerUnit: costPerUnit ?? this.costPerUnit,
      lastUpdated: lastUpdated ?? DateTime.now(),
    );
  }

  // Helper methods
  bool get isLowStock => reorderLevel != null && currentStock <= reorderLevel!;
  
  bool get isOutOfStock => currentStock <= 0;
  
  double get totalValue => costPerUnit != null ? currentStock * costPerUnit! : 0.0;

  // Calculate days until stock runs out based on usage rate
  int? calculateDaysUntilEmpty(double dailyUsageRate) {
    if (dailyUsageRate <= 0) return null;
    return (currentStock / dailyUsageRate).ceil();
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Inventory && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
