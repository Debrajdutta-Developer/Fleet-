import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fleet_os_erp/features/auth/presentation/auth_providers.dart';
import 'package:fleet_os_erp/features/auth/domain/user_entity.dart';
import 'package:fleet_os_erp/features/fleet_ops/domain/fuel_entity.dart';
import 'package:fleet_os_erp/features/fleet_ops/domain/maintenance_entity.dart';
import 'package:fleet_os_erp/features/fleet_ops/domain/compliance_entity.dart';
import 'package:fleet_os_erp/features/fleet_ops/domain/fleet_ops_repository.dart';
import 'package:fleet_os_erp/features/fleet_ops/presentation/fleet_ops_providers.dart';
import 'package:fleet_os_erp/features/finance/domain/finance_transaction_entity.dart';
import 'package:fleet_os_erp/features/finance/domain/finance_repository.dart';
import 'package:fleet_os_erp/features/finance/presentation/finance_providers.dart';
import 'package:fleet_os_erp/features/vehicles/domain/vehicle_entity.dart';
import 'package:fleet_os_erp/features/vehicles/domain/vehicle_repository.dart';
import 'package:fleet_os_erp/features/vehicles/presentation/vehicle_providers.dart';
import 'package:fleet_os_erp/features/trips/domain/trip_repository.dart';
import 'package:fleet_os_erp/features/trips/presentation/trip_providers.dart';
import 'package:fleet_os_erp/features/trips/domain/trip_entity.dart';
import 'package:fleet_os_erp/features/trips/domain/audit_log_entity.dart';

class MockFleetOpsRepository implements FleetOpsRepository {
  final List<FuelEntity> fuelLogs;
  final List<MaintenanceEntity> maintLogs;
  final List<ComplianceEntity> docs;

  MockFleetOpsRepository({
    required this.fuelLogs,
    required this.maintLogs,
    required this.docs,
  });

  @override
  Stream<List<FuelEntity>> watchFuelLogs(String companyId) =>
      Stream.value(fuelLogs);

  @override
  Future<List<FuelEntity>> getFuelLogs(String companyId) async => fuelLogs;

  @override
  Future<FuelEntity> createFuelLog(String companyId, FuelEntity fuelLog) async {
    fuelLogs.add(fuelLog);
    return fuelLog;
  }

  @override
  Future<void> updateFuelLog(String companyId, FuelEntity fuelLog) async {
    final idx = fuelLogs.indexWhere((f) => f.id == fuelLog.id);
    if (idx != -1) {
      fuelLogs[idx] = fuelLog;
    }
  }

  @override
  Future<void> deleteFuelLog(String companyId, String fuelLogId) async {
    final idx = fuelLogs.indexWhere((f) => f.id == fuelLogId);
    if (idx != -1) {
      fuelLogs[idx] = fuelLogs[idx].copyWith(deletedAt: DateTime.now());
    }
  }

  @override
  Stream<List<MaintenanceEntity>> watchMaintenanceLogs(String companyId) =>
      Stream.value(maintLogs);

  @override
  Future<List<MaintenanceEntity>> getMaintenanceLogs(String companyId) async =>
      maintLogs;

  @override
  Future<MaintenanceEntity> createMaintenanceLog(
      String companyId, MaintenanceEntity maintLog) async {
    maintLogs.add(maintLog);
    return maintLog;
  }

  @override
  Future<void> updateMaintenanceLog(
      String companyId, MaintenanceEntity maintLog) async {
    final idx = maintLogs.indexWhere((m) => m.id == maintLog.id);
    if (idx != -1) {
      maintLogs[idx] = maintLog;
    }
  }

  @override
  Future<void> deleteMaintenanceLog(String companyId, String maintLogId) async {
    final idx = maintLogs.indexWhere((m) => m.id == maintLogId);
    if (idx != -1) {
      maintLogs[idx] = maintLogs[idx].copyWith(deletedAt: DateTime.now());
    }
  }

