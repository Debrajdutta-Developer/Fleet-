import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../hr_providers.dart';
import '../../domain/department_entity.dart';
import '../../domain/designation_entity.dart';
import '../../domain/shift_entity.dart';

class HrSettingsScreen extends ConsumerWidget {
  const HrSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deptsAsync = ref.watch(departmentsStreamProvider);
    final desigsAsync = ref.watch(designationsStreamProvider);
    final shiftsAsync = ref.watch(shiftsStreamProvider);
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('HR Organization Settings'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.business_outlined), text: 'Departments'),
              Tab(icon: Icon(Icons.badge_outlined), text: 'Designations'),
              Tab(icon: Icon(Icons.schedule_outlined), text: 'Shifts'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Departments Tab
            _DepartmentsTab(deptsAsync: deptsAsync),
            // Designations Tab
            _DesignationsTab(desigsAsync: desigsAsync, deptsAsync: deptsAsync),
            // Shifts Tab
            _ShiftsTab(shiftsAsync: shiftsAsync),
          ],
        ),
      ),
    );
  }
}

// ---------------- DEPARTMENTS TAB ----------------
class _DepartmentsTab extends ConsumerWidget {
  final AsyncValue<List<DepartmentEntity>> deptsAsync;

  const _DepartmentsTab({required this.deptsAsync});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Corporate Departments', style: theme.textTheme.titleMedium),
              ElevatedButton.icon(
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add Dept'),
                onPressed: () => _showDeptForm(context, ref, null),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: deptsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Error: $err')),
              data: (depts) {
                if (depts.isEmpty) {
                  return const Center(
                      child: Text('No departments configured.'));
                }
                return ListView.builder(
                  itemCount: depts.length,
                  itemBuilder: (context, index) {
                    final d = depts[index];
                    return Card(
                      child: ListTile(
                        title: Text(d.name,
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(d.description),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined),
                              onPressed: () => _showDeptForm(context, ref, d),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline,
                                  color: Colors.red),
                              onPressed: () => _deleteDept(context, ref, d.id),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          )
        ],
      ),
    );
  }

  void _showDeptForm(
      BuildContext context, WidgetRef ref, DepartmentEntity? dept) {
    showDialog<void>(
      context: context,
      builder: (context) => DepartmentDialog(dept: dept),
    );
  }

  void _deleteDept(BuildContext context, WidgetRef ref, String deptId) async {
    final ok = await ref
        .read(hrSettingsControllerProvider.notifier)
        .deleteDepartment(deptId);
    if (context.mounted && ok) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Department soft-deleted')));
    }
  }
}

class DepartmentDialog extends ConsumerStatefulWidget {
  final DepartmentEntity? dept;

  const DepartmentDialog({super.key, this.dept});

  @override
  ConsumerState<DepartmentDialog> createState() => _DepartmentDialogState();
}

class _DepartmentDialogState extends ConsumerState<DepartmentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.dept != null) {
      _nameController.text = widget.dept!.name;
      _descController.text = widget.dept!.description;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.dept == null ? 'Add Department' : 'Edit Department'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                  labelText: 'Name', border: OutlineInputBorder()),
              validator: (val) =>
                  val == null || val.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descController,
              decoration: const InputDecoration(
                  labelText: 'Description', border: OutlineInputBorder()),
              validator: (val) =>
                  val == null || val.isEmpty ? 'Required' : null,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () async {
            if (_formKey.currentState?.validate() ?? false) {
              final d = (widget.dept ??
                      DepartmentEntity(
                        id: '',
                        companyId: '',
                        name: '',
                        description: '',
                        createdAt: DateTime.now(),
                        updatedAt: DateTime.now(),
                      ))
                  .copyWith(
                name: _nameController.text.trim(),
                description: _descController.text.trim(),
              );

              final ok = await ref
                  .read(hrSettingsControllerProvider.notifier)
                  .saveDepartment(d);
              if (context.mounted && ok) {
                Navigator.of(context).pop();
              }
            }
          },
          child: const Text('Save'),
        )
      ],
    );
  }
}

