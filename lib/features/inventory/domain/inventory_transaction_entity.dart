class InventoryTransactionEntity {
  final String id;
  final String companyId;
  final String partId;
  final String partName;
  final String type; // stock_in, stock_out, adjustment
  final int
      quantity; // change in quantity (can be negative for stock_out/adjustment)
  final double unitCost; // cost per unit (for stock_in/adjustment)
  final double totalCost; // quantity * unitCost
  final String? referenceId; // e.g. maintenance log ID or purchase order ID
  final String notes;
  final DateTime date;
  final DateTime createdAt;
  final DateTime updatedAt;

  const InventoryTransactionEntity({
    required this.id,
    required this.companyId,
    required this.partId,
    required this.partName,
    required this.type,
    required this.quantity,
    required this.unitCost,
    required this.totalCost,
    this.referenceId,
    required this.notes,
    required this.date,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'companyId': companyId,
      'partId': partId,
      'partName': partName,
      'type': type,
      'quantity': quantity,
      'unitCost': unitCost,
      'totalCost': totalCost,
      'referenceId': referenceId,
      'notes': notes,
      'date': date.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory InventoryTransactionEntity.fromMap(Map<String, dynamic> map) {
    return InventoryTransactionEntity(
      id: map['id'] as String? ?? '',
      companyId: map['companyId'] as String? ?? '',
      partId: map['partId'] as String? ?? '',
      partName: map['partName'] as String? ?? '',
      type: map['type'] as String? ?? 'stock_in',
      quantity: map['quantity'] as int? ?? 0,
      unitCost: (map['unitCost'] as num? ?? 0.0).toDouble(),
      totalCost: (map['totalCost'] as num? ?? 0.0).toDouble(),
      referenceId: map['referenceId'] as String?,
      notes: map['notes'] as String? ?? '',
      date: map['date'] != null
          ? DateTime.parse(map['date'] as String)
          : DateTime.now(),
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'] as String)
          : DateTime.now(),
    );
  }

  InventoryTransactionEntity copyWith({
    String? id,
    String? companyId,
    String? partId,
    String? partName,
    String? type,
    int? quantity,
    double? unitCost,
    double? totalCost,
    String? referenceId,
    String? notes,
    DateTime? date,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return InventoryTransactionEntity(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      partId: partId ?? this.partId,
      partName: partName ?? this.partName,
      type: type ?? this.type,
      quantity: quantity ?? this.quantity,
      unitCost: unitCost ?? this.unitCost,
      totalCost: totalCost ?? this.totalCost,
      referenceId: referenceId ?? this.referenceId,
      notes: notes ?? this.notes,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
