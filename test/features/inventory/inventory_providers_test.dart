import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import 'package:fleet_os_erp/features/auth/domain/user_entity.dart';
import 'package:fleet_os_erp/features/auth/presentation/auth_providers.dart';
import 'package:fleet_os_erp/features/inventory/domain/part_entity.dart';
import 'package:fleet_os_erp/features/inventory/domain/supplier_entity.dart';
import 'package:fleet_os_erp/features/inventory/domain/inventory_transaction_entity.dart';
import 'package:fleet_os_erp/features/inventory/domain/inventory_repository.dart';
import 'package:fleet_os_erp/features/inventory/presentation/inventory_providers.dart';
import 'package:fleet_os_erp/features/finance/domain/finance_transaction_entity.dart';
import 'package:fleet_os_erp/features/finance/domain/finance_repository.dart';
import 'package:fleet_os_erp/features/finance/presentation/finance_providers.dart';
import 'package:fleet_os_erp/features/trips/domain/audit_log_entity.dart';
import 'package:fleet_os_erp/features/trips/domain/trip_entity.dart';
import 'package:fleet_os_erp/features/trips/domain/trip_repository.dart';
import 'package:fleet_os_erp/features/trips/presentation/trip_providers.dart';
import 'package:fleet_os_erp/features/fleet_ops/domain/maintenance_entity.dart';
import 'package:fleet_os_erp/features/fleet_ops/domain/fuel_entity.dart';
import 'package:fleet_os_erp/features/fleet_ops/domain/compliance_entity.dart';
import 'package:fleet_os_erp/features/fleet_ops/domain/fleet_ops_repository.dart';
import 'package:fleet_os_erp/features/fleet_ops/presentation/fleet_ops_providers.dart';
import 'package:fleet_os_erp/features/vehicles/domain/vehicle_entity.dart';
import 'package:fleet_os_erp/features/vehicles/domain/vehicle_repository.dart';
import 'package:fleet_os_erp/features/vehicles/presentation/vehicle_providers.dart';

class MockInventoryRepository implements InventoryRepository {
  final List<PartEntity> parts;
  final List<SupplierEntity> suppliers;
  final List<InventoryTransactionEntity> transactions;

  MockInventoryRepository({
    required this.parts,
    required this.suppliers,
    required this.transactions,
  });

  @override
  Stream<List<PartEntity>> watchParts(String companyId) => Stream.value(parts);

  @override
  Future<List<PartEntity>> getParts(String companyId) async => parts;

  @override
  Future<PartEntity?> getPartById(String companyId, String partId) async {
    final list = parts.where((p) => p.id == partId).toList();
    return list.isNotEmpty ? list.first : null;
  }

  @override
  Future<PartEntity> createPart(String companyId, PartEntity part) async {
    final newPart =
        part.id.isEmpty ? part.copyWith(id: const Uuid().v4()) : part;
    parts.add(newPart);
    return newPart;
  }

  @override
  Future<void> updatePart(String companyId, PartEntity part) async {
    final idx = parts.indexWhere((p) => p.id == part.id);
    if (idx != -1) {
      parts[idx] = part;
    }
  }

  @override
  Future<void> deletePart(String companyId, String partId) async {
    parts.removeWhere((p) => p.id == partId);
  }

  @override
  Stream<List<SupplierEntity>> watchSuppliers(String companyId) =>
      Stream.value(suppliers);

  @override
  Future<List<SupplierEntity>> getSuppliers(String companyId) async =>
      suppliers;

  @override
  Future<SupplierEntity?> getSupplierById(
      String companyId, String supplierId) async {
    final list = suppliers.where((s) => s.id == supplierId).toList();
    return list.isNotEmpty ? list.first : null;
  }

  @override
  Future<SupplierEntity> createSupplier(
      String companyId, SupplierEntity supplier) async {
    final newSupplier = supplier.id.isEmpty
        ? supplier.copyWith(id: const Uuid().v4())
        : supplier;
    suppliers.add(newSupplier);
    return newSupplier;
  }

  @override
  Future<void> updateSupplier(String companyId, SupplierEntity supplier) async {
    final idx = suppliers.indexWhere((s) => s.id == supplier.id);
    if (idx != -1) {
      suppliers[idx] = supplier;
    }
  }

  @override
  Future<void> deleteSupplier(String companyId, String supplierId) async {
    suppliers.removeWhere((s) => s.id == supplierId);
  }

  @override
  Stream<List<InventoryTransactionEntity>> watchTransactions(
          String companyId) =>
      Stream.value(transactions);

  @override
  Future<List<InventoryTransactionEntity>> getTransactions(
          String companyId) async =>
      transactions;

