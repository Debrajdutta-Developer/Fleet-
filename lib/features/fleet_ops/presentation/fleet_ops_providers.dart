import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/presentation/auth_providers.dart';
import '../data/fleet_ops_repository_impl.dart';
import '../domain/fuel_entity.dart';
import '../domain/maintenance_entity.dart';
import '../domain/compliance_entity.dart';
import '../domain/fleet_ops_repository.dart';
import '../../finance/domain/finance_transaction_entity.dart';
import '../../finance/presentation/finance_providers.dart';
import '../../vehicles/domain/vehicle_entity.dart';
import '../../vehicles/presentation/vehicle_providers.dart';
import '../../trips/presentation/trip_providers.dart';
import '../../trips/domain/audit_log_entity.dart';
import '../../trips/domain/trip_entity.dart';
import '../../inventory/presentation/inventory_providers.dart';
import '../../inventory/domain/inventory_transaction_entity.dart';

final fleetOpsRepositoryProvider = Provider<FleetOpsRepository>((ref) {
  return FleetOpsRepositoryImpl();
});

final fuelLogsStreamProvider =
    StreamProvider.autoDispose<List<FuelEntity>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user?.companyId == null) return Stream.value([]);
  return ref.watch(fleetOpsRepositoryProvider).watchFuelLogs(user!.companyId!);
});

final maintenanceLogsStreamProvider =
    StreamProvider.autoDispose<List<MaintenanceEntity>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user?.companyId == null) return Stream.value([]);
  return ref
      .watch(fleetOpsRepositoryProvider)
      .watchMaintenanceLogs(user!.companyId!);
});

final complianceDocumentsStreamProvider =
    StreamProvider.autoDispose<List<ComplianceEntity>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user?.companyId == null) return Stream.value([]);
  return ref
      .watch(fleetOpsRepositoryProvider)
      .watchComplianceDocuments(user!.companyId!);
});

// ================= FUEL FORM CONTROLLER =================

class FuelFormState {
  final bool isLoading;
  final String? errorMessage;
  final bool isCompleted;

  const FuelFormState({
    this.isLoading = false,
    this.errorMessage,
    this.isCompleted = false,
  });

  FuelFormState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool? isCompleted,
  }) {
    return FuelFormState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}

class FuelFormController extends StateNotifier<FuelFormState> {
  final FleetOpsRepository _repository;
  final Ref _ref;

  FuelFormController({required FleetOpsRepository repository, required Ref ref})
      : _repository = repository,
        _ref = ref,
        super(const FuelFormState());

