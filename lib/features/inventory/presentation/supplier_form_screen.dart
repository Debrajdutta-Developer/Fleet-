import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/custom_button.dart';
import '../domain/supplier_entity.dart';
import 'inventory_providers.dart';

class SupplierFormScreen extends ConsumerStatefulWidget {
  final String? supplierId;

  const SupplierFormScreen({super.key, this.supplierId});

  @override
  ConsumerState<SupplierFormScreen> createState() => _SupplierFormScreenState();
}

class _SupplierFormScreenState extends ConsumerState<SupplierFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _contactPersonController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _addressController;

  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _contactPersonController = TextEditingController();
    _phoneController = TextEditingController();
    _emailController = TextEditingController();
    _addressController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _contactPersonController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _initializeValues(List<SupplierEntity> suppliers) {
    if (_initialized) return;
    if (widget.supplierId != null) {
      final supplier = suppliers.firstWhere((s) => s.id == widget.supplierId);
      _nameController.text = supplier.name;
      _contactPersonController.text = supplier.contactPerson;
      _phoneController.text = supplier.phone;
      _emailController.text = supplier.email;
      _addressController.text = supplier.address;
    }
    _initialized = true;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final supplier = SupplierEntity(
      id: widget.supplierId ?? '',
      companyId: '',
      name: _nameController.text.trim(),
      contactPerson: _contactPersonController.text.trim(),
      phone: _phoneController.text.trim(),
      email: _emailController.text.trim(),
      address: _addressController.text.trim(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final success = await ref
        .read(supplierFormControllerProvider.notifier)
        .saveSupplier(supplier);

    if (success && mounted) {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formState = ref.watch(supplierFormControllerProvider);
    final suppliers = ref.watch(suppliersStreamProvider).valueOrNull ?? [];

    if (widget.supplierId != null && suppliers.isNotEmpty) {
      _initializeValues(suppliers);
    }

    final isEditMode = widget.supplierId != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditMode ? 'Edit Supplier' : 'Add Supplier'),
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
                    // Supplier Name
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Supplier Company Name',
                        prefixIcon: Icon(Icons.business_rounded),
                      ),
                      validator: (val) => val == null || val.trim().isEmpty
                          ? 'Enter supplier name'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    // Contact Person
                    TextFormField(
                      controller: _contactPersonController,
                      decoration: const InputDecoration(
                        labelText: 'Contact Person Name',
                        prefixIcon: Icon(Icons.person_rounded),
                      ),
                      validator: (val) => val == null || val.trim().isEmpty
                          ? 'Enter contact person name'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    // Phone
                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number',
                        prefixIcon: Icon(Icons.phone_rounded),
                      ),
                      validator: (val) => val == null || val.trim().isEmpty
                          ? 'Enter phone number'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    // Email
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email Address',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      validator: (val) => val == null || val.trim().isEmpty
                          ? 'Enter email address'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    // Address
                    TextFormField(
                      controller: _addressController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Physical Address',
                        prefixIcon: Icon(Icons.location_on_outlined),
                      ),
                      validator: (val) => val == null || val.trim().isEmpty
                          ? 'Enter supplier address'
                          : null,
                    ),
                    const SizedBox(height: 32),
                    CustomButton(
                      text: isEditMode ? 'Update Supplier' : 'Save Supplier',
                      onPressed: _submit,
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
