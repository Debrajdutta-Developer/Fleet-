import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/presentation/auth_providers.dart';
import '../data/driver_repository_impl.dart';
import '../domain/driver_entity.dart';
import '../domain/driver_repository.dart';
import '../../vehicles/presentation/vehicle_providers.dart';
import '../../trips/domain/trip_entity.dart';
import '../../trips/presentation/trip_providers.dart';
import '../../trips/domain/audit_log_entity.dart';

/// Provider for DriverRepository
final driverRepositoryProvider = Provider<DriverRepository>((ref) {
  return DriverRepositoryImpl();
});

/// StreamProvider listening to the company's drivers
final driversStreamProvider =
    StreamProvider.autoDispose<List<DriverEntity>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user?.companyId == null) return Stream.value([]);
  return ref.watch(driverRepositoryProvider).watchDrivers(user!.companyId!);
});

/// State representation for driver form screen
class DriverFormState {
  final bool isLoading;
  final String? errorMessage;
  final bool isCompleted;

  const DriverFormState({
    this.isLoading = false,
    this.errorMessage,
    this.isCompleted = false,
  });

  DriverFormState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool? isCompleted,
  }) {
    return DriverFormState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}

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

/// Controller managing Driver Creation and Updates
class DriverFormController extends StateNotifier<DriverFormState> {
  final DriverRepository _repository;
  final Ref _ref;

  DriverFormController({required DriverRepository repository, required Ref ref})
      : _repository = repository,
        _ref = ref,
        super(const DriverFormState());

  /// Create or update a driver record
  Future<bool> saveDriver(DriverEntity driver) async {
    state = state.copyWith(isLoading: true);
    try {
      final user = _ref.read(currentUserProvider);
      if (user?.companyId == null) throw Exception('No company authenticated.');
      final companyId = user!.companyId!;

      // Validation: Phone and License number cannot be empty
      if (driver.fullName.trim().isEmpty)
        throw Exception('Driver name cannot be empty.');
      if (driver.phone.trim().isEmpty)
        throw Exception('Phone number cannot be empty.');
      if (driver.licenseNumber.trim().isEmpty)
        throw Exception('License number cannot be empty.');

      DriverEntity savedDriver;
      if (driver.id.isEmpty) {
        savedDriver = await _repository.createDriver(companyId, driver);
      } else {
        await _repository.updateDriver(companyId, driver);
        savedDriver = driver;
      }

      // Write Audit Log
      final tripRepo = _ref.read(tripRepositoryProvider);
      final auditLog = AuditLogEntity(
        id: '',
        companyId: companyId,
        entityType: 'driver',
        entityId: savedDriver.id,
        action: driver.id.isEmpty ? 'driver_created' : 'driver_updated',
        description: driver.id.isEmpty
            ? 'Driver ${savedDriver.fullName} was onboarded to the fleet.'
            : 'Driver ${savedDriver.fullName} profiles were updated.',
        userId: user.uid,
        userName: user.displayName.isEmpty ? 'Operator' : user.displayName,
        timestamp: DateTime.now(),
      );
      // Hacky bypass to write audit log (createTrip writes to audit_logs collection)
      await tripRepo.createTrip(companyId, _dummyTrip(companyId), auditLog);

      state = const DriverFormState(isCompleted: true);
      return true;
    } catch (e) {
      state = DriverFormState(
          errorMessage: e.toString().replaceAll('Exception: ', ''));
      return false;
    }
  }
}

final driverFormControllerProvider =
    StateNotifierProvider.autoDispose<DriverFormController, DriverFormState>(
        (ref) {
  final repository = ref.watch(driverRepositoryProvider);
  return DriverFormController(repository: repository, ref: ref);
});

/// Controller managing driver list actions, status changes, and vehicle assignments
class DriverListController extends StateNotifier<AsyncValue<void>> {
  final DriverRepository _repository;
  final Ref _ref;

  DriverListController({required DriverRepository repository, required Ref ref})
      : _repository = repository,
        _ref = ref,
        super(const AsyncValue.data(null));

