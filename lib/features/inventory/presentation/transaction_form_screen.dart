import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/widgets/custom_button.dart';
import '../domain/inventory_transaction_entity.dart';
import 'inventory_providers.dart';

class TransactionFormScreen extends ConsumerStatefulWidget {
  final String? preSelectedPartId;

  const TransactionFormScreen({super.key, this.preSelectedPartId});

  @override
  ConsumerState<TransactionFormScreen> createState() =>
      _TransactionFormScreenState();
}

class _TransactionFormScreenState extends ConsumerState<TransactionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _qtyController;
  late TextEditingController _unitCostController;
  late TextEditingController _notesController;

  String? _selectedPartId;
  String? _selectedPartName;
  String _txType = 'stock_in';
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _qtyController = TextEditingController();
    _unitCostController = TextEditingController();
    _notesController = TextEditingController();
    _selectedPartId = widget.preSelectedPartId;
  }

  @override
  void dispose() {
    _qtyController.dispose();
    _unitCostController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedPartId == null || _selectedPartName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a spare part')),
      );
      return;
    }

    final qtyChange = int.parse(_qtyController.text.trim());
    final absoluteQty = _txType == 'stock_out' ? -qtyChange.abs() : qtyChange;

    final double uCost =
        double.tryParse(_unitCostController.text.trim()) ?? 0.0;

    final tx = InventoryTransactionEntity(
      id: '',
      companyId: '',
      partId: _selectedPartId!,
      partName: _selectedPartName!,
      type: _txType,
      quantity: absoluteQty,
      unitCost: uCost,
      totalCost: absoluteQty.abs() * uCost,
      notes: _notesController.text.trim(),
      date: _selectedDate,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final success = await ref
        .read(inventoryTransactionControllerProvider.notifier)
        .recordTransaction(tx);

    if (success && mounted) {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formState = ref.watch(inventoryTransactionControllerProvider);
    final parts = ref.watch(partsStreamProvider).valueOrNull ?? [];

    if (_selectedPartId != null &&
        parts.isNotEmpty &&
        _selectedPartName == null) {
      final matched = parts.firstWhere((p) => p.id == _selectedPartId);
      _selectedPartName = matched.name;
      _unitCostController.text = matched.unitCost.toString();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Record Stock Transaction'),
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
                    // Part Selector
                    DropdownButtonFormField<String>(
                      value: _selectedPartId,
                      decoration: const InputDecoration(
                        labelText: 'Select Spare Part',
                        prefixIcon: Icon(Icons.settings_suggest_rounded),
                      ),
                      items: parts
                          .map((p) => DropdownMenuItem(
                              value: p.id,
                              child: Text(
                                  '${p.name} (${p.partNumber}) - Qty: ${p.quantity}')))
                          .toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedPartId = val;
                          final matched = parts.firstWhere((p) => p.id == val);
                          _selectedPartName = matched.name;
                          _unitCostController.text =
                              matched.unitCost.toString();
                        });
                      },
                      validator: (val) =>
                          val == null ? 'Select a spare part' : null,
                    ),
                    const SizedBox(height: 16),
                    // Transaction Type
                    DropdownButtonFormField<String>(
                      value: _txType,
                      decoration: const InputDecoration(
                        labelText: 'Transaction Type',
                        prefixIcon: Icon(Icons.info_outline_rounded),
                      ),
                      items: ['stock_in', 'stock_out', 'adjustment']
                          .map((s) => DropdownMenuItem(
                              value: s,
                              child:
                                  Text(s.toUpperCase().replaceAll('_', ' '))))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _txType = val;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    // Quantity Change
                    TextFormField(
                      controller: _qtyController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Quantity Change',
                        prefixIcon: Icon(Icons.add_road_rounded),
                      ),
                      validator: (val) => val == null || val.trim().isEmpty
                          ? 'Enter quantity value'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    // Cost per Unit
                    TextFormField(
                      controller: _unitCostController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Cost Price per Unit (\$)',
                        prefixIcon: Icon(Icons.attach_money_rounded),
                      ),
                      validator: (val) => val == null || val.trim().isEmpty
                          ? 'Enter cost price'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    // Notes
                    TextFormField(
                      controller: _notesController,
                      decoration: const InputDecoration(
                        labelText: 'Transaction Description / Notes',
                        prefixIcon: Icon(Icons.description_outlined),
                      ),
                      validator: (val) => val == null || val.trim().isEmpty
                          ? 'Enter transaction description'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    // Date
                    ListTile(
                      leading: const Icon(Icons.calendar_today_rounded),
                      title: const Text('Transaction Date'),
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
                      text: 'Record Transaction',
                      onPressed: _submit,
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
