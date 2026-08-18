import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../hr_providers.dart';
import '../../domain/employee_entity.dart';
import '../../domain/department_entity.dart';

class EmployeeListScreen extends ConsumerStatefulWidget {
  const EmployeeListScreen({super.key});

  @override
  ConsumerState<EmployeeListScreen> createState() => _EmployeeListScreenState();
}

class _EmployeeListScreenState extends ConsumerState<EmployeeListScreen> {
  String _searchQuery = '';
  String? _selectedDeptId;
  String? _selectedStatus;
  int _currentPage = 1;
  static const int _pageSize = 8;

  @override
  Widget build(BuildContext context) {
    final employeesAsync = ref.watch(employeesStreamProvider);
    final deptsAsync = ref.watch(departmentsStreamProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('HR & Employee Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'HR Settings',
            onPressed: () => context.push('/hr/settings'),
          ),
          IconButton(
            icon: const Icon(Icons.receipt_long_outlined),
            tooltip: 'Payroll Preparation',
            onPressed: () => context.push('/hr/payroll'),
          ),
          IconButton(
            icon: const Icon(Icons.time_to_leave_outlined),
            tooltip: 'Leaves Approval',
            onPressed: () => context.push('/hr/leaves'),
          ),
          IconButton(
            icon: const Icon(Icons.fingerprint_outlined),
            tooltip: 'Attendance Log',
            onPressed: () => context.push('/hr/attendance'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/hr/employees/new'),
        icon: const Icon(Icons.person_add_outlined),
        label: const Text('Add Employee'),
      ),
      body: employeesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) =>
            Center(child: Text('Error loading employees: $error')),
        data: (employees) {
          final depts = deptsAsync.valueOrNull ?? [];

          // 1. Apply Search
          var filtered = employees.where((emp) {
            final nameMatch = emp.fullName
                    .toLowerCase()
                    .contains(_searchQuery.toLowerCase()) ||
                emp.email.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                emp.phone.contains(_searchQuery);
            final deptMatch =
                _selectedDeptId == null || emp.departmentId == _selectedDeptId;
            final statusMatch =
                _selectedStatus == null || emp.status == _selectedStatus;
            return nameMatch && deptMatch && statusMatch;
          }).toList();

          // Sort by creation date descending
          filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));

          // 2. Pagination
          final totalCount = filtered.length;
          final totalPages = (totalCount / _pageSize).ceil();
          final startIndex = (_currentPage - 1) * _pageSize;
          final endIndex = startIndex + _pageSize > totalCount
              ? totalCount
              : startIndex + _pageSize;
          final paginatedList = totalCount > 0
              ? filtered.sublist(startIndex, endIndex)
              : <EmployeeEntity>[];

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Filters Row
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 12.0),
                    child: Row(
                      children: [
                        // Search Input
                        Expanded(
                          flex: 3,
                          child: TextField(
                            onChanged: (val) {
                              setState(() {
                                _searchQuery = val;
                                _currentPage = 1;
                              });
                            },
                            decoration: InputDecoration(
                              hintText: 'Search by name, email or phone...',
                              prefixIcon: const Icon(Icons.search),
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8)),
                              contentPadding: const EdgeInsets.symmetric(
                                  vertical: 0, horizontal: 16),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Department Filter
                        Expanded(
                          flex: 2,
                          child: DropdownButtonFormField<String>(
                            value: _selectedDeptId,
                            isExpanded: true,
                            decoration: InputDecoration(
                              labelText: 'Department',
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8)),
                              contentPadding: const EdgeInsets.symmetric(
                                  vertical: 0, horizontal: 12),
                            ),
                            items: [
                              const DropdownMenuItem(
                                  value: null, child: Text('All Departments')),
                              ...depts.map((d) => DropdownMenuItem(
                                  value: d.id, child: Text(d.name))),
                            ],
                            onChanged: (val) {
                              setState(() {
                                _selectedDeptId = val;
                                _currentPage = 1;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Status Filter
                        Expanded(
                          flex: 2,
                          child: DropdownButtonFormField<String>(
                            value: _selectedStatus,
                            isExpanded: true,
                            decoration: InputDecoration(
                              labelText: 'Status',
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8)),
                              contentPadding: const EdgeInsets.symmetric(
                                  vertical: 0, horizontal: 12),
                            ),
                            items: const [
                              DropdownMenuItem(
                                  value: null, child: Text('All Statuses')),
                              DropdownMenuItem(
                                  value: 'active', child: Text('Active')),
                              DropdownMenuItem(
                                  value: 'suspended', child: Text('Suspended')),
                              DropdownMenuItem(
                                  value: 'terminated',
                                  child: Text('Terminated')),
                            ],
                            onChanged: (val) {
                              setState(() {
                                _selectedStatus = val;
                                _currentPage = 1;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Table Headers / Stats
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Showing ${totalCount == 0 ? 0 : startIndex + 1}-$endIndex of $totalCount Employees',
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Row(
                      children: [
                        ActionChip(
                          avatar: const Icon(Icons.fingerprint, size: 16),
                          label: const Text('Clock In/Out Dashboard'),
                          onPressed: () => _showClockDialog(context, employees),
                        ),
                      ],
                    )
                  ],
                ),
                const SizedBox(height: 12),
                // Main List Table
                Expanded(
                  child: totalCount == 0
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.people_outline,
                                  size: 64, color: colorScheme.outline),
                              const SizedBox(height: 16),
                              Text('No employees found.',
                                  style: theme.textTheme.titleMedium),
                            ],
                          ),
                        )
                      : Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            side: BorderSide(color: colorScheme.outlineVariant),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListView.separated(
                            itemCount: paginatedList.length,
                            separatorBuilder: (context, index) =>
                                const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final emp = paginatedList[index];
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

                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: colorScheme.primaryContainer,
                                  child: Text(
                                    '${emp.firstName[0]}${emp.lastName[0]}'
                                        .toUpperCase(),
                                    style: TextStyle(
                                        color: colorScheme.onPrimaryContainer,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                                title: Text(emp.fullName,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold)),
                                subtitle: Text(
                                    '$deptName • ${emp.role.toUpperCase()} • \$${emp.baseSalary.toStringAsFixed(2)}/mo'),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _StatusChip(status: emp.status),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      icon: const Icon(Icons.arrow_forward_ios,
                                          size: 16),
                                      onPressed: () => context
                                          .push('/hr/employees/${emp.id}'),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                ),
                const SizedBox(height: 16),
                // Pagination Controls
                if (totalPages > 1)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left),
                        onPressed: _currentPage > 1
                            ? () => setState(() => _currentPage--)
                            : null,
                      ),
                      Text('Page $_currentPage of $totalPages',
                          style: theme.textTheme.bodyMedium),
                      IconButton(
                        icon: const Icon(Icons.chevron_right),
                        onPressed: _currentPage < totalPages
                            ? () => setState(() => _currentPage++)
                            : null,
                      ),
                    ],
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showClockDialog(BuildContext context, List<EmployeeEntity> employees) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return ClockInOutDialog(employees: employees);
      },
    );
  }
}

