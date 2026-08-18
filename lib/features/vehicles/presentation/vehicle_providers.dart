import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/presentation/auth_providers.dart';
import '../data/vehicle_repository_impl.dart';
import '../domain/vehicle_entity.dart';
import '../domain/vehicle_repository.dart';
import '../../drivers/presentation/driver_providers.dart';

/// Provider for VehicleRepository.
final vehicleRepositoryProvider = Provider<VehicleRepository>((ref) {
  return VehicleRepositoryImpl();
});

/// StreamProvider listening to real-time active fleet changes.
final vehiclesStreamProvider = StreamProvider.autoDispose<List<VehicleEntity>>((
  ref,
) {
  final user = ref.watch(currentUserProvider);
  if (user?.companyId == null) return Stream.value([]);
  return ref.watch(vehicleRepositoryProvider).watchVehicles(user!.companyId!);
});

/// UI State for Vehicle Form operations.
class VehicleFormState {
  final bool isLoading;
  final String? errorMessage;
  final bool isCompleted;

  const VehicleFormState({
    this.isLoading = false,
    this.errorMessage,
    this.isCompleted = false,
  });

  VehicleFormState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool? isCompleted,
  }) {
    return VehicleFormState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}

/// Controller overseeing Vehicle Add/Edit actions and compliance document uploads.
class VehicleFormController extends StateNotifier<VehicleFormState> {
  final VehicleRepository _repository;
  final Ref _ref;

  VehicleFormController({
    required VehicleRepository repository,
    required Ref ref,
  })  : _repository = repository,
        _ref = ref,
        super(const VehicleFormState());

  /// Create new vehicle asset
  Future<bool> saveVehicle(VehicleEntity vehicle) async {
    state = state.copyWith(isLoading: true);
    try {
      final user = _ref.read(currentUserProvider);
      if (user?.companyId == null) throw Exception('No company authenticated.');
      final companyId = user!.companyId!;

      VehicleEntity? existingVehicle;
      if (vehicle.id.isNotEmpty) {
        final vehicles = await _repository.getVehicles(companyId);
        final idx = vehicles.indexWhere((v) => v.id == vehicle.id);
        if (idx != -1) {
          existingVehicle = vehicles[idx];
        }
      }

      // Check transition to 'active' from 'registration'
      if (vehicle.status == 'active' &&
          (existingVehicle == null ||
              existingVehicle.status == 'registration')) {
        if (vehicle.insuranceExpiry.isBefore(DateTime.now()) ||
            vehicle.pucExpiry.isBefore(DateTime.now()) ||
            vehicle.fitnessExpiry.isBefore(DateTime.now())) {
          throw Exception(
              'Validation Blocked: Cannot transition to Active. Safety documents (Insurance/PUC/Fitness) are expired or missing.');
        }
      }

      // If status transitions to 'maintenance' or 'sold', unlink the driver
      VehicleEntity updatedVehicle = vehicle;
      if (vehicle.status == 'maintenance' || vehicle.status == 'sold') {
        if (vehicle.assignedDriverId != null &&
            vehicle.assignedDriverId!.isNotEmpty) {
          // unlink from driver's side
          final driverRepo = _ref.read(driverRepositoryProvider);
          await driverRepo.linkVehicle(
              companyId, vehicle.assignedDriverId!, null, null);

          // unlink from vehicle's side
          updatedVehicle = VehicleEntity(
            id: vehicle.id,
            vin: vehicle.vin,
            licensePlate: vehicle.licensePlate,
            make: vehicle.make,
            model: vehicle.model,
            year: vehicle.year,
            status: vehicle.status,
            fuelType: vehicle.fuelType,
            odometer: vehicle.odometer,
            lastServiceDate: vehicle.lastServiceDate,
            insuranceExpiry: vehicle.insuranceExpiry,
            pucExpiry: vehicle.pucExpiry,
            fitnessExpiry: vehicle.fitnessExpiry,
            assignedDriverId: null,
            assignedDriverName: null,
            createdAt: vehicle.createdAt,
            updatedAt: vehicle.updatedAt,
            deletedAt: vehicle.deletedAt,
          );
        }
      }

      if (updatedVehicle.id.isEmpty) {
        await _repository.createVehicle(companyId, updatedVehicle);
      } else {
        await _repository.updateVehicle(companyId, updatedVehicle);
      }

      state = const VehicleFormState(isCompleted: true);
      return true;
    } catch (e) {
      state = VehicleFormState(
          errorMessage: e.toString().replaceAll('Exception: ', ''));
      return false;
    }
  }

  /// Upload compliance document
  Future<String?> uploadDocument({
    required String vehicleId,
    required String docType, // insurance, puc, fitness
    required File file,
  }) async {
    state = state.copyWith(isLoading: true);
    try {
      final user = _ref.read(currentUserProvider);
      if (user?.companyId == null) throw Exception('No company authenticated.');

      final downloadUrl = await _repository.uploadComplianceDocument(
        user!.companyId!,
        vehicleId,
        docType,
        file,
      );

      state = const VehicleFormState();
      return downloadUrl;
    } catch (e) {
      state = VehicleFormState(errorMessage: e.toString());
      return null;
    }
  }
}

