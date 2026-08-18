class RouteRate {
  final String pickup;
  final String delivery;
  final double ratePerTon;
  final double flatRate;

  const RouteRate({
    required this.pickup,
    required this.delivery,
    this.ratePerTon = 0.0,
    this.flatRate = 0.0,
  });

  Map<String, dynamic> toMap() {
    return {
      'pickup': pickup,
      'delivery': delivery,
      'ratePerTon': ratePerTon,
      'flatRate': flatRate,
    };
  }

  factory RouteRate.fromMap(Map<String, dynamic> map) {
    return RouteRate(
      pickup: map['pickup'] as String? ?? '',
      delivery: map['delivery'] as String? ?? '',
      ratePerTon: (map['ratePerTon'] as num? ?? 0.0).toDouble(),
      flatRate: (map['flatRate'] as num? ?? 0.0).toDouble(),
    );
  }
}

class VehicleRate {
  final String vehicleId;
  final String licensePlate;
  final double ratePerTon;
  final double flatRate;

  const VehicleRate({
    required this.vehicleId,
    required this.licensePlate,
    this.ratePerTon = 0.0,
    this.flatRate = 0.0,
  });

  Map<String, dynamic> toMap() {
    return {
      'vehicleId': vehicleId,
      'licensePlate': licensePlate,
      'ratePerTon': ratePerTon,
      'flatRate': flatRate,
    };
  }

  factory VehicleRate.fromMap(Map<String, dynamic> map) {
    return VehicleRate(
      vehicleId: map['vehicleId'] as String? ?? '',
      licensePlate: map['licensePlate'] as String? ?? '',
      ratePerTon: (map['ratePerTon'] as num? ?? 0.0).toDouble(),
      flatRate: (map['flatRate'] as num? ?? 0.0).toDouble(),
    );
  }
}

class ContractEntity {
  final String id;
  final String customerId;
  final String customerName;
  final String contractNumber;
  final DateTime startDate;
  final DateTime endDate;
  final String status; // active, expired, terminated
  final double defaultFreightRate; // per ton or per trip base rate
  final List<RouteRate> routeRates;
  final List<VehicleRate> vehicleRates;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  const ContractEntity({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.contractNumber,
    required this.startDate,
    required this.endDate,
    this.status = 'active',
    this.defaultFreightRate = 0.0,
    this.routeRates = const [],
    this.vehicleRates = const [],
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customerId': customerId,
      'customerName': customerName,
      'contractNumber': contractNumber,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'status': status,
      'defaultFreightRate': defaultFreightRate,
      'routeRates': routeRates.map((r) => r.toMap()).toList(),
      'vehicleRates': vehicleRates.map((v) => v.toMap()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'deletedAt': deletedAt?.toIso8601String(),
    };
  }

  factory ContractEntity.fromMap(Map<String, dynamic> map) {
    final routeList = map['routeRates'] as List<dynamic>? ?? [];
    final vehicleList = map['vehicleRates'] as List<dynamic>? ?? [];
    return ContractEntity(
      id: map['id'] as String? ?? '',
      customerId: map['customerId'] as String? ?? '',
      customerName: map['customerName'] as String? ?? '',
      contractNumber: map['contractNumber'] as String? ?? '',
      startDate: map['startDate'] != null
          ? DateTime.parse(map['startDate'] as String)
          : DateTime.now(),
      endDate: map['endDate'] != null
          ? DateTime.parse(map['endDate'] as String)
          : DateTime.now(),
      status: map['status'] as String? ?? 'active',
      defaultFreightRate: (map['defaultFreightRate'] as num? ?? 0.0).toDouble(),
      routeRates: routeList
          .map((r) => RouteRate.fromMap(Map<String, dynamic>.from(r as Map)))
          .toList(),
      vehicleRates: vehicleList
          .map((v) => VehicleRate.fromMap(Map<String, dynamic>.from(v as Map)))
          .toList(),
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

  ContractEntity copyWith({
    String? id,
    String? customerId,
    String? customerName,
    String? contractNumber,
    DateTime? startDate,
    DateTime? endDate,
    String? status,
    double? defaultFreightRate,
    List<RouteRate>? routeRates,
    List<VehicleRate>? vehicleRates,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return ContractEntity(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      contractNumber: contractNumber ?? this.contractNumber,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      status: status ?? this.status,
      defaultFreightRate: defaultFreightRate ?? this.defaultFreightRate,
      routeRates: routeRates ?? this.routeRates,
      vehicleRates: vehicleRates ?? this.vehicleRates,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }
}
