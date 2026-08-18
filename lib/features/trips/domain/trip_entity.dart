import 'trip_status_history.dart';

class TripEntity {
  final String id;
  final String companyId;
  final String vehicleId;
  final String vehicleLicensePlate;
  final String driverId;
  final String driverName;
  final String customerId;
  final String customerName;
  final String pickupLocation;
  final String deliveryLocation;
  final String cargoType;
  final double coalQuantity; // Requirement 8: Coal Quantity (tons)
  final double freightAmount;
  final double advancePayment;
  final double permitExpense;
  final String
      status; // scheduled, dispatched, loading, inTransit, delivered, completed, cancelled
  final List<TripStatusHistory> statusHistory;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  const TripEntity({
    required this.id,
    required this.companyId,
    required this.vehicleId,
    required this.vehicleLicensePlate,
    required this.driverId,
    required this.driverName,
    required this.customerId,
    required this.customerName,
    required this.pickupLocation,
    required this.deliveryLocation,
    required this.cargoType,
    required this.coalQuantity,
    required this.freightAmount,
    required this.advancePayment,
    required this.permitExpense,
    required this.status,
    required this.statusHistory,
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
      'customerId': customerId,
      'customerName': customerName,
      'pickupLocation': pickupLocation,
      'deliveryLocation': deliveryLocation,
      'cargoType': cargoType,
      'coalQuantity': coalQuantity,
      'freightAmount': freightAmount,
      'advancePayment': advancePayment,
      'permitExpense': permitExpense,
      'status': status,
      'statusHistory': statusHistory.map((x) => x.toMap()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'deletedAt': deletedAt?.toIso8601String(),
    };
  }

  factory TripEntity.fromMap(Map<String, dynamic> map) {
    return TripEntity(
      id: map['id'] as String? ?? '',
      companyId: map['companyId'] as String? ?? '',
      vehicleId: map['vehicleId'] as String? ?? '',
      vehicleLicensePlate: map['vehicleLicensePlate'] as String? ?? '',
      driverId: map['driverId'] as String? ?? '',
      driverName: map['driverName'] as String? ?? '',
      customerId: map['customerId'] as String? ?? '',
      customerName: map['customerName'] as String? ?? '',
      pickupLocation: map['pickupLocation'] as String? ?? '',
      deliveryLocation: map['deliveryLocation'] as String? ?? '',
      cargoType: map['cargoType'] as String? ?? '',
      coalQuantity: (map['coalQuantity'] as num? ?? 0.0).toDouble(),
      freightAmount: (map['freightAmount'] as num? ?? 0.0).toDouble(),
      advancePayment: (map['advancePayment'] as num? ?? 0.0).toDouble(),
      permitExpense: (map['permitExpense'] as num? ?? 0.0).toDouble(),
      status: map['status'] as String? ?? 'scheduled',
      statusHistory: map['statusHistory'] != null
          ? (map['statusHistory'] as List)
              .map(
                (x) => TripStatusHistory.fromMap(
                  Map<String, dynamic>.from(x as Map),
                ),
              )
              .toList()
          : [],
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

  TripEntity copyWith({
    String? id,
    String? companyId,
    String? vehicleId,
    String? vehicleLicensePlate,
    String? driverId,
    String? driverName,
    String? customerId,
    String? customerName,
    String? pickupLocation,
    String? deliveryLocation,
    String? cargoType,
    double? coalQuantity,
    double? freightAmount,
    double? advancePayment,
    double? permitExpense,
    String? status,
    List<TripStatusHistory>? statusHistory,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return TripEntity(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      vehicleId: vehicleId ?? this.vehicleId,
      vehicleLicensePlate: vehicleLicensePlate ?? this.vehicleLicensePlate,
      driverId: driverId ?? this.driverId,
      driverName: driverName ?? this.driverName,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      pickupLocation: pickupLocation ?? this.pickupLocation,
      deliveryLocation: deliveryLocation ?? this.deliveryLocation,
      cargoType: cargoType ?? this.cargoType,
      coalQuantity: coalQuantity ?? this.coalQuantity,
      freightAmount: freightAmount ?? this.freightAmount,
      advancePayment: advancePayment ?? this.advancePayment,
      permitExpense: permitExpense ?? this.permitExpense,
      status: status ?? this.status,
      statusHistory: statusHistory ?? this.statusHistory,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }
}
