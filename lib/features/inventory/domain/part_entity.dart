class PartEntity {
  final String id;
  final String companyId;
  final String partNumber;
  final String name;
  final String description;
  final String category; // engine, brake, tyre, electrical, lubricant, other
  final int quantity;
  final int minStockThreshold;
  final double unitCost;
  final String? supplierId;
  final String? supplierName;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  const PartEntity({
    required this.id,
    required this.companyId,
    required this.partNumber,
    required this.name,
    required this.description,
    required this.category,
    required this.quantity,
    required this.minStockThreshold,
    required this.unitCost,
    this.supplierId,
    this.supplierName,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'companyId': companyId,
      'partNumber': partNumber,
      'name': name,
      'description': description,
      'category': category,
      'quantity': quantity,
      'minStockThreshold': minStockThreshold,
      'unitCost': unitCost,
      'supplierId': supplierId,
      'supplierName': supplierName,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'deletedAt': deletedAt?.toIso8601String(),
    };
  }

  factory PartEntity.fromMap(Map<String, dynamic> map) {
    return PartEntity(
      id: map['id'] as String? ?? '',
      companyId: map['companyId'] as String? ?? '',
      partNumber: map['partNumber'] as String? ?? '',
      name: map['name'] as String? ?? '',
      description: map['description'] as String? ?? '',
      category: map['category'] as String? ?? 'other',
      quantity: map['quantity'] as int? ?? 0,
      minStockThreshold: map['minStockThreshold'] as int? ?? 0,
      unitCost: (map['unitCost'] as num? ?? 0.0).toDouble(),
      supplierId: map['supplierId'] as String?,
      supplierName: map['supplierName'] as String?,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'] as String)
          : DateTime.now(),
      deletedAt: map['deletedAt'] != null
          ? DateTime.parse(map['deletedAt'] as String)
          : null,
    );
  }

  PartEntity copyWith({
    String? id,
    String? companyId,
    String? partNumber,
    String? name,
    String? description,
    String? category,
    int? quantity,
    int? minStockThreshold,
    double? unitCost,
    String? supplierId,
    String? supplierName,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return PartEntity(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      partNumber: partNumber ?? this.partNumber,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      quantity: quantity ?? this.quantity,
      minStockThreshold: minStockThreshold ?? this.minStockThreshold,
      unitCost: unitCost ?? this.unitCost,
      supplierId: supplierId ?? this.supplierId,
      supplierName: supplierName ?? this.supplierName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }
}
