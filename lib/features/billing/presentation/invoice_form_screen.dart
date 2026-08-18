import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../customers/presentation/customer_providers.dart';
import '../../customers/domain/invoice_entity.dart';
import '../../trips/presentation/trip_providers.dart';
import '../../dispatch/presentation/dispatch_providers.dart';
import 'billing_providers.dart';

class InvoiceFormScreen extends ConsumerStatefulWidget {
  final String? invoiceId;

  const InvoiceFormScreen({super.key, this.invoiceId});

  @override
  ConsumerState<InvoiceFormScreen> createState() => _InvoiceFormScreenState();
}

class _InvoiceFormScreenState extends ConsumerState<InvoiceFormScreen> {
  final _formKey = GlobalKey<FormState>();

  // Form Fields
  late String _invoiceNumber;
  String? _selectedCustomerId;
  String? _selectedCustomerName;
  String? _selectedTripId;
  String? _selectedDispatchId;

  double _freightCharge = 0.0;
  double _fuelCharge = 0.0;
  double _tollCharge = 0.0;
  double _extraCharges = 0.0;
  double _discount = 0.0;
  double _gstVat = 0.0;

  DateTime _issueDate = DateTime.now();
  DateTime _dueDate = DateTime.now().add(const Duration(days: 30));
  String _status = 'draft';
  String _paymentStatus = 'pending';
  final _notesController = TextEditingController();

  InvoiceEntity? _existingInvoice;
  bool _initialized = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  double get _grandTotal =>
      _freightCharge +
      _fuelCharge +
      _tollCharge +
      _extraCharges -
      _discount +
      _gstVat;

