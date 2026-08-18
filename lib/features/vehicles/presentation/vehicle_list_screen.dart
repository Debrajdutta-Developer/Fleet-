import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../core/widgets/loading_widget.dart';
import '../domain/vehicle_entity.dart';
import 'vehicle_providers.dart';

/// Screen displaying lists and grids of all vehicles within the corporate tenant.
class VehicleListScreen extends ConsumerStatefulWidget {
  const VehicleListScreen({super.key});

  @override
  ConsumerState<VehicleListScreen> createState() => _VehicleListScreenState();
}

class _VehicleListScreenState extends ConsumerState<VehicleListScreen> {
  String _statusFilter = 'All';
  final _searchController = TextEditingController();
  String _searchQuery = '';

  final List<String> _filters = [
    'All',
    'active',
    'maintenance',
    'idle',
    'sold',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final vehiclesAsync = ref.watch(vehiclesStreamProvider);

    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isDesktop = screenWidth > 992;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fleet Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(vehiclesStreamProvider),
            tooltip: 'Force Sync DB',
          ),
        ],
      ),
      body: vehiclesAsync.when(
        loading: () =>
            LoadingWidget.fullScreen(message: 'Syncing vehicle telemetry...'),
        error: (err, stack) => Center(
          child: EmptyStateWidget(
            title: 'Telemetry Connection Failed',
            description: err.toString(),
            icon: Icons.error_outline_rounded,
            actionText: 'Retry Connection',
            onActionPressed: () => ref.invalidate(vehiclesStreamProvider),
          ),
        ),
        data: (vehicles) {
          // Apply query searches & status filter maps
          final filteredVehicles = vehicles.where((v) {
            final matchesStatus =
                _statusFilter == 'All' || v.status == _statusFilter;
            final matchesQuery =
                v.licensePlate.toLowerCase().contains(_searchQuery) ||
                    v.vin.toLowerCase().contains(_searchQuery) ||
                    v.make.toLowerCase().contains(_searchQuery) ||
                    v.model.toLowerCase().contains(_searchQuery);
            return matchesStatus && matchesQuery;
          }).toList();

          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top control bar (Add, search, and filters)
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: (val) => setState(
                          () => _searchQuery = val.trim().toLowerCase(),
                        ),
                        decoration: InputDecoration(
                          hintText: 'Search by VIN, License Plate, Make...',
                          prefixIcon: Icon(
                            Icons.search_outlined,
                            color: colorScheme.onSurface.withOpacity(0.5),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Add vehicle action button
                    CustomButton(
                      text: 'ADD VEHICLE',
                      icon: Icons.add_rounded,
                      width: 150,
                      height: 48,
                      onPressed: () => context.push('/vehicles/new'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Horizontal filters scrollable list
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _filters.map((filter) {
                      final isSelected = _statusFilter == filter;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ChoiceChip(
                          label: Text(filter.toUpperCase()),
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

                // Main Fleet List Grid
                Expanded(
                  child: filteredVehicles.isEmpty
                      ? EmptyStateWidget(
                          title: 'No Vehicles Registered',
                          description: _searchQuery.isEmpty
                              ? 'Your company partition is clean. Register your first vehicle to get started.'
                              : 'No matches found. Try widening your search queries.',
                          icon: Icons.local_shipping_outlined,
                          actionText:
                              _searchQuery.isEmpty ? 'Onboard Vehicle' : null,
                          onActionPressed: _searchQuery.isEmpty
                              ? () => context.push('/vehicles/new')
                              : null,
                        )
                      : GridView.builder(
                          itemCount: filteredVehicles.length,
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount:
                                isDesktop ? 3 : (screenWidth > 600 ? 2 : 1),
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 1.5,
                          ),
                          itemBuilder: (context, index) {
                            final vehicle = filteredVehicles[index];
                            return _VehicleCard(vehicle: vehicle);
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

class _VehicleCard extends StatelessWidget {
  final VehicleEntity vehicle;

  const _VehicleCard({required this.vehicle});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Compliance color warnings
    final hasIssues = VehicleComplianceHelper.isInsuranceExpired(vehicle) ||
        VehicleComplianceHelper.isPucExpired(vehicle) ||
        VehicleComplianceHelper.isFitnessExpired(vehicle);

    final statusColors = {
      'active': Colors.green,
      'maintenance': Colors.amber,
      'idle': Colors.grey,
      'sold': Colors.red,
    };

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.push('/vehicles/${vehicle.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        vehicle.licensePlate,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'VIN: ${vehicle.vin.substring(0, 8).toUpperCase()}...',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface.withOpacity(0.5),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  // Status badge indicator
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: (statusColors[vehicle.status] ?? Colors.blue)
                          .withOpacity(0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: statusColors[vehicle.status] ?? Colors.blue,
                      ),
                    ),
                    child: Text(
                      vehicle.status.toUpperCase(),
                      style: TextStyle(
                        color: statusColors[vehicle.status] ?? Colors.blue,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              // Specs details
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${vehicle.make} ${vehicle.model} (${vehicle.year})',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Odometer: ${vehicle.odometer.toStringAsFixed(0)} km',
                        style: TextStyle(
                          color: colorScheme.onSurface.withOpacity(0.6),
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        vehicle.fuelType.toUpperCase(),
                        style: TextStyle(
                          color: colorScheme.onSurface.withOpacity(0.6),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // Compliance alerts alerts
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.person_outline_rounded, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        vehicle.assignedDriverName ?? 'No Driver',
                        style: TextStyle(
                          fontSize: 12,
                          color: vehicle.assignedDriverName == null
                              ? Colors.amber
                              : Colors.green,
                        ),
                      ),
                    ],
                  ),
                  if (hasIssues)
                    Row(
                      children: const [
                        Icon(
                          Icons.warning_amber_rounded,
                          color: Colors.red,
                          size: 18,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'ALERTS',
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
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
