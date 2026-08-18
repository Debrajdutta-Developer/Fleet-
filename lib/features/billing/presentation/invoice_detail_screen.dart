import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../customers/domain/invoice_entity.dart';
import '../domain/payment_entity.dart';
import 'billing_providers.dart';

class InvoiceDetailScreen extends ConsumerStatefulWidget {
  final String invoiceId;

  const InvoiceDetailScreen({super.key, required this.invoiceId});

  @override
  ConsumerState<InvoiceDetailScreen> createState() =>
      _InvoiceDetailScreenState();
}

class _InvoiceDetailScreenState extends ConsumerState<InvoiceDetailScreen> {
  final _paymentFormKey = GlobalKey<FormState>();
  double _paymentAmount = 0.0;
  String _paymentMethod = 'cash';
  final _paymentNotesController = TextEditingController();
  final _paymentRefController = TextEditingController();

  @override
  void dispose() {
    _paymentNotesController.dispose();
    _paymentRefController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final invoicesAsync = ref.watch(billingInvoicesProvider);
    final paymentsAsync = ref.watch(billingPaymentsProvider);

    // Watch loading states
    final invoiceState = ref.watch(billingInvoiceFormControllerProvider);
    final paymentState = ref.watch(paymentFormControllerProvider);

    ref.listen<InvoiceFormState>(billingInvoiceFormControllerProvider,
        (prev, next) {
      if (next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(next.errorMessage!), backgroundColor: Colors.red),
        );
      }
      if (next.isCompleted) {
        ref.invalidate(billingInvoicesProvider);
      }
    });

    ref.listen<PaymentFormState>(paymentFormControllerProvider, (prev, next) {
      if (next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(next.errorMessage!), backgroundColor: Colors.red),
        );
      }
      if (next.isCompleted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment transaction completed.')),
        );
        ref.invalidate(billingInvoicesProvider);
        ref.invalidate(billingPaymentsProvider);
      }
    });

    if (invoicesAsync.isLoading || paymentsAsync.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final invoices = invoicesAsync.value ?? [];
    final idx = invoices.indexWhere((inv) => inv.id == widget.invoiceId);
    if (idx == -1) {
      return const Scaffold(
        body: Center(child: Text('Invoice not found.')),
      );
    }
    final invoice = invoices[idx];

    final payments = (paymentsAsync.value ?? [])
        .where((p) => p.invoiceId == invoice.id)
        .toList();

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isDesktop = screenWidth > 992;

    return Scaffold(
      appBar: AppBar(
        title: Text('Invoice #${invoice.invoiceNumber}'),
        actions: [
          if (invoice.status == 'draft')
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: ElevatedButton.icon(
                icon: const Icon(Icons.send_rounded),
                label: const Text('Issue Invoice'),
                onPressed: () => _confirmIssue(context, invoice.id),
              ),
            ),
          if (invoice.status == 'draft' || user?.role == 'admin')
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Edit Invoice',
              onPressed: () {
                context.push('/invoices/${invoice.id}/edit');
              },
            ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded),
            tooltip: 'Delete Invoice',
            onPressed: () => _confirmDelete(context, invoice.id),
          ),
        ],
      ),
      body: (invoiceState.isLoading || paymentState.isLoading)
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  if (isDesktop)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                            flex: 2,
                            child:
                                _buildDetailsCard(invoice, theme, colorScheme)),
                        const SizedBox(width: 24),
                        Expanded(
                            child: _buildPaymentsSummaryCard(
                                invoice, payments, theme, colorScheme)),
                      ],
                    )
                  else
                    Column(
                      children: [
                        _buildDetailsCard(invoice, theme, colorScheme),
                        const SizedBox(height: 24),
                        _buildPaymentsSummaryCard(
                            invoice, payments, theme, colorScheme),
                      ],
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildDetailsCard(
      InvoiceEntity invoice, ThemeData theme, ColorScheme colorScheme) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.outline.withOpacity(0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      invoice.customerName,
                      style: theme.textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text('Customer ID: ${invoice.customerId}'),
                  ],
                ),
                _buildStatusBadge(invoice.status, colorScheme),
              ],
            ),
            const Divider(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildInfoColumn('Issue Date', _formatDate(invoice.issueDate)),
                _buildInfoColumn('Due Date', _formatDate(invoice.dueDate)),
                _buildInfoColumn(
                    'Trip ID Reference',
                    invoice.tripId.isNotEmpty
                        ? invoice.tripId.substring(0, 8).toUpperCase()
                        : 'N/A'),
                _buildInfoColumn(
                    'Dispatch ID Reference',
                    invoice.dispatchId != null
                        ? invoice.dispatchId!.substring(0, 8).toUpperCase()
                        : 'N/A'),
              ],
            ),
            const Divider(height: 40),
            Text(
              'Charges Breakdown',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildChargesBreakdown(invoice, theme),
            const Divider(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'GRAND TOTAL',
                  style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900, color: colorScheme.primary),
                ),
                Text(
                  '\$${invoice.grandTotal.toStringAsFixed(2)}',
                  style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900, color: colorScheme.primary),
                ),
              ],
            ),
            if (invoice.notes != null && invoice.notes!.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text(
                'Notes & Payment Terms',
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(invoice.notes!, style: theme.textTheme.bodyMedium),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildChargesBreakdown(InvoiceEntity invoice, ThemeData theme) {
    return Column(
      children: [
        _buildBreakdownRow('Freight Rate Charge', invoice.freightCharge),
        _buildBreakdownRow('Fuel Surcharge', invoice.fuelCharge),
        _buildBreakdownRow('Toll Expenses', invoice.tollCharge),
        _buildBreakdownRow('Demurrage & Extras', invoice.extraCharges),
        _buildBreakdownRow('Discounts Applied', -invoice.discount,
            isNegative: true),
        _buildBreakdownRow('GST/VAT tax (18% default)', invoice.gstVat),
      ],
    );
  }

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

  Widget _buildInfoColumn(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildStatusBadge(String status, ColorScheme colorScheme) {
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: badgeColor.withOpacity(0.3)),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
            color: badgeColor, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }

  Widget _buildPaymentsSummaryCard(InvoiceEntity invoice,
      List<PaymentEntity> payments, ThemeData theme, ColorScheme colorScheme) {
    return Column(
      children: [
        Card(
          elevation: 0,
          color: colorScheme.primaryContainer.withOpacity(0.1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: colorScheme.primary.withOpacity(0.1)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Payment Summary',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                _buildSummaryLine('Amount Paid',
                    '\$${invoice.amountPaid.toStringAsFixed(2)}', Colors.green),
                const SizedBox(height: 12),
                _buildSummaryLine(
                    'Outstanding',
                    '\$${invoice.outstandingAmount.toStringAsFixed(2)}',
                    Colors.red),
                if (invoice.outstandingAmount > 0.0 &&
                    invoice.status != 'draft' &&
                    invoice.status != 'cancelled') ...[
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.add_card_rounded),
                      label: const Text('Record Payment'),
                      onPressed: () =>
                          _showRecordPaymentDialog(context, invoice),
                    ),
                  ),
                ]
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: colorScheme.outline.withOpacity(0.2)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Payment Logs',
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                if (payments.isEmpty)
                  const Center(child: Text('No payments recorded.'))
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: payments.length,
                    separatorBuilder: (_, __) => const Divider(),
                    itemBuilder: (context, index) {
                      final p = payments[index];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                            '\$${p.amount.toStringAsFixed(2)} - ${p.paymentMethod.toUpperCase()}'),
                        subtitle: Text(
                          'Date: ${_formatDate(p.paymentDate)}\nRef: ${p.referenceNumber ?? "None"}\nStatus: ${p.status.toUpperCase()}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: (p.status == 'completed')
                            ? TextButton(
                                onPressed: () => _confirmRefund(context, p.id),
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
                  )
              ],
            ),
          ),
        )
      ],
    );
  }

  Widget _buildSummaryLine(String label, String value, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        Text(value,
            style: TextStyle(
                fontWeight: FontWeight.bold, fontSize: 18, color: valueColor)),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return date.toLocal().toString().split(' ')[0];
  }

  void _showRecordPaymentDialog(BuildContext context, InvoiceEntity invoice) {
    _paymentAmount = invoice.outstandingAmount;
    _paymentMethod = 'cash';
    _paymentNotesController.clear();
    _paymentRefController.clear();

    showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Record Invoice Payment'),
              content: Form(
                key: _paymentFormKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      initialValue: _paymentAmount.toStringAsFixed(2),
                      decoration: const InputDecoration(
                        labelText: 'Payment Amount (\$)',
                      ),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty)
                          return 'Required';
                        final amt = double.tryParse(val);
                        if (amt == null) return 'Invalid number';
                        if (amt <= 0.0) return 'Must be greater than zero';
                        if (amt > invoice.outstandingAmount) {
                          return 'Cannot exceed remaining invoice balance';
                        }
                        return null;
                      },
                      onChanged: (val) {
                        _paymentAmount = double.tryParse(val) ?? 0.0;
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _paymentMethod,
                      decoration:
                          const InputDecoration(labelText: 'Payment Method'),
                      items: const [
                        DropdownMenuItem(value: 'cash', child: Text('Cash')),
                        DropdownMenuItem(
                            value: 'bank_transfer',
                            child: Text('Bank Transfer')),
                        DropdownMenuItem(value: 'upi', child: Text('UPI')),
                        DropdownMenuItem(
                            value: 'card', child: Text('Debit/Credit Card')),
                        DropdownMenuItem(
                            value: 'cheque', child: Text('Cheque')),
                        DropdownMenuItem(value: 'other', child: Text('Other')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() => _paymentMethod = val);
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _paymentRefController,
                      decoration: const InputDecoration(
                        labelText: 'Ref / Cheque / Transaction ID (Optional)',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _paymentNotesController,
                      decoration: const InputDecoration(
                        labelText: 'Transaction Notes (Optional)',
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (!_paymentFormKey.currentState!.validate()) return;
                    Navigator.pop(context);

                    final payment = PaymentEntity(
                      id: '',
                      companyId: '',
                      invoiceId: invoice.id,
                      amount: _paymentAmount,
                      paymentMethod: _paymentMethod,
                      status: 'completed',
                      paymentDate: DateTime.now(),
                      referenceNumber: _paymentRefController.text.trim(),
                      notes: _paymentNotesController.text.trim(),
                      createdAt: DateTime.now(),
                      updatedAt: DateTime.now(),
                    );
                    await ref
                        .read(paymentFormControllerProvider.notifier)
                        .recordPayment(payment);
                  },
                  child: const Text('Confirm'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmIssue(BuildContext context, String invoiceId) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Issue'),
        content: const Text(
            'Are you sure you want to issue this invoice? This will create official accounting ledger entries and lock editing unless you are an Administrator.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ref
                  .read(billingInvoiceFormControllerProvider.notifier)
                  .issueInvoice(invoiceId);
            },
            child: const Text('Issue'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, String invoiceId) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Invoice'),
        content: const Text(
            'Are you sure you want to delete this invoice? This action soft-deletes the invoice and cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await ref
                  .read(billingInvoiceFormControllerProvider.notifier)
                  .deleteInvoice(invoiceId);
              if (success && context.mounted) {
                context.pop();
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _confirmRefund(BuildContext context, String paymentId) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Refund Transaction'),
        content: const Text(
            'Are you sure you want to issue a full refund for this payment transaction? This will revert the invoice balance and outstanding amount, and write debit ledger records.'),
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
