import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/presentation/auth_providers.dart';
import '../data/dispatch_repository_impl.dart';
import '../domain/route_entity.dart';
import '../domain/dispatch_entity.dart';
import '../domain/dispatch_repository.dart';
import '../../vehicles/presentation/vehicle_providers.dart';
import '../../drivers/presentation/driver_providers.dart';
import '../../trips/presentation/trip_providers.dart';
import '../../trips/domain/trip_entity.dart';
import '../../trips/domain/audit_log_entity.dart';
import '../../customers/presentation/customer_providers.dart';

final dispatchRepositoryProvider = Provider<DispatchRepository>((ref) {
  return DispatchRepositoryImpl();
});

final routesStreamProvider =
    StreamProvider.autoDispose<List<RouteEntity>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user?.companyId == null) return Stream.value([]);
  return ref.watch(dispatchRepositoryProvider).watchRoutes(user!.companyId!);
});

final dispatchesStreamProvider =
    StreamProvider.autoDispose<List<DispatchEntity>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user?.companyId == null) return Stream.value([]);
  return ref
      .watch(dispatchRepositoryProvider)
      .watchDispatches(user!.companyId!);
});

// --- Route Form State & Controller ---

class RouteFormState {
  final bool isLoading;
  final String? errorMessage;
  final bool isCompleted;

  const RouteFormState({
    this.isLoading = false,
    this.errorMessage,
    this.isCompleted = false,
  });

  RouteFormState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool? isCompleted,
  }) {
    return RouteFormState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}

class RouteFormController extends StateNotifier<RouteFormState> {
  final DispatchRepository _repository;
  final Ref _ref;

  RouteFormController(
      {required DispatchRepository repository, required Ref ref})
      : _repository = repository,
        _ref = ref,
        super(const RouteFormState());

  Future<bool> saveRoute(RouteEntity route) async {
    state = state.copyWith(isLoading: true);
    try {
      final user = _ref.read(currentUserProvider);
      if (user?.companyId == null) throw Exception('No company authenticated.');
      final companyId = user!.companyId!;

      if (route.name.trim().isEmpty) {
        throw Exception('Route name cannot be empty.');
      }
      if (route.startLocation.trim().isEmpty) {
        throw Exception('Start location cannot be empty.');
      }
      if (route.endLocation.trim().isEmpty) {
        throw Exception('End location cannot be empty.');
      }
      if (route.distanceKm <= 0) {
        throw Exception('Distance must be greater than zero.');
      }

      RouteEntity savedRoute;
      if (route.id.isEmpty) {
        savedRoute = await _repository.createRoute(companyId, route);
      } else {
        await _repository.updateRoute(companyId, route);
        savedRoute = route;
      }

      // Write Audit Log
      final tripRepo = _ref.read(tripRepositoryProvider);
      final auditLog = AuditLogEntity(
        id: '',
        companyId: companyId,
        entityType: 'route',
        entityId: savedRoute.id,
        action: route.id.isEmpty ? 'route_created' : 'route_updated',
        description: 'Route ${savedRoute.name} was saved.',
        userId: user.uid,
        userName: user.displayName.isEmpty ? 'Operator' : user.displayName,
        timestamp: DateTime.now(),
      );
      await tripRepo.createTrip(companyId, _dummyTrip(companyId), auditLog);

      state = const RouteFormState(isCompleted: true);
      return true;
    } catch (e) {
      state = RouteFormState(
          errorMessage: e.toString().replaceAll('Exception: ', ''));
      return false;
    }
  }
}

final routeFormControllerProvider =
    StateNotifierProvider.autoDispose<RouteFormController, RouteFormState>(
        (ref) {
  final repository = ref.watch(dispatchRepositoryProvider);
  return RouteFormController(repository: repository, ref: ref);
});

// --- Route List Controller ---

class RouteListController extends StateNotifier<AsyncValue<void>> {
  final DispatchRepository _repository;
  final Ref _ref;

  RouteListController(
      {required DispatchRepository repository, required Ref ref})
      : _repository = repository,
        _ref = ref,
        super(const AsyncValue.data(null));

