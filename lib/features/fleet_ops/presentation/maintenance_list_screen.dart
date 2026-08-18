import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../domain/maintenance_entity.dart';
import 'fleet_ops_providers.dart';

class MaintenanceListScreen extends ConsumerStatefulWidget {
  const MaintenanceListScreen({super.key});

  @override
  ConsumerState<MaintenanceListScreen> createState() =>
      _MaintenanceListScreenState();
}

class _MaintenanceListScreenState extends ConsumerState<MaintenanceListScreen> {
  String _searchQuery = '';
  String _typeFilter = 'All';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final maintenanceLogsAsync = ref.watch(maintenanceLogsStreamProvider);

    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isDesktop = screenWidth > 992;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Maintenance logs'),
      ),
      body: maintenanceLogsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: EmptyStateWidget(
            title: 'Failed to sync maintenance logs',
            description: err.toString(),
            icon: Icons.error_outline_rounded,
            actionText: 'Retry',
            onActionPressed: () =>
                ref.invalidate(maintenanceLogsStreamProvider),
          ),
        ),
        data: (logs) {
          final filtered = logs.where((l) {
            final matchesType = _typeFilter == 'All' ||
                l.type.toLowerCase() == _typeFilter.toLowerCase();
            final query = _searchQuery.toLowerCase();
            final matchesQuery =
                l.vehicleLicensePlate.toLowerCase().contains(query) ||
                    l.description.toLowerCase().contains(query) ||
                    (l.vendorName ?? '').toLowerCase().contains(query);
            return matchesType && matchesQuery;
          }).toList();

          final totalCost =
              filtered.map((l) => l.cost).fold<double>(0.0, (s, c) => s + c);
          final preventativeCost = filtered
              .where((l) => l.type == 'preventative')
              .map((l) => l.cost)
              .fold<double>(0.0, (s, c) => s + c);
          final correctiveCost = totalCost - preventativeCost;

          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cost Analytics Cards
                Row(
                  children: [
                    Expanded(
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Total Maintenance Cost',
                                  style: theme.textTheme.bodyMedium),
                              const SizedBox(height: 4),
                              Text(
                                '\$${totalCost.toStringAsFixed(2)}',
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
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Preventative Cost',
                                  style: theme.textTheme.bodyMedium),
                              const SizedBox(height: 4),
                              Text(
                                '\$${preventativeCost.toStringAsFixed(2)}',
                                style: theme.textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
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
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Corrective Cost',
                                  style: theme.textTheme.bodyMedium),
                              const SizedBox(height: 4),
                              Text(
                                '\$${correctiveCost.toStringAsFixed(2)}',
                                style: theme.textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red,
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
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          hintText:
                              'Search by vehicle plate, vendor, repair description...',
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
                      items: ['All', 'Preventative', 'Corrective']
                          .map(
                              (s) => DropdownMenuItem(value: s, child: Text(s)))
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
                      text: 'Log Maintenance',
                      icon: Icons.add_rounded,
                      onPressed: () => context.push('/maintenance/new'),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: filtered.isEmpty
                      ? EmptyStateWidget(
                          title: 'No Maintenance Logs Found',
                          description: _searchQuery.isEmpty
                              ? 'Get started by logging your first vehicle repair entry.'
                              : 'No maintenance records match your search query.',
                          icon: Icons.build_outlined,
                          actionText:
                              _searchQuery.isEmpty ? 'Log Maintenance' : null,
                          onActionPressed: _searchQuery.isEmpty
                              ? () => context.push('/maintenance/new')
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
                            childAspectRatio: 1.4,
                          ),
                          itemBuilder: (context, index) {
                            final log = filtered[index];
                            return _MaintenanceCard(log: log);
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

class _MaintenanceCard extends ConsumerWidget {
  final MaintenanceEntity log;

  const _MaintenanceCard({required this.log});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final dateStr = DateFormat('dd MMM yyyy').format(log.date);

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
                        log.vehicleLicensePlate,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: log.type == 'preventative'
                              ? Colors.green.withOpacity(0.12)
                              : Colors.red.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          log.type.toUpperCase(),
                          style: TextStyle(
                            color: log.type == 'preventative'
                                ? Colors.green
                                : Colors.red,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
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
                          context.push('/maintenance/${log.id}/edit'),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded,
                          size: 20, color: Colors.red),
                      onPressed: () async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Delete Maintenance Log'),
                            content: const Text(
                                'Are you sure you want to delete this maintenance record?'),
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
                              .read(maintenanceListControllerProvider.notifier)
                              .deleteMaintenanceLog(log.id);
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
            const Divider(height: 12),
            Text(
              log.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium,
            ),
            const Divider(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Cost', style: theme.textTheme.labelSmall),
                    Text('\$${log.cost}', style: theme.textTheme.titleMedium),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Vendor', style: theme.textTheme.labelSmall),
                    Text(log.vendorName ?? 'General Service',
                        style: theme.textTheme.titleMedium),
                  ],
                ),
              ],
            ),
            const Divider(height: 12),
            Row(
              children: [
                const Icon(Icons.calendar_today_rounded, size: 14),
                const SizedBox(width: 6),
                Text(dateStr, style: theme.textTheme.bodyMedium),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
