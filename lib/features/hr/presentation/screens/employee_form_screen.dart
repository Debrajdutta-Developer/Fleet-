import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../hr_providers.dart';
import '../../domain/employee_entity.dart';
import '../../../auth/presentation/auth_providers.dart';

class EmployeeFormScreen extends ConsumerStatefulWidget {
  final String? employeeId;

  const EmployeeFormScreen({super.key, this.employeeId});

  @override
  ConsumerState<EmployeeFormScreen> createState() => _EmployeeFormScreenState();
}

class _EmployeeFormScreenState extends ConsumerState<EmployeeFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _baseSalaryController = TextEditingController();
  final _allowanceController = TextEditingController();
  final _deductionsController = TextEditingController();

  String? _selectedDeptId;
  String? _selectedDesigId;
  String _selectedStatus = 'active';
  String _selectedRole = 'driver';
  DateTime _hiredDate = DateTime.now();

  EmployeeEntity? _existingEmployee;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _loadExistingEmployee());
  }

  void _loadExistingEmployee() async {
    if (widget.employeeId != null && widget.employeeId != 'new') {
      final user = ref.read(currentUserProvider);
      if (user?.companyId == null) return;
      final emp = await ref
          .read(hrRepositoryProvider)
          .getEmployeeById(user!.companyId!, widget.employeeId!);
      if (emp != null) {
        setState(() {
          _existingEmployee = emp;
          _firstNameController.text = emp.firstName;
          _lastNameController.text = emp.lastName;
          _emailController.text = emp.email;
          _phoneController.text = emp.phone;
          _baseSalaryController.text = emp.baseSalary.toString();
          _allowanceController.text = emp.allowance.toString();
          _deductionsController.text = emp.deductions.toString();
          _selectedDeptId = emp.departmentId;
          _selectedDesigId = emp.designationId;
          _selectedStatus = emp.status;
          _selectedRole = emp.role;
          _hiredDate = emp.hiredAt;
        });
      }
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _baseSalaryController.dispose();
    _allowanceController.dispose();
    _deductionsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final depts = ref.watch(departmentsStreamProvider).valueOrNull ?? [];
    final desigs = ref.watch(designationsStreamProvider).valueOrNull ?? [];
    final state = ref.watch(employeeFormControllerProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Filter designations by department if selected
    final filteredDesigs = _selectedDeptId == null
        ? desigs
        : desigs.where((d) => d.departmentId == _selectedDeptId).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.employeeId == 'new' || widget.employeeId == null
            ? 'Add Employee'
            : 'Edit Employee'),
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Error block
                    if (state.errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: colorScheme.errorContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          state.errorMessage!,
                          style: TextStyle(color: colorScheme.onErrorContainer),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    // Profile/Identity section
                    Card(
                      elevation: 1,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Basic Details',
                                style: theme.textTheme.titleMedium),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _firstNameController,
                                    decoration: const InputDecoration(
                                      labelText: 'First Name',
                                      border: OutlineInputBorder(),
                                    ),
                                    validator: (val) =>
                                        val == null || val.isEmpty
                                            ? 'Required'
                                            : null,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: TextFormField(
                                    controller: _lastNameController,
                                    decoration: const InputDecoration(
                                      labelText: 'Last Name',
                                      border: OutlineInputBorder(),
                                    ),
                                    validator: (val) =>
                                        val == null || val.isEmpty
                                            ? 'Required'
                                            : null,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: const InputDecoration(
                                labelText: 'Email Address',
                                border: OutlineInputBorder(),
                              ),
                              validator: (val) => val == null || val.isEmpty
                                  ? 'Required'
                                  : null,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              decoration: const InputDecoration(
                                labelText: 'Phone Number',
                                border: OutlineInputBorder(),
                              ),
                              validator: (val) => val == null || val.isEmpty
                                  ? 'Required'
                                  : null,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Assignment & Role mapping (RBAC)
                    Card(
                      elevation: 1,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Work & Role Mapping',
                                style: theme.textTheme.titleMedium),
                            const SizedBox(height: 16),
                            DropdownButtonFormField<String>(
                              value: _selectedRole,
                              decoration: const InputDecoration(
                                labelText: 'System Role',
                                border: OutlineInputBorder(),
                              ),
                              items: const [
                                DropdownMenuItem(
                                    value: 'driver', child: Text('Driver')),
                                DropdownMenuItem(
                                    value: 'dispatcher',
                                    child: Text('Dispatcher')),
                                DropdownMenuItem(
                                    value: 'accountant',
                                    child: Text('Accountant')),
                                DropdownMenuItem(
                                    value: 'manager', child: Text('Manager')),
                                DropdownMenuItem(
                                    value: 'admin',
                                    child: Text('Administrator')),
                              ],
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => _selectedRole = val);
                                }
                              },
                            ),
                            const SizedBox(height: 16),
                            DropdownButtonFormField<String>(
                              value: _selectedDeptId,
                              decoration: const InputDecoration(
                                labelText: 'Department',
                                border: OutlineInputBorder(),
                              ),
                              items: [
                                const DropdownMenuItem(
                                    value: null, child: Text('None (General)')),
                                ...depts.map((d) => DropdownMenuItem(
                                    value: d.id, child: Text(d.name))),
                              ],
                              onChanged: (val) {
                                setState(() {
                                  _selectedDeptId = val;
                                  _selectedDesigId =
                                      null; // Reset designation on department change
                                });
                              },
                            ),
                            const SizedBox(height: 16),
                            DropdownButtonFormField<String>(
                              value: _selectedDesigId,
                              decoration: const InputDecoration(
                                labelText: 'Designation',
                                border: OutlineInputBorder(),
                              ),
                              items: [
                                const DropdownMenuItem(
                                    value: null, child: Text('None')),
                                ...filteredDesigs.map((d) => DropdownMenuItem(
                                    value: d.id, child: Text(d.title))),
                              ],
                              onChanged: (val) {
                                setState(() => _selectedDesigId = val);
                              },
                            ),
                            const SizedBox(height: 16),
                            DropdownButtonFormField<String>(
                              value: _selectedStatus,
                              decoration: const InputDecoration(
                                labelText: 'Status',
                                border: OutlineInputBorder(),
                              ),
                              items: const [
                                DropdownMenuItem(
                                    value: 'active', child: Text('Active')),
                                DropdownMenuItem(
                                    value: 'suspended',
                                    child: Text('Suspended')),
                                DropdownMenuItem(
                                    value: 'terminated',
                                    child: Text('Terminated')),
                              ],
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => _selectedStatus = val);
                                }
                              },
                            ),
                            const SizedBox(height: 16),
                            ListTile(
                              title: const Text('Hired Date'),
                              subtitle: Text(
                                  DateFormat('yyyy-MM-dd').format(_hiredDate)),
                              trailing:
                                  const Icon(Icons.calendar_today_outlined),
                              onTap: () async {
                                final selected = await showDatePicker(
                                  context: context,
                                  initialDate: _hiredDate,
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime.now()
                                      .add(const Duration(days: 365)),
                                );
                                if (selected != null) {
                                  setState(() => _hiredDate = selected);
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Salary Structure
                    Card(
                      elevation: 1,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Salary & Compensation Structure',
                                style: theme.textTheme.titleMedium),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _baseSalaryController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Base Monthly Salary (\$)',
                                border: OutlineInputBorder(),
                              ),
                              validator: (val) => val == null || val.isEmpty
                                  ? 'Required'
                                  : null,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _allowanceController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Standard Allowances (\$)',
                                border: OutlineInputBorder(),
                              ),
                              validator: (val) => val == null || val.isEmpty
                                  ? 'Required'
                                  : null,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _deductionsController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Standard Deductions (\$)',
                                border: OutlineInputBorder(),
                              ),
                              validator: (val) => val == null || val.isEmpty
                                  ? 'Required'
                                  : null,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () => _submitForm(),
                      child: const Text('Save Employee',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  void _submitForm() async {
    if (_formKey.currentState?.validate() ?? false) {
      final base = double.tryParse(_baseSalaryController.text) ?? 0.0;
      final allowance = double.tryParse(_allowanceController.text) ?? 0.0;
      final deductions = double.tryParse(_deductionsController.text) ?? 0.0;

      final emp = EmployeeEntity(
        id: _existingEmployee?.id ?? '',
        companyId: _existingEmployee?.companyId ?? '',
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        departmentId: _selectedDeptId,
        designationId: _selectedDesigId,
        status: _selectedStatus,
        role: _selectedRole,
        baseSalary: base,
        allowance: allowance,
        deductions: deductions,
        hiredAt: _hiredDate,
        createdAt: _existingEmployee?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final success = await ref
          .read(employeeFormControllerProvider.notifier)
          .saveEmployee(emp);
      if (success && mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Employee saved successfully')),
        );
      }
    }
  }
}