  @override
  Widget build(BuildContext context) {
    final customersAsync = ref.watch(customersStreamProvider);
    final tripsAsync = ref.watch(tripsStreamProvider);
    final dispatchesAsync = ref.watch(dispatchesStreamProvider);
    final invoicesAsync = ref.watch(billingInvoicesProvider);

    final formState = ref.watch(billingInvoiceFormControllerProvider);

    ref.listen<InvoiceFormState>(billingInvoiceFormControllerProvider,
        (prev, next) {
      if (next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
      if (next.isCompleted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invoice saved successfully.')),
        );
        ref.invalidate(billingInvoicesProvider);
        context.pop();
      }
    });

    // Initialize values if editing
    if (widget.invoiceId != null && !_initialized && invoicesAsync.hasValue) {
      final invoices = invoicesAsync.value ?? [];
      final idx = invoices.indexWhere((inv) => inv.id == widget.invoiceId);
      if (idx != -1) {
        _existingInvoice = invoices[idx];
        _invoiceNumber = _existingInvoice!.invoiceNumber;
        _selectedCustomerId = _existingInvoice!.customerId;
        _selectedCustomerName = _existingInvoice!.customerName;
        _selectedTripId = _existingInvoice!.tripId;
        _selectedDispatchId = _existingInvoice!.dispatchId;
        _freightCharge = _existingInvoice!.freightCharge;
        _fuelCharge = _existingInvoice!.fuelCharge;
        _tollCharge = _existingInvoice!.tollCharge;
        _extraCharges = _existingInvoice!.extraCharges;
        _discount = _existingInvoice!.discount;
        _gstVat = _existingInvoice!.gstVat;
        _issueDate = _existingInvoice!.issueDate;
        _dueDate = _existingInvoice!.dueDate;
        _status = _existingInvoice!.status;
        _paymentStatus = _existingInvoice!.paymentStatus;
        _notesController.text = _existingInvoice!.notes ?? '';
        _initialized = true;
      }
    } else if (!_initialized) {
      _invoiceNumber =
          'INV-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';
      _initialized = true;
    }

    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isDesktop = screenWidth > 992;

    return Scaffold(
      appBar: AppBar(
        title:
            Text(widget.invoiceId == null ? 'Create Invoice' : 'Edit Invoice'),
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
                    Text(
                      'Invoice Details',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 24),
                    // Form Row 1: Invoice Number & Date
                    _buildFormRow(
                      isDesktop,
                      [
                        TextFormField(
                          initialValue: _invoiceNumber,
                          decoration: const InputDecoration(
                            labelText: 'Invoice Number',
                            prefixIcon: Icon(Icons.tag),
                          ),
                          validator: (val) => val == null || val.trim().isEmpty
                              ? 'Required'
                              : null,
                          onChanged: (val) => _invoiceNumber = val.trim(),
                        ),
                        _buildDatePicker(
                          context,
                          label: 'Issue Date',
                          selectedDate: _issueDate,
                          onDateSelected: (date) {
                            setState(() {
                              _issueDate = date;
                              if (_dueDate.isBefore(_issueDate)) {
                                _dueDate =
                                    _issueDate.add(const Duration(days: 30));
                              }
                            });
                          },
                        ),
                        _buildDatePicker(
                          context,
                          label: 'Due Date',
                          selectedDate: _dueDate,
                          onDateSelected: (date) {
                            if (date.isBefore(_issueDate)) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      'Due date cannot be before issue date.'),
                                ),
                              );
                              return;
                            }
                            setState(() => _dueDate = date);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Form Row 2: Customer, Trip, Dispatch Selection
                    _buildFormRow(
                      isDesktop,
                      [
                        customersAsync.when(
                          data: (customers) => DropdownButtonFormField<String>(
                            value: _selectedCustomerId,
                            decoration: const InputDecoration(
                              labelText: 'Customer Account',
                              prefixIcon: Icon(Icons.people_outline_rounded),
                            ),
                            items: customers.map((c) {
                              return DropdownMenuItem(
                                value: c.id,
                                child: Text(c.name),
                              );
                            }).toList(),
                            validator: (val) => val == null ? 'Required' : null,
                            onChanged: (val) {
                              setState(() {
                                _selectedCustomerId = val;
                                _selectedCustomerName = customers
                                    .firstWhere((c) => c.id == val)
                                    .name;
                              });
                            },
                          ),
                          loading: () =>
                              const Center(child: LinearProgressIndicator()),
                          error: (e, _) => Text('Error loading customers: $e'),
                        ),
                        tripsAsync.when(
                          data: (trips) => DropdownButtonFormField<String>(
                            value: _selectedTripId,
                            decoration: const InputDecoration(
                              labelText: 'Trip Reference (Optional)',
                              prefixIcon: Icon(Icons.route_outlined),
                            ),
                            items: [
                              const DropdownMenuItem(
                                value: '',
                                child: Text('No Trip Reference'),
                              ),
                              ...trips.where((t) => t.id.isNotEmpty).map((t) {
                                return DropdownMenuItem(
                                  value: t.id,
                                  child: Text(
                                      'Trip #${t.id.substring(0, 8).toUpperCase()} - ${t.customerName}'),
                                );
                              }),
                            ],
                            onChanged: (val) {
                              setState(() {
                                _selectedTripId = val == '' ? null : val;
                              });
                            },
                          ),
                          loading: () =>
                              const Center(child: LinearProgressIndicator()),
                          error: (e, _) => Text('Error loading trips: $e'),
                        ),
                        dispatchesAsync.when(
                          data: (dispatches) => DropdownButtonFormField<String>(
                            value: _selectedDispatchId,
                            decoration: const InputDecoration(
                              labelText: 'Dispatch Reference (Optional)',
                              prefixIcon: Icon(Icons.local_shipping_outlined),
                            ),
                            items: [
                              const DropdownMenuItem(
                                value: '',
                                child: Text('No Dispatch Reference'),
                              ),
                              ...dispatches
                                  .where((d) => d.id.isNotEmpty)
                                  .map((d) {
                                return DropdownMenuItem(
                                  value: d.id,
                                  child: Text(
                                      'Dispatch #${d.id.substring(0, 8).toUpperCase()} - ${d.routeId}'),
                                );
                              }),
                            ],
                            onChanged: (val) {
                              setState(() {
                                _selectedDispatchId = val == '' ? null : val;
                              });
                            },
                          ),
                          loading: () =>
                              const Center(child: LinearProgressIndicator()),
                          error: (e, _) => Text('Error loading dispatches: $e'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'Financial Calculations',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 24),
                    // Form Row 3: Charges
                    _buildFormRow(
                      isDesktop,
                      [
                        TextFormField(
                          initialValue: _freightCharge.toStringAsFixed(2),
                          decoration: const InputDecoration(
                            labelText: 'Freight Charge (\$)',
                            prefixIcon: Icon(Icons.attach_money_rounded),
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          validator: (val) => _validateDouble(val),
                          onChanged: (val) {
                            setState(() =>
                                _freightCharge = double.tryParse(val) ?? 0.0);
                          },
                        ),
                        TextFormField(
                          initialValue: _fuelCharge.toStringAsFixed(2),
                          decoration: const InputDecoration(
                            labelText: 'Fuel Charge/Surcharge (\$)',
                            prefixIcon: Icon(Icons.local_gas_station_rounded),
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          validator: (val) => _validateDouble(val),
                          onChanged: (val) {
                            setState(() =>
                                _fuelCharge = double.tryParse(val) ?? 0.0);
                          },
                        ),
                        TextFormField(
                          initialValue: _tollCharge.toStringAsFixed(2),
                          decoration: const InputDecoration(
                            labelText: 'Toll Expense (\$)',
                            prefixIcon: Icon(Icons.toll_rounded),
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          validator: (val) => _validateDouble(val),
                          onChanged: (val) {
                            setState(() =>
                                _tollCharge = double.tryParse(val) ?? 0.0);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Form Row 4: Extras, Discount, GST
                    _buildFormRow(
                      isDesktop,
                      [
                        TextFormField(
                          initialValue: _extraCharges.toStringAsFixed(2),
                          decoration: const InputDecoration(
                            labelText: 'Demurrage / Extras (\$)',
                            prefixIcon: Icon(Icons.add_circle_outline_rounded),
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          validator: (val) => _validateDouble(val),
                          onChanged: (val) {
                            setState(() =>
                                _extraCharges = double.tryParse(val) ?? 0.0);
                          },
                        ),
                        TextFormField(
                          initialValue: _discount.toStringAsFixed(2),
                          decoration: const InputDecoration(
                            labelText: 'Contract Discount (\$)',
                            prefixIcon:
                                Icon(Icons.remove_circle_outline_rounded),
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          validator: (val) => _validateDouble(val),
                          onChanged: (val) {
                            setState(
                                () => _discount = double.tryParse(val) ?? 0.0);
                          },
                        ),
                        TextFormField(
                          initialValue: _gstVat.toStringAsFixed(2),
                          decoration: const InputDecoration(
                            labelText: 'GST / VAT Tax (\$)',
                            prefixIcon: Icon(Icons.percent_rounded),
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          validator: (val) => _validateDouble(val),
                          onChanged: (val) {
                            setState(
                                () => _gstVat = double.tryParse(val) ?? 0.0);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    // Calculation breakdown Panel
                    Card(
                      color: Theme.of(context)
                          .colorScheme
                          .primaryContainer
                          .withOpacity(0.2),
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'GRAND TOTAL DUE',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '\$${_grandTotal.toStringAsFixed(2)}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineLarge
                                      ?.copyWith(
                                        fontWeight: FontWeight.w900,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                      ),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'Status: ${_status.toUpperCase()}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Payment: ${_paymentStatus.toUpperCase()}',
                                  style: TextStyle(
                                    color: _paymentStatus == 'completed'
                                        ? Colors.green
                                        : Colors.orange,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            )
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Notes field
                    TextFormField(
                      controller: _notesController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Payment Notes / Terms & Conditions',
                        prefixIcon: Icon(Icons.notes),
                      ),
                    ),
                    const SizedBox(height: 40),
                    // Action Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => context.pop(),
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton(
                          onPressed: _saveForm,
                          child: const Text('Save Invoice Draft'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildFormRow(bool isDesktop, List<Widget> children) {
    if (isDesktop) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children
            .map((c) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 16.0),
                    child: c,
                  ),
                ))
            .toList(),
      );
    } else {
      return Column(
        children: children
            .map((c) => Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: c,
                ))
            .toList(),
      );
    }
  }

  Widget _buildDatePicker(
    BuildContext context, {
    required String label,
    required DateTime selectedDate,
    required ValueChanged<DateTime> onDateSelected,
  }) {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: selectedDate,
          firstDate: DateTime.now().subtract(const Duration(days: 365)),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (date != null) {
          onDateSelected(date);
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.calendar_today_rounded),
        ),
        child: Text(
          selectedDate.toLocal().toString().split(' ')[0],
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ),
    );
  }

  String? _validateDouble(String? val) {
    if (val == null || val.trim().isEmpty) return 'Required';
    final parsed = double.tryParse(val);
    if (parsed == null) return 'Invalid amount';
    if (parsed < 0) return 'Cannot be negative';
    return null;
  }

  void _saveForm() {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCustomerId == null || _selectedCustomerName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a customer.')),
      );
      return;
    }

    final invoice = InvoiceEntity(
      id: widget.invoiceId ?? '',
      tripId: _selectedTripId ?? '',
      dispatchId: _selectedDispatchId,
      customerId: _selectedCustomerId!,
      customerName: _selectedCustomerName!,
      invoiceNumber: _invoiceNumber,
      freightCharge: _freightCharge,
      fuelCharge: _fuelCharge,
      tollCharge: _tollCharge,
      extraCharges: _extraCharges,
      discount: _discount,
      gstVat: _gstVat,
      grandTotal: _grandTotal,
      amountPaid: _existingInvoice?.amountPaid ?? 0.0,
      outstandingAmount: _grandTotal - (_existingInvoice?.amountPaid ?? 0.0),
      issueDate: _issueDate,
      dueDate: _dueDate,
      status: _status,
      paymentStatus: _paymentStatus,
      notes: _notesController.text.trim(),
      createdAt: _existingInvoice?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    ref
        .read(billingInvoiceFormControllerProvider.notifier)
        .saveInvoice(invoice);
  }
}
