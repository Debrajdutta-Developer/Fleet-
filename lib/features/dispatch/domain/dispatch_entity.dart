class DispatchEntity {
  final String id;
  final String dispatchNumber;
  final String companyId;
  final String vehicleId;
  final String vehicleLicensePlate;
  final String driverId;
  final String driverName;
  final String routeId;
  final String routeName;
  final String status; // draft, scheduled, in_transit, completed, cancelled
  final DateTime scheduledTime;
  final String? notes;
  final String? tripId; // Link to the integrated Trip
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  const DispatchEntity({
    required this.id,
    required this.dispatchNumber,
    required this.companyId,
    required this.vehicleId,
    required this.vehicleLicensePlate,
    required this.driverId,
    required this.driverName,
    required this.routeId,
    required this.routeName,
    required this.status,
    required this.scheduledTime,
    this.notes,
    this.tripId,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'dispatchNumber': dispatchNumber,
      'companyId': companyId,
      'vehicleId': vehicleId,
      'vehicleLicensePlate': vehicleLicensePlate,
      'driverId': driverId,
      'driverName': driverName,
      'routeId': routeId,
      'routeName': routeName,
      'status': status,
      'scheduledTime': scheduledTime.toIso8601String(),
      'notes': notes,
      'tripId': tripId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'deletedAt': deletedAt?.toIso8601String(),
    };
  }

  factory DispatchEntity.fromMap(Map<String, dynamic> map) {
    return DispatchEntity(
      id: map['id'] as String? ?? '',
      dispatchNumber: map['dispatchNumber'] as String? ?? '',
      companyId: map['companyId'] as String? ?? '',
      vehicleId: map['vehicleId'] as String? ?? '',
      vehicleLicensePlate: map['vehicleLicensePlate'] as String? ?? '',
      driverId: map['driverId'] as String? ?? '',
      driverName: map['driverName'] as String? ?? '',
      routeId: map['routeId'] as String? ?? '',
      routeName: map['routeName'] as String? ?? '',
      status: map['status'] as String? ?? 'draft',
      scheduledTime: map['scheduledTime'] != null
          ? DateTime.parse(map['scheduledTime'] as String)
          : DateTime.now(),
      notes: map['notes'] as String?,
      tripId: map['tripId'] as String?,
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

  DispatchEntity copyWith({
    String? id,
    String? dispatchNumber,
    String? companyId,
    String? vehicleId,
    String? vehicleLicensePlate,
    String? driverId,
    String? driverName,
    String? routeId,
    String? routeName,
    String? status,
    DateTime? scheduledTime,
    String? notes,
    String? tripId,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return DispatchEntity(
      id: id ?? this.id,
      dispatchNumber: dispatchNumber ?? this.dispatchNumber,
      companyId: companyId ?? this.companyId,
      vehicleId: vehicleId ?? this.vehicleId,
      vehicleLicensePlate: vehicleLicensePlate ?? this.vehicleLicensePlate,
      driverId: driverId ?? this.driverId,
      driverName: driverName ?? this.driverName,
      routeId: routeId ?? this.routeId,
      routeName: routeName ?? this.routeName,
      status: status ?? this.status,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      notes: notes ?? this.notes,
      tripId: tripId ?? this.tripId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }
}