  Future<bool> deleteRoute(String routeId) async {
    state = const AsyncValue.loading();
    try {
      final user = _ref.read(currentUserProvider);
      if (user?.companyId == null) throw Exception('No company authenticated.');
      final companyId = user!.companyId!;

      await _repository.deleteRoute(companyId, routeId);

      // Write Audit Log
      final tripRepo = _ref.read(tripRepositoryProvider);
      final auditLog = AuditLogEntity(
        id: '',
        companyId: companyId,
        entityType: 'route',
        entityId: routeId,
        action: 'route_deleted',
        description: 'Route soft-deleted.',
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

final routeListControllerProvider =
    StateNotifierProvider.autoDispose<RouteListController, AsyncValue<void>>(
        (ref) {
  final repository = ref.watch(dispatchRepositoryProvider);
  return RouteListController(repository: repository, ref: ref);
});

// --- Dispatch Form Controller ---

class DispatchFormController extends StateNotifier<RouteFormState> {
  final DispatchRepository _repository;
  final Ref _ref;

  DispatchFormController(
      {required DispatchRepository repository, required Ref ref})
      : _repository = repository,
        _ref = ref,
        super(const RouteFormState());

  Future<bool> saveDispatch(DispatchEntity dispatch) async {
    state = state.copyWith(isLoading: true);
    try {
      final user = _ref.read(currentUserProvider);
      if (user?.companyId == null) throw Exception('No company authenticated.');
      final companyId = user!.companyId!;

      if (dispatch.vehicleId.isEmpty) {
        throw Exception('Vehicle must be selected.');
      }
      if (dispatch.driverId.isEmpty) {
        throw Exception('Driver must be selected.');
      }
      if (dispatch.routeId.isEmpty) {
        throw Exception('Route must be selected.');
      }

      // 1. Driver Availability Validation
      final allDispatches = await _repository.getDispatches(companyId);
      final activeDispatches = allDispatches.where((d) =>
          d.status != 'completed' &&
          d.status != 'cancelled' &&
          d.id != dispatch.id);

      if (activeDispatches.any((d) => d.driverId == dispatch.driverId)) {
        throw Exception(
            'Validation Blocked: Driver is already assigned to another active dispatch.');
      }

      final tripRepo = _ref.read(tripRepositoryProvider);
      final allTrips = await tripRepo.getTrips(companyId);
      final activeTrips = allTrips.where((t) =>
          t.status != 'completed' &&
          t.status != 'cancelled' &&
          t.id != dispatch.tripId);

      if (activeTrips.any((t) => t.driverId == dispatch.driverId)) {
        throw Exception(
            'Validation Blocked: Driver is already assigned to another active trip.');
      }

      // 2. Vehicle Availability Validation & State Machine Enforcements
      if (activeDispatches.any((d) => d.vehicleId == dispatch.vehicleId)) {
        throw Exception(
            'Validation Blocked: Vehicle is already assigned to another active dispatch.');
      }
      if (activeTrips.any((t) => t.vehicleId == dispatch.vehicleId)) {
        throw Exception(
            'Validation Blocked: Vehicle is already assigned to another active trip.');
      }

      final vehicleRepo = _ref.read(vehicleRepositoryProvider);
      final vehicles = await vehicleRepo.getVehicles(companyId);
      final vehicleIdx = vehicles.indexWhere((v) => v.id == dispatch.vehicleId);
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

      // Auto transition from idle to active
      if (vehicle.status == 'idle') {
        await vehicleRepo.updateVehicle(
            companyId, vehicle.copyWith(status: 'active'));
      }

      // 3. Create or Update associated TripEntity to maintain synchronization
      String finalTripId = dispatch.tripId ?? '';
      if (finalTripId.isEmpty) {
        finalTripId = 'trip_disp_${DateTime.now().millisecondsSinceEpoch}';
        final customerRepo = _ref.read(customerRepositoryProvider);
        final customers = await customerRepo.getCustomers(companyId);
        final customerId =
            customers.isNotEmpty ? customers.first.id : 'cust_default';
        final customerName =
            customers.isNotEmpty ? customers.first.name : 'Default Customer';

        final initialTrip = TripEntity(
          id: finalTripId,
          companyId: companyId,
          vehicleId: dispatch.vehicleId,
          vehicleLicensePlate: dispatch.vehicleLicensePlate,
          driverId: dispatch.driverId,
          driverName: dispatch.driverName,
          customerId: customerId,
          customerName: customerName,
          pickupLocation: dispatch.routeName.split(' to ')[0],
          deliveryLocation: dispatch.routeName.split(' to ').length > 1
              ? dispatch.routeName.split(' to ')[1]
              : dispatch.routeName,
          cargoType: 'Coal',
          coalQuantity: 25.0,
          freightAmount: 1200.0,
          advancePayment: 0.0,
          permitExpense: 0.0,
          status: dispatch.status == 'draft' ? 'draft' : 'scheduled',
          statusHistory: const [],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final initialAudit = AuditLogEntity(
          id: '',
          companyId: companyId,
          entityType: 'trip',
          entityId: finalTripId,
          action: 'trip_created',
          description:
              'Linked Trip for Dispatch ${dispatch.dispatchNumber} auto-created.',
          userId: user.uid,
          userName: user.displayName.isEmpty ? 'Operator' : user.displayName,
          timestamp: DateTime.now(),
        );

        await tripRepo.createTrip(companyId, initialTrip, initialAudit);
      }

      final updatedDispatch = dispatch.copyWith(tripId: finalTripId);

      DispatchEntity savedDispatch;
      if (dispatch.id.isEmpty) {
        savedDispatch =
            await _repository.createDispatch(companyId, updatedDispatch);
      } else {
        await _repository.updateDispatch(companyId, updatedDispatch);
        savedDispatch = updatedDispatch;
      }

      // Write Audit Log
      final auditLog = AuditLogEntity(
        id: '',
        companyId: companyId,
        entityType: 'dispatch',
        entityId: savedDispatch.id,
        action: dispatch.id.isEmpty ? 'dispatch_created' : 'dispatch_updated',
        description: 'Dispatch ${savedDispatch.dispatchNumber} was saved.',
        userId: user.uid,
        userName: user.displayName.isEmpty ? 'Operator' : user.displayName,
        timestamp: DateTime.now(),
      );
      await tripRepo.createTrip(companyId, _dummyTrip(companyId), auditLog);

      state = const RouteFormState(isCompleted: true);
      return true;
    } catch (e) {
      state = RouteFormState(
          errorMessage: e.toString().replaceAll('Exception: ', ''));
      return false;
    }
  }
}

final dispatchFormControllerProvider =
    StateNotifierProvider.autoDispose<DispatchFormController, RouteFormState>(
        (ref) {
  final repository = ref.watch(dispatchRepositoryProvider);
  return DispatchFormController(repository: repository, ref: ref);
});

// --- Dispatch List Controller ---

class DispatchListController extends StateNotifier<AsyncValue<void>> {
  final DispatchRepository _repository;
  final Ref _ref;

  DispatchListController(
      {required DispatchRepository repository, required Ref ref})
      : _repository = repository,
        _ref = ref,
        super(const AsyncValue.data(null));

  Future<bool> updateStatus(String dispatchId, String status) async {
    state = const AsyncValue.loading();
    try {
      final user = _ref.read(currentUserProvider);
      if (user?.companyId == null) throw Exception('No company authenticated.');
      final companyId = user!.companyId!;

      final dispatch = await _repository.getDispatchById(companyId, dispatchId);
      if (dispatch == null) throw Exception('Dispatch not found.');

      await _repository.updateDispatchStatus(companyId, dispatchId, status);

      // --- Propagate Status to Linked Trip & Trigger side effects ---
      if (dispatch.tripId != null && dispatch.tripId!.isNotEmpty) {
        String targetTripStatus = 'scheduled';
        if (status == 'in_transit') targetTripStatus = 'inTransit';
        if (status == 'completed') targetTripStatus = 'completed';
        if (status == 'cancelled') targetTripStatus = 'cancelled';

        final tripController = _ref.read(tripListControllerProvider.notifier);
        await tripController.updateStatus(dispatch.tripId!, targetTripStatus);
      }

      // Manual state mappings for drivers and vehicles if status transitions directly
      final vehicleRepo = _ref.read(vehicleRepositoryProvider);
      final driverRepo = _ref.read(driverRepositoryProvider);

      if (status == 'in_transit') {
        final vehicles = await vehicleRepo.getVehicles(companyId);
        final vIdx = vehicles.indexWhere((v) => v.id == dispatch.vehicleId);
        if (vIdx != -1) {
          await vehicleRepo.updateVehicle(
              companyId, vehicles[vIdx].copyWith(status: 'inTransit'));
        }
        await driverRepo.updateDriverStatus(
            companyId, dispatch.driverId, 'on_duty');
      } else if (status == 'completed' || status == 'cancelled') {
        final vehicles = await vehicleRepo.getVehicles(companyId);
        final vIdx = vehicles.indexWhere((v) => v.id == dispatch.vehicleId);
        if (vIdx != -1) {
          await vehicleRepo.updateVehicle(
              companyId, vehicles[vIdx].copyWith(status: 'active'));
        }
        await driverRepo.updateDriverStatus(
            companyId, dispatch.driverId, 'available');
      }

      // Write Audit Log
      final tripRepo = _ref.read(tripRepositoryProvider);
      final auditLog = AuditLogEntity(
        id: '',
        companyId: companyId,
        entityType: 'dispatch',
        entityId: dispatchId,
        action: 'dispatch_status_changed',
        description:
            'Dispatch ${dispatch.dispatchNumber} status updated to ${status.toUpperCase()}.',
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

  Future<bool> deleteDispatch(String dispatchId) async {
    state = const AsyncValue.loading();
    try {
      final user = _ref.read(currentUserProvider);
      if (user?.companyId == null) throw Exception('No company authenticated.');
      final companyId = user!.companyId!;

      await _repository.deleteDispatch(companyId, dispatchId);

      // Write Audit Log
      final tripRepo = _ref.read(tripRepositoryProvider);
      final auditLog = AuditLogEntity(
        id: '',
        companyId: companyId,
        entityType: 'dispatch',
        entityId: dispatchId,
        action: 'dispatch_deleted',
        description: 'Dispatch soft-deleted.',
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

final dispatchListControllerProvider =
    StateNotifierProvider.autoDispose<DispatchListController, AsyncValue<void>>(
        (ref) {
  final repository = ref.watch(dispatchRepositoryProvider);
  return DispatchListController(repository: repository, ref: ref);
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
