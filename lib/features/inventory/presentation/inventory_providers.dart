import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/presentation/auth_providers.dart';
import '../data/inventory_repository_impl.dart';
import '../domain/part_entity.dart';
import '../domain/supplier_entity.dart';
import '../domain/inventory_transaction_entity.dart';
import '../domain/inventory_repository.dart';
import '../../finance/domain/finance_transaction_entity.dart';
import '../../finance/presentation/finance_providers.dart';
import '../../trips/presentation/trip_providers.dart';
import '../../trips/domain/audit_log_entity.dart';
import '../../trips/domain/trip_entity.dart';

final inventoryRepositoryProvider = Provider<InventoryRepository>((ref) {
  return InventoryRepositoryImpl();
});

final partsStreamProvider = StreamProvider.autoDispose<List<PartEntity>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user?.companyId == null) return Stream.value([]);
  return ref.watch(inventoryRepositoryProvider).watchParts(user!.companyId!);
});

final suppliersStreamProvider =
    StreamProvider.autoDispose<List<SupplierEntity>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user?.companyId == null) return Stream.value([]);
  return ref
      .watch(inventoryRepositoryProvider)
      .watchSuppliers(user!.companyId!);
});

final inventoryTransactionsStreamProvider =
    StreamProvider.autoDispose<List<InventoryTransactionEntity>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user?.companyId == null) return Stream.value([]);
  return ref
      .watch(inventoryRepositoryProvider)
      .watchTransactions(user!.companyId!);
});

// ================= PART FORM CONTROLLER =================

class PartFormState {
  final bool isLoading;
  final String? errorMessage;
  final bool isCompleted;

  const PartFormState({
    this.isLoading = false,
    this.errorMessage,
    this.isCompleted = false,
  });

  PartFormState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool? isCompleted,
  }) {
    return PartFormState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}

class PartFormController extends StateNotifier<PartFormState> {
  final InventoryRepository _repository;
  final Ref _ref;

  PartFormController(
      {required InventoryRepository repository, required Ref ref})
      : _repository = repository,
        _ref = ref,
        super(const PartFormState());

  Future<bool> savePart(PartEntity part) async {
    state = state.copyWith(isLoading: true);
    try {
      final user = _ref.read(currentUserProvider);
      if (user?.companyId == null) throw Exception('No company authenticated.');
      final companyId = user!.companyId!;

      if (part.partNumber.trim().isEmpty)
        throw Exception('Please enter a part number.');
      if (part.name.trim().isEmpty)
        throw Exception('Please enter a part name.');
      if (part.minStockThreshold < 0)
        throw Exception('Minimum threshold cannot be negative.');

      PartEntity saved;
      if (part.id.isEmpty) {
        saved = await _repository.createPart(companyId, part);
      } else {
        await _repository.updatePart(companyId, part);
        saved = part;
      }

      // Write Audit Log
      final tripRepo = _ref.read(tripRepositoryProvider);
      final auditLog = AuditLogEntity(
        id: '',
        companyId: companyId,
        entityType: 'spare_part',
        entityId: saved.id,
        action: part.id.isEmpty ? 'part_created' : 'part_updated',
        description: 'Spare part ${saved.name} (${saved.partNumber}) saved.',
        userId: user.uid,
        userName: user.displayName.isEmpty ? 'Operator' : user.displayName,
        timestamp: DateTime.now(),
      );
      await tripRepo.createTrip(companyId, _dummyTrip(companyId), auditLog);

      state = const PartFormState(isCompleted: true);
      return true;
    } catch (e) {
      state = PartFormState(
          errorMessage: e.toString().replaceAll('Exception: ', ''));
      return false;
    }
  }
}

final partFormControllerProvider =
    StateNotifierProvider.autoDispose<PartFormController, PartFormState>((ref) {
  final repository = ref.watch(inventoryRepositoryProvider);
  return PartFormController(repository: repository, ref: ref);
});

class PartListController extends StateNotifier<AsyncValue<void>> {
  final InventoryRepository _repository;
  final Ref _ref;

  PartListController(
      {required InventoryRepository repository, required Ref ref})
      : _repository = repository,
        _ref = ref,
        super(const AsyncValue.data(null));

