import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fleet_os_erp/features/vehicles/domain/vehicle_entity.dart';
import 'package:fleet_os_erp/features/trips/domain/trip_entity.dart';
import 'package:fleet_os_erp/features/vehicles/presentation/vehicle_providers.dart';
import 'package:fleet_os_erp/features/trips/presentation/trip_providers.dart';
import 'package:fleet_os_erp/features/dashboard/presentation/dashboard_providers.dart';
import 'package:fleet_os_erp/features/drivers/presentation/driver_providers.dart';
import 'package:fleet_os_erp/features/customers/presentation/customer_providers.dart';
import 'package:fleet_os_erp/features/vendors/presentation/vendor_providers.dart';
import 'package:fleet_os_erp/features/inventory/presentation/inventory_providers.dart';
import 'package:fleet_os_erp/features/dispatch/presentation/dispatch_providers.dart';

void main() {
  group('Dashboard Stats Provider Tests', () {
    final now = DateTime.now();

    final tVehicles = [
      VehicleEntity(
        id: 'v1',
        vin: 'VIN1',
        licensePlate: 'LP1',
        make: 'Volvo',
        model: 'VNL',
        year: 2023,
        status: 'active',
        fuelType: 'diesel',
        odometer: 1000,
        insuranceExpiry: now.add(const Duration(days: 30)),
        pucExpiry: now.add(const Duration(days: 30)),
        fitnessExpiry: now.add(const Duration(days: 30)),
        createdAt: now,
        updatedAt: now,
      ),
      VehicleEntity(
        id: 'v2',
        vin: 'VIN2',
        licensePlate: 'LP2',
        make: 'Volvo',
        model: 'VNL',
        year: 2023,
        status: 'active',
        fuelType: 'diesel',
        odometer: 2000,
        // Expired insurance (should count as critical diagnostic issue)
        insuranceExpiry: now.subtract(const Duration(days: 1)),
        pucExpiry: now.add(const Duration(days: 30)),
        fitnessExpiry: now.add(const Duration(days: 30)),
        createdAt: now,
        updatedAt: now,
      ),
      VehicleEntity(
        id: 'v3',
        vin: 'VIN3',
        licensePlate: 'LP3',
        make: 'Volvo',
        model: 'VNL',
        year: 2023,
        status: 'maintenance',
        fuelType: 'diesel',
        odometer: 3000,
        insuranceExpiry: now.add(const Duration(days: 30)),
        pucExpiry: now.add(const Duration(days: 30)),
        fitnessExpiry: now.add(const Duration(days: 30)),
        createdAt: now,
        updatedAt: now,
      ),
    ];

    final tTrips = [
      TripEntity(
        id: 't1',
        companyId: 'comp_1',
        vehicleId: 'v1',
        vehicleLicensePlate: 'LP1',
        driverId: 'd1',
        driverName: 'John',
        customerId: 'c1',
        customerName: 'Walmart',
        pickupLocation: 'NY',
        deliveryLocation: 'BOS',
        cargoType: 'Coal',
        coalQuantity: 20, // 20 tons
        freightAmount: 1000,
        advancePayment: 100,
        permitExpense: 0,
        status: 'inTransit', // Active trip
        statusHistory: [],
        createdAt: now,
        updatedAt: now,
      ),
      TripEntity(
        id: 't2',
        companyId: 'comp_1',
        vehicleId: 'v2',
        vehicleLicensePlate: 'LP2',
        driverId: 'd2',
        driverName: 'Sarah',
        customerId: 'c1',
        customerName: 'Walmart',
        pickupLocation: 'NY',
        deliveryLocation: 'BOS',
        cargoType: 'Coal',
        coalQuantity: 15, // 15 tons
        freightAmount: 1000,
        advancePayment: 100,
        permitExpense: 0,
        status: 'scheduled', // Scheduled/Planned trip
        statusHistory: [],
        createdAt: now,
        updatedAt: now,
      ),
    ];

    test('should correctly compute all live stats metrics from streams',
        () async {
      final container = ProviderContainer(
        overrides: [
          vehiclesStreamProvider.overrideWith((ref) => Stream.value(tVehicles)),
          tripsStreamProvider.overrideWith((ref) => Stream.value(tTrips)),
          driversStreamProvider.overrideWith((ref) => Stream.value([])),
          customersStreamProvider.overrideWith((ref) => Stream.value([])),
          vendorsStreamProvider.overrideWith((ref) => Stream.value([])),
          partsStreamProvider.overrideWith((ref) => Stream.value([])),
          contractsStreamProvider.overrideWith((ref) => Stream.value([])),
          invoicesStreamProvider.overrideWith((ref) => Stream.value([])),
          routesStreamProvider.overrideWith((ref) => Stream.value([])),
          dispatchesStreamProvider.overrideWith((ref) => Stream.value([])),
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

      // 1. Verify active fleet count (v1 and v2 are active; v3 is in maintenance)
      expect(stats.activeFleetCount, 2);

      // 2. Verify trips scheduled (t2 is scheduled; t1 is inTransit)
      expect(stats.tripsScheduled, 1);

      // 3. Verify critical diagnostics count (v2 has expired insurance)
      expect(stats.criticalDiagnosticsCount, 1);

      // 4. Verify average payload capacity:
      // Active trips are t1 (inTransit, cargo 20) and t2 (scheduled, cargo 15).
      // Total coal = 20 + 15 = 35 tons.
      // Average capacity = (35 / (2 * 25)) * 100 = 70%
      expect(stats.averagePayloadCapacity, 70.0);

      // 5. Verify customer and vendor counts
      expect(stats.totalCustomersCount, 0);
      expect(stats.totalVendorsCount, 0);

      // 6. Verify inventory statistics
      expect(stats.totalPartsCount, 0);
      expect(stats.lowStockPartsCount, 0);
      expect(stats.totalStockValue, 0.0);

      // 7. Verify contract & invoice statistics
      expect(stats.activeContractsCount, 0);
      expect(stats.outstandingInvoicesAmount, 0.0);
    });
  });
}
