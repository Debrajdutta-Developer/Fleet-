class FuelEntity {
  final String id;
  final String companyId;
  final String vehicleId;
  final String vehicleLicensePlate;
  final String driverId;
  final String driverName;
  final double fuelQty;
  final double amount;
  final double odometer;
  final DateTime date;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  const FuelEntity({
    required this.id,
    required this.companyId,
    required this.vehicleId,
    required this.vehicleLicensePlate,
    required this.driverId,
    required this.driverName,
    required this.fuelQty,
    required this.amount,
    required this.odometer,
    required this.date,
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
      'driverId': driverId,
      'driverName': driverName,
      'fuelQty': fuelQty,
      'amount': amount,
      'odometer': odometer,
      'date': date.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'deletedAt': deletedAt?.toIso8601String(),
    };
  }

  factory FuelEntity.fromMap(Map<String, dynamic> map) {
    return FuelEntity(
      id: map['id'] as String? ?? '',
      companyId: map['companyId'] as String? ?? '',
      vehicleId: map['vehicleId'] as String? ?? '',
      vehicleLicensePlate: map['vehicleLicensePlate'] as String? ?? '',
      driverId: map['driverId'] as String? ?? '',
      driverName: map['driverName'] as String? ?? '',
      fuelQty: (map['fuelQty'] as num? ?? 0.0).toDouble(),
      amount: (map['amount'] as num? ?? 0.0).toDouble(),
      odometer: (map['odometer'] as num? ?? 0.0).toDouble(),
      date: map['date'] != null
          ? DateTime.parse(map['date'] as String)
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

  FuelEntity copyWith({
    String? id,
    String? companyId,
    String? vehicleId,
    String? vehicleLicensePlate,
    String? driverId,
    String? driverName,
    double? fuelQty,
    double? amount,
    double? odometer,
    DateTime? date,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return FuelEntity(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      vehicleId: vehicleId ?? this.vehicleId,
      vehicleLicensePlate: vehicleLicensePlate ?? this.vehicleLicensePlate,
      driverId: driverId ?? this.driverId,
      driverName: driverName ?? this.driverName,
      fuelQty: fuelQty ?? this.fuelQty,
      amount: amount ?? this.amount,
      odometer: odometer ?? this.odometer,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }
}