  Future<bool> deletePart(String partId) async {
    state = const AsyncValue.loading();
    try {
      final user = _ref.read(currentUserProvider);
      if (user?.companyId == null) throw Exception('No company authenticated.');
      final companyId = user!.companyId!;

      await _repository.deletePart(companyId, partId);

      // Write Audit Log
      final tripRepo = _ref.read(tripRepositoryProvider);
      final auditLog = AuditLogEntity(
        id: '',
        companyId: companyId,
        entityType: 'spare_part',
        entityId: partId,
        action: 'part_deleted',
        description: 'Spare part record soft-deleted.',
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

final partListControllerProvider =
    StateNotifierProvider.autoDispose<PartListController, AsyncValue<void>>(
        (ref) {
  final repository = ref.watch(inventoryRepositoryProvider);
  return PartListController(repository: repository, ref: ref);
});

// ================= SUPPLIER FORM CONTROLLER =================

class SupplierFormState {
  final bool isLoading;
  final String? errorMessage;
  final bool isCompleted;

  const SupplierFormState({
    this.isLoading = false,
    this.errorMessage,
    this.isCompleted = false,
  });

  SupplierFormState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool? isCompleted,
  }) {
    return SupplierFormState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}

class SupplierFormController extends StateNotifier<SupplierFormState> {
  final InventoryRepository _repository;
  final Ref _ref;

  SupplierFormController(
      {required InventoryRepository repository, required Ref ref})
      : _repository = repository,
        _ref = ref,
        super(const SupplierFormState());

  Future<bool> saveSupplier(SupplierEntity supplier) async {
    state = state.copyWith(isLoading: true);
    try {
      final user = _ref.read(currentUserProvider);
      if (user?.companyId == null) throw Exception('No company authenticated.');
      final companyId = user!.companyId!;

      if (supplier.name.trim().isEmpty)
        throw Exception('Please enter a supplier name.');
      if (supplier.contactPerson.trim().isEmpty)
        throw Exception('Please enter contact person.');

      SupplierEntity saved;
      if (supplier.id.isEmpty) {
        saved = await _repository.createSupplier(companyId, supplier);
      } else {
        await _repository.updateSupplier(companyId, supplier);
        saved = supplier;
      }

      // Write Audit Log
      final tripRepo = _ref.read(tripRepositoryProvider);
      final auditLog = AuditLogEntity(
        id: '',
        companyId: companyId,
        entityType: 'supplier',
        entityId: saved.id,
        action: supplier.id.isEmpty ? 'supplier_created' : 'supplier_updated',
        description: 'Supplier ${saved.name} saved.',
        userId: user.uid,
        userName: user.displayName.isEmpty ? 'Operator' : user.displayName,
        timestamp: DateTime.now(),
      );
      await tripRepo.createTrip(companyId, _dummyTrip(companyId), auditLog);

      state = const SupplierFormState(isCompleted: true);
      return true;
    } catch (e) {
      state = SupplierFormState(
          errorMessage: e.toString().replaceAll('Exception: ', ''));
      return false;
    }
  }
}

final supplierFormControllerProvider = StateNotifierProvider.autoDispose<
    SupplierFormController, SupplierFormState>((ref) {
  final repository = ref.watch(inventoryRepositoryProvider);
  return SupplierFormController(repository: repository, ref: ref);
});

class SupplierListController extends StateNotifier<AsyncValue<void>> {
  final InventoryRepository _repository;
  final Ref _ref;

  SupplierListController(
      {required InventoryRepository repository, required Ref ref})
      : _repository = repository,
        _ref = ref,
        super(const AsyncValue.data(null));

  Future<bool> deleteSupplier(String supplierId) async {
    state = const AsyncValue.loading();
    try {
      final user = _ref.read(currentUserProvider);
      if (user?.companyId == null) throw Exception('No company authenticated.');
      final companyId = user!.companyId!;

      await _repository.deleteSupplier(companyId, supplierId);

      // Write Audit Log
      final tripRepo = _ref.read(tripRepositoryProvider);
      final auditLog = AuditLogEntity(
        id: '',
        companyId: companyId,
        entityType: 'supplier',
        entityId: supplierId,
        action: 'supplier_deleted',
        description: 'Supplier record soft-deleted.',
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

final supplierListControllerProvider =
    StateNotifierProvider.autoDispose<SupplierListController, AsyncValue<void>>(
        (ref) {
  final repository = ref.watch(inventoryRepositoryProvider);
  return SupplierListController(repository: repository, ref: ref);
});

// ================= INVENTORY TRANSACTION CONTROLLER =================

class InventoryTransactionState {
  final bool isLoading;
  final String? errorMessage;
  final bool isCompleted;

  const InventoryTransactionState({
    this.isLoading = false,
    this.errorMessage,
    this.isCompleted = false,
  });

  InventoryTransactionState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool? isCompleted,
  }) {
    return InventoryTransactionState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}

class InventoryTransactionController
    extends StateNotifier<InventoryTransactionState> {
  final InventoryRepository _repository;
  final Ref _ref;

  InventoryTransactionController(
      {required InventoryRepository repository, required Ref ref})
      : _repository = repository,
        _ref = ref,
        super(const InventoryTransactionState());

  Future<bool> recordTransaction(InventoryTransactionEntity transaction) async {
    state = state.copyWith(isLoading: true);
    try {
      final user = _ref.read(currentUserProvider);
      if (user?.companyId == null) throw Exception('No company authenticated.');
      final companyId = user!.companyId!;

      if (transaction.partId.isEmpty)
        throw Exception('Please select a spare part.');
      if (transaction.quantity == 0)
        throw Exception('Quantity change must not be zero.');

      // Fetch the part to update stock quantity
      final part = await _repository.getPartById(companyId, transaction.partId);
      if (part == null) throw Exception('Spare part not found.');

      // Validate stock out / adjustment constraints
      final newQty = part.quantity + transaction.quantity;
      if (newQty < 0) {
        throw Exception(
            'Transaction failed. Out of stock! Available: ${part.quantity}.');
      }

      // Record transaction
      final savedTx =
          await _repository.createTransaction(companyId, transaction);

      // Update part stock quantity
      final updatedPart = part.copyWith(
        quantity: newQty,
        unitCost: transaction.type == 'stock_in'
            ? transaction.unitCost
            : part.unitCost,
      );
      await _repository.updatePart(companyId, updatedPart);

      // Integration: Finance Auto Expense (on stock_in)
      if (transaction.type == 'stock_in') {
        final financeRepo = _ref.read(financeRepositoryProvider);
        final tx = FinanceTransactionEntity(
          id: 'tx_part_${savedTx.id}',
          companyId: companyId,
          type: 'expense',
          category: 'parts',
          amount: savedTx.totalCost,
          paymentMode: 'cash',
          referenceNumber: savedTx.id,
          notes:
              'Automated inventory stock-in expense: ${savedTx.quantity}x ${savedTx.partName}.',
          transactionDate: savedTx.date,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final txAuditLog = AuditLogEntity(
          id: '',
          companyId: companyId,
          entityType: 'finance_transaction',
          entityId: tx.id,
          action: 'transaction_created',
          description: 'Automated part purchase cost ledger entry.',
          userId: user.uid,
          userName: user.displayName.isEmpty ? 'Operator' : user.displayName,
          timestamp: DateTime.now(),
        );
        await financeRepo.createTransaction(companyId, tx, txAuditLog);
      }

      // Write Audit Log
      final tripRepo = _ref.read(tripRepositoryProvider);
      final auditLog = AuditLogEntity(
        id: '',
        companyId: companyId,
        entityType: 'inventory_tx',
        entityId: savedTx.id,
        action: 'inventory_transaction_recorded',
        description:
            'Inventory ${savedTx.type.toUpperCase()}: ${savedTx.quantity}x ${savedTx.partName}.',
        userId: user.uid,
        userName: user.displayName.isEmpty ? 'Operator' : user.displayName,
        timestamp: DateTime.now(),
      );
      await tripRepo.createTrip(companyId, _dummyTrip(companyId), auditLog);

      state = const InventoryTransactionState(isCompleted: true);
      return true;
    } catch (e) {
      state = InventoryTransactionState(
          errorMessage: e.toString().replaceAll('Exception: ', ''));
      return false;
    }
  }
}

final inventoryTransactionControllerProvider =
    StateNotifierProvider.autoDispose<InventoryTransactionController,
        InventoryTransactionState>((ref) {
  final repository = ref.watch(inventoryRepositoryProvider);
  return InventoryTransactionController(repository: repository, ref: ref);
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
