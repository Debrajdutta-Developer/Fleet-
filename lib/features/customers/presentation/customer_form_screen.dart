import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/custom_button.dart';
import '../domain/customer_entity.dart';
import 'customer_providers.dart';

class CustomerFormScreen extends ConsumerStatefulWidget {
  final String? customerId;

  const CustomerFormScreen({super.key, this.customerId});

  @override
  ConsumerState<CustomerFormScreen> createState() => _CustomerFormScreenState();
}

class _CustomerFormScreenState extends ConsumerState<CustomerFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _contactController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _addressController;
  late TextEditingController _creditLimitController;

  List<ContactPerson> _contactsList = [];
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _contactController = TextEditingController();
    _phoneController = TextEditingController();
    _emailController = TextEditingController();
    _addressController = TextEditingController();
    _creditLimitController = TextEditingController(text: '0.0');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _contactController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _creditLimitController.dispose();
    super.dispose();
  }

  void _initializeValues(List<CustomerEntity> customers) {
    if (_initialized) return;
    if (widget.customerId != null) {
      final customer = customers.firstWhere((c) => c.id == widget.customerId);
      _nameController.text = customer.name;
      _contactController.text = customer.contactName;
      _phoneController.text = customer.phone;
      _emailController.text = customer.email;
      _addressController.text = customer.address;
      _creditLimitController.text = customer.creditLimit.toString();
      _contactsList = List.from(customer.contacts);
    }
    _initialized = true;
  }

  void _addContact() {
    setState(() {
      _contactsList.add(const ContactPerson(
        name: '',
        email: '',
        phone: '',
        role: 'Manager',
      ));
    });
  }

  void _removeContact(int index) {
    setState(() {
      _contactsList.removeAt(index);
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final customer = CustomerEntity(
      id: widget.customerId ?? '',
      name: _nameController.text.trim(),
      contactName: _contactController.text.trim(),
      phone: _phoneController.text.trim(),
      email: _emailController.text.trim(),
      address: _addressController.text.trim(),
      creditLimit: double.tryParse(_creditLimitController.text.trim()) ?? 0.0,
      contacts: _contactsList,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final success = await ref
        .read(customerFormControllerProvider.notifier)
        .saveCustomer(customer);

    if (success && mounted) {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formState = ref.watch(customerFormControllerProvider);
    final customers = ref.watch(customersStreamProvider).valueOrNull ?? [];

    if (widget.customerId != null && customers.isNotEmpty) {
      _initializeValues(customers);
    }

    final isEditMode = widget.customerId != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditMode ? 'Edit Customer' : 'Add Customer'),
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
                        labelText: 'Customer Corporate Name',
                        prefixIcon: Icon(Icons.business_rounded),
                      ),
                      validator: (val) => val == null || val.trim().isEmpty
                          ? 'Enter customer corporate name'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _contactController,
                            decoration: const InputDecoration(
                              labelText: 'Primary Contact Person',
                              prefixIcon: Icon(Icons.person_rounded),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _creditLimitController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Credit Limit (\$)',
                              prefixIcon: Icon(Icons.credit_card_rounded),
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty)
                                return 'Enter credit limit';
                              if (double.tryParse(val) == null)
                                return 'Enter valid number';
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
                          child: TextFormField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(
                              labelText: 'Phone Number',
                              prefixIcon: Icon(Icons.phone_rounded),
                            ),
                            validator: (val) =>
                                val == null || val.trim().isEmpty
                                    ? 'Enter phone number'
                                    : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              labelText: 'Email Address',
                              prefixIcon: Icon(Icons.email_outlined),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _addressController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Office Address',
                        prefixIcon: Icon(Icons.location_on_outlined),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Additional Contact Persons',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: _addContact,
                          icon: const Icon(Icons.add_circle_outline_rounded),
                          label: const Text('Add Contact'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_contactsList.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: Text('No additional contacts added yet.',
                            style: TextStyle(fontStyle: FontStyle.italic)),
                      )
                    else
                      ...List.generate(_contactsList.length, (index) {
                        final contact = _contactsList[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Contact #${index + 1}',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold)),
                                    IconButton(
                                      icon: const Icon(
                                          Icons.remove_circle_outline_rounded,
                                          color: Colors.red),
                                      onPressed: () => _removeContact(index),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        initialValue: contact.name,
                                        decoration: const InputDecoration(
                                            labelText: 'Name'),
                                        onChanged: (val) {
                                          _contactsList[index] = ContactPerson(
                                            name: val,
                                            email: _contactsList[index].email,
                                            phone: _contactsList[index].phone,
                                            role: _contactsList[index].role,
                                          );
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: TextFormField(
                                        initialValue: contact.role,
                                        decoration: const InputDecoration(
                                            labelText: 'Role/Designation'),
                                        onChanged: (val) {
                                          _contactsList[index] = ContactPerson(
                                            name: _contactsList[index].name,
                                            email: _contactsList[index].email,
                                            phone: _contactsList[index].phone,
                                            role: val,
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        initialValue: contact.phone,
                                        decoration: const InputDecoration(
                                            labelText: 'Phone'),
                                        onChanged: (val) {
                                          _contactsList[index] = ContactPerson(
                                            name: _contactsList[index].name,
                                            email: _contactsList[index].email,
                                            phone: val,
                                            role: _contactsList[index].role,
                                          );
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: TextFormField(
                                        initialValue: contact.email,
                                        decoration: const InputDecoration(
                                            labelText: 'Email'),
                                        onChanged: (val) {
                                          _contactsList[index] = ContactPerson(
                                            name: _contactsList[index].name,
                                            email: val,
                                            phone: _contactsList[index].phone,
                                            role: _contactsList[index].role,
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    const SizedBox(height: 32),
                    CustomButton(
                      text: isEditMode ? 'Update Customer' : 'Add Customer',
                      onPressed: _submit,
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