// ---------------- DESIGNATIONS TAB ----------------
class _DesignationsTab extends ConsumerWidget {
  final AsyncValue<List<DesignationEntity>> desigsAsync;
  final AsyncValue<List<DepartmentEntity>> deptsAsync;

  const _DesignationsTab({required this.desigsAsync, required this.deptsAsync});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final depts = deptsAsync.valueOrNull ?? [];

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Job Roles / Designations',
                  style: theme.textTheme.titleMedium),
              ElevatedButton.icon(
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add Role'),
                onPressed: () => _showDesigForm(context, ref, depts, null),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: desigsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Error: $err')),
              data: (desigs) {
                if (desigs.isEmpty) {
                  return const Center(
                      child: Text('No designations configured.'));
                }
                return ListView.builder(
                  itemCount: desigs.length,
                  itemBuilder: (context, index) {
                    final d = desigs[index];
                    final deptName = depts
                        .firstWhere((dept) => dept.id == d.departmentId,
                            orElse: () => DepartmentEntity(
                                id: '',
                                companyId: '',
                                name: 'General',
                                description: '',
                                createdAt: DateTime.now(),
                                updatedAt: DateTime.now()))
                        .name;

                    return Card(
                      child: ListTile(
                        title: Text(d.title,
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('$deptName • ${d.description}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined),
                              onPressed: () =>
                                  _showDesigForm(context, ref, depts, d),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline,
                                  color: Colors.red),
                              onPressed: () => _deleteDesig(context, ref, d.id),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          )
        ],
      ),
    );
  }

  void _showDesigForm(BuildContext context, WidgetRef ref,
      List<DepartmentEntity> depts, DesignationEntity? desig) {
    showDialog<void>(
      context: context,
      builder: (context) => DesignationDialog(depts: depts, desig: desig),
    );
  }

  void _deleteDesig(BuildContext context, WidgetRef ref, String desigId) async {
    final ok = await ref
        .read(hrSettingsControllerProvider.notifier)
        .deleteDesignation(desigId);
    if (context.mounted && ok) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Designation soft-deleted')));
    }
  }
}

class DesignationDialog extends ConsumerStatefulWidget {
  final List<DepartmentEntity> depts;
  final DesignationEntity? desig;

  const DesignationDialog({super.key, required this.depts, this.desig});

  @override
  ConsumerState<DesignationDialog> createState() => _DesignationDialogState();
}

class _DesignationDialogState extends ConsumerState<DesignationDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  String? _selectedDeptId;

  @override
  void initState() {
    super.initState();
    if (widget.desig != null) {
      _titleController.text = widget.desig!.title;
      _descController.text = widget.desig!.description;
      _selectedDeptId = widget.desig!.departmentId;
    } else if (widget.depts.isNotEmpty) {
      _selectedDeptId = widget.depts.first.id;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title:
          Text(widget.desig == null ? 'Add Designation' : 'Edit Designation'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                  labelText: 'Title', border: OutlineInputBorder()),
              validator: (val) =>
                  val == null || val.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descController,
              decoration: const InputDecoration(
                  labelText: 'Description', border: OutlineInputBorder()),
              validator: (val) =>
                  val == null || val.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedDeptId,
              decoration: const InputDecoration(
                  labelText: 'Department', border: OutlineInputBorder()),
              items: widget.depts
                  .map(
                      (d) => DropdownMenuItem(value: d.id, child: Text(d.name)))
                  .toList(),
              validator: (val) => val == null ? 'Required' : null,
              onChanged: (val) => setState(() => _selectedDeptId = val),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () async {
            if (_formKey.currentState?.validate() ?? false) {
              final d = (widget.desig ??
                      DesignationEntity(
                        id: '',
                        companyId: '',
                        title: '',
                        description: '',
                        departmentId: '',
                        createdAt: DateTime.now(),
                        updatedAt: DateTime.now(),
                      ))
                  .copyWith(
                title: _titleController.text.trim(),
                description: _descController.text.trim(),
                departmentId: _selectedDeptId!,
              );

              final ok = await ref
                  .read(hrSettingsControllerProvider.notifier)
                  .saveDesignation(d);
              if (context.mounted && ok) {
                Navigator.of(context).pop();
              }
            }
          },
          child: const Text('Save'),
        )
      ],
    );
  }
}

