import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../domain/part_entity.dart';
import 'inventory_providers.dart';

class PartListScreen extends ConsumerStatefulWidget {
  const PartListScreen({super.key});

  @override
  ConsumerState<PartListScreen> createState() => _PartListScreenState();
}

class _PartListScreenState extends ConsumerState<PartListScreen> {
  String _searchQuery = '';
  String _categoryFilter = 'All';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final partsAsync = ref.watch(partsStreamProvider);

    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isDesktop = screenWidth > 992;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory & Spare Parts'),
      ),
      body: partsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: EmptyStateWidget(
            title: 'Failed to sync inventory parts',
            description: err.toString(),
            icon: Icons.error_outline_rounded,
            actionText: 'Retry',
            onActionPressed: () => ref.invalidate(partsStreamProvider),
          ),
        ),
        data: (parts) {
          final filtered = parts.where((p) {
            final matchesCategory = _categoryFilter == 'All' ||
                p.category.toLowerCase() == _categoryFilter.toLowerCase();
            final query = _searchQuery.toLowerCase();
            final matchesQuery = p.name.toLowerCase().contains(query) ||
                p.partNumber.toLowerCase().contains(query) ||
                (p.supplierName ?? '').toLowerCase().contains(query);
            return matchesCategory && matchesQuery;
          }).toList();

          final totalStockValue =
              parts.fold<double>(0.0, (s, p) => s + (p.quantity * p.unitCost));
          final lowStockPartsCount =
              parts.where((p) => p.quantity <= p.minStockThreshold).length;

          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top overview cards
                Row(
                  children: [
                    Expanded(
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Total Stock Value',
                                  style: theme.textTheme.bodyMedium),
                              const SizedBox(height: 4),
                              Text(
                                '\$${totalStockValue.toStringAsFixed(2)}',
                                style: theme.textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Card(
                        color: lowStockPartsCount > 0
                            ? colorScheme.errorContainer
                            : null,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Low Stock Alerts',
                                  style: theme.textTheme.bodyMedium),
                              const SizedBox(height: 4),
                              Text(
                                '$lowStockPartsCount parts',
                                style: theme.textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: lowStockPartsCount > 0
                                      ? colorScheme.error
                                      : null,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Search and Filters
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          hintText:
                              'Search by part name, part number, supplier...',
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
                      value: _categoryFilter,
                      decoration: InputDecoration(
                        constraints: const BoxConstraints(maxWidth: 160),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: [
                        'All',
                        'Engine',
                        'Brake',
                        'Tyre',
                        'Electrical',
                        'Lubricant',
                        'Other'
                      ]
                          .map(
                              (s) => DropdownMenuItem(value: s, child: Text(s)))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _categoryFilter = val;
                          });
                        }
                      },
                    ),
                    const SizedBox(width: 16),
                    CustomButton(
                      text: 'Add Part',
                      icon: Icons.add_rounded,
                      onPressed: () => context.push('/inventory/new'),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: filtered.isEmpty
                      ? EmptyStateWidget(
                          title: 'No Spare Parts Found',
                          description: _searchQuery.isEmpty
                              ? 'Get started by adding your first spare part asset.'
                              : 'No parts match your search query.',
                          icon: Icons.settings_input_component_rounded,
                          actionText: _searchQuery.isEmpty ? 'Add Part' : null,
                          onActionPressed: _searchQuery.isEmpty
                              ? () => context.push('/inventory/new')
                              : null,
                        )
                      : GridView.builder(
                          itemCount: filtered.length,
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount:
                                isDesktop ? 3 : (screenWidth > 600 ? 2 : 1),
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 1.35,
                          ),
                          itemBuilder: (context, index) {
                            final part = filtered[index];
                            return _PartCard(part: part);
                          },
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

class _PartCard extends ConsumerWidget {
  final PartEntity part;

  const _PartCard({required this.part});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isLowStock = part.quantity <= part.minStockThreshold;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        part.name,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Part No: ${part.partNumber}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 20),
                      onPressed: () =>
                          context.push('/inventory/${part.id}/edit'),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded,
                          size: 20, color: Colors.red),
                      onPressed: () async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Delete Part'),
                            content: const Text(
                                'Are you sure you want to delete this spare part record?'),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(false),
                                child: const Text('Cancel'),
                              ),
                              ElevatedButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(true),
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    foregroundColor: Colors.white),
                                child: const Text('Delete'),
                              ),
                            ],
                          ),
                        );
                        if (confirmed == true) {
                          ref
                              .read(partListControllerProvider.notifier)
                              .deletePart(part.id);
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
            const Divider(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Category', style: theme.textTheme.labelSmall),
                    Text(part.category.toUpperCase(),
                        style: theme.textTheme.titleMedium),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Unit Cost', style: theme.textTheme.labelSmall),
                    Text('\$${part.unitCost}',
                        style: theme.textTheme.titleMedium),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Stock Qty', style: theme.textTheme.labelSmall),
                    Row(
                      children: [
                        Text(
                          '${part.quantity}',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: isLowStock ? Colors.red : Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (isLowStock) ...[
                          const SizedBox(width: 4),
                          const Icon(Icons.warning_amber_rounded,
                              size: 16, color: Colors.red),
                        ],
                      ],
                    ),
                  ],
                ),
              ],
            ),
            const Divider(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    part.supplierName != null
                        ? 'Supplier: ${part.supplierName}'
                        : 'No supplier linked',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
                ElevatedButton(
                  onPressed: () => context
                      .push('/inventory/transactions/new?partId=${part.id}'),
                  style: ElevatedButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    visualDensity: VisualDensity.compact,
                  ),
                  child: const Text('Adjust Stock',
                      style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