  @override
  Future<InventoryTransactionEntity> createTransaction(
      String companyId, InventoryTransactionEntity transaction) async {
    final newTx = transaction.id.isEmpty
        ? transaction.copyWith(id: const Uuid().v4())
        : transaction;
    transactions.add(newTx);
    return newTx;
  }
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

class MockFinanceRepository implements FinanceRepository {
  final List<FinanceTransactionEntity> txs = [];

  @override
  Stream<List<FinanceTransactionEntity>> watchTransactions(String companyId) =>
      Stream.value(txs);

  @override
  Future<List<FinanceTransactionEntity>> getTransactions(
          String companyId) async =>
      txs;

  @override
  Future<FinanceTransactionEntity> createTransaction(String companyId,
      FinanceTransactionEntity transaction, AuditLogEntity auditLog) async {
    txs.add(transaction);
    return transaction;
  }

  @override
  Future<void> deleteTransaction(
      String companyId, String transactionId, AuditLogEntity auditLog) async {}

  @override
  Future<FinanceTransactionEntity?> getTransactionById(
    String companyId,
    String transactionId,
  ) async =>
      null;

  @override
  Stream<List<AuditLogEntity>> watchAuditLogsForFinance(String companyId) =>
      Stream.value([]);
}

class MockFleetOpsRepository implements FleetOpsRepository {
  @override
  Future<MaintenanceEntity> createMaintenanceLog(
          String companyId, MaintenanceEntity log) async =>
      log;
  @override
  Future<void> updateMaintenanceLog(
      String companyId, MaintenanceEntity log) async {}
  @override
  Future<void> deleteMaintenanceLog(String companyId, String logId) async {}
  @override
  Stream<List<MaintenanceEntity>> watchMaintenanceLogs(String companyId) =>
      Stream.value([]);
  @override
  Future<List<MaintenanceEntity>> getMaintenanceLogs(String companyId) async =>
      [];

  @override
  Future<FuelEntity> createFuelLog(
          String companyId, FuelEntity fuelLog) async =>
      fuelLog;
  @override
  Future<void> updateFuelLog(String companyId, FuelEntity fuelLog) async {}
  @override
  Future<void> deleteFuelLog(String companyId, String fuelLogId) async {}
  @override
  Stream<List<FuelEntity>> watchFuelLogs(String companyId) => Stream.value([]);
  @override
  Future<List<FuelEntity>> getFuelLogs(String companyId) async => [];
  @override
  Future<ComplianceEntity> createComplianceDocument(
          String companyId, ComplianceEntity document) async =>
      document;
  @override
  Future<void> updateComplianceDocument(
      String companyId, ComplianceEntity document) async {}
  @override
  Future<void> deleteComplianceDocument(
      String companyId, String documentId) async {}
  @override
  Stream<List<ComplianceEntity>> watchComplianceDocuments(String companyId) =>
      Stream.value([]);
  @override
  Future<List<ComplianceEntity>> getComplianceDocuments(
          String companyId) async =>
      [];
}

class MockVehicleRepository implements VehicleRepository {
  @override
  Future<void> updateVehicle(String companyId, VehicleEntity vehicle) async {}

