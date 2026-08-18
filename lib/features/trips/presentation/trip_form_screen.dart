import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../vehicles/domain/vehicle_entity.dart';
import '../../vehicles/presentation/vehicle_providers.dart';
import '../../drivers/presentation/driver_providers.dart';
import '../../drivers/domain/driver_entity.dart';
import '../../customers/presentation/customer_providers.dart';
import '../../customers/domain/customer_entity.dart';
import '../domain/trip_entity.dart';
import 'trip_providers.dart';

class TripFormScreen extends ConsumerStatefulWidget {
  final String? tripId;

  const TripFormScreen({super.key, this.tripId});

  @override
  ConsumerState<TripFormScreen> createState() => _TripFormScreenState();
}

class _TripFormScreenState extends ConsumerState<TripFormScreen> {
  final _formKey = GlobalKey<FormState>();

  // Text controllers
  final _pickupController = TextEditingController();
  final _deliveryController = TextEditingController();
  final _cargoController = TextEditingController();
  final _coalController = TextEditingController(); // Requirement 8
  final _freightController = TextEditingController();
  final _advanceController = TextEditingController();
  final _permitExpenseController = TextEditingController();

  // Selected entities
  VehicleEntity? _selectedVehicle;
  String? _selectedDriverId;
  String? _selectedDriverName;
  String? _selectedCustomerId;
  String? _selectedCustomerName;

  // Selected vehicle permit date for rule testing
  DateTime? _selectedVehiclePermitExpiry;

  @override
  void initState() {
    super.initState();
    _loadInitialValues();
  }

