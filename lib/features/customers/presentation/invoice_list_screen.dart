import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../customers/presentation/customer_providers.dart';
import '../../customers/domain/invoice_entity.dart';
import '../domain/customer_entity.dart';
import '../../billing/domain/payment_entity.dart';
import '../../billing/presentation/billing_providers.dart';
import '../../trips/domain/audit_log_entity.dart';
import '../../../core/widgets/empty_state_widget.dart';

class InvoiceListScreen extends ConsumerStatefulWidget {
  const InvoiceListScreen({super.key});

  @override
  ConsumerState<InvoiceListScreen> createState() => _InvoiceListScreenState();
}

class _InvoiceListScreenState extends ConsumerState<InvoiceListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _invoiceFilterStatus = 'all';
  String _paymentFilterMethod = 'all';
  String? _selectedReportCustomerId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final invoicesAsync = ref.watch(billingInvoicesProvider);
    final paymentsAsync = ref.watch(billingPaymentsProvider);
    final auditLogsAsync = ref.watch(billingAuditLogsProvider);
    final customersAsync = ref.watch(customersStreamProvider);

    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isDesktop = screenWidth > 992;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Billing, Invoicing & Payments'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.add_rounded),
              label: const Text('Create Invoice'),
              onPressed: () {
                context.push('/invoices/new');
              },
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.receipt_long_rounded), text: 'Invoices'),
            Tab(icon: Icon(Icons.payment_rounded), text: 'Payment Logs'),
            Tab(icon: Icon(Icons.analytics_rounded), text: 'Reports & Ledger'),
          ],
        ),
      ),
      body: invoicesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: EmptyStateWidget(
            title: 'Failed to sync invoices',
            description: err.toString(),
            icon: Icons.error_outline_rounded,
            actionText: 'Retry',
            onActionPressed: () => ref.invalidate(billingInvoicesProvider),
          ),
        ),
        data: (invoices) {
          final payments = paymentsAsync.value ?? [];
          final auditLogs = auditLogsAsync.value ?? [];
          final customers = customersAsync.value ?? [];

          return TabBarView(
            controller: _tabController,
            children: [
              _buildInvoicesTab(invoices, isDesktop, colorScheme, theme),
              _buildPaymentsTab(payments, isDesktop, colorScheme, theme),
              _buildReportsTab(invoices, payments, auditLogs, customers,
                  isDesktop, colorScheme, theme),
            ],
          );
        },
      ),
    );
  }

  // --- TAB 1: INVOICES ---

  Widget _buildInvoicesTab(List<InvoiceEntity> invoices, bool isDesktop,
      ColorScheme colorScheme, ThemeData theme) {
    // Metric Calculations
    final totalReceivables = invoices
        .where((i) =>
            i.status == 'issued' ||
            i.status == 'partially_paid' ||
            i.status == 'overdue')
        .fold<double>(0.0, (sum, i) => sum + i.outstandingAmount);
    final totalDrafts = invoices.where((i) => i.status == 'draft').length;
    final totalOverdue = invoices
        .where((i) =>
            i.status == 'overdue' ||
            (i.status != 'paid' &&
                i.status != 'cancelled' &&
                i.dueDate.isBefore(DateTime.now())))
        .length;

    final filteredInvoices = invoices.where((inv) {
      if (_invoiceFilterStatus == 'all') return true;
      return inv.status == _invoiceFilterStatus;
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row of Metric Cards
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'Total Outstanding Receivables',
                  '\$${totalReceivables.toStringAsFixed(2)}',
                  Icons.pending_actions_outlined,
                  Colors.red,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildMetricCard(
                  'Unissued Drafts',
                  totalDrafts.toString(),
                  Icons.edit_document,
                  Colors.indigo,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildMetricCard(
                  'Overdue Invoices',
                  totalOverdue.toString(),
                  Icons.warning_amber_rounded,
                  Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Filter Selector Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              DropdownButton<String>(
                value: _invoiceFilterStatus,
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('All Invoices')),
                  DropdownMenuItem(value: 'draft', child: Text('Drafts')),
                  DropdownMenuItem(value: 'issued', child: Text('Issued')),
                  DropdownMenuItem(
                      value: 'partially_paid', child: Text('Partially Paid')),
                  DropdownMenuItem(value: 'paid', child: Text('Paid')),
                  DropdownMenuItem(value: 'overdue', child: Text('Overdue')),
                  DropdownMenuItem(
                      value: 'cancelled', child: Text('Cancelled')),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _invoiceFilterStatus = val);
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Table / List View
          Expanded(
            child: filteredInvoices.isEmpty
                ? const Center(
                    child: Text('No invoices match the selected filter.'))
                : _buildInvoicesListOrTable(
                    filteredInvoices, isDesktop, theme, colorScheme),
          ),
        ],
      ),
    );
  }

  Widget _buildInvoicesListOrTable(List<InvoiceEntity> list, bool isDesktop,
      ThemeData theme, ColorScheme colorScheme) {
    if (isDesktop) {
      return Card(
        clipBehavior: Clip.antiAlias,
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: DataTable(
            columns: const [
              DataColumn(label: Text('INVOICE NUMBER')),
              DataColumn(label: Text('CUSTOMER')),
              DataColumn(label: Text('GRAND TOTAL')),
              DataColumn(label: Text('OUTSTANDING')),
              DataColumn(label: Text('STATUS')),
              DataColumn(label: Text('DUE DATE')),
              DataColumn(label: Text('ACTIONS')),
            ],
            rows: list.map((inv) {
              return DataRow(cells: [
                DataCell(Text(inv.invoiceNumber,
                    style: const TextStyle(fontWeight: FontWeight.bold))),
                DataCell(Text(inv.customerName)),
                DataCell(Text('\$${inv.grandTotal.toStringAsFixed(2)}')),
                DataCell(Text('\$${inv.outstandingAmount.toStringAsFixed(2)}',
                    style: TextStyle(
                        color: inv.outstandingAmount > 0
                            ? Colors.red
                            : Colors.green))),
                DataCell(_buildBadge(inv.status)),
                DataCell(Text(inv.dueDate.toLocal().toString().split(' ')[0])),
                DataCell(
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.visibility_outlined),
                        onPressed: () => context.push('/invoices/${inv.id}'),
                      ),
                      if (inv.status == 'draft')
                        IconButton(
                          icon: const Icon(Icons.send_rounded),
                          onPressed: () => _triggerIssueInvoice(inv.id),
                        ),
                    ],
                  ),
                ),
              ]);
            }).toList(),
          ),
        ),
      );
    } else {
      return ListView.builder(
        itemCount: list.length,
        itemBuilder: (context, index) {
          final inv = list[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              title: Text(inv.invoiceNumber,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(
                  '${inv.customerName}\nGrand Total: \$${inv.grandTotal.toStringAsFixed(2)}\nDue: ${inv.dueDate.toLocal().toString().split(' ')[0]}'),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _buildBadge(inv.status),
                  const SizedBox(height: 4),
                  Text(
                      '\$${inv.outstandingAmount.toStringAsFixed(2)} outstanding',
                      style: TextStyle(
                          fontSize: 11,
                          color: inv.outstandingAmount > 0
                              ? Colors.red
                              : Colors.green)),
                ],
              ),
              onTap: () => context.push('/invoices/${inv.id}'),
            ),
          );
        },
      );
    }
  }

  // --- TAB 2: PAYMENTS LOGS ---

  Widget _buildPaymentsTab(List<PaymentEntity> payments, bool isDesktop,
      ColorScheme colorScheme, ThemeData theme) {
    final filteredPayments = payments.where((p) {
      if (_paymentFilterMethod == 'all') return true;
      return p.paymentMethod == _paymentFilterMethod;
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              DropdownButton<String>(
                value: _paymentFilterMethod,
                items: const [
                  DropdownMenuItem(
                      value: 'all', child: Text('All Payment Modes')),
                  DropdownMenuItem(value: 'cash', child: Text('Cash')),
                  DropdownMenuItem(
                      value: 'bank_transfer', child: Text('Bank Transfer')),
                  DropdownMenuItem(value: 'upi', child: Text('UPI')),
                  DropdownMenuItem(value: 'card', child: Text('Card')),
                  DropdownMenuItem(value: 'cheque', child: Text('Cheque')),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _paymentFilterMethod = val);
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: filteredPayments.isEmpty
                ? const Center(child: Text('No payments found.'))
                : ListView.separated(
                    itemCount: filteredPayments.length,
                    separatorBuilder: (_, __) => const Divider(),
                    itemBuilder: (context, index) {
                      final p = filteredPayments[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: p.status == 'completed'
                              ? Colors.green.withOpacity(0.1)
                              : Colors.red.withOpacity(0.1),
                          child: Icon(
                            p.status == 'completed'
                                ? Icons.check_circle_outline
                                : Icons.replay_circle_filled_outlined,
                            color: p.status == 'completed'
                                ? Colors.green
                                : Colors.red,
                          ),
                        ),
                        title: Text(
                            '\$${p.amount.toStringAsFixed(2)} - ${p.paymentMethod.toUpperCase()}'),
                        subtitle: Text(
                          'Payment Date: ${p.paymentDate.toLocal().toString().split(' ')[0]}\nRef: ${p.referenceNumber ?? "N/A"}\nStatus: ${p.status.toUpperCase()}',
                        ),
                        trailing: p.status == 'completed'
                            ? OutlinedButton(
                                onPressed: () => _confirmPaymentRefund(p.id),
                                child: const Text('Refund'),
                              )
                            : Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'REFUNDED',
                                  style: TextStyle(
                                      color: Colors.red,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // --- TAB 3: REPORTS & LEDGERS ---

  Widget _buildReportsTab(
      List<InvoiceEntity> invoices,
      List<PaymentEntity> payments,
      List<AuditLogEntity> auditLogs,
      List<CustomerEntity> customers,
      bool isDesktop,
      ColorScheme colorScheme,
      ThemeData theme) {
    return DefaultTabController(
      length: 4,
      child: Column(
        children: [
          TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: const [
              Tab(text: 'Outstanding report'),
              Tab(text: 'Revenue Summary'),
              Tab(text: 'Customer Ledger'),
              Tab(text: 'Invoice History / Audit'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildOutstandingReportSubTab(invoices, customers, theme),
                _buildRevenueSummarySubTab(invoices, theme),
                _buildCustomerLedgerSubTab(
                    invoices, payments, customers, theme),
                _buildAuditLogsSubTab(auditLogs, theme),
              ],
            ),
          )
        ],
      ),
    );
  }

  // --- 3.1 Outstanding Receivables Aging Report ---
  Widget _buildOutstandingReportSubTab(List<InvoiceEntity> invoices,
      List<CustomerEntity> customers, ThemeData theme) {
    final now = DateTime.now();
    double current = 0.0;
    double overdue1To30 = 0.0;
    double overdue31To60 = 0.0;
    double overdue60Plus = 0.0;

    for (final inv in invoices) {
      if (inv.status == 'cancelled' ||
          inv.status == 'draft' ||
          inv.outstandingAmount == 0.0) continue;
      if (inv.dueDate.isAfter(now)) {
        current += inv.outstandingAmount;
      } else {
        final diffDays = now.difference(inv.dueDate).inDays;
        if (diffDays <= 30) {
          overdue1To30 += inv.outstandingAmount;
        } else if (diffDays <= 60) {
          overdue31To60 += inv.outstandingAmount;
        } else {
          overdue60Plus += inv.outstandingAmount;
        }
      }
    }

    final totalOutstanding =
        current + overdue1To30 + overdue31To60 + overdue60Plus;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
              'Aged Accounts Receivable (Total Outstanding: \$${totalOutstanding.toStringAsFixed(2)})',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          // Aging Cards Grid
          Row(
            children: [
              Expanded(
                  child: _buildMetricCard(
                      'Current (Not Due)',
                      '\$${current.toStringAsFixed(2)}',
                      Icons.schedule,
                      Colors.blue)),
              const SizedBox(width: 8),
              Expanded(
                  child: _buildMetricCard(
                      '1-30 Days Overdue',
                      '\$${overdue1To30.toStringAsFixed(2)}',
                      Icons.warning_amber_rounded,
                      Colors.orange)),
              const SizedBox(width: 8),
              Expanded(
                  child: _buildMetricCard(
                      '31-60 Days Overdue',
                      '\$${overdue31To60.toStringAsFixed(2)}',
                      Icons.error_outline_rounded,
                      Colors.redAccent)),
              const SizedBox(width: 8),
              Expanded(
                  child: _buildMetricCard(
                      '60+ Days Overdue',
                      '\$${overdue60Plus.toStringAsFixed(2)}',
                      Icons.dangerous_outlined,
                      Colors.red)),
            ],
          ),
          const SizedBox(height: 32),
          Text('Outstanding Balance by Customer',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Card(
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: customers.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (context, index) {
                final c = customers[index];
                final creditUsage = c.creditLimit > 0
                    ? (c.outstandingBalance / c.creditLimit) * 100
                    : 0.0;
                return ListTile(
                  title: Text(c.name,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                      'Credit Limit: \$${c.creditLimit.toStringAsFixed(2)} (${creditUsage.toStringAsFixed(1)}% used)'),
                  trailing: Text(
                    '\$${c.outstandingBalance.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: c.outstandingBalance > c.creditLimit
                          ? Colors.red
                          : Colors.orange,
                    ),
                  ),
                );
              },
            ),
          )
        ],
      ),
    );
  }

  // --- 3.2 Revenue Summary ---
  Widget _buildRevenueSummarySubTab(
      List<InvoiceEntity> invoices, ThemeData theme) {
    final issuedInvoices = invoices
        .where((i) => i.status != 'cancelled' && i.status != 'draft')
        .toList();

    final double grossFreight =
        issuedInvoices.fold(0.0, (sum, i) => sum + i.freightCharge);
    final double grossFuel =
        issuedInvoices.fold(0.0, (sum, i) => sum + i.fuelCharge);
    final double grossToll =
        issuedInvoices.fold(0.0, (sum, i) => sum + i.tollCharge);
    final double grossExtras =
        issuedInvoices.fold(0.0, (sum, i) => sum + i.extraCharges);
    final double grossDiscount =
        issuedInvoices.fold(0.0, (sum, i) => sum + i.discount);
    final double grossGst =
        issuedInvoices.fold(0.0, (sum, i) => sum + i.gstVat);
    final double netRevenue = grossFreight +
        grossFuel +
        grossToll +
        grossExtras -
        grossDiscount +
        grossGst;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Revenue Breakdown Summary',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  _buildBreakdownRow('Freight Charge Revenue', grossFreight),
                  _buildBreakdownRow('Fuel Surcharge Revenue', grossFuel),
                  _buildBreakdownRow('Toll Expense Reimbursement', grossToll),
                  _buildBreakdownRow('Demurrage & Extra Charges', grossExtras),
                  _buildBreakdownRow('Discounts Subtotal', -grossDiscount,
                      isNegative: true),
                  _buildBreakdownRow('GST/VAT Tax Collected', grossGst),
                  const Divider(height: 40),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('NET REVENUE (ISSUED)',
                          style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary)),
                      Text('\$${netRevenue.toStringAsFixed(2)}',
                          style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary)),
                    ],
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  // --- 3.3 Customer Ledger ---
  Widget _buildCustomerLedgerSubTab(
      List<InvoiceEntity> invoices,
      List<PaymentEntity> payments,
      List<CustomerEntity> customers,
      ThemeData theme) {
    if (_selectedReportCustomerId == null && customers.isNotEmpty) {
      _selectedReportCustomerId = customers[0].id;
    }

    final selectedCustomer =
        customers.any((c) => c.id == _selectedReportCustomerId)
            ? customers.firstWhere((c) => c.id == _selectedReportCustomerId)
            : null;

    final customerInvoices = invoices
        .where((i) =>
            i.customerId == _selectedReportCustomerId &&
            i.status != 'cancelled' &&
            i.status != 'draft')
        .toList();
    final customerPayments = payments.where((p) {
      final inv = invoices.any((i) => i.id == p.invoiceId)
          ? invoices.firstWhere((i) => i.id == p.invoiceId)
          : null;
      return inv?.customerId == _selectedReportCustomerId;
    }).toList();

    // Generate chronological events list
    final List<Map<String, dynamic>> ledgerEvents = [];
    for (final inv in customerInvoices) {
      ledgerEvents.add({
        'date': inv.issueDate,
        'description': 'Invoice #${inv.invoiceNumber} Issued',
        'debit': inv.grandTotal,
        'credit': 0.0,
      });
    }
    for (final p in customerPayments) {
      final isRefund = p.status == 'refunded';
      ledgerEvents.add({
        'date': p.paymentDate,
        'description': isRefund
            ? 'Refund Issued (Ref: ${p.referenceNumber ?? "None"})'
            : 'Payment Received (Ref: ${p.referenceNumber ?? "None"})',
        'debit': isRefund ? p.amount : 0.0,
        'credit': isRefund ? 0.0 : p.amount,
      });
    }

    ledgerEvents.sort(
        (a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime));

    double runningBalance = 0.0;
    final List<Map<String, dynamic>> ledgerWithBalance = [];
    for (final ev in ledgerEvents) {
      runningBalance += ev['debit'] as double;
      runningBalance -= ev['credit'] as double;
      ledgerWithBalance.add({
        ...ev,
        'balance': runningBalance,
      });
    }

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Select Customer:  ',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              DropdownButton<String>(
                value: _selectedReportCustomerId,
                items: customers
                    .map((c) =>
                        DropdownMenuItem(value: c.id, child: Text(c.name)))
                    .toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _selectedReportCustomerId = val);
                  }
                },
              )
            ],
          ),
          const SizedBox(height: 24),
          if (selectedCustomer != null)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                    'Credit Limit: \$${selectedCustomer.creditLimit.toStringAsFixed(2)}'),
                Text(
                    'Current Balance: \$${selectedCustomer.outstandingBalance.toStringAsFixed(2)}',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.orange)),
              ],
            ),
          const SizedBox(height: 16),
          Expanded(
            child: ledgerWithBalance.isEmpty
                ? const Center(
                    child: Text('No transactions recorded in ledger.'))
                : Card(
                    child: ListView.separated(
                      itemCount: ledgerWithBalance.length,
                      separatorBuilder: (_, __) => const Divider(),
                      itemBuilder: (context, index) {
                        final ev = ledgerWithBalance[index];
                        final isDebit = (ev['debit'] as double) > 0.0;
                        return ListTile(
                          title: Text(ev['description'] as String,
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(
                              'Date: ${ev['date'].toString().split(' ')[0]}'),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                isDebit
                                    ? '+\$${ev['debit'].toStringAsFixed(2)}'
                                    : '-\$${ev['credit'].toStringAsFixed(2)}',
                                style: TextStyle(
                                  color: isDebit ? Colors.red : Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                  'Bal: \$${(ev['balance'] as double).toStringAsFixed(2)}',
                                  style: const TextStyle(fontSize: 11)),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
          )
        ],
      ),
    );
  }

  // --- 3.4 Invoice History & Audit Logs ---
  Widget _buildAuditLogsSubTab(List<AuditLogEntity> list, ThemeData theme) {
    // Filter to only display billing-related audit logs
    final billingAuditLogs = list
        .where((log) =>
            log.action == 'invoice_created' ||
            log.action == 'invoice_updated' ||
            log.action == 'invoice_deleted' ||
            log.action == 'invoice_issued' ||
            log.action == 'payment_received' ||
            log.action == 'payment_refunded')
        .toList();

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('System Audit Logs (Billing & Payments History)',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Expanded(
            child: billingAuditLogs.isEmpty
                ? const Center(child: Text('No history logged yet.'))
                : Card(
                    child: ListView.separated(
                      itemCount: billingAuditLogs.length,
                      separatorBuilder: (_, __) => const Divider(),
                      itemBuilder: (context, index) {
                        final log = billingAuditLogs[index];
                        return ListTile(
                          leading: const Icon(Icons.history_toggle_off_rounded),
                          title: Text(log.description),
                          subtitle: Text(
                              'User: ${log.userName} (${log.userId})\nTimestamp: ${log.timestamp.toLocal().toString().split('.')[0]}'),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              log.action.replaceAll('_', ' ').toUpperCase(),
                              style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.blue,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          )
        ],
      ),
    );
  }

  // --- HELPERS & UTILS ---

  Widget _buildBreakdownRow(String label, double value,
      {bool isNegative = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            '\$${value.toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isNegative ? Colors.red : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(
      String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 0,
      color: color.withOpacity(0.04),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: color.withOpacity(0.12)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 8),
                  Text(value,
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: color)),
                ],
              ),
            ),
            Icon(icon, color: color.withOpacity(0.7)),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(String status) {
    Color badgeColor;
    switch (status) {
      case 'paid':
        badgeColor = Colors.green;
        break;
      case 'partially_paid':
        badgeColor = Colors.blue;
        break;
      case 'issued':
        badgeColor = Colors.orange;
        break;
      case 'overdue':
        badgeColor = Colors.red;
        break;
      case 'cancelled':
        badgeColor = Colors.grey;
        break;
      default:
        badgeColor = Colors.indigo;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
            color: badgeColor, fontWeight: FontWeight.bold, fontSize: 10),
      ),
    );
  }

  void _triggerIssueInvoice(String id) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Issue'),
        content: const Text(
            'Are you sure you want to issue this invoice? This will lock editing and record ledger entries.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ref
                  .read(billingInvoiceFormControllerProvider.notifier)
                  .issueInvoice(id);
            },
            child: const Text('Issue'),
          ),
        ],
      ),
    );
  }

  void _confirmPaymentRefund(String paymentId) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Refund'),
        content: const Text(
            'Are you sure you want to issue a full refund? This reverts the invoice and customer balances, and writes ledger entries.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ref
                  .read(paymentFormControllerProvider.notifier)
                  .refundPayment(paymentId);
            },
            child: const Text('Confirm Refund'),
          ),
        ],
      ),
    );
  }
}
