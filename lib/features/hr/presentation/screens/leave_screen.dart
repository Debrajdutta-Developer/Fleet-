import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../hr_providers.dart';
import '../../domain/leave_entity.dart';
import '../../domain/employee_entity.dart';

class LeaveScreen extends ConsumerWidget {
  const LeaveScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leavesAsync = ref.watch(leavesStreamProvider);
    final employees = ref.watch(employeesStreamProvider).valueOrNull ?? [];
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Leave Management'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showLeaveRequestDialog(context, employees),
        icon: const Icon(Icons.add_task_outlined),
        label: const Text('Request Leave'),
      ),
      body: leavesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (leaves) {
          if (leaves.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.time_to_leave_outlined,
                      size: 64, color: colorScheme.outline),
                  const SizedBox(height: 16),
                  Text('No leave requests found.',
                      style: theme.textTheme.titleMedium),
                ],
              ),
            );
          }

          // Sort by creation date descending
          leaves.sort((a, b) => b.createdAt.compareTo(a.createdAt));

          final pending = leaves.where((l) => l.status == 'pending').toList();
          final historical =
              leaves.where((l) => l.status != 'pending').toList();

          return DefaultTabController(
            length: 2,
            child: Column(
              children: [
                TabBar(
                  labelColor: colorScheme.primary,
                  indicatorColor: colorScheme.primary,
                  tabs: [
                    Tab(text: 'Pending (${pending.length})'),
                    Tab(text: 'History (${historical.length})'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _LeaveListView(
                          leaves: pending,
                          employees: employees,
                          isPending: true),
                      _LeaveListView(
                          leaves: historical,
                          employees: employees,
                          isPending: false),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showLeaveRequestDialog(
      BuildContext context, List<EmployeeEntity> employees) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return LeaveRequestDialog(employees: employees);
      },
    );
  }
}

class _LeaveListView extends ConsumerWidget {
  final List<LeaveEntity> leaves;
  final List<EmployeeEntity> employees;
  final bool isPending;

  const _LeaveListView({
    required this.leaves,
    required this.employees,
    required this.isPending,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (leaves.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child:
              Text('No leaves in this tab.', style: theme.textTheme.bodyLarge),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: leaves.length,
      itemBuilder: (context, index) {
        final leave = leaves[index];
        final emp = employees.firstWhere(
          (e) => e.id == leave.employeeId,
          orElse: () => EmployeeEntity(
            id: '',
            companyId: '',
            firstName: 'Unknown',
            lastName: 'Employee',
            email: '',
            phone: '',
            status: 'active',
            role: 'driver',
            baseSalary: 0.0,
            allowance: 0.0,
            deductions: 0.0,
            hiredAt: DateTime.now(),
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        final daysCount = leave.endDate.difference(leave.startDate).inDays + 1;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      emp.fullName,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    _LeaveStatusChip(status: leave.status),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${leave.leaveType.toUpperCase()} LEAVE • $daysCount Day(s)',
                  style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.primary, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                Text(
                  'Dates: ${DateFormat('yyyy-MM-dd').format(leave.startDate)} to ${DateFormat('yyyy-MM-dd').format(leave.endDate)}',
                  style: theme.textTheme.bodyMedium,
                ),
                if (leave.reason.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Reason: "${leave.reason}"',
                    style: theme.textTheme.bodyMedium?.copyWith(
                        fontStyle: FontStyle.italic,
                        color: colorScheme.outline),
                  ),
                ],
                if (isPending) ...[
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red),
                        onPressed: () =>
                            _updateStatus(context, ref, leave, 'rejected'),
                        child: const Text('Reject'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () =>
                            _updateStatus(context, ref, leave, 'approved'),
                        child: const Text('Approve'),
                      ),
                    ],
                  ),
                ]
              ],
            ),
          ),
        );
      },
    );
  }

  void _updateStatus(BuildContext context, WidgetRef ref, LeaveEntity leave,
      String status) async {
    final success = await ref
        .read(leaveFormControllerProvider.notifier)
        .updateLeaveStatus(leave, status);
    if (success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Leave request was $status')),
      );
    }
  }
}

