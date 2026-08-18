import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fleet_os_erp/features/auth/presentation/auth_providers.dart';
import 'package:fleet_os_erp/features/auth/domain/user_entity.dart';
import 'package:fleet_os_erp/features/notifications/domain/notification_entity.dart';
import 'package:fleet_os_erp/features/notifications/domain/notification_preferences_entity.dart';
import 'package:fleet_os_erp/features/notifications/domain/notification_repository.dart';
import 'package:fleet_os_erp/features/notifications/presentation/notifications_providers.dart';

import 'package:fleet_os_erp/features/vehicles/domain/vehicle_entity.dart';
import 'package:fleet_os_erp/features/vehicles/domain/vehicle_repository.dart';
import 'package:fleet_os_erp/features/vehicles/presentation/vehicle_providers.dart';

import 'package:fleet_os_erp/features/drivers/domain/driver_entity.dart';
import 'package:fleet_os_erp/features/drivers/domain/driver_repository.dart';
import 'package:fleet_os_erp/features/drivers/presentation/driver_providers.dart';

import 'package:fleet_os_erp/features/inventory/domain/part_entity.dart';
import 'package:fleet_os_erp/features/inventory/domain/inventory_repository.dart';
import 'package:fleet_os_erp/features/inventory/presentation/inventory_providers.dart';
import 'package:fleet_os_erp/features/inventory/domain/supplier_entity.dart';
import 'package:fleet_os_erp/features/inventory/domain/inventory_transaction_entity.dart';

import 'package:fleet_os_erp/features/customers/domain/invoice_entity.dart';
import 'package:fleet_os_erp/features/billing/domain/invoice_repository.dart';
import 'package:fleet_os_erp/features/billing/presentation/billing_providers.dart';

import 'package:fleet_os_erp/features/trips/domain/trip_entity.dart';
import 'package:fleet_os_erp/features/trips/domain/trip_repository.dart';
import 'package:fleet_os_erp/features/trips/presentation/trip_providers.dart';
import 'package:fleet_os_erp/features/trips/domain/audit_log_entity.dart';

// --- Mocks ---
class MockNotificationRepository implements NotificationRepository {
  final List<NotificationEntity> notifications = [];
  NotificationPreferencesEntity preferences =
      const NotificationPreferencesEntity(
    companyId: 'c_1',
    enabledCategories: [
      'vehicles',
      'drivers',
      'inventory',
      'trips',
      'billing',
      'finance',
      'general'
    ],
    quietHoursEnabled: false,
    quietHoursStart: '22:00',
    quietHoursEnd: '06:00',
    minPriorityFilter: 'low',
  );

  @override
  Stream<List<NotificationEntity>> watchNotifications(String companyId) =>
      Stream.value(notifications);

  @override
  Future<List<NotificationEntity>> getNotifications(String companyId) async =>
      notifications;

  @override
  Future<NotificationEntity> createNotification(
      String companyId, NotificationEntity notification) async {
    final newN = notification.id.isEmpty
        ? notification.copyWith(id: 'n_${notifications.length + 1}')
        : notification;
    notifications.add(newN);
    return newN;
  }

  @override
  Future<void> updateNotification(
      String companyId, NotificationEntity notification) async {
    final idx = notifications.indexWhere((n) => n.id == notification.id);
    if (idx != -1) {
      notifications[idx] = notification;
    }
  }

  @override
  Future<void> markAllAsRead(String companyId) async {
    for (int i = 0; i < notifications.length; i++) {
      if (!notifications[i].isRead) {
        notifications[i] = notifications[i].copyWith(
          isRead: true,
          readAt: DateTime.now(),
        );
      }
    }
  }

  @override
  Future<void> deleteNotification(
      String companyId, String notificationId) async {
    notifications.removeWhere((n) => n.id == notificationId);
  }

  @override
  Stream<NotificationPreferencesEntity> watchPreferences(String companyId) =>
      Stream.value(preferences);

  @override
  Future<NotificationPreferencesEntity> getPreferences(
          String companyId) async =>
      preferences;

  @override
  Future<void> savePreferences(
      String companyId, NotificationPreferencesEntity preferences) async {
    this.preferences = preferences;
  }
}

class MockVehicleRepository implements VehicleRepository {
  final List<VehicleEntity> vehicles;
  MockVehicleRepository({required this.vehicles});

  @override
  Stream<List<VehicleEntity>> watchVehicles(String companyId) =>
      Stream.value(vehicles);
  @override
  Future<List<VehicleEntity>> getVehicles(String companyId) async => vehicles;
  @override
  Future<VehicleEntity> createVehicle(
          String companyId, VehicleEntity vehicle) async =>
      vehicle;
  @override
  Future<void> updateVehicle(String companyId, VehicleEntity vehicle) async {}
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

class MockDriverRepository implements DriverRepository {
  final List<DriverEntity> drivers;
  MockDriverRepository({required this.drivers});

