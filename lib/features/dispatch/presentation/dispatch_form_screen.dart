import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/widgets/custom_button.dart';
import '../../vehicles/presentation/vehicle_providers.dart';
import '../../drivers/presentation/driver_providers.dart';
import '../domain/dispatch_entity.dart';
import 'dispatch_providers.dart';

class DispatchFormScreen extends ConsumerStatefulWidget {
  final String? dispatchId;

  const DispatchFormScreen({super.key, this.dispatchId});

  @override
  ConsumerState<DispatchFormScreen> createState() => _DispatchFormScreenState();
}

class _DispatchFormScreenState extends ConsumerState<DispatchFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();

  String? _selectedVehicleId;
  String? _selectedVehiclePlate;
  String? _selectedDriverId;
  String? _selectedDriverName;
  String? _selectedRouteId;
  String? _selectedRouteName;

  DateTime _scheduledTime = DateTime.now().add(const Duration(hours: 2));
  String _status = 'scheduled';
  bool _initialized = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _initializeValues(List<DispatchEntity> dispatches) {
    if (_initialized) return;
    if (widget.dispatchId != null) {
      final disp = dispatches.firstWhere((d) => d.id == widget.dispatchId);
      _selectedVehicleId = disp.vehicleId;
      _selectedVehiclePlate = disp.vehicleLicensePlate;
      _selectedDriverId = disp.driverId;
      _selectedDriverName = disp.driverName;
      _selectedRouteId = disp.routeId;
      _selectedRouteName = disp.routeName;
      _scheduledTime = disp.scheduledTime;
      _status = disp.status;
      _notesController.text = disp.notes ?? '';
    }
    _initialized = true;
  }

  Future<void> _selectDateTime() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _scheduledTime,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (pickedDate != null && mounted) {
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_scheduledTime),
      );
      if (pickedTime != null) {
        setState(() {
          _scheduledTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedVehicleId == null ||
        _selectedDriverId == null ||
        _selectedRouteId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please select vehicle, driver, and route.')),
      );
      return;
    }

    final dispatch = DispatchEntity(
      id: widget.dispatchId ?? '',
      dispatchNumber: widget.dispatchId != null
          ? '' // keep existing
          : 'DISP-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
      companyId: '', // populated in provider
      vehicleId: _selectedVehicleId!,
      vehicleLicensePlate: _selectedVehiclePlate!,
      driverId: _selectedDriverId!,
      driverName: _selectedDriverName!,
      routeId: _selectedRouteId!,
      routeName: _selectedRouteName!,
      status: _status,
      scheduledTime: _scheduledTime,
      notes: _notesController.text.trim(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final success = await ref
        .read(dispatchFormControllerProvider.notifier)
        .saveDispatch(dispatch);

    if (success && mounted) {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formState = ref.watch(dispatchFormControllerProvider);
    final dispatches = ref.watch(dispatchesStreamProvider).valueOrNull ?? [];
    final vehicles = ref.watch(vehiclesStreamProvider).valueOrNull ?? [];
    final drivers = ref.watch(driversStreamProvider).valueOrNull ?? [];
    final routes = ref.watch(routesStreamProvider).valueOrNull ?? [];

    if (dispatches.isNotEmpty) {
      _initializeValues(dispatches);
    }

    final isEditMode = widget.dispatchId != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditMode ? 'Edit Dispatch' : 'Schedule Dispatch'),
      ),
      body: formState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (formState.errorMessage != null) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.error.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          formState.errorMessage!,
                          style: TextStyle(color: theme.colorScheme.error),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                    // Route Selection Dropdown
                    DropdownButtonFormField<String>(
                      value: _selectedRouteId,
                      decoration: const InputDecoration(
                        labelText: 'Select Route',
                        prefixIcon: Icon(Icons.map_rounded),
                      ),
                      items: routes.map((r) {
                        return DropdownMenuItem<String>(
                          value: r.id,
                          child: Text(r.name),
                        );
                      }).toList(),
                      onChanged: (val) {
                        final r = routes.firstWhere((route) => route.id == val);
                        setState(() {
                          _selectedRouteId = val;
                          _selectedRouteName = r.name;
                        });
                      },
                      validator: (value) =>
                          value == null ? 'Route is required' : null,
                    ),
                    const SizedBox(height: 16),
                    // Driver Selection Dropdown
                    DropdownButtonFormField<String>(
                      value: _selectedDriverId,
                      decoration: const InputDecoration(
                        labelText: 'Select Driver',
                        prefixIcon: Icon(Icons.person_rounded),
                      ),
                      items: drivers.map((d) {
                        return DropdownMenuItem<String>(
                          value: d.id,
                          child: Text('${d.fullName} (${d.status})'),
                        );
                      }).toList(),
                      onChanged: (val) {
                        final d =
                            drivers.firstWhere((driver) => driver.id == val);
                        setState(() {
                          _selectedDriverId = val;
                          _selectedDriverName = d.fullName;
                        });
                      },
                      validator: (value) =>
                          value == null ? 'Driver is required' : null,
                    ),
                    const SizedBox(height: 16),
                    // Vehicle Selection Dropdown
                    DropdownButtonFormField<String>(
                      value: _selectedVehicleId,
                      decoration: const InputDecoration(
                        labelText: 'Select Vehicle',
                        prefixIcon: Icon(Icons.local_shipping_rounded),
                      ),
                      items: vehicles.map((v) {
                        return DropdownMenuItem<String>(
                          value: v.id,
                          child: Text('${v.licensePlate} (${v.status})'),
                        );
                      }).toList(),
                      onChanged: (val) {
                        final v = vehicles.firstWhere((veh) => veh.id == val);
                        setState(() {
                          _selectedVehicleId = val;
                          _selectedVehiclePlate = v.licensePlate;
                        });
                      },
                      validator: (value) =>
                          value == null ? 'Vehicle is required' : null,
                    ),
                    const SizedBox(height: 16),
                    // Scheduled Date and Time
                    ListTile(
                      leading: const Icon(Icons.calendar_today_rounded),
                      title: const Text('Scheduled Departure Time'),
                      subtitle: Text(
                          DateFormat.yMd().add_jm().format(_scheduledTime)),
                      trailing: const Icon(Icons.arrow_drop_down_rounded),
                      onTap: _selectDateTime,
                    ),
                    const SizedBox(height: 16),
                    // Notes Input
                    TextFormField(
                      controller: _notesController,
                      decoration: const InputDecoration(
                        labelText: 'Dispatch Notes',
                        prefixIcon: Icon(Icons.notes_rounded),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 32),
                    CustomButton(
                      text: isEditMode ? 'Update Schedule' : 'Confirm Dispatch',
                      onPressed: _submit,
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
