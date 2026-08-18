import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../vehicles/presentation/vehicle_providers.dart';
import '../domain/contract_entity.dart';
import '../domain/customer_entity.dart';
import 'customer_providers.dart';

class ContractFormScreen extends ConsumerStatefulWidget {
  final String? contractId;

  const ContractFormScreen({super.key, this.contractId});

  @override
  ConsumerState<ContractFormScreen> createState() => _ContractFormScreenState();
}

class _ContractFormScreenState extends ConsumerState<ContractFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _numberController;
  late TextEditingController _defaultRateController;

  String? _selectedCustomerId;
  String? _selectedCustomerName;
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 365));
  String _status = 'active';

  List<RouteRate> _routeRates = [];
  List<VehicleRate> _vehicleRates = [];
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _numberController = TextEditingController();
    _defaultRateController = TextEditingController(text: '0.0');
  }

  @override
  void dispose() {
    _numberController.dispose();
    _defaultRateController.dispose();
    super.dispose();
  }

  void _initializeValues(
      List<ContractEntity> contracts, List<CustomerEntity> customers) {
    if (_initialized) return;
    if (widget.contractId != null) {
      final contract = contracts.firstWhere((c) => c.id == widget.contractId);
      _numberController.text = contract.contractNumber;
      _defaultRateController.text = contract.defaultFreightRate.toString();
      _selectedCustomerId = contract.customerId;
      _selectedCustomerName = contract.customerName;
      _startDate = contract.startDate;
      _endDate = contract.endDate;
      _status = contract.status;
      _routeRates = List.from(contract.routeRates);
      _vehicleRates = List.from(contract.vehicleRates);
    } else if (customers.isNotEmpty) {
      _selectedCustomerId = customers.first.id;
      _selectedCustomerName = customers.first.name;
    }
    _initialized = true;
  }

  Future<void> _selectStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked;
      });
    }
  }

  Future<void> _selectEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        _endDate = picked;
      });
    }
  }

  void _addRouteRate() {
    setState(() {
      _routeRates.add(const RouteRate(
          pickup: '', delivery: '', ratePerTon: 0.0, flatRate: 0.0));
    });
  }

  void _addVehicleRate() {
    setState(() {
      _vehicleRates.add(const VehicleRate(
          vehicleId: '', licensePlate: '', ratePerTon: 0.0, flatRate: 0.0));
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCustomerId == null) return;

    final contract = ContractEntity(
      id: widget.contractId ?? '',
      customerId: _selectedCustomerId!,
      customerName: _selectedCustomerName!,
      contractNumber: _numberController.text.trim(),
      startDate: _startDate,
      endDate: _endDate,
      status: _status,
      defaultFreightRate:
          double.tryParse(_defaultRateController.text.trim()) ?? 0.0,
      routeRates: _routeRates,
      vehicleRates: _vehicleRates,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final success = await ref
        .read(contractFormControllerProvider.notifier)
        .saveContract(contract);

    if (success && mounted) {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formState = ref.watch(contractFormControllerProvider);
    final contracts = ref.watch(contractsStreamProvider).valueOrNull ?? [];
    final customers = ref.watch(customersStreamProvider).valueOrNull ?? [];
    final vehicles = ref.watch(vehiclesStreamProvider).valueOrNull ?? [];

    if (customers.isNotEmpty) {
      _initializeValues(contracts, customers);
    }

    final isEditMode = widget.contractId != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditMode ? 'Edit Contract' : 'Create Contract'),
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
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _numberController,
                            decoration: const InputDecoration(
                              labelText: 'Contract Number',
                              prefixIcon: Icon(Icons.assignment_rounded),
                            ),
                            validator: (val) =>
                                val == null || val.trim().isEmpty
                                    ? 'Enter contract number'
                                    : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedCustomerId,
                            decoration: const InputDecoration(
                              labelText: 'Customer Account',
                              prefixIcon: Icon(Icons.business_rounded),
                            ),
                            items: customers.map((c) {
                              return DropdownMenuItem(
                                value: c.id,
                                child: Text(c.name),
                              );
                            }).toList(),
                            onChanged: (val) {
                              setState(() {
                                _selectedCustomerId = val;
                                _selectedCustomerName = customers
                                    .firstWhere((c) => c.id == val)
                                    .name;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: _selectStartDate,
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Start Date',
                                prefixIcon: Icon(Icons.calendar_today_rounded),
                              ),
                              child: Text(
                                _startDate.toLocal().toString().split(' ')[0],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: InkWell(
                            onTap: _selectEndDate,
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'End Date',
                                prefixIcon: Icon(Icons.calendar_today_rounded),
                              ),
                              child: Text(
                                _endDate.toLocal().toString().split(' ')[0],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _status,
                            decoration: const InputDecoration(
                              labelText: 'Contract Status',
                              prefixIcon: Icon(Icons.info_outline_rounded),
                            ),
                            items: const [
                              DropdownMenuItem(
                                  value: 'active', child: Text('ACTIVE')),
                              DropdownMenuItem(
                                  value: 'expired', child: Text('EXPIRED')),
                              DropdownMenuItem(
                                  value: 'terminated',
                                  child: Text('TERMINATED')),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  _status = val;
                                });
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _defaultRateController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Default Freight Rate (\$/ton)',
                              prefixIcon: Icon(Icons.monetization_on_outlined),
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty)
                                return 'Enter default rate';
                              if (double.tryParse(val) == null)
                                return 'Enter valid number';
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Route-wise Custom Rates',
                            style: theme.textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold)),
                        TextButton.icon(
                          onPressed: _addRouteRate,
                          icon: const Icon(Icons.add_circle_outline_rounded),
                          label: const Text('Add Route Rate'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...List.generate(_routeRates.length, (index) {
                      final rate = _routeRates[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      initialValue: rate.pickup,
                                      decoration: const InputDecoration(
                                          labelText:
                                              'Pickup Location (e.g. Hub A)'),
                                      onChanged: (val) {
                                        _routeRates[index] = RouteRate(
                                          pickup: val,
                                          delivery: _routeRates[index].delivery,
                                          ratePerTon:
                                              _routeRates[index].ratePerTon,
                                          flatRate: _routeRates[index].flatRate,
                                        );
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: TextFormField(
                                      initialValue: rate.delivery,
                                      decoration: const InputDecoration(
                                          labelText:
                                              'Delivery Location (e.g. Plant B)'),
                                      onChanged: (val) {
                                        _routeRates[index] = RouteRate(
                                          pickup: _routeRates[index].pickup,
                                          delivery: val,
                                          ratePerTon:
                                              _routeRates[index].ratePerTon,
                                          flatRate: _routeRates[index].flatRate,
                                        );
                                      },
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline,
                                        color: Colors.red),
                                    onPressed: () {
                                      setState(() {
                                        _routeRates.removeAt(index);
                                      });
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      initialValue: rate.ratePerTon.toString(),
                                      keyboardType: TextInputType.number,
                                      decoration: const InputDecoration(
                                          labelText: 'Rate per Ton (\$)'),
                                      onChanged: (val) {
                                        _routeRates[index] = RouteRate(
                                          pickup: _routeRates[index].pickup,
                                          delivery: _routeRates[index].delivery,
                                          ratePerTon:
                                              double.tryParse(val) ?? 0.0,
                                          flatRate: _routeRates[index].flatRate,
                                        );
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: TextFormField(
                                      initialValue: rate.flatRate.toString(),
                                      keyboardType: TextInputType.number,
                                      decoration: const InputDecoration(
                                          labelText: 'Or Flat Trip Rate (\$)'),
                                      onChanged: (val) {
                                        _routeRates[index] = RouteRate(
                                          pickup: _routeRates[index].pickup,
                                          delivery: _routeRates[index].delivery,
                                          ratePerTon:
                                              _routeRates[index].ratePerTon,
                                          flatRate: double.tryParse(val) ?? 0.0,
                                        );
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 40), // alignment
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Vehicle-specific Rates',
                            style: theme.textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold)),
                        TextButton.icon(
                          onPressed: _addVehicleRate,
                          icon: const Icon(Icons.add_circle_outline_rounded),
                          label: const Text('Add Vehicle Rate'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...List.generate(_vehicleRates.length, (index) {
                      final rate = _vehicleRates[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: DropdownButtonFormField<String>(
                                      value: rate.vehicleId.isEmpty
                                          ? null
                                          : rate.vehicleId,
                                      decoration: const InputDecoration(
                                          labelText: 'Select Vehicle'),
                                      items: vehicles.map((v) {
                                        return DropdownMenuItem(
                                          value: v.id,
                                          child: Text(
                                              '${v.licensePlate} (${v.make})'),
                                        );
                                      }).toList(),
                                      onChanged: (val) {
                                        if (val != null) {
                                          final v = vehicles.firstWhere(
                                              (veh) => veh.id == val);
                                          _vehicleRates[index] = VehicleRate(
                                            vehicleId: val,
                                            licensePlate: v.licensePlate,
                                            ratePerTon:
                                                _vehicleRates[index].ratePerTon,
                                            flatRate:
                                                _vehicleRates[index].flatRate,
                                          );
                                        }
                                      },
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline,
                                        color: Colors.red),
                                    onPressed: () {
                                      setState(() {
                                        _vehicleRates.removeAt(index);
                                      });
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      initialValue: rate.ratePerTon.toString(),
                                      keyboardType: TextInputType.number,
                                      decoration: const InputDecoration(
                                          labelText: 'Rate per Ton (\$)'),
                                      onChanged: (val) {
                                        _vehicleRates[index] = VehicleRate(
                                          vehicleId:
                                              _vehicleRates[index].vehicleId,
                                          licensePlate:
                                              _vehicleRates[index].licensePlate,
                                          ratePerTon:
                                              double.tryParse(val) ?? 0.0,
                                          flatRate:
                                              _vehicleRates[index].flatRate,
                                        );
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: TextFormField(
                                      initialValue: rate.flatRate.toString(),
                                      keyboardType: TextInputType.number,
                                      decoration: const InputDecoration(
                                          labelText: 'Or Flat Trip Rate (\$)'),
                                      onChanged: (val) {
                                        _vehicleRates[index] = VehicleRate(
                                          vehicleId:
                                              _vehicleRates[index].vehicleId,
                                          licensePlate:
                                              _vehicleRates[index].licensePlate,
                                          ratePerTon:
                                              _vehicleRates[index].ratePerTon,
                                          flatRate: double.tryParse(val) ?? 0.0,
                                        );
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 40), // alignment
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 32),
                    CustomButton(
                      text: isEditMode ? 'Update Contract' : 'Create Contract',
                      onPressed: _submit,
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
