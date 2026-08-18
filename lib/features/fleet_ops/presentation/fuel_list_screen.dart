import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../domain/fuel_entity.dart';
import 'fleet_ops_providers.dart';

class FuelListScreen extends ConsumerStatefulWidget {
  const FuelListScreen({super.key});

  @override
  ConsumerState<FuelListScreen> createState() => _FuelListScreenState();
}

class _FuelListScreenState extends ConsumerState<FuelListScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final fuelLogsAsync = ref.watch(fuelLogsStreamProvider);

    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isDesktop = screenWidth > 992;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fuel logs'),
      ),
      body: fuelLogsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: EmptyStateWidget(
            title: 'Failed to sync fuel logs',
            description: err.toString(),
            icon: Icons.error_outline_rounded,
            actionText: 'Retry',
            onActionPressed: () => ref.invalidate(fuelLogsStreamProvider),
          ),
        ),
        data: (logs) {
          final filtered = logs.where((l) {
            final query = _searchQuery.toLowerCase();
            return l.vehicleLicensePlate.toLowerCase().contains(query) ||
                l.driverName.toLowerCase().contains(query);
          }).toList();

          final totalFuelCost =
              filtered.map((l) => l.amount).fold<double>(0.0, (s, a) => s + a);
          final totalFuelQty =
              filtered.map((l) => l.fuelQty).fold<double>(0.0, (s, q) => s + q);
          final avgFuelPrice =
              totalFuelQty > 0 ? (totalFuelCost / totalFuelQty) : 0.0;

          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top statistics overview widgets
                Row(
                  children: [
                    Expanded(
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Total Fuel Cost',
                                  style: theme.textTheme.bodyMedium),
                              const SizedBox(height: 4),
                              Text(
                                '\$${totalFuelCost.toStringAsFixed(2)}',
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
                              Text('Total Refills Volume',
                                  style: theme.textTheme.bodyMedium),
                              const SizedBox(height: 4),
                              Text(
                                '${totalFuelQty.toStringAsFixed(0)} L',
                                style: theme.textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
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
                              Text('Average Fuel Price',
                                  style: theme.textTheme.bodyMedium),
                              const SizedBox(height: 4),
                              Text(
                                '\$${avgFuelPrice.toStringAsFixed(2)}/L',
                                style: theme.textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
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
                          hintText: 'Search by vehicle plate, driver name...',
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
                    CustomButton(
                      text: 'Log Fuel',
                      icon: Icons.add_rounded,
                      onPressed: () => context.push('/fuel/new'),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: filtered.isEmpty
                      ? EmptyStateWidget(
                          title: 'No Fuel Logs Found',
                          description: _searchQuery.isEmpty
                              ? 'Get started by logging your first fuel refill entry.'
                              : 'No refills match your search query.',
                          icon: Icons.local_gas_station_rounded,
                          actionText: _searchQuery.isEmpty ? 'Log Fuel' : null,
                          onActionPressed: _searchQuery.isEmpty
                              ? () => context.push('/fuel/new')
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
                            return _FuelCard(log: log);
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

class _FuelCard extends ConsumerWidget {
  final FuelEntity log;

  const _FuelCard({required this.log});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
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
                      Text(
                        'Driver: ${log.driverName}',
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
                      onPressed: () => context.push('/fuel/${log.id}/edit'),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded,
                          size: 20, color: Colors.red),
                      onPressed: () async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Delete Fuel Log'),
                            content: const Text(
                                'Are you sure you want to delete this fuel refill record?'),
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
                              .read(fuelListControllerProvider.notifier)
                              .deleteFuelLog(log.id);
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
                    Text('Volume', style: theme.textTheme.labelSmall),
                    Text('${log.fuelQty} L',
                        style: theme.textTheme.titleMedium),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Cost', style: theme.textTheme.labelSmall),
                    Text('\$${log.amount}', style: theme.textTheme.titleMedium),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Odometer', style: theme.textTheme.labelSmall),
                    Text('${log.odometer.toStringAsFixed(0)} km',
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