// ---------------- SHIFTS TAB ----------------
class _ShiftsTab extends ConsumerWidget {
  final AsyncValue<List<ShiftEntity>> shiftsAsync;

  const _ShiftsTab({required this.shiftsAsync});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Shift Schedules', style: theme.textTheme.titleMedium),
              ElevatedButton.icon(
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add Shift'),
                onPressed: () => _showShiftForm(context, ref, null),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: shiftsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Error: $err')),
              data: (shifts) {
                if (shifts.isEmpty) {
                  return const Center(child: Text('No shifts configured.'));
                }
                return ListView.builder(
                  itemCount: shifts.length,
                  itemBuilder: (context, index) {
                    final s = shifts[index];
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: colorScheme.primaryContainer,
                          child: Icon(Icons.schedule,
                              color: colorScheme.onPrimaryContainer),
                        ),
                        title: Text(s.name,
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('Hours: ${s.startTime} - ${s.endTime}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined),
                              onPressed: () => _showShiftForm(context, ref, s),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline,
                                  color: Colors.red),
                              onPressed: () => _deleteShift(context, ref, s.id),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          )
        ],
      ),
    );
  }

  void _showShiftForm(BuildContext context, WidgetRef ref, ShiftEntity? shift) {
    showDialog<void>(
      context: context,
      builder: (context) => ShiftDialog(shift: shift),
    );
  }

  void _deleteShift(BuildContext context, WidgetRef ref, String shiftId) async {
    final ok = await ref
        .read(hrSettingsControllerProvider.notifier)
        .deleteShift(shiftId);
    if (context.mounted && ok) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Shift deleted')));
    }
  }
}

class ShiftDialog extends ConsumerStatefulWidget {
  final ShiftEntity? shift;

  const ShiftDialog({super.key, this.shift});

  @override
  ConsumerState<ShiftDialog> createState() => _ShiftDialogState();
}

class _ShiftDialogState extends ConsumerState<ShiftDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _startController = TextEditingController();
  final _endController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.shift != null) {
      _nameController.text = widget.shift!.name;
      _startController.text = widget.shift!.startTime;
      _endController.text = widget.shift!.endTime;
    } else {
      _startController.text = '09:00';
      _endController.text = '17:00';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _startController.dispose();
    _endController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.shift == null ? 'Add Shift' : 'Edit Shift'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                  labelText: 'Shift Name', border: OutlineInputBorder()),
              validator: (val) =>
                  val == null || val.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _startController,
              decoration: const InputDecoration(
                  labelText: 'Start Time (e.g. 09:00)',
                  border: OutlineInputBorder()),
              validator: (val) =>
                  val == null || val.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _endController,
              decoration: const InputDecoration(
                  labelText: 'End Time (e.g. 17:00)',
                  border: OutlineInputBorder()),
              validator: (val) =>
                  val == null || val.isEmpty ? 'Required' : null,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () async {
            if (_formKey.currentState?.validate() ?? false) {
              final s = (widget.shift ??
                      ShiftEntity(
                        id: '',
                        companyId: '',
                        name: '',
                        startTime: '',
                        endTime: '',
                        createdAt: DateTime.now(),
                        updatedAt: DateTime.now(),
                      ))
                  .copyWith(
                name: _nameController.text.trim(),
                startTime: _startController.text.trim(),
                endTime: _endController.text.trim(),
              );

              final ok = await ref
                  .read(hrSettingsControllerProvider.notifier)
                  .saveShift(s);
              if (context.mounted && ok) {
                Navigator.of(context).pop();
              }
            }
          },
          child: const Text('Save'),
        )
      ],
    );
  }
}
