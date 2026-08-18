import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../core/widgets/loading_widget.dart';
import '../domain/vehicle_entity.dart';
import 'vehicle_providers.dart';

/// Screen detailing vehicle metrics, assigned drivers, and compliance document expirations.
class VehicleDetailScreen extends ConsumerStatefulWidget {
  final String vehicleId;

  const VehicleDetailScreen({super.key, required this.vehicleId});

  @override
  ConsumerState<VehicleDetailScreen> createState() =>
      _VehicleDetailScreenState();
}

class _VehicleDetailScreenState extends ConsumerState<VehicleDetailScreen> {
  bool _isUploadingDoc = false;

  Future<void> _handleArchive(VehicleEntity vehicle) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Decommission Vehicle Asset'),
        content: Text(
          'Are you sure you want to archive ${vehicle.licensePlate}? This will soft-delete the record.',
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
            child: const Text('Archive Asset'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final success = await ref
          .read(vehicleListControllerProvider.notifier)
          .deleteVehicle(vehicle.id);
      if (success && mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vehicle archived successfully.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _handleAssignDriver(VehicleEntity vehicle) async {
    // Mock list of company drivers for assignment dialog
    final List<Map<String, String>> drivers = [
      {'id': 'driver_1', 'name': 'Robert Jenkins'},
      {'id': 'driver_2', 'name': 'Sarah Connor'},
      {'id': 'driver_3', 'name': 'Alex Mercer'},
    ];

    final Map<String, String>? selectedDriver =
        await showDialog<Map<String, String>?>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Assign Primary Driver'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Select an available driver for this vehicle shift:'),
            const SizedBox(height: 16),
            ...drivers.map((d) {
              return ListTile(
                leading: const Icon(Icons.person_outline_rounded),
                title: Text(d['name']!),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                onTap: () => Navigator.of(context).pop(d),
              );
            }),
            const Divider(),
            ListTile(
              leading: const Icon(
                Icons.person_remove_outlined,
                color: Colors.red,
              ),
              title: const Text(
                'Unassign Current Driver',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () => Navigator.of(context).pop({'id': '', 'name': ''}),
            ),
          ],
        ),
      ),
    );

