import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../hr_providers.dart';
import '../../domain/payroll_entity.dart';

class PayrollScreen extends ConsumerStatefulWidget {
  const PayrollScreen({super.key});

  @override
  ConsumerState<PayrollScreen> createState() => _PayrollScreenState();
}

class _PayrollScreenState extends ConsumerState<PayrollScreen> {
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;

  @override
  Widget build(BuildContext context) {
    final payrollKey = '${_selectedMonth}_$_selectedYear';
    final payrollAsync = ref.watch(payrollStreamProvider(payrollKey));
    final controllerState = ref.watch(payrollFormControllerProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payroll Preparation'),
      ),
      body: controllerState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Select Month / Year Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<int>(
                              value: _selectedMonth,
                              decoration: const InputDecoration(
                                  labelText: 'Month',
                                  border: OutlineInputBorder()),
                              items: List.generate(12, (index) {
                                final date = DateTime(2026, index + 1, 1);
                                return DropdownMenuItem(
                                  value: index + 1,
                                  child: Text(DateFormat('MMMM').format(date)),
                                );
                              }),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => _selectedMonth = val);
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: DropdownButtonFormField<int>(
                              value: _selectedYear,
                              decoration: const InputDecoration(
                                  labelText: 'Year',
                                  border: OutlineInputBorder()),
                              items: [2025, 2026, 2027].map((y) {
                                return DropdownMenuItem(
                                    value: y, child: Text('$y'));
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => _selectedYear = val);
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 16, horizontal: 8),
                              ),
                              icon: const Icon(Icons.calculate_outlined),
                              label: const Text('Process / Calculate',
                                  overflow: TextOverflow.ellipsis),
                              onPressed: () => _generatePayroll(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Payroll table
                  Expanded(
                    child: payrollAsync.when(
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (err, _) => Center(child: Text('Error: $err')),
                      data: (payrollLines) {
                        if (payrollLines.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.receipt_long_outlined,
                                    size: 64, color: colorScheme.outline),
                                const SizedBox(height: 16),
                                Text(
                                  'No payroll processed for this month yet.',
                                  style: theme.textTheme.titleMedium,
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                    'Click "Process / Calculate" to generate drafts.'),
                              ],
                            ),
                          );
                        }

                        return Card(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              columns: const [
                                DataColumn(
                                    label: Text('Employee Name',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold))),
                                DataColumn(
                                    label: Text('Base Salary',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold))),
                                DataColumn(
                                    label: Text('Allowances',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold))),
                                DataColumn(
                                    label: Text('Deductions (Absences)',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold))),
                                DataColumn(
                                    label: Text('Net Salary',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold))),
                                DataColumn(
                                    label: Text('Status',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold))),
                                DataColumn(
                                    label: Text('Action',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold))),
                              ],
                              rows: payrollLines.map((p) {
                                return DataRow(
                                  cells: [
                                    DataCell(Text(p.employeeName)),
                                    DataCell(Text(
                                        '\$${p.baseSalary.toStringAsFixed(2)}')),
                                    DataCell(Text(
                                        '\$${p.allowances.toStringAsFixed(2)}')),
                                    DataCell(Text(
                                        '\$${p.deductions.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                            color: Colors.red))),
                                    DataCell(Text(
                                        '\$${p.netSalary.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.green))),
                                    DataCell(
                                        _PayrollStatusChip(status: p.status)),
                                    DataCell(
                                      p.status == 'draft'
                                          ? ElevatedButton(
                                              onPressed: () =>
                                                  _showPayoutDialog(context, p),
                                              child: const Text('Pay Out'),
                                            )
                                          : Text(
                                              'Paid: ${DateFormat('yyyy-MM-dd').format(p.paidAt!)}'),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  void _generatePayroll() async {
    final success = await ref
        .read(payrollFormControllerProvider.notifier)
        .prepareMonthlyPayroll(_selectedMonth, _selectedYear);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Payroll processed and generated successfully')),
      );
    }
  }

  void _showPayoutDialog(BuildContext context, PayrollEntity payroll) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return PayoutDialog(payroll: payroll);
      },
    );
  }
}

class PayoutDialog extends ConsumerStatefulWidget {
  final PayrollEntity payroll;

  const PayoutDialog({super.key, required this.payroll});

  @override
  ConsumerState<PayoutDialog> createState() => _PayoutDialogState();
}

class _PayoutDialogState extends ConsumerState<PayoutDialog> {
  final _formKey = GlobalKey<FormState>();
  final _refController = TextEditingController();

  @override
  void dispose() {
    _refController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Record Payout for ${widget.payroll.employeeName}'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
                'Confirm Net Salary to Pay: \$${widget.payroll.netSalary.toStringAsFixed(2)}'),
            const SizedBox(height: 16),
            TextFormField(
              controller: _refController,
              decoration: const InputDecoration(
                labelText: 'Transaction Reference ID / Bank Ref',
                border: OutlineInputBorder(),
              ),
              validator: (String? val) =>
                  val == null || val.isEmpty ? 'Required' : null,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            if (_formKey.currentState?.validate() ?? false) {
              final ok = await ref
                  .read(payrollFormControllerProvider.notifier)
                  .processPayout(widget.payroll, _refController.text.trim());
              if (context.mounted) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(ok
                          ? 'Payout recorded successfully'
                          : 'Failed to record payout')),
                );
              }
            }
          },
          child: const Text('Complete Payout'),
        ),
      ],
    );
  }
}

class _PayrollStatusChip extends StatelessWidget {
  final String status;

  const _PayrollStatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case 'paid':
        color = Colors.green;
        break;
      case 'processed':
        color = Colors.blue;
        break;
      case 'draft':
      default:
        color = Colors.orange;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.toUpperCase(),
        style:
            TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}
