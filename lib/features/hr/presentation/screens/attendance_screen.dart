import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../hr_providers.dart';
import '../../domain/attendance_entity.dart';
import '../../domain/employee_entity.dart';

class AttendanceScreen extends ConsumerStatefulWidget {
  const AttendanceScreen({super.key});

  @override
  ConsumerState<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends ConsumerState<AttendanceScreen> {
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final employees = ref.watch(employeesStreamProvider).valueOrNull ?? [];
    final attendanceAsync = ref.watch(attendanceStreamProvider(_selectedDate));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance Logs'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Date Picker Header
            Card(
              child: ListTile(
                leading: const Icon(Icons.calendar_today_outlined),
                title: const Text('Select Log Date'),
                subtitle:
                    Text(DateFormat('EEEE, d MMMM yyyy').format(_selectedDate)),
                trailing: ElevatedButton(
                  onPressed: () async {
                    final selected = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime(2025),
                      lastDate: DateTime.now(),
                    );
                    if (selected != null) {
                      setState(() {
                        _selectedDate = selected;
                      });
                    }
                  },
                  child: const Text('Change'),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Header stats
            attendanceAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Text('Error: $err'),
              data: (logs) {
                final presentCount =
                    logs.where((l) => l.status == 'present').length;
                final lateCount = logs.where((l) => l.status == 'late').length;
                final absentCount = employees.length - logs.length;

                return Row(
                  children: [
                    _StatBox(
                        title: 'Present',
                        count: presentCount,
                        color: Colors.green),
                    const SizedBox(width: 12),
                    _StatBox(
                        title: 'Late', count: lateCount, color: Colors.orange),
                    const SizedBox(width: 12),
                    _StatBox(
                        title: 'Absent / Unrecorded',
                        count: absentCount < 0 ? 0 : absentCount,
                        color: Colors.red),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            // Attendance lists
            Expanded(
              child: attendanceAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Center(child: Text('Error: $err')),
                data: (logs) {
                  if (employees.isEmpty) {
                    return const Center(
                        child: Text(
                            'Add employees in directory first to see attendance listings.'));
                  }

                  return Card(
                    child: ListView.separated(
                      itemCount: employees.length,
                      separatorBuilder: (context, index) => const Divider(),
                      itemBuilder: (context, index) {
                        final emp = employees[index];
                        // Find attendance record for this employee
                        final recordList =
                            logs.where((l) => l.employeeId == emp.id).toList();
                        final hasRecord = recordList.isNotEmpty;
                        final record = hasRecord ? recordList.first : null;

                        return ListTile(
                          title: Text(emp.fullName,
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(emp.role.toUpperCase()),
                              if (hasRecord && record!.checkIn != null)
                                Text(
                                    'In: ${DateFormat('hh:mm a').format(record.checkIn!)}'
                                    '${record.checkOut != null ? ' | Out: ${DateFormat('hh:mm a').format(record.checkOut!)} (${record.durationMinutes} mins)' : ''}'),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _AttendanceStatusChip(
                                status: hasRecord ? record!.status : 'absent',
                              ),
                              const SizedBox(width: 12),
                              // Fast Toggle manual present/absent log (for managers)
                              IconButton(
                                icon: const Icon(Icons.edit_note_outlined),
                                tooltip: 'Log Attendance Status',
                                onPressed: () =>
                                    _showManualLogDialog(context, emp, record),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showManualLogDialog(
      BuildContext context, EmployeeEntity emp, AttendanceEntity? record) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return ManualAttendanceDialog(
            employee: emp, existingRecord: record, selectedDate: _selectedDate);
      },
    );
  }
}

class ManualAttendanceDialog extends ConsumerStatefulWidget {
  final EmployeeEntity employee;
  final AttendanceEntity? existingRecord;
  final DateTime selectedDate;

  const ManualAttendanceDialog({
    super.key,
    required this.employee,
    this.existingRecord,
    required this.selectedDate,
  });

  @override
  ConsumerState<ManualAttendanceDialog> createState() =>
      _ManualAttendanceDialogState();
}

class _ManualAttendanceDialogState
    extends ConsumerState<ManualAttendanceDialog> {
  late String _selectedStatus;

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.existingRecord?.status ?? 'present';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Record manual status for ${widget.employee.fullName}'),
      content: DropdownButtonFormField<String>(
        value: _selectedStatus,
        decoration: const InputDecoration(
            labelText: 'Status', border: OutlineInputBorder()),
        items: const [
          DropdownMenuItem(value: 'present', child: Text('Present')),
          DropdownMenuItem(value: 'absent', child: Text('Absent')),
          DropdownMenuItem(value: 'late', child: Text('Late')),
          DropdownMenuItem(value: 'leave', child: Text('On Leave')),
        ],
        onChanged: (val) {
          if (val != null) {
            setState(() => _selectedStatus = val);
          }
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            final now = DateTime.now();
            final recordDate = DateTime(widget.selectedDate.year,
                widget.selectedDate.month, widget.selectedDate.day);
            final updated = (widget.existingRecord ??
                    AttendanceEntity(
                      id: '',
                      companyId: widget.employee.companyId,
                      employeeId: widget.employee.id,
                      date: recordDate,
                      createdAt: now,
                      updatedAt: now,
                      status: _selectedStatus,
                    ))
                .copyWith(
              status: _selectedStatus,
              updatedAt: now,
            );

            final ok = await ref
                .read(hrRepositoryProvider)
                .saveAttendance(widget.employee.companyId, updated);
            if (context.mounted) {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text(ok.id.isNotEmpty
                        ? 'Recorded status'
                        : 'Failed to record')),
              );
            }
          },
          child: const Text('Submit'),
        ),
      ],
    );
  }
}

class _StatBox extends StatelessWidget {
  final String title;
  final int count;
  final Color color;

  const _StatBox(
      {required this.title, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Expanded(
      child: Card(
        color: color.withOpacity(0.08),
        shape: RoundedRectangleBorder(
          side: BorderSide(color: color.withOpacity(0.5)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          child: Column(
            children: [
              Text(
                '$count',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: colorScheme.outline),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AttendanceStatusChip extends StatelessWidget {
  final String status;

  const _AttendanceStatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case 'present':
        color = Colors.green;
        break;
      case 'late':
        color = Colors.orange;
        break;
      case 'leave':
        color = Colors.blue;
        break;
      case 'absent':
      default:
        color = Colors.red;
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
