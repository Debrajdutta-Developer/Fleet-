import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fleet_os_erp/features/auth/presentation/auth_providers.dart';
import 'package:fleet_os_erp/features/auth/domain/user_entity.dart';
import 'package:fleet_os_erp/features/vehicles/domain/vehicle_entity.dart';
import 'package:fleet_os_erp/features/vehicles/presentation/vehicle_providers.dart';
import 'package:fleet_os_erp/features/drivers/domain/driver_entity.dart';
import 'package:fleet_os_erp/features/drivers/presentation/driver_providers.dart';
import 'package:fleet_os_erp/features/trips/domain/trip_entity.dart';
import 'package:fleet_os_erp/features/trips/presentation/trip_providers.dart';
import 'package:fleet_os_erp/features/customers/domain/invoice_entity.dart';
import 'package:fleet_os_erp/features/billing/presentation/billing_providers.dart';
import 'package:fleet_os_erp/features/finance/domain/finance_transaction_entity.dart';
import 'package:fleet_os_erp/features/finance/presentation/finance_providers.dart';
import 'package:fleet_os_erp/features/fleet_ops/presentation/fleet_ops_providers.dart';
import 'package:fleet_os_erp/features/inventory/presentation/inventory_providers.dart';
import 'package:fleet_os_erp/features/customers/presentation/customer_providers.dart';
import 'package:fleet_os_erp/features/customers/domain/customer_entity.dart';
import 'package:fleet_os_erp/features/reports/domain/report_entity.dart';
import 'package:fleet_os_erp/features/reports/domain/report_repository.dart';
import 'package:fleet_os_erp/features/reports/presentation/report_providers.dart';

class MockReportRepository implements ReportRepository {
  final List<ReportEntity> reports = [];

  @override
  Stream<List<ReportEntity>> watchReports(String companyId) =>
      Stream.value(reports);

  @override
  Future<List<ReportEntity>> getReports(String companyId) async => reports;

