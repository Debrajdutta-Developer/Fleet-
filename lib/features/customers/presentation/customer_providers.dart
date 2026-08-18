import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/presentation/auth_providers.dart';
import '../data/customer_repository_impl.dart';
import '../domain/customer_entity.dart';
import '../domain/contract_entity.dart';
import '../domain/invoice_entity.dart';
import '../domain/customer_repository.dart';
import '../../trips/presentation/trip_providers.dart';
import '../../trips/domain/audit_log_entity.dart';
import '../../trips/domain/trip_entity.dart';

final customerRepositoryProvider = Provider<CustomerRepository>((ref) {
  return CustomerRepositoryImpl();
});

final customersStreamProvider =
    StreamProvider.autoDispose<List<CustomerEntity>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user?.companyId == null) return Stream.value([]);
  return ref.watch(customerRepositoryProvider).watchCustomers(user!.companyId!);
});

final contractsStreamProvider =
    StreamProvider.autoDispose<List<ContractEntity>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user?.companyId == null) return Stream.value([]);
  return ref.watch(customerRepositoryProvider).watchContracts(user!.companyId!);
});

final invoicesStreamProvider =
    StreamProvider.autoDispose<List<InvoiceEntity>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user?.companyId == null) return Stream.value([]);
  return ref.watch(customerRepositoryProvider).watchInvoices(user!.companyId!);
});

// --- Customer Form State & Controller ---

class CustomerFormState {
  final bool isLoading;
  final String? errorMessage;
  final bool isCompleted;

  const CustomerFormState({
    this.isLoading = false,
    this.errorMessage,
    this.isCompleted = false,
  });

  CustomerFormState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool? isCompleted,
  }) {
    return CustomerFormState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}

class CustomerFormController extends StateNotifier<CustomerFormState> {
  final CustomerRepository _repository;
  final Ref _ref;

  CustomerFormController(
      {required CustomerRepository repository, required Ref ref})
      : _repository = repository,
        _ref = ref,
        super(const CustomerFormState());

  Future<bool> saveCustomer(CustomerEntity customer) async {
    state = state.copyWith(isLoading: true);
    try {
      final user = _ref.read(currentUserProvider);
      if (user?.companyId == null) throw Exception('No company authenticated.');
      final companyId = user!.companyId!;

      if (customer.name.trim().isEmpty) {
        throw Exception('Customer name cannot be empty.');
      }

      CustomerEntity savedCustomer;
      if (customer.id.isEmpty) {
        savedCustomer = await _repository.createCustomer(companyId, customer);
      } else {
        await _repository.updateCustomer(companyId, customer);
        savedCustomer = customer;
      }

      // Write Audit Log
      final tripRepo = _ref.read(tripRepositoryProvider);
      final auditLog = AuditLogEntity(
        id: '',
        companyId: companyId,
        entityType: 'customer',
        entityId: savedCustomer.id,
        action: customer.id.isEmpty ? 'customer_created' : 'customer_updated',
        description: customer.id.isEmpty
            ? 'Customer ${savedCustomer.name} was added.'
            : 'Customer ${savedCustomer.name} profiles were updated.',
        userId: user.uid,
        userName: user.displayName.isEmpty ? 'Operator' : user.displayName,
        timestamp: DateTime.now(),
      );
      await tripRepo.createTrip(companyId, _dummyTrip(companyId), auditLog);

      state = const CustomerFormState(isCompleted: true);
      return true;
    } catch (e) {
      state = CustomerFormState(
          errorMessage: e.toString().replaceAll('Exception: ', ''));
      return false;
    }
  }
}

final customerFormControllerProvider = StateNotifierProvider.autoDispose<
    CustomerFormController, CustomerFormState>((ref) {
  final repository = ref.watch(customerRepositoryProvider);
  return CustomerFormController(repository: repository, ref: ref);
});

// --- Customer List Controller ---

class CustomerListController extends StateNotifier<AsyncValue<void>> {
  final CustomerRepository _repository;
  final Ref _ref;

  CustomerListController(
      {required CustomerRepository repository, required Ref ref})
      : _repository = repository,
        _ref = ref,
        super(const AsyncValue.data(null));

