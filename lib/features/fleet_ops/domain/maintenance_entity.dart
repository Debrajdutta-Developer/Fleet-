class MaintenanceEntity {
  final String id;
  final String companyId;
  final String vehicleId;
  final String vehicleLicensePlate;
  final String? vendorId;
  final String? vendorName;
  final String type; // preventative, corrective
  final String description;
  final double cost;
  final double odometer;
  final DateTime date;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  final String? partId;
  final String? partName;
  final int? partQuantity;

  const MaintenanceEntity({
    required this.id,
    required this.companyId,
    required this.vehicleId,
    required this.vehicleLicensePlate,
    this.vendorId,
    this.vendorName,
    required this.type,
    required this.description,
    required this.cost,
    required this.odometer,
    required this.date,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.partId,
    this.partName,
    this.partQuantity,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'companyId': companyId,
      'vehicleId': vehicleId,
      'vehicleLicensePlate': vehicleLicensePlate,
      'vendorId': vendorId,
      'vendorName': vendorName,
      'type': type,
      'description': description,
      'cost': cost,
      'odometer': odometer,
      'date': date.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'deletedAt': deletedAt?.toIso8601String(),
      'partId': partId,
      'partName': partName,
      'partQuantity': partQuantity,
    };
  }

  factory MaintenanceEntity.fromMap(Map<String, dynamic> map) {
    return MaintenanceEntity(
      id: map['id'] as String? ?? '',
      companyId: map['companyId'] as String? ?? '',
      vehicleId: map['vehicleId'] as String? ?? '',
      vehicleLicensePlate: map['vehicleLicensePlate'] as String? ?? '',
      vendorId: map['vendorId'] as String?,
      vendorName: map['vendorName'] as String?,
      type: map['type'] as String? ?? 'preventative',
      description: map['description'] as String? ?? '',
      cost: (map['cost'] as num? ?? 0.0).toDouble(),
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
      partId: map['partId'] as String?,
      partName: map['partName'] as String?,
      partQuantity: map['partQuantity'] as int?,
    );
  }

  MaintenanceEntity copyWith({
    String? id,
    String? companyId,
    String? vehicleId,
    String? vehicleLicensePlate,
    String? vendorId,
    String? vendorName,
    String? type,
    String? description,
    double? cost,
    double? odometer,
    DateTime? date,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    String? partId,
    String? partName,
    int? partQuantity,
  }) {
    return MaintenanceEntity(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      vehicleId: vehicleId ?? this.vehicleId,
      vehicleLicensePlate: vehicleLicensePlate ?? this.vehicleLicensePlate,
      vendorId: vendorId ?? this.vendorId,
      vendorName: vendorName ?? this.vendorName,
      type: type ?? this.type,
      description: description ?? this.description,
      cost: cost ?? this.cost,
      odometer: odometer ?? this.odometer,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      partId: partId ?? this.partId,
      partName: partName ?? this.partName,
      partQuantity: partQuantity ?? this.partQuantity,
    );
  }
}
