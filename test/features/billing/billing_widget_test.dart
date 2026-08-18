import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fleet_os_erp/features/auth/presentation/auth_providers.dart';
import 'package:fleet_os_erp/features/auth/domain/user_entity.dart';
import 'package:fleet_os_erp/features/customers/presentation/customer_providers.dart';
import 'package:fleet_os_erp/features/customers/domain/invoice_entity.dart';
import 'package:fleet_os_erp/features/billing/presentation/billing_providers.dart';
import 'package:fleet_os_erp/features/customers/presentation/invoice_list_screen.dart';

void main() {
  testWidgets('InvoiceListScreen displays tabs and lists invoices correctly',
      (WidgetTester tester) async {
    final now = DateTime.now();

    final testInvoice = InvoiceEntity(
      id: 'inv_test_1',
      tripId: 't_1',
      customerId: 'cust_1',
      customerName: 'Walmart Inc',
      invoiceNumber: 'INV-TEST-99',
      freightCharge: 2000.0,
      grandTotal: 2000.0,
      outstandingAmount: 2000.0,
      amountPaid: 0.0,
      status: 'issued',
      issueDate: now,
      dueDate: now.add(const Duration(days: 30)),
      createdAt: now,
      updatedAt: now,
    );

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
          billingInvoicesProvider
              .overrideWith((ref) => Stream.value([testInvoice])),
          billingPaymentsProvider.overrideWith((ref) => Stream.value([])),
          billingAuditLogsProvider.overrideWith((ref) => Stream.value([])),
          customersStreamProvider.overrideWith((ref) => Stream.value([])),
        ],
        child: const MaterialApp(
          home: InvoiceListScreen(),
        ),
      ),
    );

    // Let the streams emit data and settle
    await tester.pumpAndSettle();

    // Verify app bar title
    expect(find.text('Billing, Invoicing & Payments'), findsOneWidget);

    // Verify tab headers are present
    expect(find.text('Invoices'), findsOneWidget);
    expect(find.text('Payment Logs'), findsOneWidget);
    expect(find.text('Reports & Ledger'), findsOneWidget);

    // Verify the invoice item is rendered in the list
    expect(find.text('INV-TEST-99'), findsOneWidget);
    expect(find.textContaining('Walmart Inc'), findsOneWidget);
  });
}