  @override
  Stream<List<ComplianceEntity>> watchComplianceDocuments(String companyId) =>
      Stream.value(docs);

  @override
  Future<List<ComplianceEntity>> getComplianceDocuments(
          String companyId) async =>
      docs;

  @override
  Future<ComplianceEntity> createComplianceDocument(
      String companyId, ComplianceEntity compliance) async {
    docs.add(compliance);
    return compliance;
  }

  @override
  Future<void> updateComplianceDocument(
      String companyId, ComplianceEntity compliance) async {
    final idx = docs.indexWhere((d) => d.id == compliance.id);
    if (idx != -1) {
      docs[idx] = compliance;
    }
  }

  @override
  Future<void> deleteComplianceDocument(
      String companyId, String complianceId) async {
    final idx = docs.indexWhere((d) => d.id == complianceId);
    if (idx != -1) {
      docs[idx] = docs[idx].copyWith(deletedAt: DateTime.now());
    }
  }
}

class MockFinanceRepository implements FinanceRepository {
  final List<FinanceTransactionEntity> txs = [];
  final List<AuditLogEntity> auditLogs = [];

  @override
  Stream<List<FinanceTransactionEntity>> watchTransactions(String companyId) =>
      Stream.value(txs);

  @override
  Future<List<FinanceTransactionEntity>> getTransactions(
          String companyId) async =>
      txs;

  @override
  Future<FinanceTransactionEntity?> getTransactionById(
      String companyId, String transactionId) async {
    try {
      return txs.firstWhere((t) => t.id == transactionId);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<FinanceTransactionEntity> createTransaction(
    String companyId,
    FinanceTransactionEntity transaction,
    AuditLogEntity auditLog,
  ) async {
    final idx = txs.indexWhere((t) => t.id == transaction.id);
    if (idx != -1) {
      txs[idx] = transaction;
    } else {
      txs.add(transaction);
    }
    auditLogs.add(auditLog);
    return transaction;
  }

  @override
  Future<void> deleteTransaction(
    String companyId,
    String transactionId,
    AuditLogEntity auditLog,
  ) async {
    final idx = txs.indexWhere((t) => t.id == transactionId);
    if (idx != -1) {
      txs[idx] = txs[idx].copyWith(deletedAt: DateTime.now());
    }
    auditLogs.add(auditLog);
  }

  @override
  Stream<List<AuditLogEntity>> watchAuditLogsForFinance(String companyId) =>
      Stream.value(auditLogs);
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
  Future<void> deleteVehicle(String companyId, String vehicleId) async {}

  @override
  Future<void> assignDriver(String companyId, String vehicleId,
      String? driverId, String? driverName) async {}

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

  Stream<List<AuditLogEntity>> watchAuditLogs(String companyId) =>
      Stream.value(auditLogs);
}

void main() {
  group('Fleet Operations Providers Business Logic Tests', () {
    final now = DateTime.now();

    final tVehicle = VehicleEntity(
      id: 'veh_1',
      vin: 'VIN123456789',
      licensePlate: 'ABC-123',
      make: 'Tesla',
      model: 'Semi',
      year: 2024,
      status: 'available',
      fuelType: 'electric',
      odometer: 10000.0,
      insuranceExpiry: now,
      pucExpiry: now,
      fitnessExpiry: now,
      createdAt: now,
      updatedAt: now,
    );

    test('should save fuel log, write finance transaction, and log audit log',
        () async {
      final fleetOpsRepo =
          MockFleetOpsRepository(fuelLogs: [], maintLogs: [], docs: []);
      final financeRepo = MockFinanceRepository();
      final vehicleRepo = MockVehicleRepository(vehicles: [tVehicle]);
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
          fleetOpsRepositoryProvider.overrideWithValue(fleetOpsRepo),
          financeRepositoryProvider.overrideWithValue(financeRepo),
          vehicleRepositoryProvider.overrideWithValue(vehicleRepo),
          tripRepositoryProvider.overrideWithValue(tripRepo),
        ],
      );

      final controller = container.read(fuelFormControllerProvider.notifier);
      final newFuel = FuelEntity(
        id: '',
        companyId: 'comp_1',
        vehicleId: 'veh_1',
        vehicleLicensePlate: 'ABC-123',
        driverId: 'drv_1',
        driverName: 'Driver Sam',
        fuelQty: 50.0,
        amount: 150.0,
        odometer: 12000.0,
        date: now,
        createdAt: now,
        updatedAt: now,
      );

      final result = await controller.saveFuelLog(newFuel);

      expect(result, true);
      expect(fleetOpsRepo.fuelLogs.length, 1);
      expect(financeRepo.txs.length, 1);
      expect(financeRepo.txs[0].category, 'diesel');
      expect(financeRepo.txs[0].amount, 150.0);
      expect(
          tripRepo.auditLogs.any((a) => a.action == 'fuel_log_created'), true);
    });

    test(
        'should save maintenance log, write finance transaction, and log audit log',
        () async {
      final fleetOpsRepo =
          MockFleetOpsRepository(fuelLogs: [], maintLogs: [], docs: []);
      final financeRepo = MockFinanceRepository();
      final vehicleRepo = MockVehicleRepository(vehicles: [tVehicle]);
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
          fleetOpsRepositoryProvider.overrideWithValue(fleetOpsRepo),
          financeRepositoryProvider.overrideWithValue(financeRepo),
          vehicleRepositoryProvider.overrideWithValue(vehicleRepo),
          tripRepositoryProvider.overrideWithValue(tripRepo),
        ],
      );

      final controller =
          container.read(maintenanceFormControllerProvider.notifier);
      final newMaint = MaintenanceEntity(
        id: '',
        companyId: 'comp_1',
        vehicleId: 'veh_1',
        vehicleLicensePlate: 'ABC-123',
        type: 'preventative',
        description: 'Engine Tuning',
        cost: 500.0,
        odometer: 12500.0,
        date: now,
        createdAt: now,
        updatedAt: now,
      );

      final result = await controller.saveMaintenanceLog(newMaint);

      expect(result, true);
      expect(fleetOpsRepo.maintLogs.length, 1);
      expect(financeRepo.txs.length, 1);
      expect(financeRepo.txs[0].category, 'repair');
      expect(financeRepo.txs[0].amount, 500.0);
      expect(tripRepo.auditLogs.any((a) => a.action == 'maintenance_created'),
          true);
    });

