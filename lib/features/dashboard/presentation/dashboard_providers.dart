import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../vehicles/presentation/vehicle_providers.dart';
import '../../trips/presentation/trip_providers.dart';
import '../../drivers/presentation/driver_providers.dart';
import '../../customers/presentation/customer_providers.dart';
import '../../vendors/presentation/vendor_providers.dart';
import '../../inventory/presentation/inventory_providers.dart';
import '../../dispatch/presentation/dispatch_providers.dart';

class DashboardStats {
  final int activeFleetCount;
  final int tripsScheduled;
  final int criticalDiagnosticsCount;
  final double averagePayloadCapacity;
  final int totalDriversCount;
  final int availableDriversCount;
  final int expiredLicenseDriversCount;
  final int totalCustomersCount;
  final int totalVendorsCount;
  final int totalPartsCount;
  final int lowStockPartsCount;
  final double totalStockValue;
  final int activeContractsCount;
  final double outstandingInvoicesAmount;
  final int totalRoutesCount;
  final int activeDispatchesCount;

  // Billing & Invoicing Sprint 2.8 additions
  final double totalRevenue;
  final double revenueToday;
  final double revenueThisMonth;
  final double outstandingAmount;
  final int overdueInvoicesCount;
  final int paidInvoicesCount;
  final double collectionRate;

  const DashboardStats({
    required this.activeFleetCount,
    required this.tripsScheduled,
    required this.criticalDiagnosticsCount,
    required this.averagePayloadCapacity,
    required this.totalDriversCount,
    required this.availableDriversCount,
    required this.expiredLicenseDriversCount,
    required this.totalCustomersCount,
    required this.totalVendorsCount,
    required this.totalPartsCount,
    required this.lowStockPartsCount,
    required this.totalStockValue,
    required this.activeContractsCount,
    required this.outstandingInvoicesAmount,
    required this.totalRoutesCount,
    required this.activeDispatchesCount,
    required this.totalRevenue,
    required this.revenueToday,
    required this.revenueThisMonth,
    required this.outstandingAmount,
    required this.overdueInvoicesCount,
    required this.paidInvoicesCount,
    required this.collectionRate,
  });
}

