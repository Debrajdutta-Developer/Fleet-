import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fleet_os_erp/features/auth/presentation/auth_providers.dart';
import 'package:fleet_os_erp/features/auth/domain/user_entity.dart';
import 'package:fleet_os_erp/features/dispatch/domain/route_entity.dart';
import 'package:fleet_os_erp/features/dispatch/domain/dispatch_entity.dart';
import 'package:fleet_os_erp/features/dispatch/domain/dispatch_repository.dart';
import 'package:fleet_os_erp/features/dispatch/presentation/dispatch_providers.dart';
import 'package:fleet_os_erp/features/vehicles/domain/vehicle_entity.dart';
import 'package:fleet_os_erp/features/vehicles/domain/vehicle_repository.dart';
import 'package:fleet_os_erp/features/vehicles/presentation/vehicle_providers.dart';
import 'package:fleet_os_erp/features/drivers/domain/driver_entity.dart';
import 'package:fleet_os_erp/features/drivers/domain/driver_repository.dart';
import 'package:fleet_os_erp/features/drivers/presentation/driver_providers.dart';
import 'package:fleet_os_erp/features/trips/domain/trip_entity.dart';
import 'package:fleet_os_erp/features/trips/domain/audit_log_entity.dart';
import 'package:fleet_os_erp/features/trips/domain/trip_repository.dart';
import 'package:fleet_os_erp/features/trips/presentation/trip_providers.dart';
import 'package:fleet_os_erp/features/customers/domain/customer_entity.dart';
import 'package:fleet_os_erp/features/customers/domain/contract_entity.dart';
import 'package:fleet_os_erp/features/customers/domain/invoice_entity.dart';
import 'package:fleet_os_erp/features/customers/domain/customer_repository.dart';
import 'package:fleet_os_erp/features/customers/presentation/customer_providers.dart';
import 'package:fleet_os_erp/features/dashboard/presentation/dashboard_providers.dart';
import 'package:fleet_os_erp/features/vendors/presentation/vendor_providers.dart';
import 'package:fleet_os_erp/features/inventory/presentation/inventory_providers.dart';

class MockDispatchRepository implements DispatchRepository {
  final List<RouteEntity> routes = [];
  final List<DispatchEntity> dispatches = [];

  @override
  Stream<List<RouteEntity>> watchRoutes(String companyId) =>
      Stream.value(routes);

  @override
  Future<List<RouteEntity>> getRoutes(String companyId) async => routes;

  @override
  Future<RouteEntity> createRoute(String companyId, RouteEntity route) async {
    final id = route.id.isEmpty
        ? 'r_${DateTime.now().millisecondsSinceEpoch}'
        : route.id;
    final newRoute = route.copyWith(id: id);
    routes.add(newRoute);
    return newRoute;
  }

  @override
  Future<void> updateRoute(String companyId, RouteEntity route) async {
    final idx = routes.indexWhere((r) => r.id == route.id);
    if (idx != -1) {
      routes[idx] = route;
    }
  }

  @override
  Future<void> deleteRoute(String companyId, String routeId) async {
    final idx = routes.indexWhere((r) => r.id == routeId);
    if (idx != -1) {
      routes[idx] = routes[idx].copyWith(deletedAt: DateTime.now());
    }
  }

  @override
  Stream<List<DispatchEntity>> watchDispatches(String companyId) =>
      Stream.value(dispatches);

  @override
  Future<List<DispatchEntity>> getDispatches(String companyId) async =>
      dispatches;

