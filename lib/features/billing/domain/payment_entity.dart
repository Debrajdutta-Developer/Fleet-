class PaymentEntity {
  final String id;
  final String companyId;
  final String invoiceId;
  final double amount;
  final String paymentMethod; // cash, bank_transfer, upi, card, cheque, other
  final String status; // pending, completed, failed, refunded
  final DateTime paymentDate;
  final String? referenceNumber;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  const PaymentEntity({
    required this.id,
    required this.companyId,
    required this.invoiceId,
    required this.amount,
    required this.paymentMethod,
    required this.status,
    required this.paymentDate,
    this.referenceNumber,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'companyId': companyId,
      'invoiceId': invoiceId,
      'amount': amount,
      'paymentMethod': paymentMethod,
      'status': status,
      'paymentDate': paymentDate.toIso8601String(),
      'referenceNumber': referenceNumber,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'deletedAt': deletedAt?.toIso8601String(),
    };
  }

  factory PaymentEntity.fromMap(Map<String, dynamic> map) {
    return PaymentEntity(
      id: map['id'] as String? ?? '',
      companyId: map['companyId'] as String? ?? '',
      invoiceId: map['invoiceId'] as String? ?? '',
      amount: (map['amount'] as num? ?? 0.0).toDouble(),
      paymentMethod: map['paymentMethod'] as String? ?? 'cash',
      status: map['status'] as String? ?? 'completed',
      paymentDate: map['paymentDate'] != null
          ? DateTime.parse(map['paymentDate'] as String)
          : DateTime.now(),
      referenceNumber: map['referenceNumber'] as String?,
      notes: map['notes'] as String?,
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

  PaymentEntity copyWith({
    String? id,
    String? companyId,
    String? invoiceId,
    double? amount,
    String? paymentMethod,
    String? status,
    DateTime? paymentDate,
    String? referenceNumber,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return PaymentEntity(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      invoiceId: invoiceId ?? this.invoiceId,
      amount: amount ?? this.amount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      status: status ?? this.status,
      paymentDate: paymentDate ?? this.paymentDate,
      referenceNumber: referenceNumber ?? this.referenceNumber,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }
}
