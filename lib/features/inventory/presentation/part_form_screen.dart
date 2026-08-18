import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/custom_button.dart';
import '../domain/part_entity.dart';
import 'inventory_providers.dart';

class PartFormScreen extends ConsumerStatefulWidget {
  final String? partId;

  const PartFormScreen({super.key, this.partId});

  @override
  ConsumerState<PartFormScreen> createState() => _PartFormScreenState();
}

class _PartFormScreenState extends ConsumerState<PartFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _partNumberController;
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _minStockThresholdController;
  late TextEditingController _unitCostController;

  String _category = 'engine';
  String? _selectedSupplierId;
  String? _selectedSupplierName;

  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _partNumberController = TextEditingController();
    _nameController = TextEditingController();
    _descriptionController = TextEditingController();
    _minStockThresholdController = TextEditingController();
    _unitCostController = TextEditingController();
  }

  @override
  void dispose() {
    _partNumberController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    _minStockThresholdController.dispose();
    _unitCostController.dispose();
    super.dispose();
  }

  void _initializeValues(List<PartEntity> parts) {
    if (_initialized) return;
    if (widget.partId != null) {
      final part = parts.firstWhere((p) => p.id == widget.partId);
      _partNumberController.text = part.partNumber;
      _nameController.text = part.name;
      _descriptionController.text = part.description;
      _minStockThresholdController.text = part.minStockThreshold.toString();
      _unitCostController.text = part.unitCost.toString();
      _category = part.category;
      _selectedSupplierId = part.supplierId;
      _selectedSupplierName = part.supplierName;
    }
    _initialized = true;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final part = PartEntity(
      id: widget.partId ?? '',
      companyId: '',
      partNumber: _partNumberController.text.trim(),
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      category: _category,
      quantity: widget.partId != null
          ? ref
                  .read(partsStreamProvider)
                  .valueOrNull
                  ?.firstWhere((p) => p.id == widget.partId)
                  .quantity ??
              0
          : 0,
      minStockThreshold: int.parse(_minStockThresholdController.text.trim()),
      unitCost: double.tryParse(_unitCostController.text.trim()) ?? 0.0,
      supplierId: _selectedSupplierId,
      supplierName: _selectedSupplierName,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final success =
        await ref.read(partFormControllerProvider.notifier).savePart(part);

    if (success && mounted) {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formState = ref.watch(partFormControllerProvider);
    final parts = ref.watch(partsStreamProvider).valueOrNull ?? [];
    final suppliers = ref.watch(suppliersStreamProvider).valueOrNull ?? [];

    if (widget.partId != null && parts.isNotEmpty) {
      _initializeValues(parts);
    }

    final isEditMode = widget.partId != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditMode ? 'Edit Spare Part' : 'Add Spare Part'),
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
                    // Part Number
                    TextFormField(
                      controller: _partNumberController,
                      decoration: const InputDecoration(
                        labelText: 'Part Number / SKU Code',
                        prefixIcon: Icon(Icons.qr_code_rounded),
                      ),
                      validator: (val) => val == null || val.trim().isEmpty
                          ? 'Enter part number'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    // Name
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Spare Part Name',
                        prefixIcon: Icon(Icons.settings_suggest_rounded),
                      ),
                      validator: (val) => val == null || val.trim().isEmpty
                          ? 'Enter part name'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    // Description
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        prefixIcon: Icon(Icons.description_outlined),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Category Selector
                    DropdownButtonFormField<String>(
                      value: _category,
                      decoration: const InputDecoration(
                        labelText: 'Part Category',
                        prefixIcon: Icon(Icons.category_rounded),
                      ),
                      items: [
                        'engine',
                        'brake',
                        'tyre',
                        'electrical',
                        'lubricant',
                        'other'
                      ]
                          .map((s) => DropdownMenuItem(
                              value: s, child: Text(s.toUpperCase())))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _category = val;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    // Supplier Selector
                    DropdownButtonFormField<String?>(
                      value: _selectedSupplierId,
                      decoration: const InputDecoration(
                        labelText: 'Linked Supplier (Optional)',
                        prefixIcon: Icon(Icons.business_rounded),
                      ),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('No Supplier Linked'),
                        ),
                        ...suppliers.map(
                          (s) => DropdownMenuItem<String?>(
                              value: s.id, child: Text(s.name)),
                        ),
                      ],
                      onChanged: (val) {
                        setState(() {
                          _selectedSupplierId = val;
                          _selectedSupplierName = val != null
                              ? suppliers.firstWhere((s) => s.id == val).name
                              : null;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    // Minimum Threshold Alert Level
                    TextFormField(
                      controller: _minStockThresholdController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Minimum Low-Stock Alert Threshold',
                        prefixIcon: Icon(Icons.notifications_active_rounded),
                      ),
                      validator: (val) => val == null || val.trim().isEmpty
                          ? 'Enter low stock alert level'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    // Unit Cost (Only for display / default value on purchase)
                    TextFormField(
                      controller: _unitCostController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Average Unit Purchase Cost (\$)',
                        prefixIcon: Icon(Icons.attach_money_rounded),
                      ),
                      validator: (val) => val == null || val.trim().isEmpty
                          ? 'Enter part cost price'
                          : null,
                    ),
                    const SizedBox(height: 32),
                    CustomButton(
                      text: isEditMode ? 'Update Part' : 'Save Part',
                      onPressed: _submit,
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
