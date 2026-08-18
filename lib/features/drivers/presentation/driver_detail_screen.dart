import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import 'driver_providers.dart';

class DriverDetailScreen extends ConsumerStatefulWidget {
  final String driverId;

  const DriverDetailScreen({super.key, required this.driverId});

  @override
  ConsumerState<DriverDetailScreen> createState() => _DriverDetailScreenState();
}

class _DriverDetailScreenState extends ConsumerState<DriverDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final driversAsync = ref.watch(driversStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver Profiles'),
      ),
      body: driversAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (drivers) {
          final driverIdx = drivers.indexWhere((d) => d.id == widget.driverId);
          if (driverIdx == -1) {
            return Center(
              child: EmptyStateWidget(
                title: 'Driver Record Not Found',
                description:
                    'The requested driver might have been suspended or deleted.',
                icon: Icons.person_off_rounded,
                actionText: 'Back to Roster',
                onActionPressed: () => context.pop(),
              ),
            );
          }
          final driver = drivers[driverIdx];

          final statusColors = {
            'available': Colors.green,
            'on_duty': Colors.blue,
            'off_duty': Colors.grey,
            'suspended': Colors.red,
          };

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: Card(
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
                                    driver.fullName,
                                    style:
                                        theme.textTheme.displayLarge?.copyWith(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Phone: ${driver.phone}',
                                    style: theme.textTheme.bodyLarge?.copyWith(
                                      color: colorScheme.onSurface
                                          .withOpacity(0.6),
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: (statusColors[driver.status] ??
                                          Colors.grey)
                                      .withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  driver.status.toUpperCase(),
                                  style: TextStyle(
                                    color: statusColors[driver.status] ??
                                        Colors.grey,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 48),
                          Text('License Compliance metrics',
                              style: theme.textTheme.titleMedium),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _MetricTile(
                                  label: 'License Number',
                                  value: driver.licenseNumber),
                              _MetricTile(
                                label: 'License Expiry',
                                value: driver.licenseExpiry
                                    .toLocal()
                                    .toString()
                                    .split(' ')[0],
                                isAlert: driver.licenseExpiry
                                    .isBefore(DateTime.now()),
                              ),
                              _MetricTile(
                                  label: 'Safety Score',
                                  value:
                                      '${driver.safetyScore.toStringAsFixed(0)}%'),
                            ],
                          ),
                          const SizedBox(height: 32),
                          if (driver.assignedVehicleLicensePlate != null) ...[
                            Card(
                              color: colorScheme.primary.withOpacity(0.06),
                              child: ListTile(
                                leading:
                                    const Icon(Icons.local_shipping_rounded),
                                title: const Text('Linked Primary Vehicle'),
                                subtitle:
                                    Text(driver.assignedVehicleLicensePlate!),
                                trailing: IconButton(
                                  icon: const Icon(Icons.link_off_rounded),
                                  onPressed: () => ref
                                      .read(
                                          driverListControllerProvider.notifier)
                                      .assignVehicle(driver.id, null, null),
                                  tooltip: 'Unlink Vehicle',
                                ),
                              ),
                            ),
                            const SizedBox(height: 32),
                          ],
                          Row(
                            children: [
                              CustomButton(
                                text: 'Edit Profiles',
                                icon: Icons.edit_rounded,
                                onPressed: () =>
                                    context.push('/drivers/${driver.id}/edit'),
                              ),
                              const SizedBox(width: 16),
                              OutlinedButton.icon(
                                onPressed: () async {
                                  final router = GoRouter.of(context);
                                  final confirmed = await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title:
                                          const Text('Suspend Driver Record'),
                                      content: const Text(
                                          'Are you sure you want to suspend this driver from active roster?'),
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
                                    final success = await ref
                                        .read(driverListControllerProvider
                                            .notifier)
                                        .deleteDriver(driver.id);
                                    if (success) {
                                      router.pop();
                                    }
                                  }
                                },
                                icon: const Icon(Icons.delete_outline_rounded,
                                    color: Colors.red),
                                label: const Text('Suspend Driver',
                                    style: TextStyle(color: Colors.red)),
                              ),
                            ],
                          ),
                        ],
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

class _MetricTile extends StatelessWidget {
  final String label;
  final String value;
  final bool isAlert;

  const _MetricTile(
      {required this.label, required this.value, this.isAlert = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.5),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: isAlert ? Colors.red : null,
          ),
        ),
      ],
    );
  }
}
