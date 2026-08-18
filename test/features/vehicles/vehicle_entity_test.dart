import 'package:flutter_test/flutter_test.dart';
import 'package:fleet_os_erp/features/vehicles/domain/vehicle_entity.dart';

void main() {
  group('VehicleEntity Tests', () {
    final tVehicleMap = {
      'id': 'v_123',
      'vin': '12345678901234567',
      'licensePlate': 'NY-884-AB',
      'make': 'Volvo',
      'model': 'VNL 860',
      'year': 2023,
      'status': 'active',
      'fuelType': 'diesel',
      'odometer': 12050.0,
      'lastServiceDate': '2026-06-01T12:00:00.000',
      'insuranceExpiry': '2027-06-01T12:00:00.000',
      'pucExpiry': '2026-12-01T12:00:00.000',
      'fitnessExpiry': '2027-06-01T12:00:00.000',
      'assignedDriverId': 'driver_1',
      'assignedDriverName': 'Robert Jenkins',
      'createdAt': '2026-06-01T12:00:00.000',
      'updatedAt': '2026-06-01T12:00:00.000',
      'deletedAt': null,
    };

    final tVehicleEntity = VehicleEntity(
      id: 'v_123',
      vin: '12345678901234567',
      licensePlate: 'NY-884-AB',
      make: 'Volvo',
      model: 'VNL 860',
      year: 2023,
      status: 'active',
      fuelType: 'diesel',
      odometer: 12050.0,
      lastServiceDate: DateTime.parse('2026-06-01T12:00:00.000'),
      insuranceExpiry: DateTime.parse('2027-06-01T12:00:00.000'),
      pucExpiry: DateTime.parse('2026-12-01T12:00:00.000'),
      fitnessExpiry: DateTime.parse('2027-06-01T12:00:00.000'),
      assignedDriverId: 'driver_1',
      assignedDriverName: 'Robert Jenkins',
      createdAt: DateTime.parse('2026-06-01T12:00:00.000'),
      updatedAt: DateTime.parse('2026-06-01T12:00:00.000'),
      deletedAt: null,
    );

    test('should parse from valid map representation correctly', () {
      final result = VehicleEntity.fromMap(tVehicleMap);
      expect(result.id, tVehicleEntity.id);
      expect(result.vin, tVehicleEntity.vin);
      expect(result.licensePlate, tVehicleEntity.licensePlate);
      expect(result.odometer, tVehicleEntity.odometer);
      expect(result.assignedDriverName, tVehicleEntity.assignedDriverName);
    });

    test('should serialize to matching map correctly', () {
      final result = tVehicleEntity.toMap();
      expect(result['id'], tVehicleMap['id']);
      expect(result['vin'], tVehicleMap['vin']);
      expect(result['licensePlate'], tVehicleMap['licensePlate']);
      expect(result['odometer'], tVehicleMap['odometer']);
      expect(result['assignedDriverName'], tVehicleMap['assignedDriverName']);
    });

    test('should copyWith updating specified parameters correctly', () {
      final updated = tVehicleEntity.copyWith(
        status: 'maintenance',
        odometer: 13000.0,
      );
      expect(updated.status, 'maintenance');
      expect(updated.odometer, 13000.0);
      expect(updated.id, tVehicleEntity.id); // Stays unchanged
    });
  });
}
