import 'package:flutter_test/flutter_test.dart';
import 'package:fleet_os_erp/features/trips/domain/trip_entity.dart';
import 'package:fleet_os_erp/features/trips/domain/trip_status_history.dart';

void main() {
  group('TripEntity Tests', () {
    final tTripMap = {
      'id': 'trip_123',
      'companyId': 'comp_456',
      'vehicleId': 'v_123',
      'vehicleLicensePlate': 'NY-884-AB',
      'driverId': 'driver_1',
      'driverName': 'Robert Jenkins',
      'customerId': 'cust_1',
      'customerName': 'Walmart Fulfillment',
      'pickupLocation': 'New York Port',
      'deliveryLocation': 'Boston Logistics Hub',
      'cargoType': 'Coal',
      'coalQuantity': 25.5,
      'freightAmount': 1500.0,
      'advancePayment': 500.0,
      'permitExpense': 150.0,
      'status': 'scheduled',
      'statusHistory': [
        {
          'status': 'scheduled',
          'changedAt': '2026-07-06T12:00:00.000',
          'changedBy': 'Operator Bob',
          'notes': 'Initial trip creation',
        },
      ],
      'createdAt': '2026-07-06T12:00:00.000',
      'updatedAt': '2026-07-06T12:00:00.000',
      'deletedAt': null,
    };

    final tTripEntity = TripEntity(
      id: 'trip_123',
      companyId: 'comp_456',
      vehicleId: 'v_123',
      vehicleLicensePlate: 'NY-884-AB',
      driverId: 'driver_1',
      driverName: 'Robert Jenkins',
      customerId: 'cust_1',
      customerName: 'Walmart Fulfillment',
      pickupLocation: 'New York Port',
      deliveryLocation: 'Boston Logistics Hub',
      cargoType: 'Coal',
      coalQuantity: 25.5,
      freightAmount: 1500.0,
      advancePayment: 500.0,
      permitExpense: 150.0,
      status: 'scheduled',
      statusHistory: [
        TripStatusHistory(
          status: 'scheduled',
          changedAt: DateTime.parse('2026-07-06T12:00:00.000'),
          changedBy: 'Operator Bob',
          notes: 'Initial trip creation',
        ),
      ],
      createdAt: DateTime.parse('2026-07-06T12:00:00.000'),
      updatedAt: DateTime.parse('2026-07-06T12:00:00.000'),
      deletedAt: null,
    );

    test('should parse from valid map representation correctly', () {
      final result = TripEntity.fromMap(tTripMap);
      expect(result.id, tTripEntity.id);
      expect(result.companyId, tTripEntity.companyId);
      expect(result.vehicleLicensePlate, tTripEntity.vehicleLicensePlate);
      expect(result.coalQuantity, tTripEntity.coalQuantity);
      expect(result.freightAmount, tTripEntity.freightAmount);
      expect(result.statusHistory.length, 1);
      expect(result.statusHistory[0].status, 'scheduled');
    });

    test('should serialize to matching map correctly', () {
      final result = tTripEntity.toMap();
      expect(result['id'], tTripMap['id']);
      expect(result['coalQuantity'], tTripMap['coalQuantity']);
      expect(result['freightAmount'], tTripMap['freightAmount']);
      expect(result['statusHistory'][0]['status'], 'scheduled');
    });

    test('should copyWith updating specified parameters correctly', () {
      final updated = tTripEntity.copyWith(
        status: 'dispatched',
        coalQuantity: 30.0,
      );
      expect(updated.status, 'dispatched');
      expect(updated.coalQuantity, 30.0);
      expect(updated.id, tTripEntity.id); // Stays unchanged
    });
  });
}
