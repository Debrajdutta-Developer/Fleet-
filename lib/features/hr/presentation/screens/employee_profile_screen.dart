import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../hr_providers.dart';
import '../../domain/department_entity.dart';
import '../../domain/designation_entity.dart';
import '../../../trips/domain/audit_log_entity.dart';

class EmployeeProfileScreen extends ConsumerWidget {
  final String employeeId;

  const EmployeeProfileScreen({super.key, required this.employeeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final employeesAsync = ref.watch(employeesStreamProvider);
    final depts = ref.watch(departmentsStreamProvider).valueOrNull ?? [];
    final desigs = ref.watch(designationsStreamProvider).valueOrNull ?? [];
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Employee Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit Profile',
            onPressed: () => context.push('/hr/employees/$employeeId/edit'),
          ),
          IconButton(
            icon: const Icon(Icons.delete_forever_outlined, color: Colors.red),
            tooltip: 'Terminate Employee',
            onPressed: () => _confirmTermination(context, ref),
          ),
        ],
      ),
      body: employeesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (employees) {
          final empList = employees.where((e) => e.id == employeeId).toList();
          if (empList.isEmpty) {
            return const Center(
                child: Text('Employee not found or terminated.'));
          }
          final emp = empList.first;

          final deptName = depts
              .firstWhere((d) => d.id == emp.departmentId,
                  orElse: () => DepartmentEntity(
                      id: '',
                      companyId: '',
                      name: 'General',
                      description: '',
                      createdAt: DateTime.now(),
                      updatedAt: DateTime.now()))
              .name;

          final desigTitle = desigs
              .firstWhere((d) => d.id == emp.designationId,
                  orElse: () => DesignationEntity(
                      id: '',
                      companyId: '',
                      title: 'Staff',
                      description: '',
                      departmentId: '',
                      createdAt: DateTime.now(),
                      updatedAt: DateTime.now()))
              .title;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Profile header card
                Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: colorScheme.primaryContainer,
                          child: Text(
                            '${emp.firstName[0]}${emp.lastName[0]}'
                                .toUpperCase(),
                            style: TextStyle(
                                fontSize: 32,
                                color: colorScheme.onPrimaryContainer,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(emp.fullName,
                            style: theme.textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text('$desigTitle • $deptName',
                            style: theme.textTheme.bodyLarge
                                ?.copyWith(color: colorScheme.outline)),
                        const SizedBox(height: 12),
                        _ProfileStatusChip(status: emp.status),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Personal & Work details
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Contact & Identity',
                                  style: theme.textTheme.titleMedium),
                              const Divider(height: 24),
                              _InfoRow(
                                  label: 'Email',
                                  value: emp.email,
                                  icon: Icons.email_outlined),
                              _InfoRow(
                                  label: 'Phone',
                                  value: emp.phone,
                                  icon: Icons.phone_outlined),
                              _InfoRow(
                                  label: 'System Role',
                                  value: emp.role.toUpperCase(),
                                  icon: Icons.security_outlined),
                              _InfoRow(
                                  label: 'Hired On',
                                  value: DateFormat('yyyy-MM-dd')
                                      .format(emp.hiredAt),
                                  icon: Icons.calendar_today_outlined),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Compensation Structure',
                                  style: theme.textTheme.titleMedium),
                              const Divider(height: 24),
                              _InfoRow(
                                  label: 'Base Monthly Salary',
                                  value:
                                      '\$${emp.baseSalary.toStringAsFixed(2)}',
                                  icon: Icons.payments_outlined),
                              _InfoRow(
                                  label: 'Standard Allowance',
                                  value:
                                      '\$${emp.allowance.toStringAsFixed(2)}',
                                  icon: Icons.add_circle_outline),
                              _InfoRow(
                                  label: 'Standard Deductions',
                                  value:
                                      '\$${emp.deductions.toStringAsFixed(2)}',
                                  icon: Icons.remove_circle_outline),
                              _InfoRow(
                                  label: 'Total Net Estimate',
                                  value:
                                      '\$${(emp.baseSalary + emp.allowance - emp.deductions).toStringAsFixed(2)}',
                                  icon: Icons.check_circle_outline),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Employee Audit History Log list
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Employee HR Audit History',
                            style: theme.textTheme.titleMedium),
                        const Divider(height: 24),
                        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                          stream: FirebaseFirestore.instance
                              .collection('companies')
                              .doc(emp.companyId)
                              .collection('audit_logs')
                              .where('entityId', isEqualTo: employeeId)
                              .snapshots(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                  child: CircularProgressIndicator());
                            }
                            final logs = snapshot.data?.docs
                                    .map((doc) =>
                                        AuditLogEntity.fromMap(doc.data()))
                                    .toList() ??
                                [];

                            // Sort by date descending
                            logs.sort(
                                (a, b) => b.timestamp.compareTo(a.timestamp));

                            if (logs.isEmpty) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 16.0),
                                child: Text(
                                    'No HR audit records found for this employee.'),
                              );
                            }
                            return ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: logs.length,
                              separatorBuilder: (context, index) =>
                                  const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final log = logs[index];
                                return ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor:
                                        colorScheme.secondaryContainer,
                                    child: Icon(Icons.history_outlined,
                                        size: 18,
                                        color:
                                            colorScheme.onSecondaryContainer),
                                  ),
                                  title: Text(log.description),
                                  subtitle: Text(
                                      '${log.userName} • ${DateFormat('yyyy-MM-dd HH:mm').format(log.timestamp)}'),
                                );
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _confirmTermination(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirm Employee Termination'),
          content: const Text(
              'Are you sure you want to terminate and soft-delete this employee? All driver profile mappings will remain, but the status will update.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red, foregroundColor: Colors.white),
              onPressed: () async {
                final ok = await ref
                    .read(employeeFormControllerProvider.notifier)
                    .deleteEmployee(employeeId);
                if (context.mounted) {
                  Navigator.of(context).pop(); // dialog
                  if (ok) {
                    context.pop(); // screen
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content:
                              Text('Employee terminated and soft-deleted.')),
                    );
                  }
                }
              },
              child: const Text('Terminate'),
            ),
          ],
        );
      },
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _InfoRow(
      {required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: colorScheme.outline)),
                const SizedBox(height: 2),
                Text(value,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileStatusChip extends StatelessWidget {
  final String status;

  const _ProfileStatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case 'active':
        color = Colors.green;
        break;
      case 'suspended':
        color = Colors.orange;
        break;
      case 'terminated':
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1),
      ),
    );
  }
}
