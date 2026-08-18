class FinanceTransactionEntity {
  final String id;
  final String companyId;
  final String type; // income, expense
  final String
      category; // driver_salary, advance_salary, diesel, toll, repair, tyre, insurance, miscellaneous, income
  final double amount;
  final String paymentMode; // cash, bank, upi
  final String? referenceNumber;
  final String? tripId;
  final String? tripNumber;
  final String? vehicleId;
  final String? vehicleLicensePlate;
  final String? notes;
  final String? vendorId;
  final String? vendorName;
  final DateTime transactionDate;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  const FinanceTransactionEntity({
    required this.id,
    required this.companyId,
    required this.type,
    required this.category,
    required this.amount,
    required this.paymentMode,
    this.referenceNumber,
    this.tripId,
    this.tripNumber,
    this.vehicleId,
    this.vehicleLicensePlate,
    this.notes,
    this.vendorId,
    this.vendorName,
    required this.transactionDate,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'companyId': companyId,
      'type': type,
      'category': category,
      'amount': amount,
      'paymentMode': paymentMode,
      'referenceNumber': referenceNumber,
      'tripId': tripId,
      'tripNumber': tripNumber,
      'vehicleId': vehicleId,
      'vehicleLicensePlate': vehicleLicensePlate,
      'notes': notes,
      'vendorId': vendorId,
      'vendorName': vendorName,
      'transactionDate': transactionDate.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'deletedAt': deletedAt?.toIso8601String(),
    };
  }

  factory FinanceTransactionEntity.fromMap(Map<String, dynamic> map) {
    return FinanceTransactionEntity(
      id: map['id'] as String? ?? '',
      companyId: map['companyId'] as String? ?? '',
      type: map['type'] as String? ?? 'expense',
      category: map['category'] as String? ?? 'miscellaneous',
      amount: (map['amount'] as num? ?? 0.0).toDouble(),
      paymentMode: map['paymentMode'] as String? ?? 'cash',
      referenceNumber: map['referenceNumber'] as String?,
      tripId: map['tripId'] as String?,
      tripNumber: map['tripNumber'] as String?,
      vehicleId: map['vehicleId'] as String?,
      vehicleLicensePlate: map['vehicleLicensePlate'] as String?,
      notes: map['notes'] as String?,
      vendorId: map['vendorId'] as String?,
      vendorName: map['vendorName'] as String?,
      transactionDate: map['transactionDate'] != null
          ? DateTime.parse(map['transactionDate'] as String)
          : DateTime.now(),
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

  FinanceTransactionEntity copyWith({
    String? id,
    String? companyId,
    String? type,
    String? category,
    double? amount,
    String? paymentMode,
    String? referenceNumber,
    String? tripId,
    String? tripNumber,
    String? vehicleId,
    String? vehicleLicensePlate,
    String? notes,
    String? vendorId,
    String? vendorName,
    DateTime? transactionDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return FinanceTransactionEntity(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      type: type ?? this.type,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      paymentMode: paymentMode ?? this.paymentMode,
      referenceNumber: referenceNumber ?? this.referenceNumber,
      tripId: tripId ?? this.tripId,
      tripNumber: tripNumber ?? this.tripNumber,
      vehicleId: vehicleId ?? this.vehicleId,
      vehicleLicensePlate: vehicleLicensePlate ?? this.vehicleLicensePlate,
      notes: notes ?? this.notes,
      vendorId: vendorId ?? this.vendorId,
      vendorName: vendorName ?? this.vendorName,
      transactionDate: transactionDate ?? this.transactionDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }
}