/// Provider for VehicleFormController.
final vehicleFormControllerProvider =
    StateNotifierProvider.autoDispose<VehicleFormController, VehicleFormState>((
  ref,
) {
  final repository = ref.watch(vehicleRepositoryProvider);
  return VehicleFormController(repository: repository, ref: ref);
});

/// Controller overseeing Vehicle List actions, searches, filters, and deletes.
class VehicleListController extends StateNotifier<AsyncValue<void>> {
  final VehicleRepository _repository;
  final Ref _ref;

  VehicleListController({
    required VehicleRepository repository,
    required Ref ref,
  })  : _repository = repository,
        _ref = ref,
        super(const AsyncValue.data(null));

  /// Soft deletes vehicle record by setting deletedAt
  Future<bool> deleteVehicle(String vehicleId) async {
    state = const AsyncValue.loading();
    try {
      final user = _ref.read(currentUserProvider);
      if (user?.companyId == null) throw Exception('No company authenticated.');

      await _repository.deleteVehicle(user!.companyId!, vehicleId);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// Link or unlink primary driver to vehicle
  Future<bool> assignDriver(
    String vehicleId,
    String? driverId,
    String? driverName,
  ) async {
    state = const AsyncValue.loading();
    try {
      final user = _ref.read(currentUserProvider);
      if (user?.companyId == null) throw Exception('No company authenticated.');
      final companyId = user!.companyId!;

      final vehicles = await _repository.getVehicles(companyId);
      final vehicleIdx = vehicles.indexWhere((v) => v.id == vehicleId);
      if (vehicleIdx == -1) throw Exception('Vehicle not found.');
      final vehicle = vehicles[vehicleIdx];

      if (vehicle.status == 'registration') {
        throw Exception(
            'Validation Blocked: Cannot assign driver. Vehicle is in registration status.');
      }
      if (vehicle.status == 'sold') {
        throw Exception(
            'Validation Blocked: Cannot assign driver. Vehicle is decommissioned (sold).');
      }
      if (vehicle.status == 'maintenance') {
        throw Exception(
            'Validation Blocked: Cannot assign driver. Vehicle is in maintenance.');
      }

      // If vehicle status was idle, transition it to active
      VehicleEntity updatedVehicle = vehicle.copyWith(
        assignedDriverId: driverId,
        assignedDriverName: driverName,
      );
      if (vehicle.status == 'idle') {
        updatedVehicle = updatedVehicle.copyWith(status: 'active');
      }

      await _repository.assignDriver(
        companyId,
        vehicleId,
        driverId,
        driverName,
      );

      if (vehicle.status == 'idle') {
        await _repository.updateVehicle(companyId, updatedVehicle);
      }

      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

/// Provider for VehicleListController.
final vehicleListControllerProvider =
    StateNotifierProvider.autoDispose<VehicleListController, AsyncValue<void>>((
  ref,
) {
  final repository = ref.watch(vehicleRepositoryProvider);
  return VehicleListController(repository: repository, ref: ref);
});

/// Compliance Helper utility functions to check expiry states.
class VehicleComplianceHelper {
  /// Checks if insurance is expired
  static bool isInsuranceExpired(VehicleEntity vehicle) {
    return vehicle.insuranceExpiry.isBefore(DateTime.now());
  }

  /// Checks if insurance requires renewal warning (30 days prior)
  static bool isInsuranceWarning(VehicleEntity vehicle) {
    final diff = vehicle.insuranceExpiry.difference(DateTime.now()).inDays;
    return diff >= 0 && diff <= 30;
  }

  /// Checks if PUC is expired
  static bool isPucExpired(VehicleEntity vehicle) {
    return vehicle.pucExpiry.isBefore(DateTime.now());
  }

  /// Checks if PUC requires renewal warning
  static bool isPucWarning(VehicleEntity vehicle) {
    final diff = vehicle.pucExpiry.difference(DateTime.now()).inDays;
    return diff >= 0 && diff <= 15;
  }

  /// Checks if Fitness Certificate is expired
  static bool isFitnessExpired(VehicleEntity vehicle) {
    return vehicle.fitnessExpiry.isBefore(DateTime.now());
  }

  /// Checks if Fitness requires renewal warning
  static bool isFitnessWarning(VehicleEntity vehicle) {
    final diff = vehicle.fitnessExpiry.difference(DateTime.now()).inDays;
    return diff >= 0 && diff <= 30;
  }

  /// Checks if preventative service is overdue (e.g. last service was >180 days ago)
  static bool isServiceOverdue(VehicleEntity vehicle) {
    if (vehicle.lastServiceDate == null) return true;
    final diff = DateTime.now().difference(vehicle.lastServiceDate!).inDays;
    return diff > 180;
  }
}
