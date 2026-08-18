import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../vehicles/presentation/vehicle_providers.dart';
import '../domain/driver_entity.dart';
import 'driver_providers.dart';

class DriverFormScreen extends ConsumerStatefulWidget {
  final String? driverId;

  const DriverFormScreen({super.key, this.driverId});

  @override
  ConsumerState<DriverFormScreen> createState() => _DriverFormScreenState();
}

class _DriverFormScreenState extends ConsumerState<DriverFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _licenseController;
  late DateTime _licenseExpiry;
  late String _status;
  late double _safetyScore;
  String? _selectedVehicleId;
  String? _selectedVehiclePlate;

  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _phoneController = TextEditingController();
    _licenseController = TextEditingController();
    _licenseExpiry = DateTime.now().add(const Duration(days: 365));
    _status = 'available';
    _safetyScore = 100.0;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _licenseController.dispose();
    super.dispose();
  }

  void _initializeValues(List<DriverEntity> drivers) {
    if (_initialized) return;
    if (widget.driverId != null) {
      final driver = drivers.firstWhere((d) => d.id == widget.driverId);
      _nameController.text = driver.fullName;
      _phoneController.text = driver.phone;
      _licenseController.text = driver.licenseNumber;
      _licenseExpiry = driver.licenseExpiry;
      _status = driver.status;
      _safetyScore = driver.safetyScore;
      _selectedVehicleId = driver.assignedVehicleId;
      _selectedVehiclePlate = driver.assignedVehicleLicensePlate;
    }
    _initialized = true;
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _licenseExpiry,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _licenseExpiry) {
      setState(() {
        _licenseExpiry = picked;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final driver = DriverEntity(
      id: widget.driverId ?? '',
      fullName: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      licenseNumber: _licenseController.text.trim(),
      licenseExpiry: _licenseExpiry,
      status: _status,
      safetyScore: _safetyScore,
      assignedVehicleId: _selectedVehicleId,
      assignedVehicleLicensePlate: _selectedVehiclePlate,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final success = await ref
        .read(driverFormControllerProvider.notifier)
        .saveDriver(driver);

    if (success && mounted) {
      final savedId = widget.driverId ??
          ref
              .read(driversStreamProvider)
              .valueOrNull
              ?.firstWhere((d) => d.fullName == driver.fullName)
              .id ??
          '';

      if (savedId.isNotEmpty) {
        await ref
            .read(driverListControllerProvider.notifier)
            .assignVehicle(savedId, _selectedVehicleId, _selectedVehiclePlate);
      }

      if (mounted) {
        context.pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formState = ref.watch(driverFormControllerProvider);
    final drivers = ref.watch(driversStreamProvider).valueOrNull ?? [];
    final vehicles = ref.watch(vehiclesStreamProvider).valueOrNull ?? [];

    if (widget.driverId != null && drivers.isNotEmpty) {
      _initializeValues(drivers);
    }

    final isEditMode = widget.driverId != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditMode ? 'Edit Driver' : 'Onboard Driver'),
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
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Driver Full Name',
                        prefixIcon: Icon(Icons.person_rounded),
                      ),
                      validator: (val) => val == null || val.trim().isEmpty
                          ? 'Enter driver full name'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number',
                        prefixIcon: Icon(Icons.phone_rounded),
                      ),
                      validator: (val) => val == null || val.trim().isEmpty
                          ? 'Enter phone number'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _licenseController,
                      decoration: const InputDecoration(
                        labelText: 'License Number',
                        prefixIcon: Icon(Icons.badge_rounded),
                      ),
                      validator: (val) => val == null || val.trim().isEmpty
                          ? 'Enter license number'
                          : null,
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'License Expiry Date',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurface
                                    .withOpacity(0.6),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _licenseExpiry.toLocal().toString().split(' ')[0],
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        OutlinedButton.icon(
                          onPressed: () => _selectDate(context),
                          icon: const Icon(Icons.calendar_today_rounded),
                          label: const Text('Change Date'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    DropdownButtonFormField<String>(
                      value: _status,
                      decoration: const InputDecoration(
                        labelText: 'Status',
                        prefixIcon: Icon(Icons.info_outline_rounded),
                      ),
                      items: ['available', 'on_duty', 'off_duty', 'suspended']
                          .map((s) => DropdownMenuItem(
                              value: s, child: Text(s.toUpperCase())))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _status = val;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 24),
                    DropdownButtonFormField<String>(
                      value: _selectedVehicleId,
                      decoration: const InputDecoration(
                        labelText: 'Link Primary Vehicle',
                        prefixIcon: Icon(Icons.local_shipping_outlined),
                      ),
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('NONE / UNLINKED'),
                        ),
                        ...vehicles.map((v) => DropdownMenuItem(
                              value: v.id,
                              child: Text(
                                  '${v.make} ${v.model} (${v.licensePlate})'),
                            ))
                      ],
                      onChanged: (val) {
                        setState(() {
                          _selectedVehicleId = val;
                          if (val == null) {
                            _selectedVehiclePlate = null;
                          } else {
                            _selectedVehiclePlate = vehicles
                                .firstWhere((v) => v.id == val)
                                .licensePlate;
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Safety Score: ${_safetyScore.toStringAsFixed(0)}%',
                      style: theme.textTheme.bodyMedium,
                    ),
                    Slider(
                      value: _safetyScore,
                      min: 0,
                      max: 100,
                      divisions: 100,
                      label: '${_safetyScore.toStringAsFixed(0)}%',
                      onChanged: (val) {
                        setState(() {
                          _safetyScore = val;
                        });
                      },
                    ),
                    const SizedBox(height: 32),
                    CustomButton(
                      text: isEditMode
                          ? 'Update Driver Profiles'
                          : 'Onboard Driver',
                      onPressed: _submit,
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
