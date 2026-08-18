import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/custom_button.dart';
import '../domain/vendor_entity.dart';
import 'vendor_providers.dart';

class VendorFormScreen extends ConsumerStatefulWidget {
  final String? vendorId;

  const VendorFormScreen({super.key, this.vendorId});

  @override
  ConsumerState<VendorFormScreen> createState() => _VendorFormScreenState();
}

class _VendorFormScreenState extends ConsumerState<VendorFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _addressController;
  late String _serviceType;

  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _phoneController = TextEditingController();
    _emailController = TextEditingController();
    _addressController = TextEditingController();
    _serviceType = 'miscellaneous';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _initializeValues(List<VendorEntity> vendors) {
    if (_initialized) return;
    if (widget.vendorId != null) {
      final vendor = vendors.firstWhere((v) => v.id == widget.vendorId);
      _nameController.text = vendor.name;
      _phoneController.text = vendor.phone;
      _emailController.text = vendor.email;
      _addressController.text = vendor.address;
      _serviceType = vendor.serviceType;
    }
    _initialized = true;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final vendor = VendorEntity(
      id: widget.vendorId ?? '',
      name: _nameController.text.trim(),
      serviceType: _serviceType,
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
      address: _addressController.text.trim(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final success = await ref
        .read(vendorFormControllerProvider.notifier)
        .saveVendor(vendor);

    if (success && mounted) {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formState = ref.watch(vendorFormControllerProvider);
    final vendors = ref.watch(vendorsStreamProvider).valueOrNull ?? [];

    if (widget.vendorId != null && vendors.isNotEmpty) {
      _initializeValues(vendors);
    }

    final isEditMode = widget.vendorId != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditMode ? 'Edit Vendor' : 'Add Vendor'),
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
                        labelText: 'Vendor Name',
                        prefixIcon: Icon(Icons.business_rounded),
                      ),
                      validator: (val) => val == null || val.trim().isEmpty
                          ? 'Enter vendor name'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _serviceType,
                      decoration: const InputDecoration(
                        labelText: 'Service/Goods Type',
                        prefixIcon: Icon(Icons.info_outline_rounded),
                      ),
                      items: [
                        'fuel',
                        'maintenance',
                        'parts',
                        'permit',
                        'miscellaneous'
                      ]
                          .map((s) => DropdownMenuItem(
                              value: s, child: Text(s.toUpperCase())))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _serviceType = val;
                          });
                        }
                      },
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
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email Address',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _addressController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Vendor Address',
                        prefixIcon: Icon(Icons.location_on_outlined),
                      ),
                    ),
                    const SizedBox(height: 32),
                    CustomButton(
                      text: isEditMode ? 'Update Vendor' : 'Add Vendor',
                      onPressed: _submit,
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
