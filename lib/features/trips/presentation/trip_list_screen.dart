import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../core/widgets/loading_widget.dart';
import '../domain/trip_entity.dart';
import 'trip_providers.dart';

class TripListScreen extends ConsumerStatefulWidget {
  const TripListScreen({super.key});

  @override
  ConsumerState<TripListScreen> createState() => _TripListScreenState();
}

class _TripListScreenState extends ConsumerState<TripListScreen> {
  String _statusFilter = 'ALL';
  final _searchController = TextEditingController();
  String _searchQuery = '';

  final List<String> _filters = [
    'ALL',
    'scheduled',
    'dispatched',
    'loading',
    'inTransit',
    'delivered',
    'completed',
    'cancelled',
  ];

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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final tripsAsync = ref.watch(tripsStreamProvider);

    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isDesktop = screenWidth > 992;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trip Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(tripsStreamProvider),
            tooltip: 'Refresh Trips',
          ),
        ],
      ),
      body: tripsAsync.when(
        loading: () =>
            LoadingWidget.fullScreen(message: 'Syncing logistics ledger...'),
        error: (err, stack) => Center(
          child: EmptyStateWidget(
            title: 'Trip Synced Connection Failed',
            description: err.toString(),
            icon: Icons.error_outline_rounded,
            actionText: 'Retry Connection',
            onActionPressed: () => ref.invalidate(tripsStreamProvider),
          ),
        ),
        data: (trips) {
          final filteredTrips = trips.where((t) {
            final matchesStatus = _statusFilter == 'ALL' ||
                t.status.toLowerCase() == _statusFilter.toLowerCase();
            final query = _searchQuery.toLowerCase();
            final matchesQuery =
                t.vehicleLicensePlate.toLowerCase().contains(query) ||
                    t.driverName.toLowerCase().contains(query) ||
                    t.customerName.toLowerCase().contains(query) ||
                    t.pickupLocation.toLowerCase().contains(query) ||
                    t.deliveryLocation.toLowerCase().contains(query) ||
                    t.cargoType.toLowerCase().contains(query);
            return matchesStatus && matchesQuery;
          }).toList();

          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top control bar
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
                              'Search by Customer, Vehicle, Driver, Route...',
                          prefixIcon: Icon(
                            Icons.search_outlined,
                            color: colorScheme.onSurface.withOpacity(0.5),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    CustomButton(
                      text: 'CREATE TRIP',
                      icon: Icons.add_rounded,
                      width: 150,
                      height: 48,
                      onPressed: () => context.push('/trips/new'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Filters ChoiceChips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _filters.map((filter) {
                      final isSelected = _statusFilter == filter;
                      String display = filter;
                      if (filter == 'inTransit') display = 'In Transit';
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ChoiceChip(
                          label: Text(display.toUpperCase()),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected)
                              setState(() => _statusFilter = filter);
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 24),

                // Trips Grid
                Expanded(
                  child: filteredTrips.isEmpty
                      ? EmptyStateWidget(
                          title: 'No Trips Found',
                          description: _searchQuery.isEmpty
                              ? 'No trips scheduled inside your company tenant.'
                              : 'No matches found. Try broadening your query.',
                          icon: Icons.route_outlined,
                          actionText: _searchQuery.isEmpty
                              ? 'Schedule First Trip'
                              : null,
                          onActionPressed: _searchQuery.isEmpty
                              ? () => context.push('/trips/new')
                              : null,
                        )
                      : GridView.builder(
                          itemCount: filteredTrips.length,
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount:
                                isDesktop ? 3 : (screenWidth > 600 ? 2 : 1),
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 1.45,
                          ),
                          itemBuilder: (context, index) {
                            final trip = filteredTrips[index];
                            return _TripCard(
                              trip: trip,
                              statusColor: _getStatusColor(trip.status),
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
}

class _TripCard extends ConsumerWidget {
  final TripEntity trip;
  final Color statusColor;

  const _TripCard({required this.trip, required this.statusColor});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    String displayStatus = trip.status;
    if (trip.status == 'inTransit') displayStatus = 'In Transit';

    return Card(
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.push('/trips/${trip.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Header row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          trip.customerName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                          ),
                        ),
                        Text(
                          'Cargo: ${trip.cargoType} (${trip.coalQuantity.toStringAsFixed(1)} tons)',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurface.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: statusColor, width: 1.5),
                    ),
                    child: Text(
                      displayStatus.toUpperCase(),
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 16),

              // Route representation
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.circle_outlined,
                        color: Colors.green,
                        size: 14,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          trip.pickupLocation,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 6.0),
                    child: Container(
                      width: 1,
                      height: 12,
                      color: colorScheme.onSurface.withOpacity(0.2),
                    ),
                  ),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        color: Colors.red,
                        size: 14,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          trip.deliveryLocation,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const Divider(height: 16),

              // Footer detailing vehicle and driver
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(Icons.local_shipping_outlined, size: 16),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            trip.vehicleLicensePlate,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.person_outline_rounded, size: 16),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            trip.driverName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '\$${trip.freightAmount.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.secondary,
                      fontSize: 14,
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