final dashboardStatsProvider =
    Provider.autoDispose<AsyncValue<DashboardStats>>((ref) {
  final vehiclesAsync = ref.watch(vehiclesStreamProvider);
  final tripsAsync = ref.watch(tripsStreamProvider);
  final driversAsync = ref.watch(driversStreamProvider);
  final customersAsync = ref.watch(customersStreamProvider);
  final vendorsAsync = ref.watch(vendorsStreamProvider);
  final partsAsync = ref.watch(partsStreamProvider);
  final contractsAsync = ref.watch(contractsStreamProvider);
  final invoicesAsync = ref.watch(invoicesStreamProvider);
  final routesAsync = ref.watch(routesStreamProvider);
  final dispatchesAsync = ref.watch(dispatchesStreamProvider);

  if (vehiclesAsync.isLoading ||
      tripsAsync.isLoading ||
      driversAsync.isLoading ||
      customersAsync.isLoading ||
      vendorsAsync.isLoading ||
      partsAsync.isLoading ||
      contractsAsync.isLoading ||
      invoicesAsync.isLoading ||
      routesAsync.isLoading ||
      dispatchesAsync.isLoading) {
    return const AsyncValue.loading();
  }

  if (vehiclesAsync.hasError) {
    return AsyncValue.error(vehiclesAsync.error!, vehiclesAsync.stackTrace!);
  }
  if (tripsAsync.hasError) {
    return AsyncValue.error(tripsAsync.error!, tripsAsync.stackTrace!);
  }
  if (driversAsync.hasError) {
    return AsyncValue.error(driversAsync.error!, driversAsync.stackTrace!);
  }
  if (customersAsync.hasError) {
    return AsyncValue.error(customersAsync.error!, customersAsync.stackTrace!);
  }
  if (vendorsAsync.hasError) {
    return AsyncValue.error(vendorsAsync.error!, vendorsAsync.stackTrace!);
  }
  if (partsAsync.hasError) {
    return AsyncValue.error(partsAsync.error!, partsAsync.stackTrace!);
  }
  if (contractsAsync.hasError) {
    return AsyncValue.error(contractsAsync.error!, contractsAsync.stackTrace!);
  }
  if (invoicesAsync.hasError) {
    return AsyncValue.error(invoicesAsync.error!, invoicesAsync.stackTrace!);
  }
  if (routesAsync.hasError) {
    return AsyncValue.error(routesAsync.error!, routesAsync.stackTrace!);
  }
  if (dispatchesAsync.hasError) {
    return AsyncValue.error(
        dispatchesAsync.error!, dispatchesAsync.stackTrace!);
  }

  final vehicles = vehiclesAsync.value ?? [];
  final trips = tripsAsync.value ?? [];
  final drivers = driversAsync.value ?? [];
  final customers = customersAsync.value ?? [];
  final vendors = vendorsAsync.value ?? [];
  final parts = partsAsync.value ?? [];
  final contracts = contractsAsync.value ?? [];
  final invoices = invoicesAsync.value ?? [];
  final routes = routesAsync.value ?? [];
  final dispatches = dispatchesAsync.value ?? [];

  // 1. Active Fleet Count
  final activeFleetCount = vehicles.where((v) => v.status == 'active').length;

  // 2. Trips Scheduled
  final tripsScheduled = trips
      .where((t) => t.status == 'scheduled' || t.status == 'planned')
      .length;

  // 3. Critical Diagnostics (Vehicles with expired compliance)
  final criticalDiagnosticsCount = vehicles.where((v) {
    return VehicleComplianceHelper.isInsuranceExpired(v) ||
        VehicleComplianceHelper.isPucExpired(v) ||
        VehicleComplianceHelper.isFitnessExpired(v);
  }).length;

  // 4. Active Cargo Volume / Average payload capacity
  final activeTrips =
      trips.where((t) => t.status != 'completed' && t.status != 'cancelled');
  double averagePayloadCapacity = 0.0;
  if (activeTrips.isNotEmpty) {
    final totalCoal = activeTrips
        .map((t) => t.coalQuantity)
        .fold<double>(0.0, (sum, val) => sum + val);
    averagePayloadCapacity = (totalCoal / (activeTrips.length * 25.0)) * 100;
    if (averagePayloadCapacity > 100.0) averagePayloadCapacity = 100.0;
  }

  // 5. Driver Statistics
  final totalDriversCount = drivers.length;
  final availableDriversCount =
      drivers.where((d) => d.status == 'available').length;
  final expiredLicenseDriversCount =
      drivers.where((d) => d.licenseExpiry.isBefore(DateTime.now())).length;

  // 6. Customer & Vendor Statistics
  final totalCustomersCount = customers.length;
  final totalVendorsCount = vendors.length;

  // 7. Spare Parts Inventory Statistics
  final totalPartsCount = parts.length;
  final lowStockPartsCount =
      parts.where((p) => p.quantity <= p.minStockThreshold).length;
  final totalStockValue =
      parts.fold<double>(0.0, (sum, p) => sum + (p.quantity * p.unitCost));

  // 8. Contract & Invoice Statistics
  final activeContractsCount =
      contracts.where((c) => c.status == 'active').length;
  final outstandingInvoicesAmount = invoices
      .where((i) => i.status == 'sent')
      .fold<double>(0.0, (sum, i) => sum + i.amount);

  // Billing & Invoicing Sprint 2.8 additions
  final totalRevenue = invoices
      .where((i) => i.status != 'draft' && i.status != 'cancelled')
      .fold<double>(0.0, (sum, i) => sum + i.grandTotal);

  final now = DateTime.now();
  final revenueToday = invoices
      .where((i) =>
          i.status != 'draft' &&
          i.status != 'cancelled' &&
          i.issueDate.year == now.year &&
          i.issueDate.month == now.month &&
          i.issueDate.day == now.day)
      .fold<double>(0.0, (sum, i) => sum + i.grandTotal);

  final revenueThisMonth = invoices
      .where((i) =>
          i.status != 'draft' &&
          i.status != 'cancelled' &&
          i.issueDate.year == now.year &&
          i.issueDate.month == now.month)
      .fold<double>(0.0, (sum, i) => sum + i.grandTotal);

  final outstandingAmount = invoices
      .where((i) => i.status != 'cancelled' && i.status != 'draft')
      .fold<double>(0.0, (sum, i) => sum + i.outstandingAmount);

  final overdueInvoicesCount = invoices
      .where((i) =>
          i.status == 'overdue' ||
          (i.status != 'paid' &&
              i.status != 'cancelled' &&
              i.dueDate.isBefore(now)))
      .length;

  final paidInvoicesCount = invoices.where((i) => i.status == 'paid').length;

  double collectionRate = 100.0;
  final totalPaidAmount = invoices
      .where((i) => i.status != 'draft' && i.status != 'cancelled')
      .fold<double>(0.0, (sum, i) => sum + i.amountPaid);
  if (totalRevenue > 0.0) {
    collectionRate = (totalPaidAmount / totalRevenue) * 100;
  }

  return AsyncValue.data(DashboardStats(
    activeFleetCount: activeFleetCount,
    tripsScheduled: tripsScheduled,
    criticalDiagnosticsCount: criticalDiagnosticsCount,
    averagePayloadCapacity: averagePayloadCapacity,
    totalDriversCount: totalDriversCount,
    availableDriversCount: availableDriversCount,
    expiredLicenseDriversCount: expiredLicenseDriversCount,
    totalCustomersCount: totalCustomersCount,
    totalVendorsCount: totalVendorsCount,
    totalPartsCount: totalPartsCount,
    lowStockPartsCount: lowStockPartsCount,
    totalStockValue: totalStockValue,
    activeContractsCount: activeContractsCount,
    outstandingInvoicesAmount: outstandingInvoicesAmount,
    totalRoutesCount: routes.length,
    activeDispatchesCount:
        dispatches.where((d) => d.status == 'in_transit').length,
    totalRevenue: totalRevenue,
    revenueToday: revenueToday,
    revenueThisMonth: revenueThisMonth,
    outstandingAmount: outstandingAmount,
    overdueInvoicesCount: overdueInvoicesCount,
    paidInvoicesCount: paidInvoicesCount,
    collectionRate: collectionRate,
  ));
});