  Future<bool> saveFuelLog(FuelEntity fuelLog) async {
    state = state.copyWith(isLoading: true);
    try {
      final user = _ref.read(currentUserProvider);
      if (user?.companyId == null) throw Exception('No company authenticated.');
      final companyId = user!.companyId!;

      if (fuelLog.vehicleId.isEmpty)
        throw Exception('Please select a vehicle.');
      if (fuelLog.driverId.isEmpty) throw Exception('Please select a driver.');
      if (fuelLog.fuelQty <= 0)
        throw Exception('Fuel quantity must be greater than zero.');
      if (fuelLog.amount <= 0)
        throw Exception('Fuel amount cost must be greater than zero.');

      FuelEntity saved;
      if (fuelLog.id.isEmpty) {
        saved = await _repository.createFuelLog(companyId, fuelLog);
      } else {
        await _repository.updateFuelLog(companyId, fuelLog);
        saved = fuelLog;
      }

      // Automatically create or update Finance Transaction
      final financeRepo = _ref.read(financeRepositoryProvider);
      final tx = FinanceTransactionEntity(
        id: 'tx_fuel_${saved.id}',
        companyId: companyId,
        type: 'expense',
        category: 'diesel',
        amount: saved.amount,
        paymentMode: 'cash',
        referenceNumber: saved.id,
        vehicleId: saved.vehicleId,
        vehicleLicensePlate: saved.vehicleLicensePlate,
        notes:
            'Automated fuel cost expense entry for vehicle ${saved.vehicleLicensePlate}.',
        transactionDate: saved.date,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final txAuditLog = AuditLogEntity(
        id: '',
        companyId: companyId,
        entityType: 'finance_transaction',
        entityId: tx.id,
        action: 'transaction_created',
        description:
            'Automated fuel cost transaction for vehicle ${saved.vehicleLicensePlate}.',
        userId: user.uid,
        userName: user.displayName.isEmpty ? 'Operator' : user.displayName,
        timestamp: DateTime.now(),
      );

      // Overwrite or create
      await financeRepo.createTransaction(companyId, tx, txAuditLog);

      // Write Audit Log
      final tripRepo = _ref.read(tripRepositoryProvider);
      final auditLog = AuditLogEntity(
        id: '',
        companyId: companyId,
        entityType: 'fuel_log',
        entityId: saved.id,
        action: fuelLog.id.isEmpty ? 'fuel_log_created' : 'fuel_log_updated',
        description:
            'Fuel log of ${saved.fuelQty}L logged for ${saved.vehicleLicensePlate}.',
        userId: user.uid,
        userName: user.displayName.isEmpty ? 'Operator' : user.displayName,
        timestamp: DateTime.now(),
      );
      await tripRepo.createTrip(companyId, _dummyTrip(companyId), auditLog);

      state = const FuelFormState(isCompleted: true);
      return true;
    } catch (e) {
      state = FuelFormState(
          errorMessage: e.toString().replaceAll('Exception: ', ''));
      return false;
    }
  }
}

final fuelFormControllerProvider =
    StateNotifierProvider.autoDispose<FuelFormController, FuelFormState>((ref) {
  final repository = ref.watch(fleetOpsRepositoryProvider);
  return FuelFormController(repository: repository, ref: ref);
});

class FuelListController extends StateNotifier<AsyncValue<void>> {
  final FleetOpsRepository _repository;
  final Ref _ref;

  FuelListController({required FleetOpsRepository repository, required Ref ref})
      : _repository = repository,
        _ref = ref,
        super(const AsyncValue.data(null));