  // Empty implementation to satisfy interface
  @override
  Stream<List<VehicleEntity>> watchVehicles(String companyId) =>
      Stream.value([]);
  @override
  Future<List<VehicleEntity>> getVehicles(String companyId) async => [];
  @override
  Future<VehicleEntity> createVehicle(
          String companyId, VehicleEntity vehicle) async =>
      vehicle;
  @override
  Future<void> deleteVehicle(String companyId, String vehicleId) async {}
  @override
  Future<void> assignDriver(String companyId, String vehicleId,
      String? driverId, String? driverName) async {}
  @override
  Future<String> uploadComplianceDocument(String companyId, String vehicleId,
          String docType, dynamic file) async =>
      '';
}

void main() {
  group('Inventory Module Business Logic & Integration Tests', () {
    final now = DateTime.now();

    test('should save spare part details and write audit log', () async {
      final partsList = <PartEntity>[];
      final inventoryRepo = MockInventoryRepository(
          parts: partsList, suppliers: [], transactions: []);
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
              createdAt: now,
            ),
          ),
          inventoryRepositoryProvider.overrideWithValue(inventoryRepo),
          tripRepositoryProvider.overrideWithValue(tripRepo),
        ],
      );

      final controller = container.read(partFormControllerProvider.notifier);
      final newPart = PartEntity(
        id: '',
        companyId: 'comp_1',
        partNumber: 'ENG-101',
        name: 'Oil Filter',
        description: 'Engine oil filter',
        category: 'engine',
        quantity: 0,
        minStockThreshold: 5,
        unitCost: 15.0,
        createdAt: now,
        updatedAt: now,
      );

      final result = await controller.savePart(newPart);

      expect(result, true);
      expect(partsList.length, 1);
      expect(partsList.first.partNumber, 'ENG-101');
      expect(tripRepo.auditLogs.length, 1);
      expect(tripRepo.auditLogs.first.action, 'part_created');
    });

    test(
        'should record stock transaction, update quantity, and record finance ledger on stock_in',
        () async {
      final initialPart = PartEntity(
        id: 'part_123',
        companyId: 'comp_1',
        partNumber: 'ENG-101',
        name: 'Oil Filter',
        description: 'Engine oil filter',
        category: 'engine',
        quantity: 10,
        minStockThreshold: 5,
        unitCost: 15.0,
        createdAt: now,
        updatedAt: now,
      );

      final partsList = <PartEntity>[initialPart];
      final txList = <InventoryTransactionEntity>[];
      final inventoryRepo = MockInventoryRepository(
          parts: partsList, suppliers: [], transactions: txList);
      final tripRepo = MockTripRepository();
      final financeRepo = MockFinanceRepository();

      final container = ProviderContainer(
        overrides: [
          currentUserProvider.overrideWith(
            (ref) => UserEntity(
              uid: 'user_1',
              email: 'test@company.com',
              displayName: 'Operator John',
              role: 'admin',
              companyId: 'comp_1',
              createdAt: now,
            ),
          ),
          inventoryRepositoryProvider.overrideWithValue(inventoryRepo),
          tripRepositoryProvider.overrideWithValue(tripRepo),
          financeRepositoryProvider.overrideWithValue(financeRepo),
        ],
      );

      final controller =
          container.read(inventoryTransactionControllerProvider.notifier);
      final tx = InventoryTransactionEntity(
        id: '',
        companyId: 'comp_1',
        partId: 'part_123',
        partName: 'Oil Filter',
        type: 'stock_in',
        quantity: 5,
        unitCost: 16.0,
        totalCost: 80.0,
        notes: 'Restocking parts',
        date: now,
        createdAt: now,
        updatedAt: now,
      );

      final result = await controller.recordTransaction(tx);

      expect(result, true);
      // Verify quantity is updated: 10 + 5 = 15
      expect(partsList.first.quantity, 15);
      expect(partsList.first.unitCost, 16.0);
      expect(txList.length, 1);

      // Verify automated finance ledger
      expect(financeRepo.txs.length, 1);
      expect(financeRepo.txs.first.category, 'parts');
      expect(financeRepo.txs.first.amount, 80.0);
    });

    test('should auto-deduct stock during maintenance logging', () async {
      final initialPart = PartEntity(
        id: 'part_123',
        companyId: 'comp_1',
        partNumber: 'ENG-101',
        name: 'Oil Filter',
        description: 'Engine oil filter',
        category: 'engine',
        quantity: 10,
        minStockThreshold: 5,
        unitCost: 15.0,
        createdAt: now,
        updatedAt: now,
      );

      final partsList = <PartEntity>[initialPart];
      final txList = <InventoryTransactionEntity>[];
      final inventoryRepo = MockInventoryRepository(
          parts: partsList, suppliers: [], transactions: txList);
      final tripRepo = MockTripRepository();
      final financeRepo = MockFinanceRepository();
      final fleetOpsRepo = MockFleetOpsRepository();
      final vehicleRepo = MockVehicleRepository();

      final container = ProviderContainer(
        overrides: [
          currentUserProvider.overrideWith(
            (ref) => UserEntity(
              uid: 'user_1',
              email: 'test@company.com',
              displayName: 'Operator John',
              role: 'admin',
              companyId: 'comp_1',
              createdAt: now,
            ),
          ),
          inventoryRepositoryProvider.overrideWithValue(inventoryRepo),
          tripRepositoryProvider.overrideWithValue(tripRepo),
          financeRepositoryProvider.overrideWithValue(financeRepo),
          fleetOpsRepositoryProvider.overrideWithValue(fleetOpsRepo),
          vehicleRepositoryProvider.overrideWithValue(vehicleRepo),
        ],
      );

      final controller =
          container.read(maintenanceFormControllerProvider.notifier);
      final maint = MaintenanceEntity(
        id: '',
        companyId: 'comp_1',
        vehicleId: 'veh_1',
        vehicleLicensePlate: 'ABC-123',
        type: 'preventative',
        description: 'Scheduled servicing with oil filter replacement',
        cost: 200.0,
        odometer: 15000.0,
        date: now,
        createdAt: now,
        updatedAt: now,
        partId: 'part_123',
        partName: 'Oil Filter',
        partQuantity: 2,
      );

      final result = await controller.saveMaintenanceLog(maint);

      expect(result, true);
      // Verify quantity is auto-deducted: 10 - 2 = 8
      expect(partsList.first.quantity, 8);
      // Verify stock_out transaction is recorded
      expect(txList.length, 1);
      expect(txList.first.type, 'stock_out');
      expect(txList.first.quantity, -2);
    });
  });
}
