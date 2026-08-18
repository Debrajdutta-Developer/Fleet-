import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../trips/presentation/trip_providers.dart';
import '../../vehicles/presentation/vehicle_providers.dart';
import '../../vendors/presentation/vendor_providers.dart';
import '../domain/finance_transaction_entity.dart';
import 'finance_providers.dart';

class FinanceFormScreen extends ConsumerStatefulWidget {
  final String? transactionId;

  const FinanceFormScreen({super.key, this.transactionId});

  @override
  ConsumerState<FinanceFormScreen> createState() => _FinanceFormScreenState();
}

class _FinanceFormScreenState extends ConsumerState<FinanceFormScreen> {
  final _formKey = GlobalKey<FormState>();

  // Text controllers
  final _amountController = TextEditingController();
  final _referenceController = TextEditingController();
  final _notesController = TextEditingController();

  // Selected values
  String _selectedType = 'expense'; // income or expense
  String _selectedCategory = 'miscellaneous';
  String _selectedPaymentMode = 'cash'; // cash, bank, upi
  String? _selectedTripId;
  String? _selectedTripNumber;
  String? _selectedVehicleId;
  String? _selectedVehiclePlate;
  String? _selectedVendorId;
  String? _selectedVendorName;
  DateTime _selectedDate = DateTime.now();

  // Available categories based on transaction type
  final List<Map<String, String>> _expenseCategories = [
    {'value': 'driver_salary', 'label': 'Driver Salary'},
    {'value': 'advance_salary', 'label': 'Advance Salary'},
    {'value': 'diesel', 'label': 'Diesel Expense'},
    {'value': 'toll', 'label': 'Toll Expense'},
    {'value': 'repair', 'label': 'Repair Expense'},
    {'value': 'tyre', 'label': 'Tyre Expense'},
    {'value': 'insurance', 'label': 'Insurance Expense'},
    {'value': 'miscellaneous', 'label': 'Miscellaneous Expense'},
  ];

  final List<Map<String, String>> _incomeCategories = [
    {'value': 'income', 'label': 'Freight Income'},
    {'value': 'miscellaneous', 'label': 'Other Miscellaneous Income'},
  ];

  final List<String> _paymentModes = ['cash', 'bank', 'upi'];

  @override
  void initState() {
    super.initState();
    _loadInitialValues();
  }

  void _loadInitialValues() {
    if (widget.transactionId != null) {
      final txsAsync = ref.read(financeTransactionsStreamProvider);
      final txs = txsAsync.valueOrNull ?? [];
      try {
        final tx = txs.firstWhere((t) => t.id == widget.transactionId);
        _selectedType = tx.type;
        _selectedCategory = tx.category;
        _amountController.text = tx.amount.toString();
        _selectedPaymentMode = tx.paymentMode;
        _referenceController.text = tx.referenceNumber ?? '';
        _selectedTripId = tx.tripId;
        _selectedTripNumber = tx.tripNumber;
        _selectedVehicleId = tx.vehicleId;
        _selectedVehiclePlate = tx.vehicleLicensePlate;
        _selectedVendorId = tx.vendorId;
        _selectedVendorName = tx.vendorName;
        _selectedDate = tx.transactionDate;
        _notesController.text = tx.notes ?? '';
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _referenceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.tryParse(_amountController.text.trim()) ?? 0.0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Validation Error: Amount must be greater than zero.'),
        ),
      );
      return;
    }