  Future<bool> deleteFuelLog(String fuelLogId) async {
    state = const AsyncValue.loading();
    try {
      final user = _ref.read(currentUserProvider);
      if (user?.companyId == null) throw Exception('No company authenticated.');
      final companyId = user!.companyId!;

      await _repository.deleteFuelLog(companyId, fuelLogId);

      final txAuditLog = AuditLogEntity(
        id: '',
        companyId: companyId,
        entityType: 'finance_transaction',
        entityId: 'tx_fuel_$fuelLogId',
        action: 'transaction_deleted',
        description: 'Automated fuel cost transaction deleted.',
        userId: user.uid,
        userName: user.displayName.isEmpty ? 'Operator' : user.displayName,
        timestamp: DateTime.now(),
      );

      // Automatically soft-delete corresponding finance transaction
      final financeRepo = _ref.read(financeRepositoryProvider);
      await financeRepo.deleteTransaction(
          companyId, 'tx_fuel_$fuelLogId', txAuditLog);

      // Write Audit Log
      final tripRepo = _ref.read(tripRepositoryProvider);
      final auditLog = AuditLogEntity(
        id: '',
        companyId: companyId,
        entityType: 'fuel_log',
        entityId: fuelLogId,
        action: 'fuel_log_deleted',
        description: 'Fuel log record soft-deleted.',
        userId: user.uid,
        userName: user.displayName.isEmpty ? 'Operator' : user.displayName,
        timestamp: DateTime.now(),
      );
      await tripRepo.createTrip(companyId, _dummyTrip(companyId), auditLog);

      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final fuelListControllerProvider =
    StateNotifierProvider.autoDispose<FuelListController, AsyncValue<void>>(
        (ref) {
  final repository = ref.watch(fleetOpsRepositoryProvider);
  return FuelListController(repository: repository, ref: ref);
});

// ================= MAINTENANCE FORM CONTROLLER =================

class MaintenanceFormState {
  final bool isLoading;
  final String? errorMessage;
  final bool isCompleted;

  const MaintenanceFormState({
    this.isLoading = false,
    this.errorMessage,
    this.isCompleted = false,
  });

  MaintenanceFormState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool? isCompleted,
  }) {
    return MaintenanceFormState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}

class MaintenanceFormController extends StateNotifier<MaintenanceFormState> {
  final FleetOpsRepository _repository;
  final Ref _ref;

  MaintenanceFormController(
      {required FleetOpsRepository repository, required Ref ref})
      : _repository = repository,
        _ref = ref,
        super(const MaintenanceFormState());

  Future<bool> saveMaintenanceLog(MaintenanceEntity maintLog) async {
    state = state.copyWith(isLoading: true);
    try {
      final user = _ref.read(currentUserProvider);
      if (user?.companyId == null) throw Exception('No company authenticated.');
      final companyId = user!.companyId!;

      if (maintLog.vehicleId.isEmpty)
        throw Exception('Please select a vehicle.');
      if (maintLog.description.trim().isEmpty)
        throw Exception('Please enter a description.');
      if (maintLog.cost <= 0)
        throw Exception('Maintenance cost must be greater than zero.');

      MaintenanceEntity saved;
      if (maintLog.id.isEmpty) {
        saved = await _repository.createMaintenanceLog(companyId, maintLog);
      } else {
        await _repository.updateMaintenanceLog(companyId, maintLog);
        saved = maintLog;
      }

      // Automatically create or update Finance Transaction
      final financeRepo = _ref.read(financeRepositoryProvider);
      final tx = FinanceTransactionEntity(
        id: 'tx_maint_${saved.id}',
        companyId: companyId,
        type: 'expense',
        category: 'repair',
        amount: saved.cost,
        paymentMode: 'cash',
        referenceNumber: saved.id,
        vehicleId: saved.vehicleId,
        vehicleLicensePlate: saved.vehicleLicensePlate,
        vendorId: saved.vendorId,
        vendorName: saved.vendorName,
        notes: 'Automated maintenance repair cost entry: ${saved.description}.',
        transactionDate: saved.date,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final txAuditLog = AuditLogEntity(
        id: '',
        companyId: companyId,
        entityType: 'finance_transaction',
        entityId: tx.id,
        action: 'transaction_created',
        description:
            'Automated maintenance transaction for vehicle ${saved.vehicleLicensePlate}.',
        userId: user.uid,
        userName: user.displayName.isEmpty ? 'Operator' : user.displayName,
        timestamp: DateTime.now(),
      );

      await financeRepo.createTransaction(companyId, tx, txAuditLog);

      // Automatically deduct stock if parts are used
      if (saved.partId != null &&
          saved.partQuantity != null &&
          saved.partQuantity! > 0) {
        final inventoryRepo = _ref.read(inventoryRepositoryProvider);
        final part = await inventoryRepo.getPartById(companyId, saved.partId!);
        if (part != null) {
          final partTx = InventoryTransactionEntity(
            id: 'tx_maint_part_${saved.id}',
            companyId: companyId,
            partId: saved.partId!,
            partName: saved.partName ?? part.name,
            type: 'stock_out',
            quantity: -saved.partQuantity!,
            unitCost: part.unitCost,
            totalCost: saved.partQuantity! * part.unitCost,
            referenceId: saved.id,
            notes:
                'Automatic deduction during maintenance job for vehicle ${saved.vehicleLicensePlate}.',
            date: saved.date,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
          await inventoryRepo.createTransaction(companyId, partTx);
          await inventoryRepo.updatePart(
            companyId,
            part.copyWith(quantity: part.quantity - saved.partQuantity!),
          );
        }
      }

      // Write Audit Log
      final tripRepo = _ref.read(tripRepositoryProvider);
      final auditLog = AuditLogEntity(
        id: '',
        companyId: companyId,
        entityType: 'maintenance_log',
        entityId: saved.id,
        action:
            maintLog.id.isEmpty ? 'maintenance_created' : 'maintenance_updated',
        description:
            'Maintenance logged for ${saved.vehicleLicensePlate}: ${saved.description}.',
        userId: user.uid,
        userName: user.displayName.isEmpty ? 'Operator' : user.displayName,
        timestamp: DateTime.now(),
      );
      await tripRepo.createTrip(companyId, _dummyTrip(companyId), auditLog);

      state = const MaintenanceFormState(isCompleted: true);
      return true;
    } catch (e) {
      state = MaintenanceFormState(
          errorMessage: e.toString().replaceAll('Exception: ', ''));
      return false;
    }
  }
}

final maintenanceFormControllerProvider = StateNotifierProvider.autoDispose<
    MaintenanceFormController, MaintenanceFormState>((ref) {
  final repository = ref.watch(fleetOpsRepositoryProvider);
  return MaintenanceFormController(repository: repository, ref: ref);
});

class MaintenanceListController extends StateNotifier<AsyncValue<void>> {
  final FleetOpsRepository _repository;
  final Ref _ref;

  MaintenanceListController(
      {required FleetOpsRepository repository, required Ref ref})
      : _repository = repository,
        _ref = ref,
        super(const AsyncValue.data(null));

  Future<bool> deleteMaintenanceLog(String maintLogId) async {
    state = const AsyncValue.loading();
    try {
      final user = _ref.read(currentUserProvider);
      if (user?.companyId == null) throw Exception('No company authenticated.');
      final companyId = user!.companyId!;

      await _repository.deleteMaintenanceLog(companyId, maintLogId);

      final txAuditLog = AuditLogEntity(
        id: '',
        companyId: companyId,
        entityType: 'finance_transaction',
        entityId: 'tx_maint_$maintLogId',
        action: 'transaction_deleted',
        description: 'Automated maintenance transaction deleted.',
        userId: user.uid,
        userName: user.displayName.isEmpty ? 'Operator' : user.displayName,
        timestamp: DateTime.now(),
      );

      // Automatically soft-delete corresponding finance transaction
      final financeRepo = _ref.read(financeRepositoryProvider);
      await financeRepo.deleteTransaction(
          companyId, 'tx_maint_$maintLogId', txAuditLog);

      // Write Audit Log
      final tripRepo = _ref.read(tripRepositoryProvider);
      final auditLog = AuditLogEntity(
        id: '',
        companyId: companyId,
        entityType: 'maintenance_log',
        entityId: maintLogId,
        action: 'maintenance_deleted',
        description: 'Maintenance log record soft-deleted.',
        userId: user.uid,
        userName: user.displayName.isEmpty ? 'Operator' : user.displayName,
        timestamp: DateTime.now(),
      );
      await tripRepo.createTrip(companyId, _dummyTrip(companyId), auditLog);

      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final maintenanceListControllerProvider = StateNotifierProvider.autoDispose<
    MaintenanceListController, AsyncValue<void>>((ref) {
  final repository = ref.watch(fleetOpsRepositoryProvider);
  return MaintenanceListController(repository: repository, ref: ref);
});

// ================= COMPLIANCE FORM CONTROLLER =================

class ComplianceFormState {
  final bool isLoading;
  final String? errorMessage;
  final bool isCompleted;

  const ComplianceFormState({
    this.isLoading = false,
    this.errorMessage,
    this.isCompleted = false,
  });

  ComplianceFormState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool? isCompleted,
  }) {
    return ComplianceFormState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}

class ComplianceFormController extends StateNotifier<ComplianceFormState> {
  final FleetOpsRepository _repository;
  final Ref _ref;

  ComplianceFormController(
      {required FleetOpsRepository repository, required Ref ref})
      : _repository = repository,
        _ref = ref,
        super(const ComplianceFormState());

  Future<bool> saveComplianceDocument(ComplianceEntity doc) async {
    state = state.copyWith(isLoading: true);
    try {
      final user = _ref.read(currentUserProvider);
      if (user?.companyId == null) throw Exception('No company authenticated.');
      final companyId = user!.companyId!;

      if (doc.vehicleId.isEmpty) throw Exception('Please select a vehicle.');
      if (doc.documentNumber.trim().isEmpty)
        throw Exception('Please enter a document number.');

      ComplianceEntity saved;
      if (doc.id.isEmpty) {
        saved = await _repository.createComplianceDocument(companyId, doc);
      } else {
        await _repository.updateComplianceDocument(companyId, doc);
        saved = doc;
      }

      // Synchronize vehicle statutory compliance field in vehicle repository
      final vehicleRepo = _ref.read(vehicleRepositoryProvider);
      final vehicles = await vehicleRepo.getVehicles(companyId);
      final vehicleIdx = vehicles.indexWhere((v) => v.id == saved.vehicleId);
      if (vehicleIdx != -1) {
        final vehicle = vehicles[vehicleIdx];
        VehicleEntity updatedVehicle = vehicle;
        if (saved.documentType == 'insurance') {
          updatedVehicle = vehicle.copyWith(insuranceExpiry: saved.expiryDate);
        } else if (saved.documentType == 'puc') {
          updatedVehicle = vehicle.copyWith(pucExpiry: saved.expiryDate);
        } else if (saved.documentType == 'fitness') {
          updatedVehicle = vehicle.copyWith(fitnessExpiry: saved.expiryDate);
        }
        await vehicleRepo.updateVehicle(companyId, updatedVehicle);
      }

      // Write Audit Log
      final tripRepo = _ref.read(tripRepositoryProvider);
      final auditLog = AuditLogEntity(
        id: '',
        companyId: companyId,
        entityType: 'compliance_doc',
        entityId: saved.id,
        action: doc.id.isEmpty ? 'compliance_created' : 'compliance_updated',
        description:
            'Compliance document (${saved.documentType.toUpperCase()}) added for ${saved.vehicleLicensePlate}.',
        userId: user.uid,
        userName: user.displayName.isEmpty ? 'Operator' : user.displayName,
        timestamp: DateTime.now(),
      );
      await tripRepo.createTrip(companyId, _dummyTrip(companyId), auditLog);

      state = const ComplianceFormState(isCompleted: true);
      return true;
    } catch (e) {
      state = ComplianceFormState(
          errorMessage: e.toString().replaceAll('Exception: ', ''));
      return false;
    }
  }
}

final complianceFormControllerProvider = StateNotifierProvider.autoDispose<
    ComplianceFormController, ComplianceFormState>((ref) {
  final repository = ref.watch(fleetOpsRepositoryProvider);
  return ComplianceFormController(repository: repository, ref: ref);
});

class ComplianceListController extends StateNotifier<AsyncValue<void>> {
  final FleetOpsRepository _repository;
  final Ref _ref;

  ComplianceListController(
      {required FleetOpsRepository repository, required Ref ref})
      : _repository = repository,
        _ref = ref,
        super(const AsyncValue.data(null));

  Future<bool> deleteComplianceDocument(String complianceId) async {
    state = const AsyncValue.loading();
    try {
      final user = _ref.read(currentUserProvider);
      if (user?.companyId == null) throw Exception('No company authenticated.');
      final companyId = user!.companyId!;

      await _repository.deleteComplianceDocument(companyId, complianceId);

      // Write Audit Log
      final tripRepo = _ref.read(tripRepositoryProvider);
      final auditLog = AuditLogEntity(
        id: '',
        companyId: companyId,
        entityType: 'compliance_doc',
        entityId: complianceId,
        action: 'compliance_deleted',
        description: 'Compliance document record soft-deleted.',
        userId: user.uid,
        userName: user.displayName.isEmpty ? 'Operator' : user.displayName,
        timestamp: DateTime.now(),
      );
      await tripRepo.createTrip(companyId, _dummyTrip(companyId), auditLog);

      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final complianceListControllerProvider = StateNotifierProvider.autoDispose<
    ComplianceListController, AsyncValue<void>>((ref) {
  final repository = ref.watch(fleetOpsRepositoryProvider);
  return ComplianceListController(repository: repository, ref: ref);
});

// ================= DUMMY TRIP HELPERS =================

TripEntity _dummyTrip(String companyId) {
  return TripEntity(
    id: '',
    companyId: companyId,
    vehicleId: '',
    vehicleLicensePlate: '',
    driverId: '',
    driverName: '',
    customerId: '',
    customerName: '',
    pickupLocation: '',
    deliveryLocation: '',
    cargoType: '',
    coalQuantity: 0.0,
    freightAmount: 0.0,
    advancePayment: 0.0,
    permitExpense: 0.0,
    status: 'draft',
    statusHistory: [],
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );
}
