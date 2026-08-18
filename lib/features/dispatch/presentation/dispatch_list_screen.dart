import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/widgets/empty_state_widget.dart';
import 'dispatch_providers.dart';

class DispatchListScreen extends ConsumerStatefulWidget {
  const DispatchListScreen({super.key});

  @override
  ConsumerState<DispatchListScreen> createState() => _DispatchListScreenState();
}

class _DispatchListScreenState extends ConsumerState<DispatchListScreen> {
  String _selectedStatus = 'all';

  @override
  Widget build(BuildContext context) {
    final dispatchesAsync = ref.watch(dispatchesStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dispatches & Scheduling'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/dispatches/new'),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Schedule Dispatch'),
      ),
      body: dispatchesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: EmptyStateWidget(
            title: 'Failed to sync dispatches',
            description: err.toString(),
            icon: Icons.error_outline_rounded,
            actionText: 'Retry',
            onActionPressed: () => ref.invalidate(dispatchesStreamProvider),
          ),
        ),
        data: (dispatches) {
          // Calculate stats
          int activeCount =
              dispatches.where((d) => d.status == 'in_transit').length;
          int scheduledCount =
              dispatches.where((d) => d.status == 'scheduled').length;
          int completedCount =
              dispatches.where((d) => d.status == 'completed').length;

          final filtered = dispatches.where((d) {
            if (_selectedStatus == 'all') return true;
            return d.status == _selectedStatus;
          }).toList();

          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Metrics summary
                Row(
                  children: [
                    Expanded(
                      child: _SummaryCard(
                        title: 'Active (In Transit)',
                        value: activeCount.toString(),
                        icon: Icons.local_shipping_rounded,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _SummaryCard(
                        title: 'Scheduled',
                        value: scheduledCount.toString(),
                        icon: Icons.calendar_month_rounded,
                        color: Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _SummaryCard(
                        title: 'Completed',
                        value: completedCount.toString(),
                        icon: Icons.check_circle_rounded,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Filter chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      'all',
                      'draft',
                      'scheduled',
                      'in_transit',
                      'completed',
                      'cancelled',
                    ].map((status) {
                      final isSelected = _selectedStatus == status;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label:
                              Text(status.toUpperCase().replaceAll('_', ' ')),
                          selected: isSelected,
                          onSelected: (val) {
                            if (val) {
                              setState(() => _selectedStatus = status);
                            }
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: filtered.isEmpty
                      ? const Center(
                          child:
                              Text('No dispatches matches this status filter.'),
                        )
                      : ListView.builder(
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final disp = filtered[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: _getStatusColor(disp.status)
                                      .withOpacity(0.12),
                                  child: Icon(
                                    _getStatusIcon(disp.status),
                                    color: _getStatusColor(disp.status),
                                  ),
                                ),
                                title: Text(
                                    '${disp.dispatchNumber} - ${disp.routeName}'),
                                subtitle: Text(
                                  'Driver: ${disp.driverName} • Vehicle: ${disp.vehicleLicensePlate}\n'
                                  'Scheduled: ${DateFormat.yMd().add_jm().format(disp.scheduledTime)}',
                                ),
                                isThreeLine: true,
                                trailing:
                                    const Icon(Icons.chevron_right_rounded),
                                onTap: () =>
                                    context.push('/dispatches/${disp.id}'),
                              ),
                            );
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

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(icon, color: color),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
