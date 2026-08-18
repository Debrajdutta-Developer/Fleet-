import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/presentation/auth_providers.dart';
import '../data/vendor_repository_impl.dart';
import '../domain/vendor_entity.dart';
import '../domain/vendor_repository.dart';
import '../../trips/presentation/trip_providers.dart';
import '../../trips/domain/audit_log_entity.dart';
import '../../trips/domain/trip_entity.dart';

final vendorRepositoryProvider = Provider<VendorRepository>((ref) {
  return VendorRepositoryImpl();
});

final vendorsStreamProvider =
    StreamProvider.autoDispose<List<VendorEntity>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user?.companyId == null) return Stream.value([]);
  return ref.watch(vendorRepositoryProvider).watchVendors(user!.companyId!);
});

class VendorFormState {
  final bool isLoading;
  final String? errorMessage;
  final bool isCompleted;

  const VendorFormState({
    this.isLoading = false,
    this.errorMessage,
    this.isCompleted = false,
  });

  VendorFormState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool? isCompleted,
  }) {
    return VendorFormState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}

class VendorFormController extends StateNotifier<VendorFormState> {
  final VendorRepository _repository;
  final Ref _ref;

  VendorFormController({required VendorRepository repository, required Ref ref})
      : _repository = repository,
        _ref = ref,
        super(const VendorFormState());

  Future<bool> saveVendor(VendorEntity vendor) async {
    state = state.copyWith(isLoading: true);
    try {
      final user = _ref.read(currentUserProvider);
      if (user?.companyId == null) throw Exception('No company authenticated.');
      final companyId = user!.companyId!;

      if (vendor.name.trim().isEmpty)
        throw Exception('Vendor name cannot be empty.');
      if (vendor.phone.trim().isEmpty)
        throw Exception('Phone number cannot be empty.');

      VendorEntity savedVendor;
      if (vendor.id.isEmpty) {
        savedVendor = await _repository.createVendor(companyId, vendor);
      } else {
        await _repository.updateVendor(companyId, vendor);
        savedVendor = vendor;
      }

      // Write Audit Log
      final tripRepo = _ref.read(tripRepositoryProvider);
      final auditLog = AuditLogEntity(
        id: '',
        companyId: companyId,
        entityType: 'vendor',
        entityId: savedVendor.id,
        action: vendor.id.isEmpty ? 'vendor_created' : 'vendor_updated',
        description: vendor.id.isEmpty
            ? 'Vendor ${savedVendor.name} was added.'
            : 'Vendor ${savedVendor.name} profiles were updated.',
        userId: user.uid,
        userName: user.displayName.isEmpty ? 'Operator' : user.displayName,
        timestamp: DateTime.now(),
      );
      await tripRepo.createTrip(companyId, _dummyTrip(companyId), auditLog);

      state = const VendorFormState(isCompleted: true);
      return true;
    } catch (e) {
      state = VendorFormState(
          errorMessage: e.toString().replaceAll('Exception: ', ''));
      return false;
    }
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

final vendorFormControllerProvider =
    StateNotifierProvider.autoDispose<VendorFormController, VendorFormState>(
        (ref) {
  final repository = ref.watch(vendorRepositoryProvider);
  return VendorFormController(repository: repository, ref: ref);
});

class VendorListController extends StateNotifier<AsyncValue<void>> {
  final VendorRepository _repository;
  final Ref _ref;

  VendorListController({required VendorRepository repository, required Ref ref})
      : _repository = repository,
        _ref = ref,
        super(const AsyncValue.data(null));

  Future<bool> deleteVendor(String vendorId) async {
    state = const AsyncValue.loading();
    try {
      final user = _ref.read(currentUserProvider);
      if (user?.companyId == null) throw Exception('No company authenticated.');
      final companyId = user!.companyId!;

      await _repository.deleteVendor(companyId, vendorId);

      // Write Audit Log
      final tripRepo = _ref.read(tripRepositoryProvider);
      final auditLog = AuditLogEntity(
        id: '',
        companyId: companyId,
        entityType: 'vendor',
        entityId: vendorId,
        action: 'vendor_deleted',
        description: 'Vendor record soft-deleted.',
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

final vendorListControllerProvider =
    StateNotifierProvider.autoDispose<VendorListController, AsyncValue<void>>(
        (ref) {
  final repository = ref.watch(vendorRepositoryProvider);
  return VendorListController(repository: repository, ref: ref);
});
