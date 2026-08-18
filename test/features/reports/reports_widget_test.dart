import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fleet_os_erp/features/auth/presentation/auth_providers.dart';
import 'package:fleet_os_erp/features/auth/domain/user_entity.dart';
import 'package:fleet_os_erp/features/vehicles/presentation/vehicle_providers.dart';
import 'package:fleet_os_erp/features/drivers/presentation/driver_providers.dart';
import 'package:fleet_os_erp/features/trips/presentation/trip_providers.dart';
import 'package:fleet_os_erp/features/customers/domain/invoice_entity.dart';
import 'package:fleet_os_erp/features/billing/presentation/billing_providers.dart';
import 'package:fleet_os_erp/features/finance/presentation/finance_providers.dart';
import 'package:fleet_os_erp/features/fleet_ops/presentation/fleet_ops_providers.dart';
import 'package:fleet_os_erp/features/inventory/presentation/inventory_providers.dart';
import 'package:fleet_os_erp/features/customers/presentation/customer_providers.dart';
import 'package:fleet_os_erp/features/reports/presentation/report_screen.dart';
import 'package:fleet_os_erp/features/reports/presentation/report_providers.dart';
import 'reports_providers_test.dart' show MockReportRepository;

void main() {
  testWidgets('ReportScreen displays filters, KPIs, and rendering tabs',
      (WidgetTester tester) async {
    final now = DateTime.now();

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

    final mockRepo = MockReportRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserProvider.overrideWith((ref) => UserEntity(
                uid: 'u_1',
                email: 'operator@fleet.com',
                displayName: 'Operator John',
                role: 'admin',
                companyId: 'c_1',
                createdAt: now,
              )),
          reportRepositoryProvider.overrideWithValue(mockRepo),
          vehiclesStreamProvider.overrideWith((ref) => Stream.value([])),
          driversStreamProvider.overrideWith((ref) => Stream.value([])),
          tripsStreamProvider.overrideWith((ref) => Stream.value([])),
          billingInvoicesProvider
              .overrideWith((ref) => Stream.value([testInvoice])),
          billingPaymentsProvider.overrideWith((ref) => Stream.value([])),
          financeTransactionsStreamProvider
              .overrideWith((ref) => Stream.value([])),
          partsStreamProvider.overrideWith((ref) => Stream.value([])),
          fuelLogsStreamProvider.overrideWith((ref) => Stream.value([])),
          maintenanceLogsStreamProvider.overrideWith((ref) => Stream.value([])),
          customersStreamProvider.overrideWith((ref) => Stream.value([])),
          contractsStreamProvider.overrideWith((ref) => Stream.value([])),
          savedReportsProvider.overrideWith((ref) => Stream.value([])),
        ],
        child: const MaterialApp(
          home: ReportScreen(),
        ),
      ),
    );

    // Let streams settle and UI build
    await tester.pumpAndSettle();

    // Verify main title is displayed
    expect(find.text('Enterprise BI & Reporting Engine'), findsOneWidget);

    // Verify default category Title is Revenue Report
    expect(find.text('Revenue Report'), findsOneWidget);

    // Verify filter buttons exist
    expect(find.text('Filter Date Range'), findsOneWidget);
    expect(find.text('All Vehicles'), findsOneWidget);

    // Verify calculated KPIs are displayed on screen
    expect(find.text('Total Invoiced'), findsOneWidget);
    expect(find.text('\$5500.00'),
        findsNWidgets(2)); // Total Invoiced & Total Collected

    // Verify tabs are available
    expect(find.text('Visual Analytics'), findsOneWidget);
    expect(find.text('Data Table Grid'), findsOneWidget);
    expect(find.text('Saved Reports'), findsOneWidget);

    // Verify custom painter line chart is rendering
    expect(find.byType(CustomPaint), findsAtLeastNWidgets(1));

    // Tap Data Table Grid tab
    final dataTableTab = find.text('Data Table Grid');
    await tester.ensureVisible(dataTableTab);
    await tester.tap(dataTableTab);
    await tester.pumpAndSettle();

    // Verify invoice number inside data table row
    expect(find.text('INV-TEST-01'), findsOneWidget);
    expect(find.text('Walmart Inc'), findsOneWidget);
  });
}