    final tx = FinanceTransactionEntity(
      id: widget.transactionId ?? '',
      companyId: '', // Set by controller
      type: _selectedType,
      category: _selectedCategory,
      amount: amount,
      paymentMode: _selectedPaymentMode,
      referenceNumber: _referenceController.text.trim().isEmpty
          ? null
          : _referenceController.text.trim(),
      tripId: _selectedTripId,
      tripNumber: _selectedTripNumber,
      vehicleId: _selectedVehicleId,
      vehicleLicensePlate: _selectedVehiclePlate,
      vendorId: _selectedVendorId,
      vendorName: _selectedVendorName,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      transactionDate: _selectedDate,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final success = await ref
        .read(financeFormControllerProvider.notifier)
        .saveTransaction(tx);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.transactionId == null
                ? 'Transaction recorded successfully.'
                : 'Transaction updated successfully.',
          ),
        ),
      );
      context.pop();
    } else if (mounted) {
      final state = ref.read(financeFormControllerProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text(
            state.errorMessage ?? 'An error occurred during verification.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final formState = ref.watch(financeFormControllerProvider);
    final tripsAsync = ref.watch(tripsStreamProvider);
    final vehiclesAsync = ref.watch(vehiclesStreamProvider);
    final vendorsAsync = ref.watch(vendorsStreamProvider);

    final activeCategories =
        _selectedType == 'income' ? _incomeCategories : _expenseCategories;

    // Reset selected category if it is not valid for current transaction type selection
    if (!activeCategories.any((c) => c['value'] == _selectedCategory)) {
      _selectedCategory = activeCategories.first['value']!;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.transactionId == null
              ? 'Record Transaction'
              : 'Edit Financial Record',
        ),
      ),
      body: formState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Center(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 800),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Record operational cashflows, allocate fuel expenses, toll charges, repairs, or freight revenues.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Main configuration card
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.payments_outlined,
                                      color: colorScheme.primary,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Transaction Metadata',
                                      style:
                                          theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const Divider(height: 24),

                                // Income / Expense toggle
                                Row(
                                  children: [
                                    Expanded(
                                      child: SegmentedButton<String>(
                                        segments: const [
                                          ButtonSegment<String>(
                                            value: 'expense',
                                            label: Text('EXPENSE'),
                                            icon: Icon(
                                              Icons.trending_down_rounded,
                                              color: Colors.red,
                                            ),
                                          ),
                                          ButtonSegment<String>(
                                            value: 'income',
                                            label: Text('INCOME'),
                                            icon: Icon(
                                              Icons.trending_up_rounded,
                                              color: Colors.green,
                                            ),
                                          ),
                                        ],
                                        selected: {_selectedType},
                                        onSelectionChanged: (set) {
                                          setState(() {
                                            _selectedType = set.first;
                                          });
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),

                                // Category Dropdown
                                DropdownButtonFormField<String>(
                                  value: _selectedCategory,
                                  items: activeCategories.map((c) {
                                    return DropdownMenuItem<String>(
                                      value: c['value'],
                                      child: Text(c['label']!),
                                    );
                                  }).toList(),
                                  onChanged: (val) {
                                    if (val != null) {
                                      setState(() => _selectedCategory = val);
                                    }
                                  },
                                  decoration: const InputDecoration(
                                    labelText: 'Transaction Category',
                                    prefixIcon: Icon(Icons.category_outlined),
                                  ),
                                ),
                                const SizedBox(height: 20),

                                // Amount Field
                                CustomTextField(
                                  controller: _amountController,
                                  hintText: '0.00',
                                  labelText: 'Transaction Amount (\$)',
                                  prefixIcon: Icons.attach_money_rounded,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                                  validator: (val) {
                                    if (val == null || val.trim().isEmpty) {
                                      return 'Amount is a mandatory field.';
                                    }
                                    final numVal = double.tryParse(val.trim());
                                    if (numVal == null || numVal <= 0) {
                                      return 'Please enter a valid amount > 0.';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Payment & Association details card
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.account_balance_outlined,
                                      color: colorScheme.primary,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Settlement & Allocation',
                                      style:
                                          theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const Divider(height: 24),

                                // Payment Mode & Date Row
                                Row(
                                  children: [
                                    Expanded(
                                      child: DropdownButtonFormField<String>(
                                        value: _selectedPaymentMode,
                                        items: _paymentModes.map((m) {
                                          return DropdownMenuItem<String>(
                                            value: m,
                                            child: Text(m.toUpperCase()),
                                          );
                                        }).toList(),
                                        onChanged: (val) {
                                          if (val != null) {
                                            setState(
                                              () => _selectedPaymentMode = val,
                                            );
                                          }
                                        },
                                        decoration: const InputDecoration(
                                          labelText: 'Payment Mode',
                                          prefixIcon: Icon(
                                            Icons
                                                .account_balance_wallet_outlined,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: InkWell(
                                        onTap: _pickDate,
                                        child: InputDecorator(
                                          decoration: const InputDecoration(
                                            labelText: 'Transaction Date',
                                            prefixIcon: Icon(
                                              Icons.calendar_month_outlined,
                                            ),
                                          ),
                                          child: Text(
                                            DateFormat(
                                              'dd MMM yyyy',
                                            ).format(_selectedDate),
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),

                                // Reference Number
                                CustomTextField(
                                  controller: _referenceController,
                                  hintText:
                                      'Txn reference, Check #, UPI Transaction ID',
                                  labelText: 'Reference Number (Optional)',
                                  prefixIcon: Icons.receipt_long_outlined,
                                ),
                                const SizedBox(height: 16),

                                // Trip Linkage (Optional)
                                tripsAsync.when(
                                  loading: () =>
                                      const LinearProgressIndicator(),
                                  error: (err, st) =>
                                      Text('Error loading trips: $err'),
                                  data: (trips) {
                                    final activeTrips = trips
                                        .where((t) => t.deletedAt == null)
                                        .toList();
                                    return DropdownButtonFormField<String?>(
                                      value: _selectedTripId != null &&
                                              activeTrips.any(
                                                (t) => t.id == _selectedTripId,
                                              )
                                          ? _selectedTripId
                                          : null,
                                      hint: const Text('Do not link to a trip'),
                                      items: [
                                        const DropdownMenuItem<String?>(
                                          value: null,
                                          child: Text('Not Associated to Trip'),
                                        ),
                                        ...activeTrips.map(
                                          (t) => DropdownMenuItem<String?>(
                                            value: t.id,
                                            child: Text(
                                              'Trip to ${t.deliveryLocation} (${t.customerName})',
                                            ),
                                          ),
                                        ),
                                      ],
                                      onChanged: (val) {
                                        setState(() {
                                          _selectedTripId = val;
                                          if (val != null) {
                                            _selectedTripNumber = activeTrips
                                                .firstWhere((t) => t.id == val)
                                                .id
                                                .substring(0, 8)
                                                .toUpperCase();
                                          } else {
                                            _selectedTripNumber = null;
                                          }
                                        });
                                      },
                                      decoration: const InputDecoration(
                                        labelText:
                                            'Associated Trip Allocation (Optional)',
                                        prefixIcon: Icon(Icons.route_outlined),
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(height: 16),

                                // Vehicle Linkage (Optional)
                                vehiclesAsync.when(
                                  loading: () =>
                                      const LinearProgressIndicator(),
                                  error: (err, st) =>
                                      Text('Error loading vehicles: $err'),
                                  data: (vehicles) {
                                    final activeVehicles = vehicles
                                        .where((v) => v.deletedAt == null)
                                        .toList();
                                    return DropdownButtonFormField<String?>(
                                      value: _selectedVehicleId != null &&
                                              activeVehicles.any(
                                                (v) =>
                                                    v.id == _selectedVehicleId,
                                              )
                                          ? _selectedVehicleId
                                          : null,
                                      hint: const Text(
                                        'Do not link to a vehicle',
                                      ),
                                      items: [
                                        const DropdownMenuItem<String?>(
                                          value: null,
                                          child: Text(
                                            'Not Associated to Vehicle',
                                          ),
                                        ),
                                        ...activeVehicles.map(
                                          (v) => DropdownMenuItem<String?>(
                                            value: v.id,
                                            child: Text(
                                              '${v.licensePlate} (${v.make} ${v.model})',
                                            ),
                                          ),
                                        ),
                                      ],
                                      onChanged: (val) {
                                        setState(() {
                                          _selectedVehicleId = val;
                                          if (val != null) {
                                            _selectedVehiclePlate =
                                                activeVehicles
                                                    .firstWhere(
                                                      (v) => v.id == val,
                                                    )
                                                    .licensePlate;
                                          } else {
                                            _selectedVehiclePlate = null;
                                          }
                                        });
                                      },
                                      decoration: const InputDecoration(
                                        labelText:
                                            'Associated Vehicle Allocation (Optional)',
                                        prefixIcon: Icon(
                                          Icons.local_shipping_outlined,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(height: 16),

                                if (_selectedType == 'expense') ...[
                                  vendorsAsync.when(
                                    loading: () => const Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                    error: (err, _) =>
                                        Text('Error loading vendors: $err'),
                                    data: (vendors) {
                                      return DropdownButtonFormField<String?>(
                                        value: _selectedVendorId != null &&
                                                vendors.any(
                                                  (v) =>
                                                      v.id == _selectedVendorId,
                                                )
                                            ? _selectedVendorId
                                            : null,
                                        hint: const Text(
                                          'Do not link to a vendor',
                                        ),
                                        items: [
                                          const DropdownMenuItem<String?>(
                                            value: null,
                                            child: Text(
                                              'Not Associated to Vendor',
                                            ),
                                          ),
                                          ...vendors.map(
                                            (v) => DropdownMenuItem<String?>(
                                              value: v.id,
                                              child: Text(
                                                '${v.name} (${v.serviceType.toUpperCase()})',
                                              ),
                                            ),
                                          ),
                                        ],
                                        onChanged: (val) {
                                          setState(() {
                                            _selectedVendorId = val;
                                            if (val != null) {
                                              _selectedVendorName = vendors
                                                  .firstWhere(
                                                    (v) => v.id == val,
                                                  )
                                                  .name;
                                            } else {
                                              _selectedVendorName = null;
                                            }
                                          });
                                        },
                                        decoration: const InputDecoration(
                                          labelText:
                                              'Associated Vendor Allocation (Optional)',
                                          prefixIcon: Icon(
                                            Icons.business_outlined,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                ],

                                // Notes
                                CustomTextField(
                                  controller: _notesController,
                                  hintText:
                                      'Enter additional details regarding this finance ledger ledger record...',
                                  labelText: 'Audit & Description Notes',
                                  prefixIcon: Icons.description_outlined,
                                  maxLines: 2,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Submit buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () => context.pop(),
                              child: const Text('CANCEL'),
                            ),
                            const SizedBox(width: 16),
                            CustomButton(
                              text: widget.transactionId == null
                                  ? 'RECORD LEDGER'
                                  : 'SAVE CHANGES',
                              icon: Icons.check_circle_outline_rounded,
                              width: 200,
                              onPressed: _submitForm,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}