class LeaveRequestDialog extends ConsumerStatefulWidget {
  final List<EmployeeEntity> employees;

  const LeaveRequestDialog({super.key, required this.employees});

  @override
  ConsumerState<LeaveRequestDialog> createState() => _LeaveRequestDialogState();
}

class _LeaveRequestDialogState extends ConsumerState<LeaveRequestDialog> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();

  String? _selectedEmpId;
  String _selectedLeaveType = 'annual';
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 1));

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(leaveFormControllerProvider);

    return AlertDialog(
      title: const Text('Request Leave'),
      content: state.isLoading
          ? const SizedBox(
              height: 100, child: Center(child: CircularProgressIndicator()))
          : SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      value: _selectedEmpId,
                      decoration: const InputDecoration(
                          labelText: 'Employee', border: OutlineInputBorder()),
                      items: widget.employees
                          .map((e) => DropdownMenuItem(
                              value: e.id, child: Text(e.fullName)))
                          .toList(),
                      validator: (val) => val == null ? 'Required' : null,
                      onChanged: (val) => setState(() => _selectedEmpId = val),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedLeaveType,
                      decoration: const InputDecoration(
                          labelText: 'Leave Type',
                          border: OutlineInputBorder()),
                      items: const [
                        DropdownMenuItem(
                            value: 'annual', child: Text('Annual')),
                        DropdownMenuItem(value: 'sick', child: Text('Sick')),
                        DropdownMenuItem(
                            value: 'casual', child: Text('Casual')),
                        DropdownMenuItem(
                            value: 'unpaid', child: Text('Unpaid')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedLeaveType = val);
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      title: const Text('Start Date'),
                      subtitle:
                          Text(DateFormat('yyyy-MM-dd').format(_startDate)),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final selected = await showDatePicker(
                          context: context,
                          initialDate: _startDate,
                          firstDate:
                              DateTime.now().subtract(const Duration(days: 30)),
                          lastDate:
                              DateTime.now().add(const Duration(days: 365)),
                        );
                        if (selected != null) {
                          setState(() {
                            _startDate = selected;
                            if (_endDate.isBefore(_startDate)) {
                              _endDate =
                                  _startDate.add(const Duration(days: 1));
                            }
                          });
                        }
                      },
                    ),
                    ListTile(
                      title: const Text('End Date'),
                      subtitle: Text(DateFormat('yyyy-MM-dd').format(_endDate)),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final selected = await showDatePicker(
                          context: context,
                          initialDate: _endDate,
                          firstDate: _startDate,
                          lastDate:
                              DateTime.now().add(const Duration(days: 365)),
                        );
                        if (selected != null) {
                          setState(() => _endDate = selected);
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _reasonController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Reason',
                        border: OutlineInputBorder(),
                      ),
                      validator: (val) =>
                          val == null || val.isEmpty ? 'Required' : null,
                    ),
                  ],
                ),
              ),
            ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: state.isLoading ? null : () => _submitForm(),
          child: const Text('Submit'),
        ),
      ],
    );
  }

  void _submitForm() async {
    if (_formKey.currentState?.validate() ?? false) {
      final leave = LeaveEntity(
        id: '',
        companyId: '',
        employeeId: _selectedEmpId!,
        leaveType: _selectedLeaveType,
        startDate: _startDate,
        endDate: _endDate,
        reason: _reasonController.text.trim(),
        status: 'pending',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final success = await ref
          .read(leaveFormControllerProvider.notifier)
          .requestLeave(leave);
      if (success && mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Leave request submitted')),
        );
      }
    }
  }
}

class _LeaveStatusChip extends StatelessWidget {
  final String status;

  const _LeaveStatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case 'approved':
        color = Colors.green;
        break;
      case 'rejected':
        color = Colors.red;
        break;
      case 'pending':
      default:
        color = Colors.orange;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.toUpperCase(),
        style:
            TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}
