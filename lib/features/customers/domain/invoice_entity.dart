class InvoiceEntity {
  final String id;
  final String tripId;
  final String? dispatchId;
  final String customerId;
  final String customerName;
  final String companyId;
  final String invoiceNumber;
  final double freightCharge;
  final double fuelCharge;
  final double tollCharge;
  final double extraCharges;
  final double discount;
  final double gstVat;
  final double grandTotal;
  final double amountPaid;
  final double outstandingAmount;
  final DateTime issueDate;
  final DateTime dueDate;
  final String
      status; // draft, issued, partially_paid, paid, overdue, cancelled
  final String paymentStatus; // pending, completed, failed, refunded
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  const InvoiceEntity({
    required this.id,
    required this.tripId,
    this.dispatchId,
    required this.customerId,
    required this.customerName,
    this.companyId = '',
    required this.invoiceNumber,
    double? amount, // legacy/compatibility field
    double? freightCharge,
    this.fuelCharge = 0.0,
    this.tollCharge = 0.0,
    this.extraCharges = 0.0,
    this.discount = 0.0,
    this.gstVat = 0.0,
    double? grandTotal,
    this.amountPaid = 0.0,
    double? outstandingAmount,
    required this.issueDate,
    required this.dueDate,
    this.status = 'draft',
    this.paymentStatus = 'pending',
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  })  : freightCharge = freightCharge ?? amount ?? grandTotal ?? 0.0,
        grandTotal = grandTotal ??
            amount ??
            ((freightCharge ?? 0.0) +
                fuelCharge +
                tollCharge +
                extraCharges -
                discount +
                gstVat),
        outstandingAmount = outstandingAmount ??
            (((grandTotal ?? amount ?? 0.0) +
                    (freightCharge ?? 0.0) +
                    fuelCharge +
                    tollCharge +
                    extraCharges -
                    discount +
                    gstVat) -
                amountPaid);

  /// Helper getter for backward compatibility
  double get amount => grandTotal;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tripId': tripId,
      'dispatchId': dispatchId,
      'customerId': customerId,
      'customerName': customerName,
      'companyId': companyId,
      'invoiceNumber': invoiceNumber,
      'freightCharge': freightCharge,
      'fuelCharge': fuelCharge,
      'tollCharge': tollCharge,
      'extraCharges': extraCharges,
      'discount': discount,
      'gstVat': gstVat,
      'grandTotal': grandTotal,
      'amount':
          grandTotal, // for backwards-compatibility with existing collections
      'amountPaid': amountPaid,
      'outstandingAmount': outstandingAmount,
      'status': status,
      'paymentStatus': paymentStatus,
      'notes': notes,
      'issueDate': issueDate.toIso8601String(),
      'dueDate': dueDate.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'deletedAt': deletedAt?.toIso8601String(),
    };
  }

  factory InvoiceEntity.fromMap(Map<String, dynamic> map) {
    final rawAmountPaid = (map['amountPaid'] as num? ?? 0.0).toDouble();
    final rawFreight =
        (map['freightCharge'] as num? ?? map['amount'] as num? ?? 0.0)
            .toDouble();
    final rawFuel = (map['fuelCharge'] as num? ?? 0.0).toDouble();
    final rawToll = (map['tollCharge'] as num? ?? 0.0).toDouble();
    final rawExtra = (map['extraCharges'] as num? ?? 0.0).toDouble();
    final rawDiscount = (map['discount'] as num? ?? 0.0).toDouble();
    final rawGst = (map['gstVat'] as num? ?? 0.0).toDouble();

    final computedGrandTotal = (map['grandTotal'] as num? ??
            (rawFreight + rawFuel + rawToll + rawExtra - rawDiscount + rawGst))
        .toDouble();
    final computedOutstanding = (map['outstandingAmount'] as num? ??
            (computedGrandTotal - rawAmountPaid))
        .toDouble();

    return InvoiceEntity(
      id: map['id'] as String? ?? '',
      tripId: map['tripId'] as String? ?? '',
      dispatchId: map['dispatchId'] as String?,
      customerId: map['customerId'] as String? ?? '',
      customerName: map['customerName'] as String? ?? '',
      companyId: map['companyId'] as String? ?? '',
      invoiceNumber: map['invoiceNumber'] as String? ?? '',
      freightCharge: rawFreight,
      fuelCharge: rawFuel,
      tollCharge: rawToll,
      extraCharges: rawExtra,
      discount: rawDiscount,
      gstVat: rawGst,
      grandTotal: computedGrandTotal,
      amountPaid: rawAmountPaid,
      outstandingAmount: computedOutstanding,
      status: map['status'] as String? ?? 'draft',
      paymentStatus: map['paymentStatus'] as String? ?? 'pending',
      notes: map['notes'] as String?,
      issueDate: map['issueDate'] != null
          ? DateTime.parse(map['issueDate'] as String)
          : DateTime.now(),
      dueDate: map['dueDate'] != null
          ? DateTime.parse(map['dueDate'] as String)
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

  InvoiceEntity copyWith({
    String? id,
    String? tripId,
    String? dispatchId,
    String? customerId,
    String? customerName,
    String? companyId,
    String? invoiceNumber,
    double? freightCharge,
    double? fuelCharge,
    double? tollCharge,
    double? extraCharges,
    double? discount,
    double? gstVat,
    double? grandTotal,
    double? amountPaid,
    double? outstandingAmount,
    DateTime? issueDate,
    DateTime? dueDate,
    String? status,
    String? paymentStatus,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return InvoiceEntity(
      id: id ?? this.id,
      tripId: tripId ?? this.tripId,
      dispatchId: dispatchId ?? this.dispatchId,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      companyId: companyId ?? this.companyId,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      freightCharge: freightCharge ?? this.freightCharge,
      fuelCharge: fuelCharge ?? this.fuelCharge,
      tollCharge: tollCharge ?? this.tollCharge,
      extraCharges: extraCharges ?? this.extraCharges,
      discount: discount ?? this.discount,
      gstVat: gstVat ?? this.gstVat,
      grandTotal: grandTotal ?? this.grandTotal,
      amountPaid: amountPaid ?? this.amountPaid,
      outstandingAmount: outstandingAmount ?? this.outstandingAmount,
      status: status ?? this.status,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      notes: notes ?? this.notes,
      issueDate: issueDate ?? this.issueDate,
      dueDate: dueDate ?? this.dueDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }
}
