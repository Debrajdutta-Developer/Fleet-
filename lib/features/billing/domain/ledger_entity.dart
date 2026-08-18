class LedgerEntity {
  final String id;
  final String companyId;
  final String type; // debit, credit
  final String accountType; // accounts_receivable, revenue, cash_bank
  final double amount;
  final String referenceId; // invoiceId or paymentId
  final String description;
  final DateTime date;
  final DateTime createdAt;

  const LedgerEntity({
    required this.id,
    required this.companyId,
    required this.type,
    required this.accountType,
    required this.amount,
    required this.referenceId,
    required this.description,
    required this.date,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'companyId': companyId,
      'type': type,
      'accountType': accountType,
      'amount': amount,
      'referenceId': referenceId,
      'description': description,
      'date': date.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory LedgerEntity.fromMap(Map<String, dynamic> map) {
    return LedgerEntity(
      id: map['id'] as String? ?? '',
      companyId: map['companyId'] as String? ?? '',
      type: map['type'] as String? ?? 'debit',
      accountType: map['accountType'] as String? ?? 'accounts_receivable',
      amount: (map['amount'] as num? ?? 0.0).toDouble(),
      referenceId: map['referenceId'] as String? ?? '',
      description: map['description'] as String? ?? '',
      date: map['date'] != null
          ? DateTime.parse(map['date'] as String)
          : DateTime.now(),
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : DateTime.now(),
    );
  }
}
