import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../domain/vehicle_entity.dart';
import 'vehicle_providers.dart';

/// Screen allowing additions or editing of vehicle records.
class VehicleFormScreen extends ConsumerStatefulWidget {
  final String? vehicleId;

  const VehicleFormScreen({super.key, this.vehicleId});

  @override
  ConsumerState<VehicleFormScreen> createState() => _VehicleFormScreenState();
}

class _VehicleFormScreenState extends ConsumerState<VehicleFormScreen> {
  final _formKey = GlobalKey<FormState>();

  // Text controllers
  final _vinController = TextEditingController();
  final _licensePlateController = TextEditingController();
  final _makeController = TextEditingController();
  final _modelController = TextEditingController();
  final _yearController = TextEditingController();
  final _odometerController = TextEditingController();

  // Status and type selections
  String _status = 'active';
  String _fuelType = 'diesel';

  // Compliance date values
  DateTime? _lastServiceDate;
  DateTime _insuranceExpiry = DateTime.now().add(const Duration(days: 30));
  DateTime _pucExpiry = DateTime.now().add(const Duration(days: 30));
  DateTime _fitnessExpiry = DateTime.now().add(const Duration(days: 30));

  final List<String> _statuses = ['active', 'maintenance', 'idle', 'sold'];
  final List<String> _fuelTypes = ['diesel', 'unleaded', 'electric'];

  @override
  void initState() {
    super.initState();
    _loadInitialValues();
  }

  void _loadInitialValues() {
    if (widget.vehicleId != null) {
      final vehiclesAsync = ref.read(vehiclesStreamProvider);
      final vehicles = vehiclesAsync.valueOrNull ?? [];
      final vehicle = vehicles.firstWhere((v) => v.id == widget.vehicleId);

      if (vehicle.id.isNotEmpty) {
        _vinController.text = vehicle.vin;
        _licensePlateController.text = vehicle.licensePlate;
        _makeController.text = vehicle.make;
        _modelController.text = vehicle.model;
        _yearController.text = vehicle.year.toString();
        _odometerController.text = vehicle.odometer.toString();
        _status = vehicle.status;
        _fuelType = vehicle.fuelType;
        _lastServiceDate = vehicle.lastServiceDate;
        _insuranceExpiry = vehicle.insuranceExpiry;
        _pucExpiry = vehicle.pucExpiry;
        _fitnessExpiry = vehicle.fitnessExpiry;
      }
    }
  }

  @override
  void dispose() {
    _vinController.dispose();
    _licensePlateController.dispose();
    _makeController.dispose();
    _modelController.dispose();
    _yearController.dispose();
    _odometerController.dispose();
    super.dispose();
  }

