import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../core/widgets/loading_widget.dart';
import '../domain/trip_entity.dart';
import 'trip_providers.dart';

class TripDetailScreen extends ConsumerStatefulWidget {
  final String tripId;

  const TripDetailScreen({super.key, required this.tripId});

  @override
  ConsumerState<TripDetailScreen> createState() => _TripDetailScreenState();
}

class _TripDetailScreenState extends ConsumerState<TripDetailScreen> {
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'scheduled':
        return Colors.blue;
      case 'dispatched':
        return Colors.purple;
      case 'loading':
        return Colors.amber;
      case 'intransit':
      case 'in transit':
        return Colors.cyan;
      case 'delivered':
        return Colors.orange;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatDateTime(DateTime dt) {
    return DateFormat('dd MMM yyyy, hh:mm a').format(dt.toLocal());
  }

  Future<void> _handleStatusTransition(
    TripEntity trip,
    String nextStatus,
  ) async {
    final noteController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Transition to ${nextStatus.toUpperCase()}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to transition this trip status to $nextStatus?',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: noteController,
              decoration: const InputDecoration(
                labelText: 'Transition Notes (Optional)',
                hintText: 'Enter gate pass details, invoice number, etc.',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final success = await ref
          .read(tripListControllerProvider.notifier)
          .updateStatus(trip.id, nextStatus, notes: noteController.text.trim());

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Trip status updated to $nextStatus.')),
        );
      }
    }
  }

  Future<void> _handleDeleteTrip(TripEntity trip) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Soft-Delete Trip Record'),
        content: const Text(
          'Are you sure you want to delete this trip record? The operation is non-destructive but will remove the trip from active logs.',
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
          .read(tripListControllerProvider.notifier)
          .deleteTrip(trip.id);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Trip record soft-deleted.')),
        );
        context.pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final tripAsync = ref.watch(tripDetailsStreamProvider(widget.tripId));
    final auditLogsAsync = ref.watch(
      tripAuditLogsStreamProvider(widget.tripId),
    );

    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isDesktop = screenWidth > 992;

    return tripAsync.when(
      loading: () => Scaffold(
        body: LoadingWidget.fullScreen(message: 'Loading trip ledger...'),
      ),
      error: (err, st) => Scaffold(
        appBar: AppBar(),
        body: Center(
          child: EmptyStateWidget(
            title: 'Trip Lookup Failed',
            description: err.toString(),
            icon: Icons.error_outline_rounded,
          ),
        ),
      ),
      data: (trip) {
        if (trip == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(
              child: EmptyStateWidget(
                title: 'Trip Record Missing',
                description:
                    'The requested trip record does not exist or has been soft-deleted.',
                icon: Icons.search_off_rounded,
              ),
            ),
          );
        }

        final statusColor = _getStatusColor(trip.status);
        final currentStatus = trip.status.toLowerCase();

        // Calculate available status transitions
        List<String> possibleTransitions = [];
        if (currentStatus == 'scheduled') {
          possibleTransitions = ['dispatched', 'cancelled'];
        } else if (currentStatus == 'dispatched') {
          possibleTransitions = ['loading', 'cancelled'];
        } else if (currentStatus == 'loading') {
          possibleTransitions = ['inTransit', 'cancelled'];
        } else if (currentStatus == 'intransit') {
          possibleTransitions = ['delivered', 'cancelled'];
        } else if (currentStatus == 'delivered') {
          possibleTransitions = ['completed', 'cancelled'];
        }

        final Widget mainDetails = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Header Info
            Card(
              elevation: 0,
              color: statusColor.withOpacity(0.04),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: statusColor.withOpacity(0.2),
                  width: 1.5,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'TRIP STATUS',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          trip.status.toUpperCase(),
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                    if (possibleTransitions.isNotEmpty)
                      Row(
                        children: possibleTransitions.map((next) {
                          final isCancel = next == 'cancelled';
                          return Padding(
                            padding: const EdgeInsets.only(left: 8.0),
                            child: ElevatedButton(
                              onPressed: () =>
                                  _handleStatusTransition(trip, next),
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    isCancel ? Colors.red : colorScheme.primary,
                                foregroundColor: Colors.white,
                              ),
                              child: Text(
                                next == 'inTransit'
                                    ? 'IN TRANSIT'
                                    : next.toUpperCase(),
                              ),
                            ),
                          );
                        }).toList(),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'FINAL STATE REACHED',
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Route & Cargo Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Route & Cargo Details',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Divider(height: 24),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.circle_outlined,
                          color: Colors.green,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Pickup Location',
                                style: TextStyle(
                                  color: colorScheme.onSurface.withOpacity(0.4),
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                trip.pickupLocation,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.only(
                        left: 9.0,
                        top: 4,
                        bottom: 4,
                      ),
                      child: Container(
                        width: 2,
                        height: 20,
                        color: colorScheme.onSurface.withOpacity(0.2),
                      ),
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          color: Colors.red,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Delivery Location',
                                style: TextStyle(
                                  color: colorScheme.onSurface.withOpacity(0.4),
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                trip.deliveryLocation,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 32),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Cargo Type',
                                style: TextStyle(
                                  color: colorScheme.onSurface.withOpacity(0.4),
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                trip.cargoType,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Coal Qty (tons)',
                                style: TextStyle(
                                  color: colorScheme.onSurface.withOpacity(0.4),
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${trip.coalQuantity.toStringAsFixed(1)} T',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Freight Amount',
                                style: TextStyle(
                                  color: colorScheme.onSurface.withOpacity(0.4),
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '\$${trip.freightAmount.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Advance Payment',
                                style: TextStyle(
                                  color: colorScheme.onSurface.withOpacity(0.4),
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '\$${trip.advancePayment.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: colorScheme.secondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Permit Expense',
                                style: TextStyle(
                                  color: colorScheme.onSurface.withOpacity(0.4),
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '\$${trip.permitExpense.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Assigned Entities Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Assigned Resources',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Divider(height: 24),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: colorScheme.primary.withOpacity(0.08),
                        child: Icon(
                          Icons.local_shipping,
                          color: colorScheme.primary,
                        ),
                      ),
                      title: Text(
                        trip.vehicleLicensePlate,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: const Text('Assigned Corporate Vehicle'),
                    ),
                    const Divider(),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: colorScheme.secondary.withOpacity(
                          0.08,
                        ),
                        child: Icon(Icons.person, color: colorScheme.secondary),
                      ),
                      title: Text(
                        trip.driverName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: const Text('Assigned Operator/Driver'),
                    ),
                    const Divider(),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: Colors.blue.withOpacity(0.08),
                        child: const Icon(Icons.business, color: Colors.blue),
                      ),
                      title: Text(
                        trip.customerName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: const Text('Billed Corporate Customer'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );

        // Sidebar with Status Timeline and Audit Logs
        final Widget sidePanel = Card(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Status Update Log Timeline',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Divider(height: 24),

                // Status History list representation
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: trip.statusHistory.length,
                  itemBuilder: (context, index) {
                    final hist = trip.statusHistory[index];
                    final histColor = _getStatusColor(hist.status);
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          children: [
                            CircleAvatar(radius: 8, backgroundColor: histColor),
                            if (index != trip.statusHistory.length - 1)
                              Container(
                                width: 2,
                                height: 45,
                                color: colorScheme.onSurface.withOpacity(0.12),
                              ),
                          ],
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    hist.status.toUpperCase(),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      color: histColor,
                                    ),
                                  ),
                                  Text(
                                    _formatDateTime(hist.changedAt),
                                    style: TextStyle(
                                      color: colorScheme.onSurface.withOpacity(
                                        0.4,
                                      ),
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                'Changed by: ${hist.changedBy}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              if (hist.notes != null && hist.notes!.isNotEmpty)
                                Text(
                                  'Notes: ${hist.notes}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: colorScheme.onSurface.withOpacity(
                                      0.6,
                                    ),
                                  ),
                                ),
                              const SizedBox(height: 12),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),

                const Divider(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Enterprise Audit Logs',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Icon(
                      Icons.security,
                      size: 18,
                      color: Colors.blueGrey,
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Real-time Audit logs feed from stream
                auditLogsAsync.when(
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  error: (e, s) => Text(
                    'Error loading audits: $e',
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                  ),
                  data: (logs) {
                    if (logs.isEmpty) {
                      return Text(
                        'No system audits reported yet.',
                        style: TextStyle(
                          color: colorScheme.onSurface.withOpacity(0.4),
                          fontSize: 12,
                        ),
                      );
                    }
                    return ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: logs.length,
                      separatorBuilder: (c, i) => const Divider(),
                      itemBuilder: (context, index) {
                        final log = logs[index];
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  log.action.toUpperCase(),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10,
                                    color: Colors.blueGrey,
                                  ),
                                ),
                                Text(
                                  _formatDateTime(log.timestamp),
                                  style: TextStyle(
                                    color: colorScheme.onSurface.withOpacity(
                                      0.4,
                                    ),
                                    fontSize: 9,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              log.description,
                              style: const TextStyle(fontSize: 12),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'By: ${log.userName} (UID: ${log.userId.substring(0, 5)}...)',
                              style: TextStyle(
                                color: colorScheme.onSurface.withOpacity(0.5),
                                fontSize: 10,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        );

        return Scaffold(
          appBar: AppBar(
            title: Text(
              'Trip #${trip.id.substring(0, 8).toUpperCase()} Ledger',
            ),
            actions: [
              IconButton(
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: Colors.red,
                ),
                onPressed: () => _handleDeleteTrip(trip),
                tooltip: 'Soft-Delete Trip',
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: isDesktop
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 3, child: mainDetails),
                      const SizedBox(width: 24),
                      Expanded(flex: 2, child: sidePanel),
                    ],
                  )
                : Column(
                    children: [
                      mainDetails,
                      const SizedBox(height: 24),
                      sidePanel,
                    ],
                  ),
          ),
        );
      },
    );
  }
}
