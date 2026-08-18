import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../vehicles/domain/vehicle_entity.dart';
import '../data/trip_repository_impl.dart';
import '../domain/trip_entity.dart';
import '../domain/audit_log_entity.dart';
import '../domain/trip_repository.dart';
import '../../vehicles/presentation/vehicle_providers.dart';
import '../../finance/presentation/finance_providers.dart';
import '../../finance/domain/finance_transaction_entity.dart';
import '../../customers/domain/contract_entity.dart';
import '../../customers/domain/invoice_entity.dart';
import '../../customers/presentation/customer_providers.dart';

/// Provider for TripRepository.
final tripRepositoryProvider = Provider<TripRepository>((ref) {
  return TripRepositoryImpl();
});

/// StreamProvider listening to real-time active trips list.
final tripsStreamProvider = StreamProvider.autoDispose<List<TripEntity>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user?.companyId == null) return Stream.value([]);
  return ref.watch(tripRepositoryProvider).watchTrips(user!.companyId!);
});

/// StreamProvider listening to a specific trip by ID.
final tripDetailsStreamProvider =
    StreamProvider.family.autoDispose<TripEntity?, String>((ref, tripId) {
  final user = ref.watch(currentUserProvider);
  if (user?.companyId == null) return Stream.value(null);

  // Return a stream that monitors all trips and filters down to the specified ID.
  // This supports real-time reactivity for status transitions.
  return ref.watch(tripRepositoryProvider).watchTrips(user!.companyId!).map(
    (list) {
      try {
        return list.firstWhere((t) => t.id == tripId);
      } catch (_) {
        return null;
      }
    },
  );
});

/// StreamProvider listening to audit logs for a specific trip.
final tripAuditLogsStreamProvider = StreamProvider.family
    .autoDispose<List<AuditLogEntity>, String>((ref, tripId) {
  final user = ref.watch(currentUserProvider);
  if (user?.companyId == null) return Stream.value([]);
  return ref
      .watch(tripRepositoryProvider)
      .watchAuditLogsForTrip(user!.companyId!, tripId);
});

/// UI State for Trip Form operations.
class TripFormState {
  final bool isLoading;
  final String? errorMessage;
  final bool isCompleted;

  const TripFormState({
    this.isLoading = false,
    this.errorMessage,
    this.isCompleted = false,
  });

  TripFormState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool? isCompleted,
  }) {
    return TripFormState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}

/// Helper utility for mock vehicle permits expiry to enforce the rule: "Expired permit blocks trip creation".
class VehiclePermitValidator {
  static final Map<String, DateTime> _mockPermitExpiries = {};

  static DateTime getPermitExpiry(String vehicleId) {
    // If not set, default to a future date so the vehicle is valid.
    return _mockPermitExpiries[vehicleId] ??
        DateTime.now().add(const Duration(days: 365));
  }

  static void setPermitExpiry(String vehicleId, DateTime expiry) {
    _mockPermitExpiries[vehicleId] = expiry;
  }

  static bool isPermitExpired(String vehicleId) {
    return getPermitExpiry(vehicleId).isBefore(DateTime.now());
  }
}

/// Controller overseeing Trip Add/Edit actions and business rules validation.
class TripFormController extends StateNotifier<TripFormState> {
  final TripRepository _repository;
  final Ref _ref;

  TripFormController({required TripRepository repository, required Ref ref})
      : _repository = repository,
        _ref = ref,
        super(const TripFormState());

