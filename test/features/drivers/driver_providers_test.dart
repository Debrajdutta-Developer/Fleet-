import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fleet_os_erp/features/auth/presentation/auth_providers.dart';
import 'package:fleet_os_erp/features/auth/domain/user_entity.dart';
import 'package:fleet_os_erp/features/drivers/domain/driver_entity.dart';
import 'package:fleet_os_erp/features/drivers/domain/driver_repository.dart';
import 'package:fleet_os_erp/features/drivers/presentation/driver_providers.dart';
import 'package:fleet_os_erp/features/vehicles/domain/vehicle_entity.dart';
import 'package:fleet_os_erp/features/vehicles/domain/vehicle_repository.dart';
import 'package:fleet_os_erp/features/vehicles/presentation/vehicle_providers.dart';
import 'package:fleet_os_erp/features/trips/domain/trip_repository.dart';
import 'package:fleet_os_erp/features/trips/presentation/trip_providers.dart';
import 'package:fleet_os_erp/features/trips/domain/trip_entity.dart';
import 'package:fleet_os_erp/features/trips/domain/audit_log_entity.dart';

class MockDriverRepository implements DriverRepository {
  final List<DriverEntity> drivers;
  MockDriverRepository({required this.drivers});

  @override
  Stream<List<DriverEntity>> watchDrivers(String companyId) =>
      Stream.value(drivers);

  @override
  Future<List<DriverEntity>> getDrivers(String companyId) async => drivers;