  void _loadInitialValues() {
    if (widget.tripId != null) {
      final tripsAsync = ref.read(tripsStreamProvider);
      final trips = tripsAsync.valueOrNull ?? [];
      try {
        final trip = trips.firstWhere((t) => t.id == widget.tripId);
        _pickupController.text = trip.pickupLocation;
        _deliveryController.text = trip.deliveryLocation;
        _cargoController.text = trip.cargoType;
        _coalController.text = trip.coalQuantity.toString();
        _freightController.text = trip.freightAmount.toString();
        _advanceController.text = trip.advancePayment.toString();
        _permitExpenseController.text = trip.permitExpense.toString();

        _selectedDriverId = trip.driverId;
        _selectedDriverName = trip.driverName;
        _selectedCustomerId = trip.customerId;
        _selectedCustomerName = trip.customerName;

        // Try to load the corresponding vehicle
        final vehiclesAsync = ref.read(vehiclesStreamProvider);
        final vehicles = vehiclesAsync.valueOrNull ?? [];
        _selectedVehicle = vehicles.firstWhere(
          (v) => v.id == trip.vehicleId,
          orElse: () => VehicleEntity(
            id: trip.vehicleId,
            vin: '',
            licensePlate: trip.vehicleLicensePlate,
            make: '',
            model: '',
            year: DateTime.now().year,
            status: 'active',
            fuelType: 'diesel',
            odometer: 0,
            insuranceExpiry: DateTime.now().add(const Duration(days: 365)),
            pucExpiry: DateTime.now().add(const Duration(days: 365)),
            fitnessExpiry: DateTime.now().add(const Duration(days: 365)),
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        if (_selectedVehicle != null) {
          _selectedVehiclePermitExpiry = VehiclePermitValidator.getPermitExpiry(
            _selectedVehicle!.id,
          );
        }
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _pickupController.dispose();
    _deliveryController.dispose();
    _cargoController.dispose();
    _coalController.dispose();
    _freightController.dispose();
    _advanceController.dispose();
    _permitExpenseController.dispose();
    super.dispose();
  }

  Future<void> _pickPermitExpiry() async {
    if (_selectedVehicle == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a vehicle first to manage its permit.'),
        ),
      );
      return;
    }

    final initialDate = _selectedVehiclePermitExpiry ??
        DateTime.now().add(const Duration(days: 30));
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );

    if (picked != null) {
      setState(() {
        _selectedVehiclePermitExpiry = picked;
        VehiclePermitValidator.setPermitExpiry(_selectedVehicle!.id, picked);
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedVehicle == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Validation Failure: Please assign a vehicle to this trip.',
          ),
        ),
      );
      return;
    }
    if (_selectedDriverId == null || _selectedDriverName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Validation Failure: Please assign a driver to this trip.',
          ),
        ),
      );
      return;
    }
    if (_selectedCustomerId == null || _selectedCustomerName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Validation Failure: Please assign a customer to this trip.',
          ),
        ),
      );
      return;
    }

    final coal = double.tryParse(_coalController.text.trim()) ?? 0.0;
    final freight = double.tryParse(_freightController.text.trim()) ?? 0.0;
    final advance = double.tryParse(_advanceController.text.trim()) ?? 0.0;
    final permitExpense =
        double.tryParse(_permitExpenseController.text.trim()) ?? 0.0;

    if (advance > freight) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Validation Failure: Advance payment cannot be greater than total freight amount.',
          ),
        ),
      );
      return;
    }

    final trip = TripEntity(
      id: widget.tripId ?? '',
      companyId: '', // Set by provider controller
      vehicleId: _selectedVehicle!.id,
      vehicleLicensePlate: _selectedVehicle!.licensePlate,
      driverId: _selectedDriverId!,
      driverName: _selectedDriverName!,
      customerId: _selectedCustomerId!,
      customerName: _selectedCustomerName!,
      pickupLocation: _pickupController.text.trim(),
      deliveryLocation: _deliveryController.text.trim(),
      cargoType: _cargoController.text.trim(),
      coalQuantity: coal,
      freightAmount: freight,
      advancePayment: advance,
      permitExpense: permitExpense,
      status: 'scheduled', // New trips start as scheduled
      statusHistory: [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final success = await ref
        .read(tripFormControllerProvider.notifier)
        .saveTrip(trip, selectedVehicle: _selectedVehicle);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.tripId == null
                ? 'Trip scheduled successfully.'
                : 'Trip updated successfully.',
          ),
        ),
      );
      context.pop();
    } else if (mounted) {
      final state = ref.read(tripFormControllerProvider);
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
    final formState = ref.watch(tripFormControllerProvider);
    final vehiclesAsync = ref.watch(vehiclesStreamProvider);
    final driversAsync = ref.watch(driversStreamProvider);
    final customersAsync = ref.watch(customersStreamProvider);

    final drivers = driversAsync.valueOrNull ?? [];
    final customers = customersAsync.valueOrNull ?? [];
    final List<DriverEntity> eligibleDrivers = drivers
        .where((d) => d.status == 'available' || d.id == _selectedDriverId)
        .toList();
    final List<CustomerEntity> eligibleCustomers = customers;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.tripId == null
              ? 'Schedule Logistics Trip'
              : 'Edit Trip Details',
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
                          'Schedule logistics dispatch order, validate compliance thresholds, and deploy corporate vehicles.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Section 1: Resource Assignments
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.assignment_outlined,
                                      color: colorScheme.primary,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Resource Deployments',
                                      style:
                                          theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const Divider(height: 24),

                                // Vehicle Dropdown
                                vehiclesAsync.when(
                                  loading: () =>
                                      const LinearProgressIndicator(),
                                  error: (err, st) => Text(
                                    'Error loading vehicles: $err',
                                    style: const TextStyle(color: Colors.red),
                                  ),
                                  data: (vehicles) {
                                    // Remove soft-deleted vehicles
                                    final activeVehicles = vehicles
                                        .where((v) => v.deletedAt == null)
                                        .toList();

                                    return DropdownButtonFormField<
                                        VehicleEntity>(
                                      value: _selectedVehicle != null &&
                                              activeVehicles.any(
                                                (v) =>
                                                    v.id ==
                                                    _selectedVehicle!.id,
                                              )
                                          ? activeVehicles.firstWhere(
                                              (v) =>
                                                  v.id == _selectedVehicle!.id,
                                            )
                                          : null,
                                      hint: const Text(
                                        'Assign Vehicle License Plate',
                                      ),
                                      items: activeVehicles.map((vehicle) {
                                        return DropdownMenuItem<VehicleEntity>(
                                          value: vehicle,
                                          child: Text(
                                            '${vehicle.licensePlate} (${vehicle.make} ${vehicle.model})',
                                          ),
                                        );
                                      }).toList(),
                                      onChanged: (vehicle) {
                                        setState(() {
                                          _selectedVehicle = vehicle;
                                          if (vehicle != null) {
                                            _selectedVehiclePermitExpiry =
                                                VehiclePermitValidator
                                                    .getPermitExpiry(
                                              vehicle.id,
                                            );
                                          } else {
                                            _selectedVehiclePermitExpiry = null;
                                          }
                                        });
                                      },
                                      decoration: const InputDecoration(
                                        labelText: 'Select Fleet Asset',
                                        prefixIcon: Icon(
                                          Icons.local_shipping_outlined,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(height: 16),

                                // Vehicle compliance check widgets if selected
                                if (_selectedVehicle != null) ...[
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: colorScheme.surfaceVariant
                                          .withOpacity(0.3),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: colorScheme.outline.withOpacity(
                                          0.2,
                                        ),
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Assigned Vehicle Compliance Expirations:',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        _ComplianceRow(
                                          title: 'Insurance Expiry',
                                          date:
                                              _selectedVehicle!.insuranceExpiry,
                                          isExpired: _selectedVehicle!
                                              .insuranceExpiry
                                              .isBefore(DateTime.now()),
                                        ),
                                        _ComplianceRow(
                                          title: 'PUC Compliance Expiry',
                                          date: _selectedVehicle!.pucExpiry,
                                          isExpired: _selectedVehicle!.pucExpiry
                                              .isBefore(DateTime.now()),
                                        ),
                                        _ComplianceRow(
                                          title: 'Fitness Certificate Expiry',
                                          date: _selectedVehicle!.fitnessExpiry,
                                          isExpired: _selectedVehicle!
                                              .fitnessExpiry
                                              .isBefore(DateTime.now()),
                                        ),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            _ComplianceRow(
                                              title:
                                                  'Vehicle Road Permit Expiry',
                                              date:
                                                  _selectedVehiclePermitExpiry ??
                                                      DateTime.now().add(
                                                        const Duration(
                                                            days: 365),
                                                      ),
                                              isExpired:
                                                  _selectedVehiclePermitExpiry !=
                                                          null &&
                                                      _selectedVehiclePermitExpiry!
                                                          .isBefore(
                                                              DateTime.now()),
                                            ),
                                            TextButton.icon(
                                              onPressed: _pickPermitExpiry,
                                              icon: const Icon(
                                                Icons.edit_calendar_outlined,
                                                size: 16,
                                              ),
                                              label: const Text(
                                                'Manage Permit',
                                                style: TextStyle(fontSize: 12),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                ],

                                // Driver Dropdown
                                DropdownButtonFormField<String>(
                                  value: eligibleDrivers.any(
                                    (d) => d.id == _selectedDriverId,
                                  )
                                      ? _selectedDriverId
                                      : null,
                                  hint: const Text('Assign Primary Driver'),
                                  items: eligibleDrivers.map((driver) {
                                    return DropdownMenuItem<String>(
                                      value: driver.id,
                                      child: Text(driver.fullName),
                                    );
                                  }).toList(),
                                  onChanged: (id) {
                                    setState(() {
                                      _selectedDriverId = id;
                                      _selectedDriverName = eligibleDrivers
                                          .firstWhere(
                                            (d) => d.id == id,
                                          )
                                          .fullName;
                                    });
                                  },
                                  decoration: const InputDecoration(
                                    labelText: 'Select Primary Driver',
                                    prefixIcon: Icon(
                                      Icons.person_outline_rounded,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // Customer Dropdown
                                DropdownButtonFormField<String>(
                                  value: eligibleCustomers.any(
                                    (c) => c.id == _selectedCustomerId,
                                  )
                                      ? _selectedCustomerId
                                      : null,
                                  hint: const Text('Assign Billed Customer'),
                                  items: eligibleCustomers.map((cust) {
                                    return DropdownMenuItem<String>(
                                      value: cust.id,
                                      child: Text(cust.name),
                                    );
                                  }).toList(),
                                  onChanged: (id) {
                                    setState(() {
                                      _selectedCustomerId = id;
                                      _selectedCustomerName = eligibleCustomers
                                          .firstWhere(
                                            (c) => c.id == id,
                                          )
                                          .name;
                                    });
                                  },
                                  decoration: const InputDecoration(
                                    labelText: 'Select Billed Customer',
                                    prefixIcon: Icon(Icons.business_outlined),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Section 2: Route details
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.route_outlined,
                                      color: colorScheme.primary,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Route Parameters',
                                      style:
                                          theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const Divider(height: 24),
                                CustomTextField(
                                  controller: _pickupController,
                                  hintText:
                                      'Enter pickup warehouse or terminal location',
                                  labelText: 'Pickup Location',
                                  prefixIcon: Icons.circle_outlined,
                                  validator: (val) {
                                    if (val == null || val.trim().isEmpty) {
                                      return 'Pickup location is a mandatory field.';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                CustomTextField(
                                  controller: _deliveryController,
                                  hintText:
                                      'Enter destination client or cargo hub location',
                                  labelText: 'Delivery Location',
                                  prefixIcon: Icons.location_on_outlined,
                                  validator: (val) {
                                    if (val == null || val.trim().isEmpty) {
                                      return 'Delivery location is a mandatory field.';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Section 3: Cargo & Billing details
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.currency_exchange_outlined,
                                      color: colorScheme.primary,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Cargo & Financial Parameters',
                                      style:
                                          theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const Divider(height: 24),
                                CustomTextField(
                                  controller: _cargoController,
                                  hintText:
                                      'Coal, Perishables, Hazardous materials, Heavy Machinery...',
                                  labelText: 'Cargo Type Description',
                                  prefixIcon: Icons.inventory_2_outlined,
                                  validator: (val) {
                                    if (val == null || val.trim().isEmpty) {
                                      return 'Cargo type description is a mandatory field.';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                CustomTextField(
                                  controller: _coalController,
                                  hintText: '0.00',
                                  labelText: 'Coal Quantity (tons)',
                                  prefixIcon: Icons.line_weight_outlined,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                                  validator: (val) {
                                    if (val == null || val.trim().isEmpty) {
                                      return 'Coal Quantity is a mandatory field.';
                                    }
                                    final numVal = double.tryParse(val.trim());
                                    if (numVal == null || numVal < 0) {
                                      return 'Must be a valid numeric value >= 0.';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: CustomTextField(
                                        controller: _freightController,
                                        hintText: '0.00',
                                        labelText: 'Freight Charges (\$)',
                                        prefixIcon: Icons.attach_money_outlined,
                                        keyboardType: const TextInputType
                                            .numberWithOptions(
                                          decimal: true,
                                        ),
                                        validator: (val) {
                                          if (val == null ||
                                              val.trim().isEmpty) {
                                            return 'Required.';
                                          }
                                          final numVal = double.tryParse(
                                            val.trim(),
                                          );
                                          if (numVal == null || numVal < 0) {
                                            return 'Must be >= 0.';
                                          }
                                          return null;
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: CustomTextField(
                                        controller: _advanceController,
                                        hintText: '0.00',
                                        labelText: 'Advance Payment (\$)',
                                        prefixIcon: Icons.payments_outlined,
                                        keyboardType: const TextInputType
                                            .numberWithOptions(
                                          decimal: true,
                                        ),
                                        validator: (val) {
                                          if (val == null ||
                                              val.trim().isEmpty) {
                                            return 'Required.';
                                          }
                                          final numVal = double.tryParse(
                                            val.trim(),
                                          );
                                          if (numVal == null || numVal < 0) {
                                            return 'Must be >= 0.';
                                          }
                                          return null;
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: CustomTextField(
                                        controller: _permitExpenseController,
                                        hintText: '0.00',
                                        labelText: 'Permit Expense (\$)',
                                        prefixIcon: Icons.receipt_long_outlined,
                                        keyboardType: const TextInputType
                                            .numberWithOptions(
                                          decimal: true,
                                        ),
                                        validator: (val) {
                                          if (val == null ||
                                              val.trim().isEmpty) {
                                            return 'Required.';
                                          }
                                          final numVal = double.tryParse(
                                            val.trim(),
                                          );
                                          if (numVal == null || numVal < 0) {
                                            return 'Must be >= 0.';
                                          }
                                          return null;
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Form submit buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () => context.pop(),
                              child: const Text('CANCEL'),
                            ),
                            const SizedBox(width: 16),
                            CustomButton(
                              text: widget.tripId == null
                                  ? 'SCHEDULE DISPATCH'
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

class _ComplianceRow extends StatelessWidget {
  final String title;
  final DateTime date;
  final bool isExpired;

  const _ComplianceRow({
    required this.title,
    required this.date,
    required this.isExpired,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 12, color: Colors.blueGrey),
          ),
          Row(
            children: [
              Text(
                DateFormat('dd MMM yyyy').format(date.toLocal()),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isExpired ? Colors.red : Colors.green,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                isExpired ? Icons.cancel_rounded : Icons.check_circle_rounded,
                size: 14,
                color: isExpired ? Colors.red : Colors.green,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