    test('should save compliance doc and update vehicle exipry date', () async {
      final fleetOpsRepo =
          MockFleetOpsRepository(fuelLogs: [], maintLogs: [], docs: []);
      final financeRepo = MockFinanceRepository();
      final vehicleRepo = MockVehicleRepository(vehicles: [tVehicle]);
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
          fleetOpsRepositoryProvider.overrideWithValue(fleetOpsRepo),
          financeRepositoryProvider.overrideWithValue(financeRepo),
          vehicleRepositoryProvider.overrideWithValue(vehicleRepo),
          tripRepositoryProvider.overrideWithValue(tripRepo),
        ],
      );

      final controller =
          container.read(complianceFormControllerProvider.notifier);
      final futureExpiry = now.add(const Duration(days: 300));
      final newDoc = ComplianceEntity(
        id: '',
        companyId: 'comp_1',
        vehicleId: 'veh_1',
        vehicleLicensePlate: 'ABC-123',
        documentType: 'insurance',
        documentNumber: 'INS-9999',
        expiryDate: futureExpiry,
        createdAt: now,
        updatedAt: now,
      );

      final result = await controller.saveComplianceDocument(newDoc);

      expect(result, true);
      expect(fleetOpsRepo.docs.length, 1);
      expect(vehicleRepo.vehicles[0].insuranceExpiry, futureExpiry);
      expect(tripRepo.auditLogs.any((a) => a.action == 'compliance_created'),
          true);
    });
  });
}