  @override
  Stream<List<DriverEntity>> watchDrivers(String companyId) =>
      Stream.value(drivers);
  @override
  Future<List<DriverEntity>> getDrivers(String companyId) async => drivers;
  @override
  Future<DriverEntity?> getDriverById(
          String companyId, String driverId) async =>
      drivers.firstWhere((d) => d.id == driverId);
  @override
  Future<DriverEntity> createDriver(
          String companyId, DriverEntity driver) async =>
      driver;
  @override
  Future<void> updateDriver(String companyId, DriverEntity driver) async {}
  @override
  Future<void> deleteDriver(String companyId, String driverId) async {}
  @override
  Future<void> updateDriverStatus(
      String companyId, String driverId, String status) async {}
  @override
  Future<void> linkVehicle(String companyId, String driverId, String? vehicleId,
      String? vehicleLicensePlate) async {}
}

class MockInventoryRepository implements InventoryRepository {
  final List<PartEntity> parts;
  MockInventoryRepository({required this.parts});

  @override
  Stream<List<PartEntity>> watchParts(String companyId) => Stream.value(parts);
  @override
  Future<List<PartEntity>> getParts(String companyId) async => parts;
  @override
  Future<PartEntity?> getPartById(String companyId, String partId) async =>
      parts.firstWhere((p) => p.id == partId);
  @override
  Future<PartEntity> createPart(String companyId, PartEntity part) async =>
      part;
  @override
  Future<void> updatePart(String companyId, PartEntity part) async {}
  @override
  Future<void> deletePart(String companyId, String partId) async {}

  @override
  Stream<List<SupplierEntity>> watchSuppliers(String companyId) =>
      Stream.value([]);
  @override
  Future<List<SupplierEntity>> getSuppliers(String companyId) async => [];
  @override
  Future<SupplierEntity?> getSupplierById(
          String companyId, String supplierId) async =>
      null;
  @override
  Future<SupplierEntity> createSupplier(
          String companyId, SupplierEntity supplier) async =>
      supplier;
  @override
  Future<void> updateSupplier(
      String companyId, SupplierEntity supplier) async {}
  @override
  Future<void> deleteSupplier(String companyId, String supplierId) async {}

  @override
  Stream<List<InventoryTransactionEntity>> watchTransactions(
          String companyId) =>
      Stream.value([]);
  @override
  Future<List<InventoryTransactionEntity>> getTransactions(
          String companyId) async =>
      [];
  @override
  Future<InventoryTransactionEntity> createTransaction(
          String companyId, InventoryTransactionEntity transaction) async =>
      transaction;
}

class MockInvoiceRepository implements InvoiceRepository {
  final List<InvoiceEntity> invoices;
  MockInvoiceRepository({required this.invoices});

  @override
  Stream<List<InvoiceEntity>> watchInvoices(String companyId) =>
      Stream.value(invoices);
  @override
  Future<List<InvoiceEntity>> getInvoices(String companyId) async => invoices;
  @override
  Future<InvoiceEntity?> getInvoiceById(
          String companyId, String invoiceId) async =>
      invoices.firstWhere((i) => i.id == invoiceId);
  @override
  Future<InvoiceEntity> createInvoice(
          String companyId, InvoiceEntity invoice) async =>
      invoice;
  @override
  Future<void> updateInvoice(String companyId, InvoiceEntity invoice) async {}
  @override
  Future<void> deleteInvoice(String companyId, String invoiceId) async {}
}

class MockTripRepository implements TripRepository {
  final List<TripEntity> trips;
  MockTripRepository({required this.trips});

