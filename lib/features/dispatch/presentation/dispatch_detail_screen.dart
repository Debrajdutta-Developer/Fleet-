import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/widgets/custom_button.dart';
import 'dispatch_providers.dart';

class DispatchDetailScreen extends ConsumerWidget {
  final String dispatchId;

  const DispatchDetailScreen({super.key, required this.dispatchId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dispatchesAsync = ref.watch(dispatchesStreamProvider);
    final listState = ref.watch(dispatchListControllerProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dispatch Details'),
      ),
      body: dispatchesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text(err.toString())),
        data: (dispatches) {
          final idx = dispatches.indexWhere((d) => d.id == dispatchId);
          if (idx == -1) {
            return const Center(child: Text('Dispatch schedule not found.'));
          }
          final disp = dispatches[idx];

          return listState.isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header card with dispatch status
                      Card(
                        color: _getStatusColor(disp.status).withOpacity(0.08),
                        shape: RoundedRectangleBorder(
                          side: BorderSide(color: _getStatusColor(disp.status)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    disp.dispatchNumber,
                                    style:
                                        theme.textTheme.headlineSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Status: ${disp.status.toUpperCase()}',
                                    style: TextStyle(
                                      color: _getStatusColor(disp.status),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              Icon(
                                _getStatusIcon(disp.status),
                                size: 36,
                                color: _getStatusColor(disp.status),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Information details
                      Text('Route & Path', style: theme.textTheme.titleMedium),
                      const SizedBox(height: 8),
                      ListTile(
                        leading: const Icon(Icons.route_rounded),
                        title: Text(disp.routeName),
                        subtitle:
                            Text('Linked Trip ID: ${disp.tripId ?? "None"}'),
                      ),
                      const Divider(),
                      Text('Resources Mappings',
                          style: theme.textTheme.titleMedium),
                      const SizedBox(height: 8),
                      ListTile(
                        leading: const Icon(Icons.person_rounded),
                        title: Text(disp.driverName),
                        subtitle: const Text('Primary Driver'),
                      ),
                      ListTile(
                        leading: const Icon(Icons.local_shipping_rounded),
                        title: Text(disp.vehicleLicensePlate),
                        subtitle: const Text('Scheduled Transport Asset'),
                      ),
                      const Divider(),
                      Text('Scheduling Details',
                          style: theme.textTheme.titleMedium),
                      const SizedBox(height: 8),
                      ListTile(
                        leading: const Icon(Icons.event_note_rounded),
                        title: Text(DateFormat.yMMMMd()
                            .add_jm()
                            .format(disp.scheduledTime)),
                        subtitle: const Text('Planned Departure Date & Time'),
                      ),
                      if (disp.notes != null && disp.notes!.isNotEmpty) ...[
                        const Divider(),
                        Text('Dispatcher Notes',
                            style: theme.textTheme.titleMedium),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Text(
                            disp.notes!,
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                      ],
                      const SizedBox(height: 48),
                      // Status Action Buttons
                      if (disp.status == 'scheduled' ||
                          disp.status == 'draft') ...[
                        CustomButton(
                          text: 'Start Dispatch (Mark In-Transit)',
                          onPressed: () async {
                            await ref
                                .read(dispatchListControllerProvider.notifier)
                                .updateStatus(disp.id, 'in_transit');
                          },
                        ),
                        const SizedBox(height: 12),
                      ],
                      if (disp.status == 'in_transit') ...[
                        CustomButton(
                          text: 'Complete Dispatch',
                          onPressed: () async {
                            await ref
                                .read(dispatchListControllerProvider.notifier)
                                .updateStatus(disp.id, 'completed');
                          },
                        ),
                        const SizedBox(height: 12),
                      ],
                      if (disp.status != 'completed' &&
                          disp.status != 'cancelled') ...[
                        CustomButton(
                          text: 'Cancel Dispatch',
                          onPressed: () async {
                            await ref
                                .read(dispatchListControllerProvider.notifier)
                                .updateStatus(disp.id, 'cancelled');
                          },
                          backgroundColor: theme.colorScheme.error,
                        ),
                        const SizedBox(height: 12),
                      ],
                      if (disp.status == 'completed' ||
                          disp.status == 'cancelled') ...[
                        CustomButton(
                          text: 'Delete / Archive Record',
                          onPressed: () async {
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Confirm Archiving'),
                                content: const Text(
                                    'Are you sure you want to soft-delete this completed dispatch history?'),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    child: const Text('Archive'),
                                  ),
                                ],
                              ),
                            );
                            if (confirmed == true && context.mounted) {
                              final success = await ref
                                  .read(dispatchListControllerProvider.notifier)
                                  .deleteDispatch(disp.id);
                              if (success && context.mounted) {
                                context.pop();
                              }
                            }
                          },
                          backgroundColor: theme.colorScheme.outline,
                        ),
                      ]
                    ],
                  ),
                );
        },
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'draft':
        return Colors.grey;
      case 'scheduled':
        return Colors.orange;
      case 'in_transit':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.black;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'draft':
        return Icons.edit_note_rounded;
      case 'scheduled':
        return Icons.schedule_rounded;
      case 'in_transit':
        return Icons.local_shipping_rounded;
      case 'completed':
        return Icons.check_circle_rounded;
      case 'cancelled':
        return Icons.cancel_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }
}