    if (selectedDriver != null && mounted) {
      final id = selectedDriver['id']!.isEmpty ? null : selectedDriver['id'];
      final name =
          selectedDriver['name']!.isEmpty ? null : selectedDriver['name'];

      final success = await ref
          .read(vehicleListControllerProvider.notifier)
          .assignDriver(vehicle.id, id, name);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              id == null ? 'Driver unassigned.' : 'Driver $name assigned.',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _uploadMockDocument(
    VehicleEntity vehicle,
    String docType,
  ) async {
    setState(() => _isUploadingDoc = true);

    // Simulate PDF compliance document upload delay
    await Future<void>.delayed(const Duration(milliseconds: 1500));

    if (!mounted) return;

    // Simulate updating expiry date to 1 year from now upon successful verified upload
    final updatedVehicle = vehicle.copyWith(
      insuranceExpiry: docType == 'insurance'
          ? DateTime.now().add(const Duration(days: 365))
          : vehicle.insuranceExpiry,
      pucExpiry: docType == 'puc'
          ? DateTime.now().add(const Duration(days: 180))
          : vehicle.pucExpiry,
      fitnessExpiry: docType == 'fitness'
          ? DateTime.now().add(const Duration(days: 365))
          : vehicle.fitnessExpiry,
    );

    final success = await ref
        .read(vehicleFormControllerProvider.notifier)
        .saveVehicle(updatedVehicle);

    setState(() => _isUploadingDoc = false);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${docType.toUpperCase()} document uploaded and verified.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final vehiclesAsync = ref.watch(vehiclesStreamProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Asset Diagnostics')),
      body: vehiclesAsync.when(
        loading: () =>
            LoadingWidget.fullScreen(message: 'Loading asset parameters...'),
        error: (err, _) => Center(child: Text(err.toString())),
        data: (vehicles) {
          final vehicle = vehicles.firstWhere(
            (v) => v.id == widget.vehicleId,
            orElse: () => VehicleEntity(
              id: '',
              vin: '',
              licensePlate: '',
              make: '',
              model: '',
              year: 0,
              status: '',
              fuelType: '',
              odometer: 0,
              insuranceExpiry: DateTime(1970),
              pucExpiry: DateTime(1970),
              fitnessExpiry: DateTime(1970),
              createdAt: DateTime(1970),
              updatedAt: DateTime(1970),
            ),
          );

          if (vehicle.id.isEmpty) {
            return Center(
              child: EmptyStateWidget(
                title: 'Asset Not Found',
                description:
                    'The requested vehicle may have been archived or transferred.',
                icon: Icons.search_off_rounded,
                actionText: 'Back to Fleet',
                onActionPressed: () => context.pop(),
              ),
            );
          }

          final isInsWarning = VehicleComplianceHelper.isInsuranceWarning(
            vehicle,
          );
          final isInsExpired = VehicleComplianceHelper.isInsuranceExpired(
            vehicle,
          );
          final isPucWarning = VehicleComplianceHelper.isPucWarning(vehicle);
          final isPucExpired = VehicleComplianceHelper.isPucExpired(vehicle);
          final isFitWarning = VehicleComplianceHelper.isFitnessWarning(
            vehicle,
          );
          final isFitExpired = VehicleComplianceHelper.isFitnessExpired(
            vehicle,
          );

          return _isUploadingDoc
              ? LoadingWidget.fullScreen(
                  message: 'Uploading compliance cover note PDF...',
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Card Summary
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                vehicle.licensePlate,
                                style: theme.textTheme.displayLarge?.copyWith(
                                  fontSize: 32,
                                ),
                              ),
                              Text(
                                '${vehicle.make} ${vehicle.model} (${vehicle.year})',
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: colorScheme.onBackground.withOpacity(
                                    0.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined),
                                tooltip: 'Edit Specifications',
                                onPressed: () => context.push(
                                  '/vehicles/${vehicle.id}/edit',
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_outline_rounded,
                                  color: Colors.red,
                                ),
                                tooltip: 'Archive Asset',
                                onPressed: () => _handleArchive(vehicle),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Driver Assignment Section
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor:
                                        colorScheme.primary.withOpacity(0.12),
                                    child: Icon(
                                      Icons.person_outline_rounded,
                                      color: colorScheme.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Primary Driver',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        vehicle.assignedDriverName ??
                                            'Unassigned Shift',
                                        style: TextStyle(
                                          color:
                                              vehicle.assignedDriverName == null
                                                  ? Colors.amber
                                                  : Colors.green,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              CustomButton(
                                text: vehicle.assignedDriverId == null
                                    ? 'ASSIGN'
                                    : 'MANAGE',
                                width: 100,
                                height: 38,
                                onPressed: () => _handleAssignDriver(vehicle),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Section: Specifications
                      _buildSectionHeader(theme, 'Vehicle Specifications'),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildSpecTile(
                              'VIN',
                              vehicle.vin.toUpperCase(),
                            ),
                          ),
                          Expanded(
                            child: _buildSpecTile(
                              'Fuel Type',
                              vehicle.fuelType.toUpperCase(),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: _buildSpecTile(
                              'Odometer',
                              '${vehicle.odometer.toStringAsFixed(0)} km',
                            ),
                          ),
                          Expanded(
                            child: _buildSpecTile(
                              'Last Service',
                              vehicle.lastServiceDate != null
                                  ? '${vehicle.lastServiceDate!.day}/${vehicle.lastServiceDate!.month}/${vehicle.lastServiceDate!.year}'
                                  : 'Never Recorded',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Section: Compliance Reminders
                      _buildSectionHeader(
                        theme,
                        'Statutory Compliance Documents',
                      ),
                      const SizedBox(height: 12),
                      _buildComplianceTile(
                        title: 'Third Party Liability Insurance',
                        expiryDate: vehicle.insuranceExpiry,
                        isExpired: isInsExpired,
                        isWarning: isInsWarning,
                        onUpload: () =>
                            _uploadMockDocument(vehicle, 'insurance'),
                      ),
                      _buildComplianceTile(
                        title: 'Pollution Under Control (PUC)',
                        expiryDate: vehicle.pucExpiry,
                        isExpired: isPucExpired,
                        isWarning: isPucWarning,
                        onUpload: () => _uploadMockDocument(vehicle, 'puc'),
                      ),
                      _buildComplianceTile(
                        title: 'Road Fitness Certificate',
                        expiryDate: vehicle.fitnessExpiry,
                        isExpired: isFitExpired,
                        isWarning: isFitWarning,
                        onUpload: () => _uploadMockDocument(vehicle, 'fitness'),
                      ),
                    ],
                  ),
                );
        },
      ),
    );
  }

  Widget _buildSectionHeader(ThemeData theme, String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
        const Divider(),
      ],
    );
  }

  Widget _buildSpecTile(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildComplianceTile({
    required String title,
    required DateTime expiryDate,
    required bool isExpired,
    required bool isWarning,
    required VoidCallback onUpload,
  }) {
    final statusColor =
        isExpired ? Colors.red : (isWarning ? Colors.amber : Colors.green);
    final statusText =
        isExpired ? 'EXPIRED' : (isWarning ? 'EXPIRING SOON' : 'VALID');

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'Expires: ${expiryDate.day}/${expiryDate.month}/${expiryDate.year}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: statusColor),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.upload_file_outlined),
              tooltip: 'Upload New Doc',
              onPressed: onUpload,
            ),
          ],
        ),
      ),
    );
  }
}