  @override
  Future<DispatchEntity?> getDispatchById(String companyId, String id) async {
    try {
      return dispatches.firstWhere((d) => d.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<DispatchEntity> createDispatch(
      String companyId, DispatchEntity dispatch) async {
    final id = dispatch.id.isEmpty
        ? 'disp_${DateTime.now().millisecondsSinceEpoch}'
        : dispatch.id;
    final newDispatch = dispatch.copyWith(id: id);
    dispatches.add(newDispatch);
    return newDispatch;
  }

  @override
  Future<void> updateDispatch(String companyId, DispatchEntity dispatch) async {
    final idx = dispatches.indexWhere((d) => d.id == dispatch.id);
    if (idx != -1) {
      dispatches[idx] = dispatch;
    }
  }

  @override
  Future<void> updateDispatchStatus(
      String companyId, String dispatchId, String status) async {
    final idx = dispatches.indexWhere((d) => d.id == dispatchId);
    if (idx != -1) {
      dispatches[idx] = dispatches[idx].copyWith(status: status);
    }
  }

  @override
  Future<void> deleteDispatch(String companyId, String id) async {
    final idx = dispatches.indexWhere((d) => d.id == id);
    if (idx != -1) {
      dispatches[idx] = dispatches[idx].copyWith(deletedAt: DateTime.now());
    }
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
      String companyId, VehicleEntity vehicle) async {
    vehicles.add(vehicle);
    return vehicle;
  }

  @override
  Future<void> updateVehicle(String companyId, VehicleEntity vehicle) async {
    final idx = vehicles.indexWhere((v) => v.id == vehicle.id);
    if (idx != -1) {
      vehicles[idx] = vehicle;
    }
  }

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
      null;

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
      String companyId, String driverId, String status) async {
    final idx = drivers.indexWhere((d) => d.id == driverId);
    if (idx != -1) {
      drivers[idx] = drivers[idx].copyWith(status: status);
    }
  }

  @override
  Future<void> linkVehicle(String companyId, String driverId, String? vehicleId,
      String? vehicleLicensePlate) async {}
}

class MockTripRepository implements TripRepository {
  final List<TripEntity> trips;
  final List<AuditLogEntity> auditLogs = [];

  MockTripRepository({required this.trips});

  @override
  Stream<List<TripEntity>> watchTrips(String companyId) => Stream.value(trips);

  @override
  Future<List<TripEntity>> getTrips(String companyId) async => trips;

  @override
  Future<TripEntity?> getTripById(String companyId, String tripId) async {
    try {
      return trips.firstWhere((t) => t.id == tripId);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<TripEntity> createTrip(
      String companyId, TripEntity trip, AuditLogEntity initialAuditLog) async {
    trips.add(trip);
    auditLogs.add(initialAuditLog);
    return trip;
  }

  @override
  Future<void> updateTripStatus(String companyId, String tripId,
      String newStatus, String changedByUserId, String changedByUserName,
      {String? notes}) async {
    final idx = trips.indexWhere((t) => t.id == tripId);
    if (idx != -1) {
      trips[idx] = trips[idx].copyWith(status: newStatus);
    }
  }

  @override
  Future<void> deleteTrip(
      String companyId, String tripId, AuditLogEntity deleteAuditLog) async {}

  @override
  Stream<List<AuditLogEntity>> watchAuditLogsForTrip(
      String companyId, String tripId) {
    return Stream.value(auditLogs.where((l) => l.entityId == tripId).toList());
  }
}

class MockCustomerRepository implements CustomerRepository {
  final List<CustomerEntity> customers = [];
  final List<ContractEntity> contracts = [];
  final List<InvoiceEntity> invoices = [];

  @override
  Stream<List<CustomerEntity>> watchCustomers(String companyId) =>
      Stream.value(customers);
  @override
  Future<List<CustomerEntity>> getCustomers(String companyId) async =>
      customers;
  @override
  Future<CustomerEntity?> getCustomerById(
          String companyId, String customerId) async =>
      null;
  @override
  Future<CustomerEntity> createCustomer(
          String companyId, CustomerEntity customer) async =>
      customer;
  @override
  Future<void> updateCustomer(
      String companyId, CustomerEntity customer) async {}
  @override
  Future<void> deleteCustomer(String companyId, String customerId) async {}

  @override
  Stream<List<ContractEntity>> watchContracts(String companyId) =>
      Stream.value(contracts);
  @override
  Future<List<ContractEntity>> getContracts(String companyId) async =>
      contracts;
  @override
  Future<ContractEntity?> getContractById(
          String companyId, String contractId) async =>
      null;
  @override
  Future<ContractEntity> createContract(
          String companyId, ContractEntity contract) async =>
      contract;
  @override
  Future<void> updateContract(
      String companyId, ContractEntity contract) async {}
  @override
  Future<void> deleteContract(String companyId, String contractId) async {}

  @override
  Stream<List<InvoiceEntity>> watchInvoices(String companyId) =>
      Stream.value(invoices);
  @override
  Future<List<InvoiceEntity>> getInvoices(String companyId) async => invoices;
  @override
  Future<InvoiceEntity?> getInvoiceById(
          String companyId, String invoiceId) async =>
      null;
  @override
  Future<InvoiceEntity> createInvoice(
      String companyId, InvoiceEntity invoice) async {
    invoices.add(invoice);
    return invoice;
  }

  @override
  Future<void> updateInvoiceStatus(
      String companyId, String invoiceId, String status) async {}
  @override
  Future<void> deleteInvoice(String companyId, String invoiceId) async {}
}

void main() {
  group('Dispatch & Route Planning Business Logic Tests', () {
    final now = DateTime.now();

    final tRoute = RouteEntity(
      id: 'r_1',
      name: 'Chicago to New York',
      startLocation: 'Chicago',
      endLocation: 'New York',
      distanceKm: 800.0,
      estimatedDurationMinutes: 720,
      createdAt: now,
      updatedAt: now,
    );

    final tVehicle = VehicleEntity(
      id: 'v_1',
      vin: 'VIN123',
      licensePlate: 'NY-884-OK',
      make: 'Volvo',
      model: 'VNL',
      year: 2023,
      status: 'active',
      fuelType: 'diesel',
      odometer: 100.0,
      insuranceExpiry: now.add(const Duration(days: 30)),
      pucExpiry: now.add(const Duration(days: 30)),
      fitnessExpiry: now.add(const Duration(days: 30)),
      createdAt: now,
      updatedAt: now,
    );

    final tDriver = DriverEntity(
      id: 'd_1',
      fullName: 'Robert Jenkins',
      phone: '1234567890',
      licenseNumber: 'CDL123',
      licenseExpiry: now.add(const Duration(days: 100)),
      status: 'available',
      safetyScore: 95.0,
      createdAt: now,
      updatedAt: now,
    );

    test('should validate Route CRUD operations successfully', () async {
      final dispatchRepo = MockDispatchRepository();
      final tripRepo = MockTripRepository(trips: []);

      final container = ProviderContainer(
        overrides: [
          currentUserProvider.overrideWith((ref) => UserEntity(
                uid: 'u_1',
                email: 'operator@fleet.com',
                displayName: 'Operator John',
                role: 'admin',
                companyId: 'c_1',
                createdAt: now,
              )),
          dispatchRepositoryProvider.overrideWithValue(dispatchRepo),
          tripRepositoryProvider.overrideWithValue(tripRepo),
        ],
      );

      final formController =
          container.read(routeFormControllerProvider.notifier);
      final listController =
          container.read(routeListControllerProvider.notifier);

      // Create Route
      var success = await formController.saveRoute(tRoute.copyWith(id: ''));
      expect(success, true);
      expect(dispatchRepo.routes.length, 1);
      expect(dispatchRepo.routes[0].name, 'Chicago to New York');

      // Update Route
      final createdRoute = dispatchRepo.routes[0];
      final updatedRoute = createdRoute.copyWith(distanceKm: 850.0);
      success = await formController.saveRoute(updatedRoute);
      expect(success, true);
      expect(dispatchRepo.routes[0].distanceKm, 850.0);

      // Delete Route
      success = await listController.deleteRoute(createdRoute.id);
      expect(success, true);
      expect(dispatchRepo.routes[0].deletedAt, isNotNull);
    });

    test('should validate Dispatch CRUD and availability locks', () async {
      final dispatchRepo = MockDispatchRepository();
      final vehicleRepo = MockVehicleRepository(vehicles: [tVehicle]);
      final driverRepo = MockDriverRepository(drivers: [tDriver]);
      final tripRepo = MockTripRepository(trips: []);
      final customerRepo = MockCustomerRepository();

      final container = ProviderContainer(
        overrides: [
          currentUserProvider.overrideWith((ref) => UserEntity(
                uid: 'u_1',
                email: 'operator@fleet.com',
                displayName: 'Operator John',
                role: 'admin',
                companyId: 'c_1',
                createdAt: now,
              )),
          dispatchRepositoryProvider.overrideWithValue(dispatchRepo),
          vehicleRepositoryProvider.overrideWithValue(vehicleRepo),
          driverRepositoryProvider.overrideWithValue(driverRepo),
          tripRepositoryProvider.overrideWithValue(tripRepo),
          customerRepositoryProvider.overrideWithValue(customerRepo),
        ],
      );

      final formController =
          container.read(dispatchFormControllerProvider.notifier);

      final dispatch = DispatchEntity(
        id: '',
        dispatchNumber: 'DISP-001',
        companyId: 'c_1',
        vehicleId: 'v_1',
        vehicleLicensePlate: 'NY-884-OK',
        driverId: 'd_1',
        driverName: 'Robert Jenkins',
        routeId: 'r_1',
        routeName: 'Chicago to New York',
        status: 'scheduled',
        scheduledTime: now.add(const Duration(hours: 2)),
        createdAt: now,
        updatedAt: now,
      );

      // 1. Success Create Dispatch (and associated Trip)
      var success = await formController.saveDispatch(dispatch);
      expect(success, true);
      expect(dispatchRepo.dispatches.length, 1);
      final nonDummyTrips =
          tripRepo.trips.where((t) => t.id.isNotEmpty).toList();
      expect(nonDummyTrips.length, 1);
      expect(nonDummyTrips[0].status, 'scheduled');
      expect(dispatchRepo.dispatches[0].tripId, nonDummyTrips[0].id);

      // 2. Block dispatch if driver already has an active dispatch
      final dispatch2 = dispatch.copyWith(
          dispatchNumber: 'DISP-002',
          vehicleId: 'v_other',
          vehicleLicensePlate: 'LP-OTHER');
      success = await formController.saveDispatch(dispatch2);
      expect(success, false);
      expect(container.read(dispatchFormControllerProvider).errorMessage,
          contains('Driver is already assigned'));

      // 3. Block dispatch if vehicle already has an active dispatch
      final dispatch3 = dispatch.copyWith(
          dispatchNumber: 'DISP-003',
          driverId: 'd_other',
          driverName: 'Driver Other');
      success = await formController.saveDispatch(dispatch3);
      expect(success, false);
      expect(container.read(dispatchFormControllerProvider).errorMessage,
          contains('Vehicle is already assigned'));
    });

    test(
        'should propagate dispatch status transitions to driver, vehicle, and trips',
        () async {
      final dispatch = DispatchEntity(
        id: 'disp_123',
        dispatchNumber: 'DISP-001',
        companyId: 'c_1',
        vehicleId: 'v_1',
        vehicleLicensePlate: 'NY-884-OK',
        driverId: 'd_1',
        driverName: 'Robert Jenkins',
        routeId: 'r_1',
        routeName: 'Chicago to New York',
        status: 'scheduled',
        scheduledTime: now.add(const Duration(hours: 2)),
        tripId: 'trip_123',
        createdAt: now,
        updatedAt: now,
      );

      final trip = TripEntity(
        id: 'trip_123',
        companyId: 'c_1',
        vehicleId: 'v_1',
        vehicleLicensePlate: 'NY-884-OK',
        driverId: 'd_1',
        driverName: 'Robert Jenkins',
        customerId: 'cust_1',
        customerName: 'Customer 1',
        pickupLocation: 'Chicago',
        deliveryLocation: 'New York',
        cargoType: 'Coal',
        coalQuantity: 25.0,
        freightAmount: 1000.0,
        advancePayment: 0.0,
        permitExpense: 0.0,
        status: 'scheduled',
        statusHistory: const [],
        createdAt: now,
        updatedAt: now,
      );

      final dispatchRepo = MockDispatchRepository();
      dispatchRepo.dispatches.add(dispatch);

      final vehicleRepo = MockVehicleRepository(vehicles: [tVehicle]);
      final driverRepo = MockDriverRepository(drivers: [tDriver]);
      final tripRepo = MockTripRepository(trips: [trip]);

      final container = ProviderContainer(
        overrides: [
          currentUserProvider.overrideWith((ref) => UserEntity(
                uid: 'u_1',
                email: 'operator@fleet.com',
                displayName: 'Operator John',
                role: 'admin',
                companyId: 'c_1',
                createdAt: now,
              )),
          dispatchRepositoryProvider.overrideWithValue(dispatchRepo),
          vehicleRepositoryProvider.overrideWithValue(vehicleRepo),
          driverRepositoryProvider.overrideWithValue(driverRepo),
          tripRepositoryProvider.overrideWithValue(tripRepo),
          tripListControllerProvider.overrideWith(
              (ref) => TripListController(repository: tripRepo, ref: ref)),
        ],
      );

      final listController =
          container.read(dispatchListControllerProvider.notifier);

      // Transition to In Transit
      var success = await listController.updateStatus('disp_123', 'in_transit');
      expect(success, true);
      expect(dispatchRepo.dispatches[0].status, 'in_transit');
      expect(tripRepo.trips[0].status, 'inTransit');
      expect(vehicleRepo.vehicles[0].status, 'inTransit');
      expect(driverRepo.drivers[0].status, 'on_duty');

      // Transition to Completed
      success = await listController.updateStatus('disp_123', 'completed');
      expect(success, true);
      expect(dispatchRepo.dispatches[0].status, 'completed');
      expect(tripRepo.trips[0].status, 'completed');
      expect(vehicleRepo.vehicles[0].status, 'active');
      expect(driverRepo.drivers[0].status, 'available');
    });

    test('should incorporate dispatch metrics in dashboard provider', () async {
      final container = ProviderContainer(
        overrides: [
          currentUserProvider.overrideWith((ref) => UserEntity(
                uid: 'u_1',
                email: 'operator@fleet.com',
                displayName: 'Operator John',
                role: 'admin',
                companyId: 'c_1',
                createdAt: now,
              )),
          vehiclesStreamProvider.overrideWith((ref) => Stream.value([])),
          tripsStreamProvider.overrideWith((ref) => Stream.value([])),
          driversStreamProvider.overrideWith((ref) => Stream.value([])),
          customersStreamProvider.overrideWith((ref) => Stream.value([])),
          vendorsStreamProvider.overrideWith((ref) => Stream.value([])),
          partsStreamProvider.overrideWith((ref) => Stream.value([])),
          contractsStreamProvider.overrideWith((ref) => Stream.value([])),
          invoicesStreamProvider.overrideWith((ref) => Stream.value([])),
          routesStreamProvider
              .overrideWith((ref) => Stream.value([tRoute, tRoute])),
          dispatchesStreamProvider.overrideWith((ref) => Stream.value([
                DispatchEntity(
                  id: 'd_1',
                  dispatchNumber: 'D1',
                  companyId: 'c_1',
                  vehicleId: 'v_1',
                  vehicleLicensePlate: 'LP1',
                  driverId: 'dr_1',
                  driverName: 'Dr 1',
                  routeId: 'r_1',
                  routeName: 'R 1',
                  status: 'in_transit',
                  scheduledTime: now,
                  createdAt: now,
                  updatedAt: now,
                )
              ])),
        ],
      );

      // Force resolution of the stream providers
      await container.read(vehiclesStreamProvider.future);
      await container.read(tripsStreamProvider.future);
      await container.read(driversStreamProvider.future);
      await container.read(customersStreamProvider.future);
      await container.read(vendorsStreamProvider.future);
      await container.read(partsStreamProvider.future);
      await container.read(contractsStreamProvider.future);
      await container.read(invoicesStreamProvider.future);
      await container.read(routesStreamProvider.future);
      await container.read(dispatchesStreamProvider.future);

      final statsAsync = container.read(dashboardStatsProvider);
      expect(statsAsync.hasValue, true);

      final stats = statsAsync.value!;
      expect(stats.totalRoutesCount, 2);
      expect(stats.activeDispatchesCount, 1);
    });
  });
}