  Future<bool> deleteCustomer(String customerId) async {
    state = const AsyncValue.loading();
    try {
      final user = _ref.read(currentUserProvider);
      if (user?.companyId == null) throw Exception('No company authenticated.');
      final companyId = user!.companyId!;

      await _repository.deleteCustomer(companyId, customerId);

      // Write Audit Log
      final tripRepo = _ref.read(tripRepositoryProvider);
      final auditLog = AuditLogEntity(
        id: '',
        companyId: companyId,
        entityType: 'customer',
        entityId: customerId,
        action: 'customer_deleted',
        description: 'Customer record soft-deleted.',
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

final customerListControllerProvider =
    StateNotifierProvider.autoDispose<CustomerListController, AsyncValue<void>>(
        (ref) {
  final repository = ref.watch(customerRepositoryProvider);
  return CustomerListController(repository: repository, ref: ref);
});

// --- Contract Form Controller ---

class ContractFormController extends StateNotifier<CustomerFormState> {
  final CustomerRepository _repository;
  final Ref _ref;

  ContractFormController(
      {required CustomerRepository repository, required Ref ref})
      : _repository = repository,
        _ref = ref,
        super(const CustomerFormState());

  Future<bool> saveContract(ContractEntity contract) async {
    state = state.copyWith(isLoading: true);
    try {
      final user = _ref.read(currentUserProvider);
      if (user?.companyId == null) throw Exception('No company authenticated.');
      final companyId = user!.companyId!;

      if (contract.contractNumber.trim().isEmpty) {
        throw Exception('Contract number cannot be empty.');
      }
      if (contract.customerId.isEmpty) {
        throw Exception('Customer must be selected.');
      }

      ContractEntity savedContract;
      if (contract.id.isEmpty) {
        savedContract = await _repository.createContract(companyId, contract);
      } else {
        await _repository.updateContract(companyId, contract);
        savedContract = contract;
      }

      // Write Audit Log
      final tripRepo = _ref.read(tripRepositoryProvider);
      final auditLog = AuditLogEntity(
        id: '',
        companyId: companyId,
        entityType: 'contract',
        entityId: savedContract.id,
        action: contract.id.isEmpty ? 'contract_created' : 'contract_updated',
        description: contract.id.isEmpty
            ? 'Contract ${savedContract.contractNumber} created.'
            : 'Contract ${savedContract.contractNumber} updated.',
        userId: user.uid,
        userName: user.displayName.isEmpty ? 'Operator' : user.displayName,
        timestamp: DateTime.now(),
      );
      await tripRepo.createTrip(companyId, _dummyTrip(companyId), auditLog);

      state = const CustomerFormState(isCompleted: true);
      return true;
    } catch (e) {
      state = CustomerFormState(
          errorMessage: e.toString().replaceAll('Exception: ', ''));
      return false;
    }
  }
}

final contractFormControllerProvider = StateNotifierProvider.autoDispose<
    ContractFormController, CustomerFormState>((ref) {
  final repository = ref.watch(customerRepositoryProvider);
  return ContractFormController(repository: repository, ref: ref);
});

// --- Contract List Controller ---

class ContractListController extends StateNotifier<AsyncValue<void>> {
  final CustomerRepository _repository;
  final Ref _ref;

  ContractListController(
      {required CustomerRepository repository, required Ref ref})
      : _repository = repository,
        _ref = ref,
        super(const AsyncValue.data(null));

  Future<bool> deleteContract(String contractId) async {
    state = const AsyncValue.loading();
    try {
      final user = _ref.read(currentUserProvider);
      if (user?.companyId == null) throw Exception('No company authenticated.');
      final companyId = user!.companyId!;

      await _repository.deleteContract(companyId, contractId);

      // Write Audit Log
      final tripRepo = _ref.read(tripRepositoryProvider);
      final auditLog = AuditLogEntity(
        id: '',
        companyId: companyId,
        entityType: 'contract',
        entityId: contractId,
        action: 'contract_deleted',
        description: 'Contract soft-deleted.',
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

final contractListControllerProvider =
    StateNotifierProvider.autoDispose<ContractListController, AsyncValue<void>>(
        (ref) {
  final repository = ref.watch(customerRepositoryProvider);
  return ContractListController(repository: repository, ref: ref);
});

// --- Invoice Form Controller ---

class InvoiceFormController extends StateNotifier<CustomerFormState> {
  final CustomerRepository _repository;
  final Ref _ref;

  InvoiceFormController(
      {required CustomerRepository repository, required Ref ref})
      : _repository = repository,
        _ref = ref,
        super(const CustomerFormState());

  Future<bool> saveInvoice(InvoiceEntity invoice) async {
    state = state.copyWith(isLoading: true);
    try {
      final user = _ref.read(currentUserProvider);
      if (user?.companyId == null) throw Exception('No company authenticated.');
      final companyId = user!.companyId!;

      if (invoice.id.isEmpty) {
        await _repository.createInvoice(companyId, invoice);
      } else {
        throw Exception('Invoices are auto-drafted and status-updated only.');
      }

      state = const CustomerFormState(isCompleted: true);
      return true;
    } catch (e) {
      state = CustomerFormState(
          errorMessage: e.toString().replaceAll('Exception: ', ''));
      return false;
    }
  }
}

final invoiceFormControllerProvider =
    StateNotifierProvider.autoDispose<InvoiceFormController, CustomerFormState>(
        (ref) {
  final repository = ref.watch(customerRepositoryProvider);
  return InvoiceFormController(repository: repository, ref: ref);
});

// --- Invoice List Controller ---

class InvoiceListController extends StateNotifier<AsyncValue<void>> {
  final CustomerRepository _repository;
  final Ref _ref;

  InvoiceListController(
      {required CustomerRepository repository, required Ref ref})
      : _repository = repository,
        _ref = ref,
        super(const AsyncValue.data(null));

  Future<bool> updateStatus(String invoiceId, String status) async {
    state = const AsyncValue.loading();
    try {
      final user = _ref.read(currentUserProvider);
      if (user?.companyId == null) throw Exception('No company authenticated.');
      final companyId = user!.companyId!;

      await _repository.updateInvoiceStatus(companyId, invoiceId, status);

      // Write Audit Log
      final tripRepo = _ref.read(tripRepositoryProvider);
      final auditLog = AuditLogEntity(
        id: '',
        companyId: companyId,
        entityType: 'invoice',
        entityId: invoiceId,
        action: 'invoice_status_updated',
        description: 'Invoice status updated to $status.',
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

  Future<bool> deleteInvoice(String invoiceId) async {
    state = const AsyncValue.loading();
    try {
      final user = _ref.read(currentUserProvider);
      if (user?.companyId == null) throw Exception('No company authenticated.');
      final companyId = user!.companyId!;

      await _repository.deleteInvoice(companyId, invoiceId);

      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final invoiceListControllerProvider =
    StateNotifierProvider.autoDispose<InvoiceListController, AsyncValue<void>>(
        (ref) {
  final repository = ref.watch(customerRepositoryProvider);
  return InvoiceListController(repository: repository, ref: ref);
});

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