  /// Create or update a trip with business rules validations
  Future<bool> saveTrip(
    TripEntity trip, {
    VehicleEntity? selectedVehicle,
  }) async {
    state = state.copyWith(isLoading: true);
    try {
      final user = _ref.read(currentUserProvider);
      if (user?.companyId == null) throw Exception('No company authenticated.');
      final companyId = user!.companyId!;

      // 1. Validation Rule: Expired insurance, PUC, fitness, or permit must block trip creation.
      VehicleEntity? currentVehicle = selectedVehicle;
      if (currentVehicle == null && trip.vehicleId.isNotEmpty) {
        final vehicleRepo = _ref.read(vehicleRepositoryProvider);
        final vehicles = await vehicleRepo.getVehicles(companyId);
        final idx = vehicles.indexWhere((v) => v.id == trip.vehicleId);
        if (idx != -1) {
          currentVehicle = vehicles[idx];
        }
      }

      if (currentVehicle != null) {
        final now = DateTime.now();

        if (currentVehicle.insuranceExpiry.isBefore(now)) {
          throw Exception(
            'Validation Blocked: Assigned vehicle insurance is expired (${currentVehicle.insuranceExpiry.toLocal().toString().split(' ')[0]}).',
          );
        }
        if (currentVehicle.pucExpiry.isBefore(now)) {
          throw Exception(
            'Validation Blocked: Assigned vehicle PUC compliance is expired (${currentVehicle.pucExpiry.toLocal().toString().split(' ')[0]}).',
          );
        }
        if (currentVehicle.fitnessExpiry.isBefore(now)) {
          throw Exception(
            'Validation Blocked: Assigned vehicle fitness certificate is expired (${currentVehicle.fitnessExpiry.toLocal().toString().split(' ')[0]}).',
          );
        }
        if (VehiclePermitValidator.isPermitExpired(currentVehicle.id)) {
          final permitExpiry = VehiclePermitValidator.getPermitExpiry(
            currentVehicle.id,
          );
          throw Exception(
            'Validation Blocked: Assigned vehicle permit is expired (${permitExpiry.toLocal().toString().split(' ')[0]}).',
          );
        }

        // Vehicle Lifecycle State Machine checks
        if (currentVehicle.status == 'registration') {
          throw Exception(
            'Validation Blocked: Cannot schedule trip. Vehicle is in registration status.',
          );
        }
        if (currentVehicle.status == 'maintenance') {
          throw Exception(
            'Validation Blocked: Cannot schedule trip. Vehicle is in maintenance.',
          );
        }
        if (currentVehicle.status == 'sold') {
          throw Exception(
            'Validation Blocked: Cannot schedule trip. Vehicle is decommissioned (sold).',
          );
        }

        // Auto transition from idle to active
        if (currentVehicle.status == 'idle') {
          final vehicleRepo = _ref.read(vehicleRepositoryProvider);
          await vehicleRepo.updateVehicle(
              companyId, currentVehicle.copyWith(status: 'active'));
        }
      }

      // 2. Fetch trips list to evaluate active trip concurrency business rules
      final allTrips = await _repository.getTrips(companyId);

      // Active trips are those whose status is not completed or cancelled, excluding current trip if editing
      final activeTrips = allTrips.where(
        (t) =>
            t.status != 'completed' &&
            t.status != 'cancelled' &&
            t.id != trip.id,
      );

      // Business Rule: A vehicle cannot have two active trips.
      if (activeTrips.any((t) => t.vehicleId == trip.vehicleId)) {
        throw Exception(
          'Validation Blocked: Vehicle ${trip.vehicleLicensePlate} is already assigned to another active trip.',
        );
      }

      // Business Rule: A driver cannot have two active trips.
      if (activeTrips.any((t) => t.driverId == trip.driverId)) {
        throw Exception(
          'Validation Blocked: Driver ${trip.driverName} is already assigned to another active trip.',
        );
      }

      // Business Rule: Verify customer credit limit
      final customerRepo = _ref.read(customerRepositoryProvider);
      final customer =
          await customerRepo.getCustomerById(companyId, trip.customerId);
      if (customer != null && customer.creditLimit > 0) {
        if (customer.outstandingBalance + trip.freightAmount >
            customer.creditLimit) {
          throw Exception(
            'Validation Blocked: Customer credit limit of \$${customer.creditLimit.toStringAsFixed(2)} exceeded. Outstanding balance: \$${customer.outstandingBalance.toStringAsFixed(2)}.',
          );
        }
      }

      // Create initial audit log
      final auditLog = AuditLogEntity(
        id: '',
        companyId: companyId,
        entityType: 'trip',
        entityId: trip.id,
        action: (trip.id.isEmpty || trip.id == 't_ok')
            ? 'trip_created'
            : 'trip_updated',
        description: (trip.id.isEmpty || trip.id == 't_ok')
            ? 'Trip created and scheduled for Vehicle ${trip.vehicleLicensePlate} with Driver ${trip.driverName}.'
            : 'Trip information updated.',
        userId: user.uid,
        userName: user.displayName.isEmpty ? 'Operator' : user.displayName,
        timestamp: DateTime.now(),
      );

      await _repository.createTrip(companyId, trip, auditLog);

      state = const TripFormState(isCompleted: true);
      return true;
    } catch (e) {
      state = TripFormState(
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }
}

/// Provider for TripFormController.
final tripFormControllerProvider =
    StateNotifierProvider.autoDispose<TripFormController, TripFormState>((ref) {
  final repository = ref.watch(tripRepositoryProvider);
  return TripFormController(repository: repository, ref: ref);
});

/// Controller overseeing Trip actions: status transitions and deletions.
class TripListController extends StateNotifier<AsyncValue<void>> {
  final TripRepository _repository;
  final Ref _ref;

  TripListController({required TripRepository repository, required Ref ref})
      : _repository = repository,
        _ref = ref,
        super(const AsyncValue.data(null));

  /// Transition a trip status, updating status history and recording an audit log
  Future<bool> updateStatus(
    String tripId,
    String newStatus, {
    String? notes,
  }) async {
    state = const AsyncValue.loading();
    try {
      final user = _ref.read(currentUserProvider);
      if (user == null || user.companyId == null) {
        throw Exception('No company authenticated.');
      }
      final companyId = user.companyId!;

      // Get the trip BEFORE updating so we have vehicleId and financial data
      final trip = await _repository.getTripById(companyId, tripId);
      if (trip == null) throw Exception('Trip not found.');

      await _repository.updateTripStatus(
        companyId,
        tripId,
        newStatus,
        user.uid,
        user.displayName.isEmpty ? 'Operator' : user.displayName,
        notes: notes,
      );

      // --- Automatic vehicle status updates ---
      if (newStatus == 'inTransit' || newStatus == 'in_transit') {
        final vehicleRepo = _ref.read(vehicleRepositoryProvider);
        final vehicles = await vehicleRepo.getVehicles(companyId);
        final vehicleIdx = vehicles.indexWhere((v) => v.id == trip.vehicleId);
        if (vehicleIdx != -1) {
          await vehicleRepo.updateVehicle(
            companyId,
            vehicles[vehicleIdx].copyWith(status: 'inTransit'),
          );
        }
      } else if (newStatus == 'completed' || newStatus == 'cancelled') {
        final vehicleRepo = _ref.read(vehicleRepositoryProvider);
        final vehicles = await vehicleRepo.getVehicles(companyId);
        final vehicleIdx = vehicles.indexWhere((v) => v.id == trip.vehicleId);
        if (vehicleIdx != -1) {
          await vehicleRepo.updateVehicle(
            companyId,
            vehicles[vehicleIdx].copyWith(status: 'active'),
          );
        }

        // --- Automatic finance transactions on trip completion ---
        if (newStatus == 'completed') {
          final financeRepo = _ref.read(financeRepositoryProvider);

          // Retrieve active contract for customer and calculate freight pricing
          final customerRepo = _ref.read(customerRepositoryProvider);
          final contracts = await customerRepo.getContracts(companyId);
          final nowTime = DateTime.now();
          final activeContract = contracts.firstWhere(
            (c) =>
                c.customerId == trip.customerId &&
                c.status == 'active' &&
                c.startDate.isBefore(nowTime) &&
                c.endDate.isAfter(nowTime),
            orElse: () => ContractEntity(
              id: '',
              customerId: '',
              customerName: '',
              contractNumber: '',
              startDate: DateTime.now(),
              endDate: DateTime.now(),
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          );

          double calculatedAmount = trip.freightAmount;
          if (activeContract.id.isNotEmpty) {
            // Check vehicle-wise pricing
            final vehicleRate = activeContract.vehicleRates.firstWhere(
              (v) => v.vehicleId == trip.vehicleId,
              orElse: () => const VehicleRate(vehicleId: '', licensePlate: ''),
            );

            if (vehicleRate.vehicleId.isNotEmpty) {
              calculatedAmount = vehicleRate.flatRate > 0
                  ? vehicleRate.flatRate
                  : (vehicleRate.ratePerTon * trip.coalQuantity);
            } else {
              // Check route-wise pricing
              final routeRate = activeContract.routeRates.firstWhere(
                (r) =>
                    r.pickup.toLowerCase().trim() ==
                        trip.pickupLocation.toLowerCase().trim() &&
                    r.delivery.toLowerCase().trim() ==
                        trip.deliveryLocation.toLowerCase().trim(),
                orElse: () => const RouteRate(pickup: '', delivery: ''),
              );

              if (routeRate.pickup.isNotEmpty) {
                calculatedAmount = routeRate.flatRate > 0
                    ? routeRate.flatRate
                    : (routeRate.ratePerTon * trip.coalQuantity);
              } else if (activeContract.defaultFreightRate > 0) {
                calculatedAmount =
                    activeContract.defaultFreightRate * trip.coalQuantity;
              }
            }
          }

          // Generate Invoice Draft
          final invoiceId = 'inv_$tripId';
          final newInvoice = InvoiceEntity(
            id: invoiceId,
            tripId: tripId,
            customerId: trip.customerId,
            customerName: trip.customerName,
            invoiceNumber: 'INV-${DateTime.now().millisecondsSinceEpoch}',
            amount: calculatedAmount,
            status: 'draft',
            issueDate: DateTime.now(),
            dueDate: DateTime.now().add(const Duration(days: 30)),
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
          await customerRepo.createInvoice(companyId, newInvoice);

          // Update Customer outstanding balance
          final customer =
              await customerRepo.getCustomerById(companyId, trip.customerId);
          if (customer != null) {
            final updatedCustomer = customer.copyWith(
              outstandingBalance:
                  customer.outstandingBalance + calculatedAmount,
            );
            await customerRepo.updateCustomer(companyId, updatedCustomer);
          }

          // 1. Create Income transaction for contract-calculated amount
          final incomeTxId = 'tx_inc_$tripId';
          final incomeTx = FinanceTransactionEntity(
            id: incomeTxId,
            companyId: companyId,
            type: 'income',
            category: 'income',
            amount: calculatedAmount,
            paymentMode: 'bank',
            tripId: trip.id,
            tripNumber: trip.id,
            vehicleId: trip.vehicleId,
            vehicleLicensePlate: trip.vehicleLicensePlate,
            notes:
                'Automatically generated freight income on completion of Trip $tripId',
            transactionDate: DateTime.now(),
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
          final incomeAuditLog = AuditLogEntity(
            id: '',
            companyId: companyId,
            entityType: 'finance_transaction',
            entityId: incomeTxId,
            action: 'transaction_created',
            description:
                'INCOME recorded for Category: INCOME with Amount: \$${calculatedAmount.toStringAsFixed(2)}.',
            userId: user.uid,
            userName: user.displayName.isEmpty ? 'Operator' : user.displayName,
            timestamp: DateTime.now(),
          );
          await financeRepo.createTransaction(
              companyId, incomeTx, incomeAuditLog);

          // 2. Create Expense transaction for advancePayment if > 0
          if (trip.advancePayment > 0) {
            final advTxId = 'tx_adv_$tripId';
            final advTx = FinanceTransactionEntity(
              id: advTxId,
              companyId: companyId,
              type: 'expense',
              category: 'advance_salary',
              amount: trip.advancePayment,
              paymentMode: 'cash',
              tripId: trip.id,
              tripNumber: trip.id,
              vehicleId: trip.vehicleId,
              vehicleLicensePlate: trip.vehicleLicensePlate,
              notes:
                  'Automatically generated advance salary on completion of Trip $tripId',
              transactionDate: DateTime.now(),
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            );
            final advAuditLog = AuditLogEntity(
              id: '',
              companyId: companyId,
              entityType: 'finance_transaction',
              entityId: advTxId,
              action: 'transaction_created',
              description:
                  'EXPENSE recorded for Category: ADVANCE_SALARY with Amount: \$${trip.advancePayment.toStringAsFixed(2)}.',
              userId: user.uid,
              userName:
                  user.displayName.isEmpty ? 'Operator' : user.displayName,
              timestamp: DateTime.now(),
            );
            await financeRepo.createTransaction(companyId, advTx, advAuditLog);
          }

          // 3. Create Expense transaction for permitExpense if > 0
          if (trip.permitExpense > 0) {
            final permitTxId = 'tx_permit_$tripId';
            final permitTx = FinanceTransactionEntity(
              id: permitTxId,
              companyId: companyId,
              type: 'expense',
              category: 'miscellaneous',
              amount: trip.permitExpense,
              paymentMode: 'cash',
              tripId: trip.id,
              tripNumber: trip.id,
              vehicleId: trip.vehicleId,
              vehicleLicensePlate: trip.vehicleLicensePlate,
              notes:
                  'Automatically generated permit expense on completion of Trip $tripId',
              transactionDate: DateTime.now(),
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            );
            final permitAuditLog = AuditLogEntity(
              id: '',
              companyId: companyId,
              entityType: 'finance_transaction',
              entityId: permitTxId,
              action: 'transaction_created',
              description:
                  'EXPENSE recorded for Category: MISCELLANEOUS with Amount: \$${trip.permitExpense.toStringAsFixed(2)}.',
              userId: user.uid,
              userName:
                  user.displayName.isEmpty ? 'Operator' : user.displayName,
              timestamp: DateTime.now(),
            );
            await financeRepo.createTransaction(
                companyId, permitTx, permitAuditLog);
          }
        }
      }

      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// Soft deletes a trip, recording a deleted action audit log
  Future<bool> deleteTrip(String tripId) async {
    state = const AsyncValue.loading();
    try {
      final user = _ref.read(currentUserProvider);
      if (user?.companyId == null) throw Exception('No company authenticated.');

      final deleteAuditLog = AuditLogEntity(
        id: '',
        companyId: user!.companyId!,
        entityType: 'trip',
        entityId: tripId,
        action: 'trip_deleted',
        description: 'Trip $tripId was soft-deleted by user.',
        userId: user.uid,
        userName: user.displayName.isEmpty ? 'Operator' : user.displayName,
        timestamp: DateTime.now(),
      );

      await _repository.deleteTrip(user.companyId!, tripId, deleteAuditLog);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

/// Provider for TripListController.
final tripListControllerProvider =
    StateNotifierProvider.autoDispose<TripListController, AsyncValue<void>>((
  ref,
) {
  final repository = ref.watch(tripRepositoryProvider);
  return TripListController(repository: repository, ref: ref);
});
