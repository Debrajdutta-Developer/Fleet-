import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../core/widgets/loading_widget.dart';
import '../domain/finance_transaction_entity.dart';
import 'finance_providers.dart';

class FinanceListScreen extends ConsumerStatefulWidget {
  const FinanceListScreen({super.key});

  @override
  ConsumerState<FinanceListScreen> createState() => _FinanceListScreenState();
}

class _FinanceListScreenState extends ConsumerState<FinanceListScreen> {
  String _typeFilter = 'ALL'; // ALL, income, expense
  String _categoryFilter = 'ALL';
  String _searchQuery = '';
  final _searchController = TextEditingController();

  final List<String> _typeFilters = ['ALL', 'income', 'expense'];

  final List<Map<String, String>> _categories = [
    {'value': 'ALL', 'label': 'ALL CATEGORIES'},
    {'value': 'income', 'label': 'Freight Income'},
    {'value': 'driver_salary', 'label': 'Driver Salary'},
    {'value': 'advance_salary', 'label': 'Advance Salary'},
    {'value': 'diesel', 'label': 'Diesel Expense'},
    {'value': 'toll', 'label': 'Toll Expense'},
    {'value': 'repair', 'label': 'Repair Expense'},
    {'value': 'tyre', 'label': 'Tyre Expense'},
    {'value': 'insurance', 'label': 'Insurance Expense'},
    {'value': 'miscellaneous', 'label': 'Miscellaneous'},
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatCategoryKey(String key) {
    return key
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  Color _getCategoryColor(String type) {
    return type == 'income' ? Colors.green : Colors.red;
  }

  Future<void> _handleDeleteTransaction(FinanceTransactionEntity tx) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Soft-Delete Ledger Record'),
        content: Text(
          'Are you sure you want to remove the ledger entry for \$${tx.amount.toStringAsFixed(2)}? This action is soft-delete only.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final success = await ref
          .read(financeListControllerProvider.notifier)
          .deleteTransaction(tx.id, tx.category, tx.amount);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ledger record soft-deleted.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final transactionsAsync = ref.watch(financeTransactionsStreamProvider);
    final ledgerEntries = ref.watch(ledgerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Financial Ledgers'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(financeTransactionsStreamProvider),
            tooltip: 'Refresh Ledger',
          ),
        ],
      ),
      body: transactionsAsync.when(
        loading: () =>
            LoadingWidget.fullScreen(message: 'Compiling financial reports...'),
        error: (err, stack) => Center(
          child: EmptyStateWidget(
            title: 'Finance Ledger Connection Failed',
            description: err.toString(),
            icon: Icons.error_outline_rounded,
            actionText: 'Retry Connection',
            onActionPressed: () =>
                ref.invalidate(financeTransactionsStreamProvider),
          ),
        ),
        data: (txs) {
          // Filter ledger entries
          final filteredLedger = ledgerEntries.where((entry) {
            final tx = entry.transaction;
            final matchesType = _typeFilter == 'ALL' ||
                tx.type.toLowerCase() == _typeFilter.toLowerCase();
            final matchesCategory = _categoryFilter == 'ALL' ||
                tx.category.toLowerCase() == _categoryFilter.toLowerCase();
            final query = _searchQuery.toLowerCase();
            final matchesQuery = (tx.notes?.toLowerCase().contains(query) ??
                    false) ||
                (tx.referenceNumber?.toLowerCase().contains(query) ?? false) ||
                (tx.vehicleLicensePlate?.toLowerCase().contains(query) ??
                    false) ||
                (tx.tripNumber?.toLowerCase().contains(query) ?? false) ||
                tx.category.toLowerCase().contains(query);
            return matchesType && matchesCategory && matchesQuery;
          }).toList();

          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Toolbar
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: (val) => setState(
                          () => _searchQuery = val.trim().toLowerCase(),
                        ),
                        decoration: InputDecoration(
                          hintText:
                              'Search by category, notes, check reference, vehicle plate...',
                          prefixIcon: Icon(
                            Icons.search_outlined,
                            color: colorScheme.onSurface.withOpacity(0.5),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    CustomButton(
                      text: 'REPORTS',
                      icon: Icons.analytics_outlined,
                      width: 130,
                      height: 48,
                      onPressed: () => context.push('/finance/reports'),
                    ),
                    const SizedBox(width: 12),
                    CustomButton(
                      text: 'RECORD',
                      icon: Icons.add_rounded,
                      width: 130,
                      height: 48,
                      onPressed: () => context.push('/finance/new'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Choice chips for income/expense
                Row(
                  children: [
                    ..._typeFilters.map((filter) {
                      final isSelected = _typeFilter == filter;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ChoiceChip(
                          label: Text(filter.toUpperCase()),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) setState(() => _typeFilter = filter);
                          },
                        ),
                      );
                    }),
                    const Spacer(),
                    // Category dropdown filter
                    Container(
                      width: 200,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: colorScheme.outline.withOpacity(0.3),
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _categoryFilter,
                          isExpanded: true,
                          items: _categories.map((c) {
                            return DropdownMenuItem<String>(
                              value: c['value'],
                              child: Text(
                                c['label']!,
                                style: const TextStyle(fontSize: 12),
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _categoryFilter = val);
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Ledger Grid/Table
                Expanded(
                  child: filteredLedger.isEmpty
                      ? EmptyStateWidget(
                          title: 'No Transactions Found',
                          description: _searchQuery.isEmpty
                              ? 'No transactions recorded for this tenant company.'
                              : 'No matches found. Try broadening your filters.',
                          icon: Icons.payments_outlined,
                          actionText: _searchQuery.isEmpty
                              ? 'Record First Entry'
                              : null,
                          onActionPressed: _searchQuery.isEmpty
                              ? () => context.push('/finance/new')
                              : null,
                        )
                      : Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: colorScheme.outline.withOpacity(0.2),
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: SingleChildScrollView(
                              scrollDirection: Axis.vertical,
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: DataTable(
                                  headingRowColor: MaterialStateProperty.all(
                                    colorScheme.surfaceVariant.withOpacity(0.5),
                                  ),
                                  columns: const [
                                    DataColumn(label: Text('DATE')),
                                    DataColumn(label: Text('CATEGORY')),
                                    DataColumn(label: Text('PAYMENT')),
                                    DataColumn(label: Text('ALLOCATIONS')),
                                    DataColumn(label: Text('AMOUNT')),
                                    DataColumn(label: Text('LEDGER BALANCE')),
                                    DataColumn(label: Text('NOTES')),
                                    DataColumn(label: Text('ACTIONS')),
                                  ],
                                  rows: filteredLedger.map((entry) {
                                    final tx = entry.transaction;
                                    final dateStr = DateFormat(
                                      'dd MMM yyyy',
                                    ).format(tx.transactionDate);
                                    final color = _getCategoryColor(tx.type);
                                    final sign =
                                        tx.type == 'income' ? '+' : '-';

                                    List<String> allocs = [];
                                    if (tx.vehicleLicensePlate != null)
                                      allocs.add(
                                        'Vehicle: ${tx.vehicleLicensePlate}',
                                      );
                                    if (tx.tripNumber != null)
                                      allocs.add('Trip #${tx.tripNumber}');
                                    if (tx.vendorName != null)
                                      allocs.add('Vendor: ${tx.vendorName}');
                                    final allocStr = allocs.isEmpty
                                        ? 'General'
                                        : allocs.join('\n');

                                    return DataRow(
                                      cells: [
                                        DataCell(
                                          Text(
                                            dateStr,
                                            style: const TextStyle(
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                        DataCell(
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: color.withOpacity(0.08),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                              border: Border.all(
                                                color: color.withOpacity(0.3),
                                              ),
                                            ),
                                            child: Text(
                                              _formatCategoryKey(
                                                tx.category,
                                              ).toUpperCase(),
                                              style: TextStyle(
                                                color: color,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                        DataCell(
                                          Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                tx.paymentMode.toUpperCase(),
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              if (tx.referenceNumber != null)
                                                Text(
                                                  tx.referenceNumber!,
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    color: colorScheme.onSurface
                                                        .withOpacity(0.5),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                        DataCell(
                                          Text(
                                            allocStr,
                                            style: const TextStyle(
                                              fontSize: 11,
                                            ),
                                          ),
                                        ),
                                        DataCell(
                                          Text(
                                            '$sign\$${tx.amount.toStringAsFixed(2)}',
                                            style: TextStyle(
                                              color: color,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                        DataCell(
                                          Text(
                                            '\$${entry.runningBalance.toStringAsFixed(2)}',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                              color: entry.runningBalance >= 0
                                                  ? colorScheme.primary
                                                  : Colors.red,
                                            ),
                                          ),
                                        ),
                                        DataCell(
                                          SizedBox(
                                            width: 150,
                                            child: Text(
                                              tx.notes ?? '-',
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontSize: 11,
                                              ),
                                            ),
                                          ),
                                        ),
                                        DataCell(
                                          Row(
                                            children: [
                                              IconButton(
                                                icon: const Icon(
                                                  Icons.edit_outlined,
                                                  size: 18,
                                                ),
                                                onPressed: () => context.push(
                                                  '/finance/${tx.id}/edit',
                                                ),
                                                tooltip: 'Edit Record',
                                              ),
                                              IconButton(
                                                icon: const Icon(
                                                  Icons.delete_outline_rounded,
                                                  size: 18,
                                                  color: Colors.red,
                                                ),
                                                onPressed: () =>
                                                    _handleDeleteTransaction(
                                                  tx,
                                                ),
                                                tooltip: 'Soft Delete',
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                          ),
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
