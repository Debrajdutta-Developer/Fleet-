import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../domain/inventory_transaction_entity.dart';
import 'inventory_providers.dart';

class TransactionListScreen extends ConsumerStatefulWidget {
  const TransactionListScreen({super.key});

  @override
  ConsumerState<TransactionListScreen> createState() =>
      _TransactionListScreenState();
}

class _TransactionListScreenState extends ConsumerState<TransactionListScreen> {
  String _searchQuery = '';
  String _typeFilter = 'All';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final transactionsAsync = ref.watch(inventoryTransactionsStreamProvider);

    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isDesktop = screenWidth > 992;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory Transactions'),
      ),
      body: transactionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: EmptyStateWidget(
            title: 'Failed to sync transactions',
            description: err.toString(),
            icon: Icons.error_outline_rounded,
            actionText: 'Retry',
            onActionPressed: () =>
                ref.invalidate(inventoryTransactionsStreamProvider),
          ),
        ),
        data: (transactions) {
          final sorted = List<InventoryTransactionEntity>.from(transactions)
            ..sort((a, b) => b.date.compareTo(a.date));

          final filtered = sorted.where((t) {
            final matchesType = _typeFilter == 'All' ||
                t.type.toLowerCase() == _typeFilter.toLowerCase();
            final query = _searchQuery.toLowerCase();
            final matchesQuery = t.partName.toLowerCase().contains(query) ||
                t.notes.toLowerCase().contains(query) ||
                (t.referenceId ?? '').toLowerCase().contains(query);
            return matchesType && matchesQuery;
          }).toList();

          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          hintText:
                              'Search by part name, transaction notes, reference ID...',
                          prefixIcon: const Icon(Icons.search_rounded),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onChanged: (val) {
                          setState(() {
                            _searchQuery = val;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    DropdownButtonFormField<String>(
                      value: _typeFilter,
                      decoration: InputDecoration(
                        constraints: const BoxConstraints(maxWidth: 160),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: ['All', 'Stock_In', 'Stock_Out', 'Adjustment']
                          .map((s) => DropdownMenuItem(
                              value: s, child: Text(s.replaceAll('_', ' '))))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _typeFilter = val;
                          });
                        }
                      },
                    ),
                    const SizedBox(width: 16),
                    CustomButton(
                      text: 'Record Tx',
                      icon: Icons.add_rounded,
                      onPressed: () =>
                          context.push('/inventory/transactions/new'),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: filtered.isEmpty
                      ? EmptyStateWidget(
                          title: 'No Transactions Found',
                          description: _searchQuery.isEmpty
                              ? 'Get started by recording stock adjustments or stock ins.'
                              : 'No inventory transactions match your search query.',
                          icon: Icons.receipt_long_outlined,
                          actionText:
                              _searchQuery.isEmpty ? 'Record Stock Tx' : null,
                          onActionPressed: _searchQuery.isEmpty
                              ? () =>
                                  context.push('/inventory/transactions/new')
                              : null,
                        )
                      : isDesktop
                          ? _buildDesktopTable(theme, colorScheme, filtered)
                          : _buildMobileList(theme, colorScheme, filtered),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDesktopTable(
    ThemeData theme,
    ColorScheme colorScheme,
    List<InventoryTransactionEntity> list,
  ) {
    return Card(
      child: SingleChildScrollView(
        child: DataTable(
          columns: const [
            DataColumn(label: Text('Part Name')),
            DataColumn(label: Text('Type')),
            DataColumn(label: Text('Qty Change')),
            DataColumn(label: Text('Unit Cost')),
            DataColumn(label: Text('Total Cost')),
            DataColumn(label: Text('Notes')),
            DataColumn(label: Text('Date')),
          ],
          rows: list.map((tx) {
            final dateStr = DateFormat('dd MMM yyyy, HH:mm').format(tx.date);
            final isPositive = tx.quantity > 0;
            return DataRow(
              cells: [
                DataCell(Text(tx.partName,
                    style: const TextStyle(fontWeight: FontWeight.bold))),
                DataCell(
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: tx.type == 'stock_in'
                          ? Colors.green.withOpacity(0.12)
                          : tx.type == 'stock_out'
                              ? Colors.red.withOpacity(0.12)
                              : Colors.orange.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      tx.type.toUpperCase().replaceAll('_', ' '),
                      style: TextStyle(
                        color: tx.type == 'stock_in'
                            ? Colors.green
                            : tx.type == 'stock_out'
                                ? Colors.red
                                : Colors.orange,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                DataCell(
                  Text(
                    '${isPositive ? '+' : ''}${tx.quantity}',
                    style: TextStyle(
                      color: isPositive ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                DataCell(Text('\$${tx.unitCost.toStringAsFixed(2)}')),
                DataCell(Text('\$${tx.totalCost.toStringAsFixed(2)}')),
                DataCell(Text(tx.notes,
                    maxLines: 1, overflow: TextOverflow.ellipsis)),
                DataCell(Text(dateStr)),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildMobileList(
    ThemeData theme,
    ColorScheme colorScheme,
    List<InventoryTransactionEntity> list,
  ) {
    return ListView.builder(
      itemCount: list.length,
      itemBuilder: (context, index) {
        final tx = list[index];
        final dateStr = DateFormat('dd MMM yyyy').format(tx.date);
        final isPositive = tx.quantity > 0;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            title: Text(tx.partName,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(tx.notes),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      tx.type.toUpperCase().replaceAll('_', ' '),
                      style: TextStyle(
                        color: tx.type == 'stock_in'
                            ? Colors.green
                            : tx.type == 'stock_out'
                                ? Colors.red
                                : Colors.orange,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(dateStr),
                  ],
                ),
              ],
            ),
            trailing: Text(
              '${isPositive ? '+' : ''}${tx.quantity}',
              style: TextStyle(
                color: isPositive ? Colors.green : Colors.red,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      },
    );
  }
}
