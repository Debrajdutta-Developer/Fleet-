import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../domain/driver_entity.dart';
import 'driver_providers.dart';

class DriverListScreen extends ConsumerStatefulWidget {
  const DriverListScreen({super.key});

  @override
  ConsumerState<DriverListScreen> createState() => _DriverListScreenState();
}

class _DriverListScreenState extends ConsumerState<DriverListScreen> {
  String _searchQuery = '';
  String _statusFilter = 'All';

  @override
  Widget build(BuildContext context) {
    final driversAsync = ref.watch(driversStreamProvider);

    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isDesktop = screenWidth > 992;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver Roster'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(driversStreamProvider),
            tooltip: 'Force Sync Roster',
          ),
        ],
      ),
      body: driversAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: EmptyStateWidget(
            title: 'Roster Synchronization Failed',
            description: err.toString(),
            icon: Icons.error_outline_rounded,
            actionText: 'Retry Sync',
            onActionPressed: () => ref.invalidate(driversStreamProvider),
          ),
        ),
        data: (drivers) {
          final filteredDrivers = drivers.where((d) {
            final matchesStatus = _statusFilter == 'All' ||
                d.status == _statusFilter.toLowerCase();
            final matchesQuery =
                d.fullName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                    d.phone.contains(_searchQuery) ||
                    d.licenseNumber
                        .toLowerCase()
                        .contains(_searchQuery.toLowerCase());
            return matchesStatus && matchesQuery;
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
                          hintText: 'Search by driver name, license, phone...',
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
                      value: _statusFilter,
                      decoration: InputDecoration(
                        constraints: const BoxConstraints(maxWidth: 160),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: [
                        'All',
                        'Available',
                        'On_duty',
                        'Off_duty',
                        'Suspended'
                      ]
                          .map(
                              (s) => DropdownMenuItem(value: s, child: Text(s)))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _statusFilter = val;
                          });
                        }
                      },
                    ),
                    const SizedBox(width: 16),
                    CustomButton(
                      text: 'Onboard Driver',
                      icon: Icons.add_rounded,
                      onPressed: () => context.push('/drivers/new'),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: filteredDrivers.isEmpty
                      ? EmptyStateWidget(
                          title: 'No Drivers Found',
                          description: _searchQuery.isEmpty
                              ? 'Get started by onboarding your first driver.'
                              : 'No drivers match your search query.',
                          icon: Icons.people_outline_rounded,
                          actionText:
                              _searchQuery.isEmpty ? 'Onboard Driver' : null,
                          onActionPressed: _searchQuery.isEmpty
                              ? () => context.push('/drivers/new')
                              : null,
                        )
                      : GridView.builder(
                          itemCount: filteredDrivers.length,
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount:
                                isDesktop ? 3 : (screenWidth > 600 ? 2 : 1),
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 1.5,
                          ),
                          itemBuilder: (context, index) {
                            final driver = filteredDrivers[index];
                            return _DriverCard(driver: driver);
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

class _DriverCard extends ConsumerWidget {
  final DriverEntity driver;

  const _DriverCard({required this.driver});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final statusColors = {
      'available': Colors.green,
      'on_duty': Colors.blue,
      'off_duty': Colors.grey,
      'suspended': Colors.red,
    };

    final isExpired = driver.licenseExpiry.isBefore(DateTime.now());

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.push('/drivers/${driver.id}'),
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
                          driver.fullName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'License: ${driver.licenseNumber}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurface.withOpacity(0.5),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: (statusColors[driver.status] ?? Colors.grey)
                          .withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      driver.status.toUpperCase(),
                      style: TextStyle(
                        color: statusColors[driver.status] ?? Colors.grey,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.phone_rounded, size: 14),
                  const SizedBox(width: 6),
                  Text(driver.phone, style: theme.textTheme.bodyMedium),
                ],
              ),
              if (driver.assignedVehicleLicensePlate != null) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.local_shipping_rounded, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      'Vehicle: ${driver.assignedVehicleLicensePlate}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.star_rounded,
                          color: Colors.amber, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        driver.safetyScore.toStringAsFixed(0),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  if (isExpired)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'EXPIRED LICENSE',
                        style: TextStyle(
                            color: Colors.red,
                            fontSize: 8,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