  @override
  Future<DriverEntity?> getDriverById(String companyId, String driverId) async {
    try {
      return drivers.firstWhere((d) => d.id == driverId);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<DriverEntity> createDriver(
      String companyId, DriverEntity driver) async {
    drivers.add(driver);
    return driver;
  }

  @override
  Future<void> updateDriver(String companyId, DriverEntity driver) async {
    final idx = drivers.indexWhere((d) => d.id == driver.id);
    if (idx != -1) {
      drivers[idx] = driver;
    }
  }

  @override
  Future<void> deleteDriver(String companyId, String driverId) async {
    final idx = drivers.indexWhere((d) => d.id == driverId);
    if (idx != -1) {
      drivers[idx] = drivers[idx].copyWith(deletedAt: DateTime.now());
    }
  }

  @override
  Future<void> updateDriverStatus(
      String companyId, String driverId, String status) async {
    final idx = drivers.indexWhere((d) => d.id == driverId);
    if (idx != -1) {
      drivers[idx] = drivers[idx].copyWith(status: status);
    }
  }

  @override
  Future<void> linkVehicle(
    String companyId,
    String driverId,
    String? vehicleId,
    String? vehicleLicensePlate,
  ) async {
    final idx = drivers.indexWhere((d) => d.id == driverId);
    if (idx != -1) {
      final d = drivers[idx];
      drivers[idx] = DriverEntity(
        id: d.id,
        fullName: d.fullName,
        phone: d.phone,
        licenseNumber: d.licenseNumber,
        licenseExpiry: d.licenseExpiry,
        status: d.status,
        safetyScore: d.safetyScore,
        assignedVehicleId: vehicleId,
        assignedVehicleLicensePlate: vehicleLicensePlate,
        createdAt: d.createdAt,
        updatedAt: d.updatedAt,
        deletedAt: d.deletedAt,
      );
    }
  }
}

class MockVehicleRepository implements VehicleRepository {
  final List<VehicleEntity> vehicles;
  MockVehicleRepository({required this.vehicles});

  @override
  Stream<List<VehicleEntity>> watchVehicles(String companyId) =>
      Stream.value(vehicles);

  @override
  Future<List<VehicleEntity>> getVehicles(String companyId) async => vehicles;

  @override
  Future<VehicleEntity> createVehicle(
          String companyId, VehicleEntity vehicle) async =>
      vehicle;

  @override
  Future<void> updateVehicle(String companyId, VehicleEntity vehicle) async {}

  @override
  Future<void> deleteVehicle(String companyId, String vehicleId) async {}

  @override
  Future<void> assignDriver(
    String companyId,
    String vehicleId,
    String? driverId,
    String? driverName,
  ) async {
    final idx = vehicles.indexWhere((v) => v.id == vehicleId);
    if (idx != -1) {
      vehicles[idx] = vehicles[idx].copyWith(
        assignedDriverId: driverId,
        assignedDriverName: driverName,
      );
    }
  }

  @override
  Future<String> uploadComplianceDocument(
          String companyId, String vehicleId, String docType, file) async =>
      '';
}

class MockTripRepository implements TripRepository {
  final List<AuditLogEntity> auditLogs = [];

  @override
  Stream<List<TripEntity>> watchTrips(String companyId) => Stream.value([]);

  @override
  Future<List<TripEntity>> getTrips(String companyId) async => [];

  @override
  Future<TripEntity?> getTripById(String companyId, String tripId) async =>
      null;

  @override
  Future<TripEntity> createTrip(
      String companyId, TripEntity trip, AuditLogEntity initialAuditLog) async {
    auditLogs.add(initialAuditLog);
    return trip;
  }

  @override
  Future<void> updateTripStatus(String companyId, String tripId,
      String newStatus, String cbId, String cbName,
      {String? notes}) async {}

  @override
  Future<void> deleteTrip(
      String companyId, String tripId, AuditLogEntity deleteAuditLog) async {}

  @override
  Stream<List<AuditLogEntity>> watchAuditLogsForTrip(
          String companyId, String tripId) =>
      Stream.value([]);
}

void main() {
  group('Driver Providers Business Logic Tests', () {
    late List<DriverEntity> tDrivers;
    late List<VehicleEntity> tVehicles;
    final now = DateTime.now();

    setUp(() {
      tDrivers = [
        DriverEntity(
          id: 'driver_1',
          fullName: 'John Doe',
          phone: '1234567890',
          licenseNumber: 'LIC_123',
          licenseExpiry: now.add(const Duration(days: 30)),
          status: 'available',
          safetyScore: 95,
          createdAt: now,
          updatedAt: now,
        ),
      ];

      tVehicles = [
        VehicleEntity(
          id: 'vehicle_1',
          vin: 'VIN_1',
          licensePlate: 'PLATE_1',
          make: 'Volvo',
          model: 'VNL',
          year: 2023,
          status: 'active',
          fuelType: 'diesel',
          odometer: 1000,
          insuranceExpiry: now.add(const Duration(days: 30)),
          pucExpiry: now.add(const Duration(days: 30)),
          fitnessExpiry: now.add(const Duration(days: 30)),
          createdAt: now,
          updatedAt: now,
        ),
      ];
    });

    test('should save driver and write audit logs successfully', () async {
      final driverRepo = MockDriverRepository(drivers: []);
      final tripRepo = MockTripRepository();

      final container = ProviderContainer(
        overrides: [
          currentUserProvider.overrideWith(
            (ref) => UserEntity(
              uid: 'user_1',
              email: 'test@company.com',
              displayName: 'Operator John',
              role: 'admin',
              companyId: 'comp_1',
              createdAt: DateTime.now(),
            ),
          ),
          driverRepositoryProvider.overrideWithValue(driverRepo),
          tripRepositoryProvider.overrideWithValue(tripRepo),
        ],
      );

      final controller = container.read(driverFormControllerProvider.notifier);
      final newDriver = DriverEntity(
        id: '',
        fullName: 'Jane Doe',
        phone: '0987654321',
        licenseNumber: 'LIC_456',
        licenseExpiry: now,
        status: 'available',
        safetyScore: 100,
        createdAt: now,
        updatedAt: now,
      );

      final result = await controller.saveDriver(newDriver);
      expect(result, true);
      expect(driverRepo.drivers.length, 1);
      expect(driverRepo.drivers[0].fullName, 'Jane Doe');
      expect(tripRepo.auditLogs.length, 1);
      expect(tripRepo.auditLogs[0].action, 'driver_created');
    });

    test('should update driver status and write audit logs successfully',
        () async {
      final driverRepo = MockDriverRepository(drivers: tDrivers);
      final tripRepo = MockTripRepository();

      final container = ProviderContainer(
        overrides: [
          currentUserProvider.overrideWith(
            (ref) => UserEntity(
              uid: 'user_1',
              email: 'test@company.com',
              displayName: 'Operator John',
              role: 'admin',
              companyId: 'comp_1',
              createdAt: DateTime.now(),
            ),
          ),
          driverRepositoryProvider.overrideWithValue(driverRepo),
          tripRepositoryProvider.overrideWithValue(tripRepo),
        ],
      );

      final controller = container.read(driverListControllerProvider.notifier);
      final result = await controller.updateStatus('driver_1', 'on_duty');

      expect(result, true);
      expect(driverRepo.drivers[0].status, 'on_duty');
      expect(tripRepo.auditLogs.length, 1);
      expect(tripRepo.auditLogs[0].action, 'driver_status_changed');
    });

    test(
        'should handle bidirectional vehicle assignment and update vehicle links',
        () async {
      final driverRepo = MockDriverRepository(drivers: tDrivers);
      final vehicleRepo = MockVehicleRepository(vehicles: tVehicles);
      final tripRepo = MockTripRepository();

      final container = ProviderContainer(
        overrides: [
          currentUserProvider.overrideWith(
            (ref) => UserEntity(
              uid: 'user_1',
              email: 'test@company.com',
              displayName: 'Operator John',
              role: 'admin',
              companyId: 'comp_1',
              createdAt: DateTime.now(),
            ),
          ),
          driverRepositoryProvider.overrideWithValue(driverRepo),
          vehicleRepositoryProvider.overrideWithValue(vehicleRepo),
          tripRepositoryProvider.overrideWithValue(tripRepo),
          driversStreamProvider.overrideWith((ref) => Stream.value(tDrivers)),
        ],
      );

      final controller = container.read(driverListControllerProvider.notifier);
      final result =
          await controller.assignVehicle('driver_1', 'vehicle_1', 'PLATE_1');

      expect(result, true);
      // Link in Driver Repo
      expect(driverRepo.drivers[0].assignedVehicleId, 'vehicle_1');
      expect(driverRepo.drivers[0].assignedVehicleLicensePlate, 'PLATE_1');

      // Link in Vehicle Repo
      expect(vehicleRepo.vehicles[0].assignedDriverId, 'driver_1');
      expect(vehicleRepo.vehicles[0].assignedDriverName, 'John Doe');
    });
  });
}
