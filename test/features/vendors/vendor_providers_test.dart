import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fleet_os_erp/features/auth/presentation/auth_providers.dart';
import 'package:fleet_os_erp/features/auth/domain/user_entity.dart';
import 'package:fleet_os_erp/features/vendors/domain/vendor_entity.dart';
import 'package:fleet_os_erp/features/vendors/domain/vendor_repository.dart';
import 'package:fleet_os_erp/features/vendors/presentation/vendor_providers.dart';
import 'package:fleet_os_erp/features/trips/domain/trip_repository.dart';
import 'package:fleet_os_erp/features/trips/presentation/trip_providers.dart';
import 'package:fleet_os_erp/features/trips/domain/trip_entity.dart';
import 'package:fleet_os_erp/features/trips/domain/audit_log_entity.dart';

class MockVendorRepository implements VendorRepository {
  final List<VendorEntity> vendors;
  MockVendorRepository({required this.vendors});

  @override
  Stream<List<VendorEntity>> watchVendors(String companyId) =>
      Stream.value(vendors);

  @override
  Future<List<VendorEntity>> getVendors(String companyId) async => vendors;

  @override
  Future<VendorEntity?> getVendorById(String companyId, String vendorId) async {
    try {
      return vendors.firstWhere((v) => v.id == vendorId);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<VendorEntity> createVendor(
      String companyId, VendorEntity vendor) async {
    vendors.add(vendor);
    return vendor;
  }

  @override
  Future<void> updateVendor(String companyId, VendorEntity vendor) async {
    final idx = vendors.indexWhere((v) => v.id == vendor.id);
    if (idx != -1) {
      vendors[idx] = vendor;
    }
  }

  @override
  Future<void> deleteVendor(String companyId, String vendorId) async {
    final idx = vendors.indexWhere((v) => v.id == vendorId);
    if (idx != -1) {
      vendors[idx] = vendors[idx].copyWith(deletedAt: DateTime.now());
    }
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

void main() {
  group('Vendor Providers Business Logic Tests', () {
    final now = DateTime.now();
    final tVendors = [
      VendorEntity(
        id: 'vend_1',
        name: 'Super Fuel Co.',
        serviceType: 'fuel',
        phone: '1234567890',
        email: 'info@superfuel.com',
        address: 'New York',
        createdAt: now,
        updatedAt: now,
      ),
    ];

    test('should save vendor and write audit logs successfully', () async {
      final vendorRepo = MockVendorRepository(vendors: List.from(tVendors));
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
          vendorRepositoryProvider.overrideWithValue(vendorRepo),
          tripRepositoryProvider.overrideWithValue(tripRepo),
        ],
      );

      final controller = container.read(vendorFormControllerProvider.notifier);
      final newVendor = VendorEntity(
        id: '',
        name: 'A1 Mechanics',
        serviceType: 'maintenance',
        phone: '0987654321',
        email: 'service@a1mechanics.com',
        address: 'Chicago',
        createdAt: now,
        updatedAt: now,
      );

      final result = await controller.saveVendor(newVendor);

      expect(result, true);
      expect(vendorRepo.vendors.length, 2);
      expect(vendorRepo.vendors[1].name, 'A1 Mechanics');
      expect(tripRepo.auditLogs.length, 1);
      expect(tripRepo.auditLogs[0].action, 'vendor_created');
    });

    test('should soft-delete vendor and write delete audit log successfully',
        () async {
      final vendorRepo = MockVendorRepository(vendors: List.from(tVendors));
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
          vendorRepositoryProvider.overrideWithValue(vendorRepo),
          tripRepositoryProvider.overrideWithValue(tripRepo),
        ],
      );

      final controller = container.read(vendorListControllerProvider.notifier);
      final result = await controller.deleteVendor('vend_1');

      expect(result, true);
      expect(vendorRepo.vendors[0].deletedAt, isNotNull);
      expect(tripRepo.auditLogs.length, 1);
      expect(tripRepo.auditLogs[0].action, 'vendor_deleted');
    });
  });
}
