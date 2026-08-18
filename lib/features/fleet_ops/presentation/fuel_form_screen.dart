import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../vehicles/presentation/vehicle_providers.dart';
import '../../drivers/presentation/driver_providers.dart';
import '../domain/fuel_entity.dart';
import 'fleet_ops_providers.dart';

class FuelFormScreen extends ConsumerStatefulWidget {
  final String? fuelLogId;

  const FuelFormScreen({super.key, this.fuelLogId});

  @override
  ConsumerState<FuelFormScreen> createState() => _FuelFormScreenState();
}

class _FuelFormScreenState extends ConsumerState<FuelFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _fuelQtyController;
  late TextEditingController _amountController;
  late TextEditingController _odometerController;

  String? _selectedVehicleId;
  String? _selectedVehiclePlate;
  String? _selectedDriverId;
  String? _selectedDriverName;
  DateTime _selectedDate = DateTime.now();

  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _fuelQtyController = TextEditingController();
    _amountController = TextEditingController();
    _odometerController = TextEditingController();
  }

  @override
  void dispose() {
    _fuelQtyController.dispose();
    _amountController.dispose();
    _odometerController.dispose();
    super.dispose();
  }

  void _initializeValues(List<FuelEntity> logs) {
    if (_initialized) return;
    if (widget.fuelLogId != null) {
      final log = logs.firstWhere((l) => l.id == widget.fuelLogId);
      _fuelQtyController.text = log.fuelQty.toString();
      _amountController.text = log.amount.toString();
      _odometerController.text = log.odometer.toString();
      _selectedVehicleId = log.vehicleId;
      _selectedVehiclePlate = log.vehicleLicensePlate;
      _selectedDriverId = log.driverId;
      _selectedDriverName = log.driverName;
      _selectedDate = log.date;
    }
    _initialized = true;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedVehicleId == null || _selectedVehiclePlate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a vehicle')),
      );
      return;
    }
    if (_selectedDriverId == null || _selectedDriverName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a driver')),
      );
      return;
    }

    final log = FuelEntity(
      id: widget.fuelLogId ?? '',
      companyId: '',
      vehicleId: _selectedVehicleId!,
      vehicleLicensePlate: _selectedVehiclePlate!,
      driverId: _selectedDriverId!,
      driverName: _selectedDriverName!,
      fuelQty: double.parse(_fuelQtyController.text.trim()),
      amount: double.parse(_amountController.text.trim()),
      odometer: double.parse(_odometerController.text.trim()),
      date: _selectedDate,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final success =
        await ref.read(fuelFormControllerProvider.notifier).saveFuelLog(log);

    if (success && mounted) {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formState = ref.watch(fuelFormControllerProvider);
    final fuelLogs = ref.watch(fuelLogsStreamProvider).valueOrNull ?? [];
    final vehicles = ref.watch(vehiclesStreamProvider).valueOrNull ?? [];
    final drivers = ref.watch(driversStreamProvider).valueOrNull ?? [];

    if (widget.fuelLogId != null && fuelLogs.isNotEmpty) {
      _initializeValues(fuelLogs);
    }

    final isEditMode = widget.fuelLogId != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditMode ? 'Edit Fuel Entry' : 'Log Fuel Entry'),
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
                    // Vehicle Selector
                    DropdownButtonFormField<String>(
                      value: _selectedVehicleId,
                      decoration: const InputDecoration(
                        labelText: 'Select Vehicle',
                        prefixIcon: Icon(Icons.local_shipping_rounded),
                      ),
                      items: vehicles
                          .map((v) => DropdownMenuItem(
                              value: v.id, child: Text(v.licensePlate)))
                          .toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedVehicleId = val;
                          _selectedVehiclePlate = vehicles
                              .firstWhere((v) => v.id == val)
                              .licensePlate;
                        });
                      },
                      validator: (val) =>
                          val == null ? 'Select a vehicle' : null,
                    ),
                    const SizedBox(height: 16),
                    // Driver Selector
                    DropdownButtonFormField<String>(
                      value: _selectedDriverId,
                      decoration: const InputDecoration(
                        labelText: 'Select Driver',
                        prefixIcon: Icon(Icons.person_rounded),
                      ),
                      items: drivers
                          .map((d) => DropdownMenuItem(
                              value: d.id, child: Text(d.fullName)))
                          .toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedDriverId = val;
                          _selectedDriverName =
                              drivers.firstWhere((d) => d.id == val).fullName;
                        });
                      },
                      validator: (val) =>
                          val == null ? 'Select a driver' : null,
                    ),
                    const SizedBox(height: 16),
                    // Fuel Quantity
                    TextFormField(
                      controller: _fuelQtyController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Fuel Volume (Liters)',
                        prefixIcon: Icon(Icons.local_gas_station_rounded),
                      ),
                      validator: (val) => val == null || val.trim().isEmpty
                          ? 'Enter fuel quantity'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    // Amount Cost
                    TextFormField(
                      controller: _amountController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Cost Amount (\$)',
                        prefixIcon: Icon(Icons.attach_money_rounded),
                      ),
                      validator: (val) => val == null || val.trim().isEmpty
                          ? 'Enter fuel amount cost'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    // Odometer
                    TextFormField(
                      controller: _odometerController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Odometer Reading (km)',
                        prefixIcon: Icon(Icons.speed_rounded),
                      ),
                      validator: (val) => val == null || val.trim().isEmpty
                          ? 'Enter current odometer'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    // Date picker
                    ListTile(
                      leading: const Icon(Icons.calendar_today_rounded),
                      title: const Text('Refill Date'),
                      subtitle:
                          Text(DateFormat('dd MMM yyyy').format(_selectedDate)),
                      trailing:
                          const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          setState(() {
                            _selectedDate = picked;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 32),
                    CustomButton(
                      text: isEditMode ? 'Update Entry' : 'Log Refill',
                      onPressed: _submit,
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
