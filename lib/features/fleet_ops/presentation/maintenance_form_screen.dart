import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../vehicles/presentation/vehicle_providers.dart';
import '../../vendors/presentation/vendor_providers.dart';
import '../../inventory/presentation/inventory_providers.dart';
import '../domain/maintenance_entity.dart';
import 'fleet_ops_providers.dart';

class MaintenanceFormScreen extends ConsumerStatefulWidget {
  final String? maintLogId;

  const MaintenanceFormScreen({super.key, this.maintLogId});

  @override
  ConsumerState<MaintenanceFormScreen> createState() =>
      _MaintenanceFormScreenState();
}

class _MaintenanceFormScreenState extends ConsumerState<MaintenanceFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _descriptionController;
  late TextEditingController _costController;
  late TextEditingController _odometerController;

  String? _selectedVehicleId;
  String? _selectedVehiclePlate;
  String? _selectedVendorId;
  String? _selectedVendorName;
  String _maintType = 'preventative';
  DateTime _selectedDate = DateTime.now();

  String? _selectedPartId;
  String? _selectedPartName;
  late TextEditingController _partQtyController;

  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _descriptionController = TextEditingController();
    _costController = TextEditingController();
    _odometerController = TextEditingController();
    _partQtyController = TextEditingController();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _costController.dispose();
    _odometerController.dispose();
    _partQtyController.dispose();
    super.dispose();
  }

  void _initializeValues(List<MaintenanceEntity> logs) {
    if (_initialized) return;
    if (widget.maintLogId != null) {
      final log = logs.firstWhere((l) => l.id == widget.maintLogId);
      _descriptionController.text = log.description;
      _costController.text = log.cost.toString();
      _odometerController.text = log.odometer.toString();
      _selectedVehicleId = log.vehicleId;
      _selectedVehiclePlate = log.vehicleLicensePlate;
      _selectedVendorId = log.vendorId;
      _selectedVendorName = log.vendorName;
      _maintType = log.type;
      _selectedDate = log.date;
      _selectedPartId = log.partId;
      _selectedPartName = log.partName;
      _partQtyController.text = log.partQuantity?.toString() ?? '';
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

    final log = MaintenanceEntity(
      id: widget.maintLogId ?? '',
      companyId: '',
      vehicleId: _selectedVehicleId!,
      vehicleLicensePlate: _selectedVehiclePlate!,
      vendorId: _selectedVendorId,
      vendorName: _selectedVendorName,
      type: _maintType,
      description: _descriptionController.text.trim(),
      cost: double.parse(_costController.text.trim()),
      odometer: double.parse(_odometerController.text.trim()),
      date: _selectedDate,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      partId: _selectedPartId,
      partName: _selectedPartName,
      partQuantity: _selectedPartId != null
          ? int.tryParse(_partQtyController.text.trim())
          : null,
    );

    final success = await ref
        .read(maintenanceFormControllerProvider.notifier)
        .saveMaintenanceLog(log);

    if (success && mounted) {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formState = ref.watch(maintenanceFormControllerProvider);
    final maintLogs =
        ref.watch(maintenanceLogsStreamProvider).valueOrNull ?? [];
    final vehicles = ref.watch(vehiclesStreamProvider).valueOrNull ?? [];
    final vendors = ref.watch(vendorsStreamProvider).valueOrNull ?? [];
    final parts = ref.watch(partsStreamProvider).valueOrNull ?? [];

    if (widget.maintLogId != null && maintLogs.isNotEmpty) {
      _initializeValues(maintLogs);
    }

    final isEditMode = widget.maintLogId != null;

    return Scaffold(
      appBar: AppBar(
        title:
            Text(isEditMode ? 'Edit Maintenance Log' : 'Log Maintenance Job'),
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
                    // Vendor Selector
                    DropdownButtonFormField<String?>(
                      value: _selectedVendorId,
                      decoration: const InputDecoration(
                        labelText: 'Select Vendor Workshop (Optional)',
                        prefixIcon: Icon(Icons.business_rounded),
                      ),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('General/Internal Workshop'),
                        ),
                        ...vendors.map(
                          (v) => DropdownMenuItem<String?>(
                              value: v.id, child: Text(v.name)),
                        ),
                      ],
                      onChanged: (val) {
                        setState(() {
                          _selectedVendorId = val;
                          _selectedVendorName = val != null
                              ? vendors.firstWhere((v) => v.id == val).name
                              : null;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    // Type selector
                    DropdownButtonFormField<String>(
                      value: _maintType,
                      decoration: const InputDecoration(
                        labelText: 'Maintenance Type',
                        prefixIcon: Icon(Icons.info_outline_rounded),
                      ),
                      items: ['preventative', 'corrective']
                          .map((s) => DropdownMenuItem(
                              value: s, child: Text(s.toUpperCase())))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _maintType = val;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    // Spare Part selector
                    DropdownButtonFormField<String?>(
                      value: _selectedPartId,
                      decoration: const InputDecoration(
                        labelText: 'Select Spare Part Used (Optional)',
                        prefixIcon: Icon(Icons.settings_suggest_rounded),
                      ),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('No Spare Part Used'),
                        ),
                        ...parts.map(
                          (p) => DropdownMenuItem<String?>(
                            value: p.id,
                            child: Text(
                                '${p.name} (${p.partNumber}) - Avail: ${p.quantity}'),
                          ),
                        ),
                      ],
                      onChanged: (val) {
                        setState(() {
                          _selectedPartId = val;
                          _selectedPartName = val != null
                              ? parts.firstWhere((p) => p.id == val).name
                              : null;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    // Part quantity used
                    if (_selectedPartId != null) ...[
                      TextFormField(
                        controller: _partQtyController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Spare Part Quantity Used',
                          prefixIcon:
                              Icon(Icons.production_quantity_limits_rounded),
                        ),
                        validator: (val) {
                          if (_selectedPartId != null &&
                              (val == null || val.trim().isEmpty)) {
                            return 'Enter quantity of parts used';
                          }
                          final parsed = int.tryParse(val ?? '');
                          if (parsed == null || parsed <= 0) {
                            return 'Enter a positive integer quantity';
                          }
                          // Check available stock
                          final part =
                              parts.firstWhere((p) => p.id == _selectedPartId);
                          if (parsed > part.quantity) {
                            return 'Not enough stock! Available: ${part.quantity}';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                    ],
                    // Job Description
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Repair Job Description',
                        prefixIcon: Icon(Icons.description_outlined),
                      ),
                      validator: (val) => val == null || val.trim().isEmpty
                          ? 'Enter job description'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    // Cost Cost
                    TextFormField(
                      controller: _costController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Job Cost (\$)',
                        prefixIcon: Icon(Icons.attach_money_rounded),
                      ),
                      validator: (val) => val == null || val.trim().isEmpty
                          ? 'Enter maintenance cost'
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
                      title: const Text('Maintenance Date'),
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
                      text: isEditMode ? 'Update Log' : 'Save Maintenance',
                      onPressed: _submit,
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
