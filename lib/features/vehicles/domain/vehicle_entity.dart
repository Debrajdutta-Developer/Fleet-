/// Represents a vehicle asset inside the FleetOS ERP system.
class VehicleEntity {
  final String id;
  final String vin;
  final String licensePlate;
  final String make;
  final String model;
  final int year;
  final String status; // active, maintenance, idle, sold, archived
  final String fuelType; // diesel, unleaded, electric
  final double odometer;
  final DateTime? lastServiceDate;
  final DateTime insuranceExpiry;
  final DateTime pucExpiry;
  final DateTime fitnessExpiry;
  final String? assignedDriverId;
  final String? assignedDriverName;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  const VehicleEntity({
    required this.id,
    required this.vin,
    required this.licensePlate,
    required this.make,
    required this.model,
    required this.year,
    required this.status,
    required this.fuelType,
    required this.odometer,
    this.lastServiceDate,
    required this.insuranceExpiry,
    required this.pucExpiry,
    required this.fitnessExpiry,
    this.assignedDriverId,
    this.assignedDriverName,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  /// Map representations for Firestore operations
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'vin': vin,
      'licensePlate': licensePlate,
      'make': make,
      'model': model,
      'year': year,
      'status': status,
      'fuelType': fuelType,
      'odometer': odometer,
      'lastServiceDate': lastServiceDate?.toIso8601String(),
      'insuranceExpiry': insuranceExpiry.toIso8601String(),
      'pucExpiry': pucExpiry.toIso8601String(),
      'fitnessExpiry': fitnessExpiry.toIso8601String(),
      'assignedDriverId': assignedDriverId,
      'assignedDriverName': assignedDriverName,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'deletedAt': deletedAt?.toIso8601String(),
    };
  }

  /// Create vehicle entity from Firestore document map
  factory VehicleEntity.fromMap(Map<String, dynamic> map) {
    return VehicleEntity(
      id: map['id'] as String,
      vin: map['vin'] as String? ?? '',
      licensePlate: map['licensePlate'] as String? ?? '',
      make: map['make'] as String? ?? '',
      model: map['model'] as String? ?? '',
      year: map['year'] as int? ?? DateTime.now().year,
      status: map['status'] as String? ?? 'registration',
      fuelType: map['fuelType'] as String? ?? 'diesel',
      odometer: (map['odometer'] as num? ?? 0.0).toDouble(),
      lastServiceDate: map['lastServiceDate'] != null
          ? DateTime.parse(map['lastServiceDate'] as String)
          : null,
      insuranceExpiry: map['insuranceExpiry'] != null
          ? DateTime.parse(map['insuranceExpiry'] as String)
          : DateTime.now(),
      pucExpiry: map['pucExpiry'] != null
          ? DateTime.parse(map['pucExpiry'] as String)
          : DateTime.now(),
      fitnessExpiry: map['fitnessExpiry'] != null
          ? DateTime.parse(map['fitnessExpiry'] as String)
          : DateTime.now(),
      assignedDriverId: map['assignedDriverId'] as String?,
      assignedDriverName: map['assignedDriverName'] as String?,
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

  /// Implements copyWith for state changes inside presentation controllers
  VehicleEntity copyWith({
    String? id,
    String? vin,
    String? licensePlate,
    String? make,
    String? model,
    int? year,
    String? status,
    String? fuelType,
    double? odometer,
    DateTime? lastServiceDate,
    DateTime? insuranceExpiry,
    DateTime? pucExpiry,
    DateTime? fitnessExpiry,
    String? assignedDriverId,
    String? assignedDriverName,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return VehicleEntity(
      id: id ?? this.id,
      vin: vin ?? this.vin,
      licensePlate: licensePlate ?? this.licensePlate,
      make: make ?? this.make,
      model: model ?? this.model,
      year: year ?? this.year,
      status: status ?? this.status,
      fuelType: fuelType ?? this.fuelType,
      odometer: odometer ?? this.odometer,
      lastServiceDate: lastServiceDate ?? this.lastServiceDate,
      insuranceExpiry: insuranceExpiry ?? this.insuranceExpiry,
      pucExpiry: pucExpiry ?? this.pucExpiry,
      fitnessExpiry: fitnessExpiry ?? this.fitnessExpiry,
      assignedDriverId: assignedDriverId ?? this.assignedDriverId,
      assignedDriverName: assignedDriverName ?? this.assignedDriverName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }
}
