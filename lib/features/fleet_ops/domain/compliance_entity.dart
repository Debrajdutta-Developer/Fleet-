class ComplianceEntity {
  final String id;
  final String companyId;
  final String vehicleId;
  final String vehicleLicensePlate;
  final String documentType; // insurance, puc, fitness, permit, other
  final String documentNumber;
  final DateTime expiryDate;
  final String? documentUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  const ComplianceEntity({
    required this.id,
    required this.companyId,
    required this.vehicleId,
    required this.vehicleLicensePlate,
    required this.documentType,
    required this.documentNumber,
    required this.expiryDate,
    this.documentUrl,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'companyId': companyId,
      'vehicleId': vehicleId,
      'vehicleLicensePlate': vehicleLicensePlate,
      'documentType': documentType,
      'documentNumber': documentNumber,
      'expiryDate': expiryDate.toIso8601String(),
      'documentUrl': documentUrl,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'deletedAt': deletedAt?.toIso8601String(),
    };
  }

  factory ComplianceEntity.fromMap(Map<String, dynamic> map) {
    return ComplianceEntity(
      id: map['id'] as String? ?? '',
      companyId: map['companyId'] as String? ?? '',
      vehicleId: map['vehicleId'] as String? ?? '',
      vehicleLicensePlate: map['vehicleLicensePlate'] as String? ?? '',
      documentType: map['documentType'] as String? ?? 'other',
      documentNumber: map['documentNumber'] as String? ?? '',
      expiryDate: map['expiryDate'] != null
          ? DateTime.parse(map['expiryDate'] as String)
          : DateTime.now(),
      documentUrl: map['documentUrl'] as String?,
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

  ComplianceEntity copyWith({
    String? id,
    String? companyId,
    String? vehicleId,
    String? vehicleLicensePlate,
    String? documentType,
    String? documentNumber,
    DateTime? expiryDate,
    String? documentUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return ComplianceEntity(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      vehicleId: vehicleId ?? this.vehicleId,
      vehicleLicensePlate: vehicleLicensePlate ?? this.vehicleLicensePlate,
      documentType: documentType ?? this.documentType,
      documentNumber: documentNumber ?? this.documentNumber,
      expiryDate: expiryDate ?? this.expiryDate,
      documentUrl: documentUrl ?? this.documentUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }
}
