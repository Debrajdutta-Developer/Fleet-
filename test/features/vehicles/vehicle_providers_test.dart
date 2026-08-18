import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fleet_os_erp/features/auth/presentation/auth_providers.dart';
import 'package:fleet_os_erp/features/auth/domain/user_entity.dart';
import 'package:fleet_os_erp/features/vehicles/domain/vehicle_entity.dart';
import 'package:fleet_os_erp/features/vehicles/domain/vehicle_repository.dart';
import 'package:fleet_os_erp/features/vehicles/presentation/vehicle_providers.dart';
import 'package:fleet_os_erp/features/drivers/domain/driver_entity.dart';
import 'package:fleet_os_erp/features/drivers/domain/driver_repository.dart';
import 'package:fleet_os_erp/features/drivers/presentation/driver_providers.dart';

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
      String companyId, VehicleEntity vehicle) async {
    vehicles.add(vehicle);
    return vehicle;
  }

  @override
  Future<void> updateVehicle(String companyId, VehicleEntity vehicle) async {
    final idx = vehicles.indexWhere((v) => v.id == vehicle.id);
    if (idx != -1) {
      vehicles[idx] = vehicle;
    }
  }

  @override
  Future<void> deleteVehicle(String companyId, String vehicleId) async {
    final idx = vehicles.indexWhere((v) => v.id == vehicleId);
    if (idx != -1) {
      vehicles[idx] =
          vehicles[idx].copyWith(deletedAt: DateTime.now(), status: 'archived');
    }
  }

  @override
  Future<void> assignDriver(String companyId, String vehicleId,
      String? driverId, String? driverName) async {
    final idx = vehicles.indexWhere((v) => v.id == vehicleId);
    if (idx != -1) {
      vehicles[idx] = vehicles[idx].copyWith(
        assignedDriverId: driverId,
        assignedDriverName: driverName,
      );
    }
  }

  @override
  Future<String> uploadComplianceDocument(String companyId, String vehicleId,
          String docType, dynamic file) async =>
      '';
}

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
  Future<void> deleteDriver(String companyId, String driverId) async {}

  @override
  Future<void> updateDriverStatus(
      String companyId, String driverId, String status) async {}

  @override
  Future<void> linkVehicle(String companyId, String driverId, String? vehicleId,
      String? vehicleLicensePlate) async {
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

void main() {
  group('VehicleComplianceHelper Tests', () {
    final tActiveVehicle = VehicleEntity(
      id: 'v_1',
      vin: '12345678901234567',
      licensePlate: 'NY-884-AB',
      make: 'Volvo',
      model: 'VNL 860',
      year: 2023,
      status: 'active',
      fuelType: 'diesel',
      odometer: 100.0,
      lastServiceDate: DateTime.now().subtract(const Duration(days: 30)),
      insuranceExpiry: DateTime.now().add(const Duration(days: 45)), // Valid
      pucExpiry: DateTime.now().add(const Duration(days: 20)), // Valid
      fitnessExpiry: DateTime.now().add(const Duration(days: 60)), // Valid
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final tExpiredVehicle = VehicleEntity(
      id: 'v_2',
      vin: '12345678901234567',
      licensePlate: 'NY-884-AC',
      make: 'Volvo',
      model: 'VNL 860',
      year: 2023,
      status: 'active',
      fuelType: 'diesel',
      odometer: 200.0,
      lastServiceDate:
          DateTime.now().subtract(const Duration(days: 200)), // Overdue
      insuranceExpiry:
          DateTime.now().subtract(const Duration(days: 2)), // Expired
      pucExpiry: DateTime.now().subtract(const Duration(days: 5)), // Expired
      fitnessExpiry:
          DateTime.now().subtract(const Duration(days: 10)), // Expired
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    test('should validate active non-expired documents correctly', () {
      expect(VehicleComplianceHelper.isInsuranceExpired(tActiveVehicle), false);
      expect(VehicleComplianceHelper.isPucExpired(tActiveVehicle), false);
      expect(VehicleComplianceHelper.isFitnessExpired(tActiveVehicle), false);
      expect(VehicleComplianceHelper.isServiceOverdue(tActiveVehicle), false);
    });

    test('should detect expired compliance documents correctly', () {
      expect(VehicleComplianceHelper.isInsuranceExpired(tExpiredVehicle), true);
      expect(VehicleComplianceHelper.isPucExpired(tExpiredVehicle), true);
      expect(VehicleComplianceHelper.isFitnessExpired(tExpiredVehicle), true);
      expect(VehicleComplianceHelper.isServiceOverdue(tExpiredVehicle), true);
    });

    test('should identify document warning thresholds correctly', () {
      final warningVehicle = tActiveVehicle.copyWith(
        insuranceExpiry:
            DateTime.now().add(const Duration(days: 10)), // Warning (0-30 days)
        pucExpiry:
            DateTime.now().add(const Duration(days: 5)), // Warning (0-15 days)
      );
      expect(VehicleComplianceHelper.isInsuranceWarning(warningVehicle), true);
      expect(VehicleComplianceHelper.isPucWarning(warningVehicle), true);
    });
  });

  group('Vehicle Lifecycle State Machine Business Rules Tests', () {
    final now = DateTime.now();

    final tActiveVehicle = VehicleEntity(
      id: 'v_active',
      vin: 'VIN123',
      licensePlate: 'LP1',
      make: 'Volvo',
      model: 'VNL',
      year: 2023,
      status: 'active',
      fuelType: 'diesel',
      odometer: 100.0,
      insuranceExpiry: now.add(const Duration(days: 30)),
      pucExpiry: now.add(const Duration(days: 30)),
      fitnessExpiry: now.add(const Duration(days: 30)),
      createdAt: now,
      updatedAt: now,
    );

    final tRegVehicle = VehicleEntity(
      id: 'v_reg',
      vin: 'VIN456',
      licensePlate: 'LP2',
      make: 'Volvo',
      model: 'VNL',
      year: 2023,
      status: 'registration',
      fuelType: 'diesel',
      odometer: 0.0,
      insuranceExpiry: now.add(const Duration(days: 30)),
      pucExpiry: now.add(const Duration(days: 30)),
      fitnessExpiry: now.add(const Duration(days: 30)),
      createdAt: now,
      updatedAt: now,
    );

    final tExpiredVehicle = VehicleEntity(
      id: 'v_expired',
      vin: 'VIN789',
      licensePlate: 'LP3',
      make: 'Volvo',
      model: 'VNL',
      year: 2023,
      status: 'registration',
      fuelType: 'diesel',
      odometer: 10.0,
      insuranceExpiry: now.subtract(const Duration(days: 10)), // Expired
      pucExpiry: now.add(const Duration(days: 30)),
      fitnessExpiry: now.add(const Duration(days: 30)),
      createdAt: now,
      updatedAt: now,
    );

    final tIdleVehicle = VehicleEntity(
      id: 'v_idle',
      vin: 'VIN101',
      licensePlate: 'LP4',
      make: 'Volvo',
      model: 'VNL',
      year: 2023,
      status: 'idle',
      fuelType: 'diesel',
      odometer: 1000.0,
      insuranceExpiry: now.add(const Duration(days: 30)),
      pucExpiry: now.add(const Duration(days: 30)),
      fitnessExpiry: now.add(const Duration(days: 30)),
      createdAt: now,
      updatedAt: now,
    );

    test(
        'should allow transition from registration to active when safety documents are valid',
        () async {
      final repo = MockVehicleRepository(vehicles: [tRegVehicle]);
      final container = ProviderContainer(
        overrides: [
          currentUserProvider.overrideWith((ref) => UserEntity(
                uid: 'u_1',
                email: 'operator@fleet.com',
                displayName: 'Operator',
                role: 'admin',
                companyId: 'c_1',
                createdAt: now,
              )),
          vehicleRepositoryProvider.overrideWithValue(repo),
        ],
      );

      final controller = container.read(vehicleFormControllerProvider.notifier);
      final activeTarget = tRegVehicle.copyWith(status: 'active');

      final success = await controller.saveVehicle(activeTarget);
      expect(success, true);
      expect(repo.vehicles[0].status, 'active');
    });

    test(
        'should block transition from registration to active if safety documents are expired',
        () async {
      final repo = MockVehicleRepository(vehicles: [tExpiredVehicle]);
      final container = ProviderContainer(
        overrides: [
          currentUserProvider.overrideWith((ref) => UserEntity(
                uid: 'u_1',
                email: 'operator@fleet.com',
                displayName: 'Operator',
                role: 'admin',
                companyId: 'c_1',
                createdAt: now,
              )),
          vehicleRepositoryProvider.overrideWithValue(repo),
        ],
      );

      final controller = container.read(vehicleFormControllerProvider.notifier);
      final activeTarget = tExpiredVehicle.copyWith(status: 'active');

      final success = await controller.saveVehicle(activeTarget);
      expect(success, false);
      expect(container.read(vehicleFormControllerProvider).errorMessage,
          contains('expired or missing'));
    });

    test(
        'should decouple driver when vehicle status transitions to maintenance or sold',
        () async {
      final vehicleWithDriver = tActiveVehicle.copyWith(
        assignedDriverId: 'd_1',
        assignedDriverName: 'Robert Jenkins',
      );
      final driver = DriverEntity(
        id: 'd_1',
        fullName: 'Robert Jenkins',
        phone: '123',
        licenseNumber: 'L123',
        licenseExpiry: now.add(const Duration(days: 100)),
        status: 'on_duty',
        safetyScore: 90.0,
        assignedVehicleId: 'v_active',
        createdAt: now,
        updatedAt: now,
      );

      final vehicleRepo = MockVehicleRepository(vehicles: [vehicleWithDriver]);
      final driverRepo = MockDriverRepository(drivers: [driver]);

      final container = ProviderContainer(
        overrides: [
          currentUserProvider.overrideWith((ref) => UserEntity(
                uid: 'u_1',
                email: 'operator@fleet.com',
                displayName: 'Operator',
                role: 'admin',
                companyId: 'c_1',
                createdAt: now,
              )),
          vehicleRepositoryProvider.overrideWithValue(vehicleRepo),
          driverRepositoryProvider.overrideWithValue(driverRepo),
        ],
      );

      final controller = container.read(vehicleFormControllerProvider.notifier);
      final maintenanceVehicle =
          vehicleWithDriver.copyWith(status: 'maintenance');

      final success = await controller.saveVehicle(maintenanceVehicle);
      expect(success, true);

      // Verify driver is decoupled on vehicle document
      expect(vehicleRepo.vehicles[0].assignedDriverId, null);
      expect(vehicleRepo.vehicles[0].assignedDriverName, null);

      // Verify vehicle is unlinked on driver document
      expect(driverRepo.drivers[0].assignedVehicleId, null);
    });

    test(
        'should block driver assignment if vehicle status is registration, sold, or maintenance',
        () async {
      final repo = MockVehicleRepository(vehicles: [
        tRegVehicle,
        tActiveVehicle.copyWith(id: 'v_sold', status: 'sold'),
        tActiveVehicle.copyWith(id: 'v_maint', status: 'maintenance'),
      ]);

      final container = ProviderContainer(
        overrides: [
          currentUserProvider.overrideWith((ref) => UserEntity(
                uid: 'u_1',
                email: 'operator@fleet.com',
                displayName: 'Operator',
                role: 'admin',
                companyId: 'c_1',
                createdAt: now,
              )),
          vehicleRepositoryProvider.overrideWithValue(repo),
        ],
      );

      final listController =
          container.read(vehicleListControllerProvider.notifier);

      // 1. Block registration
      var success = await listController.assignDriver('v_reg', 'd_1', 'Robert');
      expect(success, false);

      // 2. Block sold
      success = await listController.assignDriver('v_sold', 'd_1', 'Robert');
      expect(success, false);

      // 3. Block maintenance
      success = await listController.assignDriver('v_maint', 'd_1', 'Robert');
      expect(success, false);
    });

    test(
        'should transition status from idle to active automatically upon driver assignment',
        () async {
      final repo = MockVehicleRepository(vehicles: [tIdleVehicle]);
      final container = ProviderContainer(
        overrides: [
          currentUserProvider.overrideWith((ref) => UserEntity(
                uid: 'u_1',
                email: 'operator@fleet.com',
                displayName: 'Operator',
                role: 'admin',
                companyId: 'c_1',
                createdAt: now,
              )),
          vehicleRepositoryProvider.overrideWithValue(repo),
        ],
      );

      final listController =
          container.read(vehicleListControllerProvider.notifier);
      final success =
          await listController.assignDriver('v_idle', 'd_1', 'Robert Jenkins');

      expect(success, true);
      expect(repo.vehicles[0].status, 'active');
      expect(repo.vehicles[0].assignedDriverId, 'd_1');
    });
  });
}
