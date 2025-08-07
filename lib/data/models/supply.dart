import 'package:flutter/foundation.dart';

/// Supply Types for tracking usage - either countable items, measurable fluids, or reconstitution solutions
enum SupplyType {
  item,
  fluid,
  diluent;

  String get displayName {
    switch (this) {
      case SupplyType.item:
        return 'Item (Countable)';
      case SupplyType.fluid:
        return 'Fluid (Volume)';
      case SupplyType.diluent:
        return 'Diluent (Reconstitution)';
    }
  }

  String get shortName {
    switch (this) {
      case SupplyType.item:
        return 'Item';
      case SupplyType.fluid:
        return 'Fluid';
      case SupplyType.diluent:
        return 'Diluent';
    }
  }

  String get defaultUnit {
    switch (this) {
      case SupplyType.item:
        return 'pieces';
      case SupplyType.fluid:
        return 'ml';
      case SupplyType.diluent:
        return 'ml';
    }
  }

  static SupplyType fromString(String type) {
    return SupplyType.values.firstWhere(
      (e) => e.displayName.toLowerCase() == type.toLowerCase(),
      orElse: () => SupplyType.item,
    );
  }
}

@immutable
class Supply {
  final int? id;
  final String name;
  final SupplyType type;
  final String? brand;
  final String? size; // e.g., "1ml", "25G", "2x2 inches"
  final double quantity; // Changed to double for fluids
  final double? reorderLevel; // Changed to double for fluids
  final String? unit; // e.g., "pieces", "ml", "liters"
  final String? lotNumber;
  final DateTime? expirationDate;
  final String? location;
  final String? notes;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Supply({
    this.id,
    required this.name,
    required this.type,
    this.brand,
    this.size,
    required this.quantity,
    this.reorderLevel,
    this.unit,
    this.lotNumber,
    this.expirationDate,
    this.location,
    this.notes,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Supply.create({
    required String name,
    required SupplyType type,
    String? brand,
    String? size,
    required double quantity,
    double? reorderLevel,
    String? unit,
    String? lotNumber,
    DateTime? expirationDate,
    String? location,
    String? notes,
  }) {
    final now = DateTime.now();
    return Supply(
      name: name,
      type: type,
      brand: brand,
      size: size,
      quantity: quantity,
      reorderLevel: reorderLevel,
      unit: unit ?? type.defaultUnit,
      lotNumber: lotNumber,
      expirationDate: expirationDate,
      location: location,
      notes: notes,
      createdAt: now,
      updatedAt: now,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type.shortName, // Store as 'Item' or 'Fluid'
      'brand': brand,
      'size': size,
      'quantity': quantity,
      'reorder_level': reorderLevel,
      'unit': unit,
      'lot_number': lotNumber,
      'expiration_date': expirationDate?.toIso8601String(),
      'location': location,
      'notes': notes,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Supply.fromMap(Map<String, dynamic> map) {
    // Handle both old 'category' field and new 'type' field for backward compatibility
    final typeString = map['type'] as String? ?? map['category'] as String? ?? 'Item';
    SupplyType supplyType;
    switch (typeString.toLowerCase()) {
      case 'fluid':
        supplyType = SupplyType.fluid;
        break;
      case 'diluent':
        supplyType = SupplyType.diluent;
        break;
      default:
        supplyType = SupplyType.item;
        break;
    }
    
    return Supply(
      id: map['id'] as int?,
      name: map['name'] as String,
      type: supplyType,
      brand: map['brand'] as String?,
      size: map['size'] as String?,
      quantity: (map['quantity'] as num).toDouble(),
      reorderLevel: map['reorder_level'] != null ? (map['reorder_level'] as num).toDouble() : null,
      unit: map['unit'] as String?,
      lotNumber: map['lot_number'] as String?,
      expirationDate: map['expiration_date'] != null 
          ? DateTime.parse(map['expiration_date'] as String)
          : null,
      location: map['location'] as String?,
      notes: map['notes'] as String?,
      isActive: (map['is_active'] as int) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Supply copyWith({
    int? id,
    String? name,
    SupplyType? type,
    String? brand,
    String? size,
    double? quantity,
    double? reorderLevel,
    String? unit,
    String? lotNumber,
    DateTime? expirationDate,
    String? location,
    String? notes,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Supply(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      brand: brand ?? this.brand,
      size: size ?? this.size,
      quantity: quantity ?? this.quantity,
      reorderLevel: reorderLevel ?? this.reorderLevel,
      unit: unit ?? this.unit,
      lotNumber: lotNumber ?? this.lotNumber,
      expirationDate: expirationDate ?? this.expirationDate,
      location: location ?? this.location,
      notes: notes ?? this.notes,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  // Helper getters
  String get displayName => size != null ? '$name ($size)' : name;
  
  String get effectiveUnit => unit ?? type.defaultUnit;
  
  bool get isLowStock => reorderLevel != null && quantity <= reorderLevel!;
  
  bool get isExpired {
    if (expirationDate == null) return false;
    return DateTime.now().isAfter(expirationDate!);
  }

  bool get isExpiringSoon {
    if (expirationDate == null) return false;
    final daysUntilExpiration = expirationDate!.difference(DateTime.now()).inDays;
    return daysUntilExpiration <= 30 && daysUntilExpiration >= 0;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Supply && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
