import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../vehicles/presentation/vehicle_providers.dart';
import '../domain/compliance_entity.dart';
import 'fleet_ops_providers.dart';

class ComplianceFormScreen extends ConsumerStatefulWidget {
  final String? complianceId;

  const ComplianceFormScreen({super.key, this.complianceId});

  @override
  ConsumerState<ComplianceFormScreen> createState() =>
      _ComplianceFormScreenState();
}

class _ComplianceFormScreenState extends ConsumerState<ComplianceFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _numberController;

  String? _selectedVehicleId;
  String? _selectedVehiclePlate;
  String _docType = 'insurance';
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 365));

  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _numberController = TextEditingController();
  }

  @override
  void dispose() {
    _numberController.dispose();
    super.dispose();
  }

  void _initializeValues(List<ComplianceEntity> docs) {
    if (_initialized) return;
    if (widget.complianceId != null) {
      final doc = docs.firstWhere((d) => d.id == widget.complianceId);
      _numberController.text = doc.documentNumber;
      _selectedVehicleId = doc.vehicleId;
      _selectedVehiclePlate = doc.vehicleLicensePlate;
      _docType = doc.documentType;
      _selectedDate = doc.expiryDate;
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

    final doc = ComplianceEntity(
      id: widget.complianceId ?? '',
      companyId: '',
      vehicleId: _selectedVehicleId!,
      vehicleLicensePlate: _selectedVehiclePlate!,
      documentType: _docType,
      documentNumber: _numberController.text.trim(),
      expiryDate: _selectedDate,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final success = await ref
        .read(complianceFormControllerProvider.notifier)
        .saveComplianceDocument(doc);

    if (success && mounted) {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formState = ref.watch(complianceFormControllerProvider);
    final docs = ref.watch(complianceDocumentsStreamProvider).valueOrNull ?? [];
    final vehicles = ref.watch(vehiclesStreamProvider).valueOrNull ?? [];

    if (widget.complianceId != null && docs.isNotEmpty) {
      _initializeValues(docs);
    }

    final isEditMode = widget.complianceId != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditMode
            ? 'Edit Compliance Document'
            : 'Add Compliance Document'),
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
                    // Document Type Selector
                    DropdownButtonFormField<String>(
                      value: _docType,
                      decoration: const InputDecoration(
                        labelText: 'Document Type',
                        prefixIcon: Icon(Icons.description_outlined),
                      ),
                      items: ['insurance', 'puc', 'fitness', 'permit', 'other']
                          .map((s) => DropdownMenuItem(
                              value: s, child: Text(s.toUpperCase())))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _docType = val;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    // Document Number
                    TextFormField(
                      controller: _numberController,
                      decoration: const InputDecoration(
                        labelText: 'Certificate / Document Number',
                        prefixIcon: Icon(Icons.badge_outlined),
                      ),
                      validator: (val) => val == null || val.trim().isEmpty
                          ? 'Enter document certificate number'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    // Date picker for expiry
                    ListTile(
                      leading: const Icon(Icons.calendar_today_rounded),
                      title: const Text('Expiry Date'),
                      subtitle:
                          Text(DateFormat('dd MMM yyyy').format(_selectedDate)),
                      trailing:
                          const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _selectedDate,
                          firstDate: DateTime.now()
                              .subtract(const Duration(days: 365)),
                          lastDate:
                              DateTime.now().add(const Duration(days: 5 * 365)),
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
                      text: isEditMode
                          ? 'Update Certificate'
                          : 'Save Certificate',
                      onPressed: _submit,
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
