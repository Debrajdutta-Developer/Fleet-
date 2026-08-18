class DriverEntity {
  final String id;
  final String fullName;
  final String phone;
  final String licenseNumber;
  final DateTime licenseExpiry;
  final String status; // available, on_duty, suspended, off_duty
  final double safetyScore;
  final String? assignedVehicleId;
  final String? assignedVehicleLicensePlate;
  final String? employeeId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  const DriverEntity({
    required this.id,
    required this.fullName,
    required this.phone,
    required this.licenseNumber,
    required this.licenseExpiry,
    required this.status,
    required this.safetyScore,
    this.assignedVehicleId,
    this.assignedVehicleLicensePlate,
    this.employeeId,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fullName': fullName,
      'phone': phone,
      'licenseNumber': licenseNumber,
      'licenseExpiry': licenseExpiry.toIso8601String(),
      'status': status,
      'safetyScore': safetyScore,
      'assignedVehicleId': assignedVehicleId,
      'assignedVehicleLicensePlate': assignedVehicleLicensePlate,
      'employeeId': employeeId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'deletedAt': deletedAt?.toIso8601String(),
    };
  }

  factory DriverEntity.fromMap(Map<String, dynamic> map) {
    return DriverEntity(
      id: map['id'] as String? ?? '',
      fullName: map['fullName'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      licenseNumber: map['licenseNumber'] as String? ?? '',
      licenseExpiry: map['licenseExpiry'] != null
          ? DateTime.parse(map['licenseExpiry'] as String)
          : DateTime.now(),
      status: map['status'] as String? ?? 'available',
      safetyScore: (map['safetyScore'] as num? ?? 100.0).toDouble(),
      assignedVehicleId: map['assignedVehicleId'] as String?,
      assignedVehicleLicensePlate:
          map['assignedVehicleLicensePlate'] as String?,
      employeeId: map['employeeId'] as String?,
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

  DriverEntity copyWith({
    String? id,
    String? fullName,
    String? phone,
    String? licenseNumber,
    DateTime? licenseExpiry,
    String? status,
    double? safetyScore,
    String? assignedVehicleId,
    String? assignedVehicleLicensePlate,
    String? employeeId,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return DriverEntity(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      licenseExpiry: licenseExpiry ?? this.licenseExpiry,
      status: status ?? this.status,
      safetyScore: safetyScore ?? this.safetyScore,
      assignedVehicleId: assignedVehicleId ?? this.assignedVehicleId,
      assignedVehicleLicensePlate:
          assignedVehicleLicensePlate ?? this.assignedVehicleLicensePlate,
      employeeId: employeeId ?? this.employeeId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }
}