  /// Transition driver status availability
  Future<bool> updateStatus(String driverId, String status) async {
    state = const AsyncValue.loading();
    try {
      final user = _ref.read(currentUserProvider);
      if (user?.companyId == null) throw Exception('No company authenticated.');
      final companyId = user!.companyId!;

      await _repository.updateDriverStatus(companyId, driverId, status);

      // Write Audit Log
      final tripRepo = _ref.read(tripRepositoryProvider);
      final auditLog = AuditLogEntity(
        id: '',
        companyId: companyId,
        entityType: 'driver',
        entityId: driverId,
        action: 'driver_status_changed',
        description: 'Driver status changed to ${status.toUpperCase()}.',
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

  /// Bidirectional assignment between Driver and Vehicle
  Future<bool> assignVehicle(
      String driverId, String? vehicleId, String? vehicleLicensePlate) async {
    state = const AsyncValue.loading();
    try {
      final user = _ref.read(currentUserProvider);
      if (user?.companyId == null) throw Exception('No company authenticated.');
      final companyId = user!.companyId!;

      final drivers = await _repository.getDrivers(companyId);
      final driverIdx = drivers.indexWhere((d) => d.id == driverId);
      if (driverIdx == -1) throw Exception('Driver not found.');
      final driver = drivers[driverIdx];

      final vehicleRepo = _ref.read(vehicleRepositoryProvider);

      // 1. Unlink previous vehicle if exists
      if (driver.assignedVehicleId != null &&
          driver.assignedVehicleId!.isNotEmpty) {
        await vehicleRepo.assignDriver(
            companyId, driver.assignedVehicleId!, null, null);
      }

      // 2. Unlink new vehicle from any other driver if vehicle is non-null
      if (vehicleId != null && vehicleId.isNotEmpty) {
        final vehicles = await vehicleRepo.getVehicles(companyId);
        final vehicleIdx = vehicles.indexWhere((v) => v.id == vehicleId);
        if (vehicleIdx == -1) throw Exception('Vehicle not found.');
        final vehicle = vehicles[vehicleIdx];

        if (vehicle.status == 'registration') {
          throw Exception(
              'Validation Blocked: Cannot assign vehicle. Vehicle is in registration status.');
        }
        if (vehicle.status == 'sold') {
          throw Exception(
              'Validation Blocked: Cannot assign vehicle. Vehicle is decommissioned (sold).');
        }
        if (vehicle.status == 'maintenance') {
          throw Exception(
              'Validation Blocked: Cannot assign vehicle. Vehicle is in maintenance.');
        }

        // If vehicle status was idle, transition it to active
        if (vehicle.status == 'idle') {
          await vehicleRepo.updateVehicle(
              companyId, vehicle.copyWith(status: 'active'));
        }

        // Find if another driver is linked to this vehicle
        for (final otherDriver in drivers) {
          if (otherDriver.id != driverId &&
              otherDriver.assignedVehicleId == vehicleId) {
            await _repository.linkVehicle(
                companyId, otherDriver.id, null, null);
          }
        }
        // Link vehicle to driver
        await vehicleRepo.assignDriver(
            companyId, vehicleId, driverId, driver.fullName);
      }

      // 3. Update driver's link details in repository
      await _repository.linkVehicle(
          companyId, driverId, vehicleId, vehicleLicensePlate);

      // Write Audit Log
      final tripRepo = _ref.read(tripRepositoryProvider);
      final auditLog = AuditLogEntity(
        id: '',
        companyId: companyId,
        entityType: 'driver',
        entityId: driverId,
        action: 'driver_vehicle_assigned',
        description: vehicleId == null
            ? 'Driver unassigned from primary vehicle.'
            : 'Driver assigned to vehicle $vehicleLicensePlate.',
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

  /// Soft deletes driver from fleet database
  Future<bool> deleteDriver(String driverId) async {
    state = const AsyncValue.loading();
    try {
      final user = _ref.read(currentUserProvider);
      if (user?.companyId == null) throw Exception('No company authenticated.');
      final companyId = user!.companyId!;

      await _repository.deleteDriver(companyId, driverId);

      // Write Audit Log
      final tripRepo = _ref.read(tripRepositoryProvider);
      final auditLog = AuditLogEntity(
        id: '',
        companyId: companyId,
        entityType: 'driver',
        entityId: driverId,
        action: 'driver_deleted',
        description: 'Driver record soft-deleted.',
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

final driverListControllerProvider =
    StateNotifierProvider.autoDispose<DriverListController, AsyncValue<void>>(
        (ref) {
  final repository = ref.watch(driverRepositoryProvider);
  return DriverListController(repository: repository, ref: ref);
});