  @override
  Future<ReportEntity?> getReportById(String companyId, String id) async {
    try {
      return reports.firstWhere((r) => r.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<ReportEntity> createReport(
      String companyId, ReportEntity report) async {
    final newReport = report.copyWith(id: 'rep_${reports.length}');
    reports.add(newReport);
    return newReport;
  }

  @override
  Future<void> deleteReport(String companyId, String id) async {
    reports.removeWhere((r) => r.id == id);
  }
}

void main() {
  group('Reports & BI Providers Unit Tests', () {
    late ProviderContainer container;
    late MockReportRepository reportRepo;
    final now = DateTime.now();

    // Mock data elements
    final testVehicle = VehicleEntity(
      id: 'v_1',
      vin: '1234567890VIN',
      licensePlate: 'NY-884-AB',
      make: 'Volvo',
      model: 'FH16',
      year: 2022,
      status: 'active',
      fuelType: 'diesel',
      odometer: 150000.0,
      fitnessExpiry: now.add(const Duration(days: 180)),
      insuranceExpiry: now.add(const Duration(days: 180)),
      pucExpiry: now.add(const Duration(days: 180)),
      createdAt: now,
      updatedAt: now,
    );

    final testDriver = DriverEntity(
      id: 'd_1',
      fullName: 'John Doe',
      phone: '+15550199',
      licenseNumber: 'CDL9988',
      licenseExpiry: now.add(const Duration(days: 365)),
      status: 'available',
      safetyScore: 92,
      createdAt: now,
      updatedAt: now,
    );

    final testTrip = TripEntity(
      id: 't_1',
      companyId: 'c_1',
      vehicleId: 'v_1',
      vehicleLicensePlate: 'NY-884-AB',
      driverId: 'd_1',
      driverName: 'John Doe',
      customerId: 'cust_1',
      customerName: 'Walmart Inc',
      pickupLocation: 'Chicago Hub',
      deliveryLocation: 'New York Port',
      cargoType: 'Electronics',
      coalQuantity: 18.0,
      freightAmount: 5000.0,
      advancePayment: 1000.0,
      permitExpense: 200.0,
      status: 'completed',
      statusHistory: const [],
      createdAt: now,
      updatedAt: now,
    );

    final testInvoice = InvoiceEntity(
      id: 'inv_1',
      tripId: 't_1',
      customerId: 'cust_1',
      customerName: 'Walmart Inc',
      invoiceNumber: 'INV-TEST-01',
      freightCharge: 5000.0,
      grandTotal: 5500.0,
      amountPaid: 5500.0,
      outstandingAmount: 0.0,
      status: 'paid',
      issueDate: now,
      dueDate: now.add(const Duration(days: 30)),
      createdAt: now,
      updatedAt: now,
    );

    final testExpense = FinanceTransactionEntity(
      id: 'tx_1',
      companyId: 'c_1',
      type: 'expense',
      category: 'diesel',
      amount: 1200.0,
      paymentMode: 'cash',
      tripId: 't_1',
      tripNumber: 'TRIP-001',
      vehicleId: 'v_1',
      vehicleLicensePlate: 'NY-884-AB',
      transactionDate: now,
      createdAt: now,
      updatedAt: now,
    );

    final testCustomer = CustomerEntity(
      id: 'cust_1',
      name: 'Walmart Inc',
      contactName: 'Jane Smith',
      email: 'logistics@walmart.com',
      phone: '1-800-walmart',
      address: 'Bentonville, AR',
      createdAt: now,
      updatedAt: now,
    );

    setUp(() {
      reportRepo = MockReportRepository();
      container = ProviderContainer(
        overrides: [
          currentUserProvider.overrideWith((ref) => UserEntity(
                uid: 'u_1',
                email: 'analyst@fleet.com',
                displayName: 'BI Analyst',
                role: 'admin',
                companyId: 'c_1',
                createdAt: now,
              )),
          reportRepositoryProvider.overrideWithValue(reportRepo),
          vehiclesStreamProvider
              .overrideWith((ref) => Stream.value([testVehicle])),
          driversStreamProvider
              .overrideWith((ref) => Stream.value([testDriver])),
          tripsStreamProvider.overrideWith((ref) => Stream.value([testTrip])),
          billingInvoicesProvider
              .overrideWith((ref) => Stream.value([testInvoice])),
          billingPaymentsProvider.overrideWith((ref) => Stream.value([])),
          financeTransactionsStreamProvider
              .overrideWith((ref) => Stream.value([testExpense])),
          partsStreamProvider.overrideWith((ref) => Stream.value([])),
          fuelLogsStreamProvider.overrideWith((ref) => Stream.value([])),
          maintenanceLogsStreamProvider.overrideWith((ref) => Stream.value([])),
          customersStreamProvider
              .overrideWith((ref) => Stream.value([testCustomer])),
          contractsStreamProvider.overrideWith((ref) => Stream.value([])),
        ],
      );
      // Listen to reportDataProvider to keep stream subscriptions warm and active
      container.listen(reportDataProvider, (previous, next) {});
    });

    tearDown(() {
      container.dispose();
    });

    test('SelectedReportType initial state defaults to financial_revenue', () {
      expect(container.read(selectedReportTypeProvider), 'financial_revenue');
    });

    test('Timeframe initial state defaults to monthly', () {
      expect(container.read(reportTimeframeProvider), 'monthly');
    });

    test('Filters initial state carries empty fields', () {
      final filters = container.read(reportFiltersProvider);
      expect(filters.vehicleId, isNull);
      expect(filters.customerId, isNull);
      expect(filters.dateRange, isNull);
    });

    test('Financial Revenue calculations are aggregated correctly', () async {
      // Set to revenue type
      container.read(selectedReportTypeProvider.notifier).state =
          'financial_revenue';

      // Let streams settle
      await pumpEventQueue();

      final reportDataVal = container.read(reportDataProvider);
      expect(reportDataVal, isA<AsyncData<ReportData>>());

      final data = reportDataVal.value!;
      expect(data.kpis['Total Invoiced'], '\$5500.00');
      expect(data.kpis['Total Collected'], '\$5500.00');
      expect(data.kpis['Outstanding Receivables'], '\$0.00');
      expect(data.rows.length, 1);
      expect(data.rows.first['Invoice Number'], 'INV-TEST-01');
      expect(data.chartData.length, 1);
      expect(data.chartData.first.value, 5500.0);
    });

    test('Financial Expense calculations are aggregated correctly', () async {
      container.read(selectedReportTypeProvider.notifier).state =
          'financial_expense';
      await pumpEventQueue();

      final reportDataVal = container.read(reportDataProvider);
      final data = reportDataVal.value!;

      expect(data.kpis['Total Expenses'], '\$1200.00');
      expect(data.kpis['Fuel Expenses'], '\$1200.00');
      expect(data.rows.length, 1);
      expect(data.rows.first['Category'], 'diesel');
    });

    test('Profit & Loss calculations verify net operational profit', () async {
      container.read(selectedReportTypeProvider.notifier).state =
          'financial_profit_loss';
      await pumpEventQueue();

      final reportDataVal = container.read(reportDataProvider);
      final data = reportDataVal.value!;

      expect(data.kpis['Total Income'], '\$5500.00');
      expect(data.kpis['Total Expense'], '\$1200.00');
      expect(data.kpis['Net Profit'], '\$4300.00');
    });

    test('Fleet Availability calculates active rates correctly', () async {
      container.read(selectedReportTypeProvider.notifier).state =
          'fleet_availability';
      await pumpEventQueue();

      final reportDataVal = container.read(reportDataProvider);
      final data = reportDataVal.value!;

      expect(data.kpis['Total Fleet Size'], '1');
      expect(data.kpis['Available Vehicles'], '1');
      expect(data.kpis['Availability Rate'], '100.0%');
    });

    test(
        'Save report parameters generates a database record and logs audit trail',
        () async {
      final data = ReportData(
        kpis: const {'Key': 'Value'},
        rows: const [
          {'Col': 'Row'}
        ],
        chartData: const [ChartDataPoint(label: 'Jan', value: 100.0)],
      );

      final filters = const ReportFilters();

      await container
          .read(reportSaveControllerProvider.notifier)
          .saveReport('Test Revenue Run', 'financial_revenue', data, filters);

      final saved = await reportRepo.getReports('c_1');
      expect(saved.length, 1);
      expect(saved.first.title, 'Test Revenue Run');
      expect(saved.first.type, 'financial_revenue');
    });
  });
}