  Future<void> _pickDate({
    required DateTime initialDate,
    required void Function(DateTime date) onDateSelected,
  }) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      setState(() => onDateSelected(picked));
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    final existingUser =
        ref.read(vehiclesStreamProvider).valueOrNull?.firstWhere(
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

    final vehicle = VehicleEntity(
      id: widget.vehicleId ?? '',
      vin: _vinController.text.trim().toUpperCase(),
      licensePlate: _licensePlateController.text.trim().toUpperCase(),
      make: _makeController.text.trim(),
      model: _modelController.text.trim(),
      year: int.parse(_yearController.text.trim()),
      status: _status,
      fuelType: _fuelType,
      odometer: double.parse(_odometerController.text.trim()),
      lastServiceDate: _lastServiceDate,
      insuranceExpiry: _insuranceExpiry,
      pucExpiry: _pucExpiry,
      fitnessExpiry: _fitnessExpiry,
      assignedDriverId: existingUser?.assignedDriverId,
      assignedDriverName: existingUser?.assignedDriverName,
      createdAt: existingUser?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final success = await ref
        .read(vehicleFormControllerProvider.notifier)
        .saveVehicle(vehicle);

    if (success && mounted) {
      context.pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vehicle specifications saved.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final formState = ref.watch(vehicleFormControllerProvider);

    final dateFormat = DateFormat('dd/MM/yyyy');

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.vehicleId == null ? 'Onboard Vehicle' : 'Edit Specifications',
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
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
                    color: colorScheme.error.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: colorScheme.error.withOpacity(0.2),
                    ),
                  ),
                  child: Text(
                    formState.errorMessage!,
                    style: TextStyle(color: colorScheme.error, fontSize: 13),
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Section: Core parameters
              _buildSectionHeader(theme, 'Vehicle Details'),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: _licensePlateController,
                      labelText: 'License Plate',
                      hintText: 'NY-884-AB',
                      prefixIcon: Icons.badge_outlined,
                      validator: (val) => val == null || val.isEmpty
                          ? 'License plate is required'
                          : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: CustomTextField(
                      controller: _vinController,
                      labelText: 'VIN Number',
                      hintText: '17 Characters',
                      prefixIcon: Icons.fingerprint_rounded,
                      validator: (val) {
                        if (val == null || val.isEmpty)
                          return 'VIN is required';
                        if (val.length != 17)
                          return 'VIN must be exactly 17 characters';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: _makeController,
                      labelText: 'Manufacturer / Make',
                      hintText: 'Volvo',
                      prefixIcon: Icons.construction_outlined,
                      validator: (val) => val == null || val.isEmpty
                          ? 'Make is required'
                          : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: CustomTextField(
                      controller: _modelController,
                      labelText: 'Model',
                      hintText: 'VNL 860',
                      prefixIcon: Icons.local_shipping_outlined,
                      validator: (val) => val == null || val.isEmpty
                          ? 'Model is required'
                          : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: _yearController,
                      labelText: 'Manufacture Year',
                      hintText: '2023',
                      keyboardType: TextInputType.number,
                      prefixIcon: Icons.calendar_today_outlined,
                      validator: (val) {
                        if (val == null || val.isEmpty) return 'Required';
                        final year = int.tryParse(val);
                        if (year == null ||
                            year < 1980 ||
                            year > DateTime.now().year + 1)
                          return 'Invalid year';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: CustomTextField(
                      controller: _odometerController,
                      labelText: 'Odometer (km)',
                      hintText: '12050',
                      keyboardType: TextInputType.number,
                      prefixIcon: Icons.speed_outlined,
                      validator: (val) {
                        if (val == null || val.isEmpty) return 'Required';
                        final odo = double.tryParse(val);
                        if (odo == null || odo < 0) return 'Invalid reading';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Section: Operational Status
              _buildSectionHeader(theme, 'Operational Status'),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _status,
                      decoration: const InputDecoration(
                        labelText: 'Asset Status',
                        prefixIcon: Icon(Icons.info_outline_rounded, size: 20),
                      ),
                      items: _statuses.map((s) {
                        return DropdownMenuItem(
                          value: s,
                          child: Text(s.toUpperCase()),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _status = val);
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _fuelType,
                      decoration: const InputDecoration(
                        labelText: 'Fuel Category',
                        prefixIcon: Icon(
                          Icons.local_gas_station_outlined,
                          size: 20,
                        ),
                      ),
                      items: _fuelTypes.map((f) {
                        return DropdownMenuItem(
                          value: f,
                          child: Text(f.toUpperCase()),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _fuelType = val);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Section: Compliance Expiration Dates
              _buildSectionHeader(
                theme,
                'Statutory Compliance Expiration Calendars',
              ),
              const SizedBox(height: 16),
              _buildDateSelector(
                label: 'Last Service Date',
                selectedDate: _lastServiceDate,
                formatter: dateFormat,
                onTap: () => _pickDate(
                  initialDate: _lastServiceDate ?? DateTime.now(),
                  onDateSelected: (date) =>
                      setState(() => _lastServiceDate = date),
                ),
              ),
              const SizedBox(height: 16),
              _buildDateSelector(
                label: 'Insurance Expiry Date',
                selectedDate: _insuranceExpiry,
                formatter: dateFormat,
                onTap: () => _pickDate(
                  initialDate: _insuranceExpiry,
                  onDateSelected: (date) =>
                      setState(() => _insuranceExpiry = date),
                ),
              ),
              const SizedBox(height: 16),
              _buildDateSelector(
                label: 'Emissions PUC Expiry Date',
                selectedDate: _pucExpiry,
                formatter: dateFormat,
                onTap: () => _pickDate(
                  initialDate: _pucExpiry,
                  onDateSelected: (date) => setState(() => _pucExpiry = date),
                ),
              ),
              const SizedBox(height: 16),
              _buildDateSelector(
                label: 'Fitness Certificate Expiry Date',
                selectedDate: _fitnessExpiry,
                formatter: dateFormat,
                onTap: () => _pickDate(
                  initialDate: _fitnessExpiry,
                  onDateSelected: (date) =>
                      setState(() => _fitnessExpiry = date),
                ),
              ),
              const SizedBox(height: 40),

              // Actions
              CustomButton(
                text: 'SAVE VEHICLE SPECIFICATIONS',
                isLoading: formState.isLoading,
                onPressed: _submitForm,
              ),
            ],
          ),
        ),
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

  Widget _buildDateSelector({
    required String label,
    required DateTime? selectedDate,
    required DateFormat formatter,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        label,
        style: const TextStyle(fontSize: 13, color: Colors.grey),
      ),
      subtitle: Text(
        selectedDate != null ? formatter.format(selectedDate) : 'Not Recorded',
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
      trailing: const Icon(Icons.calendar_month_outlined),
      onTap: onTap,
    );
  }
}
