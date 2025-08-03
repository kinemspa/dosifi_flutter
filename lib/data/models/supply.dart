import 'package:flutter/foundation.dart';

// Supply Categories
enum SupplyCategory {
  syringe,
  needle,
  swab,
  bandage,
  gauze,
  tape,
  gloves,
  wipe,
  container,
  other;

  String get displayName {
    switch (this) {
      case SupplyCategory.syringe:
        return 'Syringe';
      case SupplyCategory.needle:
        return 'Needle';
      case SupplyCategory.swab:
        return 'Swab';
      case SupplyCategory.bandage:
        return 'Bandage';
      case SupplyCategory.gauze:
        return 'Gauze';
      case SupplyCategory.tape:
        return 'Medical Tape';
      case SupplyCategory.gloves:
        return 'Gloves';
      case SupplyCategory.wipe:
        return 'Alcohol Wipe';
      case SupplyCategory.container:
        return 'Container';
      case SupplyCategory.other:
        return 'Other';
    }
  }

  static SupplyCategory fromString(String category) {
    return SupplyCategory.values.firstWhere(
      (e) => e.displayName.toLowerCase() == category.toLowerCase(),
      orElse: () => SupplyCategory.other,
    );
  }
}

@immutable
class Supply {
  final int? id;
  final String name;
  final SupplyCategory category;
  final String? brand;
  final String? size; // e.g., "1ml", "25G", "2x2 inches"
  final int quantity;
  final int? reorderLevel;
  final String? unit; // e.g., "pieces", "boxes", "packs"
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
    required this.category,
    this.brand,
    this.size,
    required this.quantity,
    this.reorderLevel,
    this.unit = 'pieces',
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
    required SupplyCategory category,
    String? brand,
    String? size,
    required int quantity,
    int? reorderLevel,
    String? unit,
    String? lotNumber,
    DateTime? expirationDate,
    String? location,
    String? notes,
  }) {
    final now = DateTime.now();
    return Supply(
      name: name,
      category: category,
      brand: brand,
      size: size,
      quantity: quantity,
      reorderLevel: reorderLevel,
      unit: unit ?? 'pieces',
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
      'category': category.displayName,
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
    return Supply(
      id: map['id'] as int?,
      name: map['name'] as String,
      category: SupplyCategory.fromString(map['category'] as String),
      brand: map['brand'] as String?,
      size: map['size'] as String?,
      quantity: map['quantity'] as int,
      reorderLevel: map['reorder_level'] as int?,
      unit: map['unit'] as String? ?? 'pieces',
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
    SupplyCategory? category,
    String? brand,
    String? size,
    int? quantity,
    int? reorderLevel,
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
      category: category ?? this.category,
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