  @override
  Stream<List<TripEntity>> watchTrips(String companyId) => Stream.value(trips);
  @override
  Future<List<TripEntity>> getTrips(String companyId) async => trips;
  @override
  Future<TripEntity?> getTripById(String companyId, String tripId) async =>
      trips.firstWhere((t) => t.id == tripId);
  @override
  Future<TripEntity> createTrip(String companyId, TripEntity trip,
          AuditLogEntity initialAuditLog) async =>
      trip;
  @override
  Future<void> updateTripStatus(String companyId, String tripId,
      String newStatus, String changedByUserId, String changedByUserName,
      {String? notes}) async {}
  @override
  Future<void> deleteTrip(
      String companyId, String tripId, AuditLogEntity deleteAuditLog) async {}
  @override
  Stream<List<AuditLogEntity>> watchAuditLogsForTrip(
          String companyId, String tripId) =>
      Stream.value([]);
}

void main() {
  final now = DateTime.now();
  final testUser = UserEntity(
    uid: 'u_1',
    email: 'operator@fleet.com',
    displayName: 'Operator',
    role: 'admin',
    companyId: 'c_1',
    createdAt: now,
  );

  group('Notifications System Providers & Rules Engine', () {
    late MockNotificationRepository mockNotificationRepo;
    late MockVehicleRepository mockVehicleRepo;
    late MockDriverRepository mockDriverRepo;
    late MockInventoryRepository mockInventoryRepo;
    late MockInvoiceRepository mockInvoiceRepo;
    late MockTripRepository mockTripRepo;

    setUp(() {
      VehicleFastagValidator.clear();
      DriverMedicalCertificateValidator.clear();
      UnpaidBillsValidator.clear();

      mockNotificationRepo = MockNotificationRepository();
      mockVehicleRepo = MockVehicleRepository(vehicles: []);
      mockDriverRepo = MockDriverRepository(drivers: []);
      mockInventoryRepo = MockInventoryRepository(parts: []);
      mockInvoiceRepo = MockInvoiceRepository(invoices: []);
      mockTripRepo = MockTripRepository(trips: []);
    });

    ProviderContainer createContainer() {
      return ProviderContainer(
        overrides: [
          currentUserProvider.overrideWith((ref) => testUser),
          notificationRepositoryProvider
              .overrideWithValue(mockNotificationRepo),
          vehicleRepositoryProvider.overrideWithValue(mockVehicleRepo),
          driverRepositoryProvider.overrideWithValue(mockDriverRepo),
          inventoryRepositoryProvider.overrideWithValue(mockInventoryRepo),
          invoiceRepositoryProvider.overrideWithValue(mockInvoiceRepo),
          tripRepositoryProvider.overrideWithValue(mockTripRepo),
        ],
      );
    }

    test('watchPreferences returns default settings if not initialized',
        () async {
      final container = createContainer();
      final prefsStream =
          container.read(notificationPreferencesStreamProvider.stream);
      final firstVal = await prefsStream.first;

      expect(firstVal.companyId, 'c_1');
      expect(firstVal.enabledCategories.length, 7);
      expect(firstVal.minPriorityFilter, 'low');
    });

    test('saving preferences updates repository settings', () async {
      final container = createContainer();
      final controller =
          container.read(notificationFormControllerProvider.notifier);

      final newPrefs = const NotificationPreferencesEntity(
        companyId: 'c_1',
        enabledCategories: ['vehicles', 'drivers'],
        quietHoursEnabled: true,
        quietHoursStart: '22:00',
        quietHoursEnd: '06:00',
        minPriorityFilter: 'high',
      );

      await controller.savePreferences(newPrefs);

      final updatedPrefs = await mockNotificationRepo.getPreferences('c_1');
      expect(updatedPrefs.minPriorityFilter, 'high');
      expect(updatedPrefs.enabledCategories, ['vehicles', 'drivers']);
    });

    test(
        'notifications stream filters based on preferences (categories & priority)',
        () async {
      // Setup some notifications
      mockNotificationRepo.notifications.addAll([
        NotificationEntity(
          id: 'n_1',
          companyId: 'c_1',
          title: 'Low Stock Part',
          message: 'Low stock',
          category: 'inventory',
          priority: 'high',
          createdAt: now,
        ),
        NotificationEntity(
          id: 'n_2',
          companyId: 'c_1',
          title: 'PUC Expiring',
          message: 'Expired',
          category: 'vehicles',
          priority: 'low',
          createdAt: now,
        ),
        NotificationEntity(
          id: 'n_3',
          companyId: 'c_1',
          title: 'Driver License',
          message: 'License Expired',
          category: 'drivers',
          priority: 'critical',
          createdAt: now,
        ),
      ]);

      // Set preferences to only allow vehicles/drivers category, and high/critical priority
      mockNotificationRepo.preferences = const NotificationPreferencesEntity(
        companyId: 'c_1',
        enabledCategories: ['vehicles', 'drivers'],
        quietHoursEnabled: false,
        quietHoursStart: '22:00',
        quietHoursEnd: '06:00',
        minPriorityFilter: 'high',
      );

      final container = createContainer();
      List<NotificationEntity>? filteredList;
      final sub = container.listen(notificationsStreamProvider, (prev, next) {
        if (next is AsyncData<List<NotificationEntity>>) {
          filteredList = next.value;
        }
      }, fireImmediately: true);

      // Wait up to 500ms for the filtered list to emit and match expected count
      for (int i = 0; i < 50; i++) {
        if (filteredList != null && filteredList!.length == 1) break;
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }

      expect(filteredList, isNotNull);
      expect(filteredList!.length, 1);
      expect(filteredList!.first.id, 'n_3');

      sub.close();
    });

    test(
        'rules evaluator detects expiring vehicle insurance and creates critical alerts',
        () async {
      mockVehicleRepo.vehicles.add(VehicleEntity(
        id: 'v_1',
        vin: 'VIN12345',
        licensePlate: 'KA-01-A-1234',
        make: 'Volvo',
        model: 'Truck-A',
        year: 2020,
        status: 'active',
        fuelType: 'diesel',
        odometer: 10000.0,
        insuranceExpiry: now.subtract(const Duration(days: 2)), // Expired
        pucExpiry: now.add(const Duration(days: 60)),
        fitnessExpiry: now.add(const Duration(days: 60)),
        createdAt: now,
        updatedAt: now,
      ));

      final container = createContainer();
      final evalController =
          container.read(alertEvaluationControllerProvider.notifier);

      final newAlerts = await evalController.evaluateAllRules();
      expect(newAlerts, 1);

      final activeNotifications = mockNotificationRepo.notifications;
      expect(activeNotifications.length, 1);
      expect(activeNotifications.first.priority, 'critical');
      expect(activeNotifications.first.title, contains('Insurance Expired'));
    });

    test('rules evaluator detects low FASTag balances', () async {
      mockVehicleRepo.vehicles.add(VehicleEntity(
        id: 'v_2',
        vin: 'VIN67890',
        licensePlate: 'MH-12-B-9999',
        make: 'Tata',
        model: 'Van-X',
        year: 2021,
        status: 'active',
        fuelType: 'diesel',
        odometer: 20000.0,
        insuranceExpiry: now.add(const Duration(days: 60)),
        pucExpiry: now.add(const Duration(days: 60)),
        fitnessExpiry: now.add(const Duration(days: 60)),
        createdAt: now,
        updatedAt: now,
      ));

      // Mock low FASTag balance
      VehicleFastagValidator.setFastagBalance('v_2', 35.0);

      final container = createContainer();
      final evalController =
          container.read(alertEvaluationControllerProvider.notifier);

      final newAlerts = await evalController.evaluateAllRules();
      expect(newAlerts, 1);

      expect(mockNotificationRepo.notifications.first.priority, 'medium');
      expect(mockNotificationRepo.notifications.first.title,
          contains('Low FASTag Balance'));
    });

    test('rules evaluator detects low inventory parts', () async {
      mockInventoryRepo.parts.add(PartEntity(
        id: 'p_1',
        companyId: 'c_1',
        name: 'Oil Filter X',
        partNumber: 'OF-100',
        description: 'Oil filter for trucks',
        category: 'filters',
        quantity: 5,
        minStockThreshold: 10, // Stock level low (5 <= 10)
        unitCost: 12.5,
        createdAt: now,
        updatedAt: now,
      ));

      final container = createContainer();
      final evalController =
          container.read(alertEvaluationControllerProvider.notifier);

      final newAlerts = await evalController.evaluateAllRules();
      expect(newAlerts, 1);

      expect(mockNotificationRepo.notifications.first.priority, 'high');
      expect(mockNotificationRepo.notifications.first.title,
          contains('Low Stock Alert'));
    });

    test('rules evaluator avoids creating duplicate alerts for the same issue',
        () async {
      mockInventoryRepo.parts.add(PartEntity(
        id: 'p_2',
        companyId: 'c_1',
        name: 'Brake Pad Z',
        partNumber: 'BP-200',
        description: 'Rear brake pad set',
        category: 'brakes',
        quantity: 2,
        minStockThreshold: 5,
        unitCost: 45.0,
        createdAt: now,
        updatedAt: now,
      ));

      final container = createContainer();
      final evalController =
          container.read(alertEvaluationControllerProvider.notifier);

      // First evaluation creates alert
      final firstEval = await evalController.evaluateAllRules();
      expect(firstEval, 1);
      expect(mockNotificationRepo.notifications.length, 1);

      // Second evaluation does not create a duplicate alert because first one is unread
      final secondEval = await evalController.evaluateAllRules();
      expect(secondEval, 0);
      expect(mockNotificationRepo.notifications.length, 1);
    });

    test('marking a notification as read updates its read status', () async {
      final notification = NotificationEntity(
        id: 'n_99',
        companyId: 'c_1',
        title: 'Title',
        message: 'Message',
        category: 'general',
        priority: 'low',
        createdAt: now,
      );
      mockNotificationRepo.notifications.add(notification);

      final container = createContainer();
      final controller =
          container.read(notificationFormControllerProvider.notifier);

      await controller.markAsRead(notification);

      final updated = mockNotificationRepo.notifications.first;
      expect(updated.isRead, true);
      expect(updated.readAt, isNotNull);
    });
  });
}