class ClockInOutDialog extends ConsumerWidget {
  final List<EmployeeEntity> employees;

  const ClockInOutDialog({super.key, required this.employees});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AlertDialog(
      title: const Text('Clock In/Out Console'),
      content: SizedBox(
        width: 400,
        child: ListView.separated(
          shrinkWrap: true,
          itemCount: employees.length,
          separatorBuilder: (context, index) => const Divider(),
          itemBuilder: (context, index) {
            final emp = employees[index];
            return ListTile(
              title: Text(emp.fullName),
              subtitle: Text(emp.role.toUpperCase()),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primaryContainer,
                      foregroundColor: colorScheme.onPrimaryContainer,
                    ),
                    onPressed: () async {
                      final ok = await ref
                          .read(attendanceClockControllerProvider.notifier)
                          .clockIn(emp.id);
                      if (context.mounted) {
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(ok
                                  ? 'Clocked In Successfully'
                                  : 'Failed to clock in')),
                        );
                      }
                    },
                    child: const Text('In'),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: () async {
                      final ok = await ref
                          .read(attendanceClockControllerProvider.notifier)
                          .clockOut(emp.id);
                      if (context.mounted) {
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(ok
                                  ? 'Clocked Out Successfully'
                                  : 'Failed to clock out')),
                        );
                      }
                    },
                    child: const Text('Out'),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;

  const _StatusChip({required this.status});

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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        status.toUpperCase(),
        style:
            TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}
