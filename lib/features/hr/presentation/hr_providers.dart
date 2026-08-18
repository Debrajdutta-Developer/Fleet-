import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../../auth/presentation/auth_providers.dart';
import '../domain/employee_entity.dart';
import '../domain/department_entity.dart';
import '../domain/designation_entity.dart';
import '../domain/attendance_entity.dart';
import '../domain/shift_entity.dart';
import '../domain/leave_entity.dart';
import '../domain/payroll_entity.dart';
import '../domain/hr_repository.dart';
import '../data/hr_repository_impl.dart';
import '../../trips/domain/audit_log_entity.dart';
import '../../drivers/presentation/driver_providers.dart';

final hrRepositoryProvider = Provider<HrRepository>((ref) {
  return HrRepositoryImpl();
});

// Stream Providers
final employeesStreamProvider =
    StreamProvider.autoDispose<List<EmployeeEntity>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user?.companyId == null) return Stream.value([]);
  return ref.watch(hrRepositoryProvider).watchEmployees(user!.companyId!);
});

final departmentsStreamProvider =
    StreamProvider.autoDispose<List<DepartmentEntity>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user?.companyId == null) return Stream.value([]);
  return ref.watch(hrRepositoryProvider).watchDepartments(user!.companyId!);
});

final designationsStreamProvider =
    StreamProvider.autoDispose<List<DesignationEntity>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user?.companyId == null) return Stream.value([]);
  return ref.watch(hrRepositoryProvider).watchDesignations(user!.companyId!);
});

final attendanceStreamProvider = StreamProvider.autoDispose
    .family<List<AttendanceEntity>, DateTime>((ref, date) {
  final user = ref.watch(currentUserProvider);
  if (user?.companyId == null) return Stream.value([]);
  return ref
      .watch(hrRepositoryProvider)
      .watchAttendance(user!.companyId!, date: date);
});

final shiftsStreamProvider =
    StreamProvider.autoDispose<List<ShiftEntity>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user?.companyId == null) return Stream.value([]);
  return ref.watch(hrRepositoryProvider).watchShifts(user!.companyId!);
});

final leavesStreamProvider =
    StreamProvider.autoDispose<List<LeaveEntity>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user?.companyId == null) return Stream.value([]);
  return ref.watch(hrRepositoryProvider).watchLeaves(user!.companyId!);
});

final payrollStreamProvider = StreamProvider.autoDispose
    .family<List<PayrollEntity>, String>((ref, monthYear) {
  final user = ref.watch(currentUserProvider);
  if (user?.companyId == null) return Stream.value([]);
  final parts = monthYear.split('_');
  final month = int.tryParse(parts[0]) ?? 1;
  final year = int.tryParse(parts[1]) ?? 2026;
  return ref
      .watch(hrRepositoryProvider)
      .watchPayroll(user!.companyId!, month, year);
});

// Notifier States & Controllers
class HrFormState {
  final bool isLoading;
  final String? errorMessage;
  final bool isSuccess;

  const HrFormState({
    this.isLoading = false,
    this.errorMessage,
    this.isSuccess = false,
  });

  HrFormState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool? isSuccess,
  }) {
    return HrFormState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }
}

// Helper to write Audit Logs for HR events
Future<void> _writeHrAuditLog(
  Ref ref, {
  required String entityType,
  required String entityId,
  required String action,
  required String description,
}) async {
  try {
    final user = ref.read(currentUserProvider);
    if (user == null || user.companyId == null) return;
    final companyId = user.companyId!;
    final auditLog = AuditLogEntity(
      id: const Uuid().v4(),
      companyId: companyId,
      entityType: entityType,
      entityId: entityId,
      action: action,
      description: description,
      userId: user.uid,
      userName: user.displayName,
      timestamp: DateTime.now(),
    );
    await FirebaseFirestore.instance
        .collection('companies')
        .doc(companyId)
        .collection('audit_logs')
        .doc(auditLog.id)
        .set(auditLog.toMap());
  } catch (_) {}
}

// Employee Controller
class EmployeeFormController extends StateNotifier<HrFormState> {
  final HrRepository _repo;
  final Ref _ref;

  EmployeeFormController(this._repo, this._ref) : super(const HrFormState());

  Future<bool> saveEmployee(EmployeeEntity employee) async {
    state =
        state.copyWith(isLoading: true, errorMessage: null, isSuccess: false);
    try {
      final user = _ref.read(currentUserProvider);
      if (user?.companyId == null)
        throw Exception('No authenticated company context.');
      final companyId = user!.companyId!;

      EmployeeEntity saved;
      if (employee.id.isEmpty) {
        saved = await _repo.createEmployee(
            companyId, employee.copyWith(companyId: companyId));
        await _writeHrAuditLog(
          _ref,
          entityType: 'employee',
          entityId: saved.id,
          action: 'employee_created',
          description:
              'Employee ${saved.fullName} created under role: ${saved.role}',
        );
      } else {
        await _repo.updateEmployee(companyId, employee);
        saved = employee;
        await _writeHrAuditLog(
          _ref,
          entityType: 'employee',
          entityId: saved.id,
          action: 'employee_updated',
          description: 'Employee ${saved.fullName} updated details.',
        );
      }

      // Link driver to employee record automatically if role is driver
      if (saved.role == 'driver') {
        try {
          final driverRepo = _ref.read(driverRepositoryProvider);
          final drivers = await driverRepo.getDrivers(companyId);
          final matches = drivers
              .where(
                  (d) => d.phone == saved.phone || d.fullName == saved.fullName)
              .toList();
          for (final d in matches) {
            if (d.employeeId != saved.id) {
              await driverRepo.updateDriver(
                  companyId, d.copyWith(employeeId: saved.id));
            }
          }
        } catch (_) {}
      }

      state = state.copyWith(isLoading: false, isSuccess: true);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> deleteEmployee(String employeeId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final user = _ref.read(currentUserProvider);
      if (user?.companyId == null)
        throw Exception('No authenticated company context.');
      await _repo.deleteEmployee(user!.companyId!, employeeId);
      await _writeHrAuditLog(
        _ref,
        entityType: 'employee',
        entityId: employeeId,
        action: 'employee_deleted',
        description: 'Employee terminated and soft-deleted.',
      );
      state = state.copyWith(isLoading: false, isSuccess: true);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }
}

final employeeFormControllerProvider =
    StateNotifierProvider.autoDispose<EmployeeFormController, HrFormState>(
        (ref) {
  return EmployeeFormController(ref.watch(hrRepositoryProvider), ref);
});

// Leave Controller
class LeaveFormController extends StateNotifier<HrFormState> {
  final HrRepository _repo;
  final Ref _ref;

  LeaveFormController(this._repo, this._ref) : super(const HrFormState());

  Future<bool> requestLeave(LeaveEntity leave) async {
    state =
        state.copyWith(isLoading: true, errorMessage: null, isSuccess: false);
    try {
      final user = _ref.read(currentUserProvider);
      if (user?.companyId == null)
        throw Exception('No authenticated company context.');
      final companyId = user!.companyId!;

      final saved = await _repo.createLeave(
          companyId, leave.copyWith(companyId: companyId, status: 'pending'));
      await _writeHrAuditLog(
        _ref,
        entityType: 'leave',
        entityId: saved.id,
        action: 'leave_requested',
        description:
            'Leave of type ${saved.leaveType} requested for Employee ${saved.employeeId}.',
      );
      state = state.copyWith(isLoading: false, isSuccess: true);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> updateLeaveStatus(LeaveEntity leave, String status) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final user = _ref.read(currentUserProvider);
      if (user?.companyId == null)
        throw Exception('No authenticated company context.');
      final updated = leave.copyWith(status: status, approvedById: user!.uid);
      await _repo.updateLeave(user.companyId!, updated);
      await _writeHrAuditLog(
        _ref,
        entityType: 'leave',
        entityId: leave.id,
        action: 'leave_status_updated',
        description: 'Leave request was $status.',
      );
      state = state.copyWith(isLoading: false, isSuccess: true);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }
}

final leaveFormControllerProvider =
    StateNotifierProvider.autoDispose<LeaveFormController, HrFormState>((ref) {
  return LeaveFormController(ref.watch(hrRepositoryProvider), ref);
});

// Payroll Controller
class PayrollFormController extends StateNotifier<HrFormState> {
  final HrRepository _repo;
  final Ref _ref;

  PayrollFormController(this._repo, this._ref) : super(const HrFormState());

  Future<bool> prepareMonthlyPayroll(int month, int year) async {
    state =
        state.copyWith(isLoading: true, errorMessage: null, isSuccess: false);
    try {
      final user = _ref.read(currentUserProvider);
      if (user?.companyId == null)
        throw Exception('No authenticated company context.');
      await _repo.preparePayroll(user!.companyId!, month, year);
      await _writeHrAuditLog(
        _ref,
        entityType: 'payroll',
        entityId: '${month}_$year',
        action: 'payroll_prepared',
        description: 'Monthly payroll draft processed for $month/$year.',
      );
      state = state.copyWith(isLoading: false, isSuccess: true);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> processPayout(PayrollEntity payroll, String referenceId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final user = _ref.read(currentUserProvider);
      if (user?.companyId == null)
        throw Exception('No authenticated company context.');
      final updated = payroll.copyWith(
        status: 'paid',
        paidAt: DateTime.now(),
        referenceId: referenceId,
      );
      await _repo.savePayroll(user!.companyId!, updated);
      await _writeHrAuditLog(
        _ref,
        entityType: 'payroll',
        entityId: payroll.id,
        action: 'payroll_payout_completed',
        description:
            'Payroll paid to ${payroll.employeeName} with reference: $referenceId.',
      );
      state = state.copyWith(isLoading: false, isSuccess: true);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }
}

final payrollFormControllerProvider =
    StateNotifierProvider.autoDispose<PayrollFormController, HrFormState>(
        (ref) {
  return PayrollFormController(ref.watch(hrRepositoryProvider), ref);
});

// Settings / Config Controller (Departments, Designations, Shifts)
class HrSettingsController extends StateNotifier<HrFormState> {
  final HrRepository _repo;
  final Ref _ref;

  HrSettingsController(this._repo, this._ref) : super(const HrFormState());

  // Department
  Future<bool> saveDepartment(DepartmentEntity dept) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final user = _ref.read(currentUserProvider);
      if (user?.companyId == null)
        throw Exception('No authenticated company context.');
      final companyId = user!.companyId!;
      if (dept.id.isEmpty) {
        await _repo.createDepartment(
            companyId, dept.copyWith(companyId: companyId));
      } else {
        await _repo.updateDepartment(companyId, dept);
      }
      state = state.copyWith(isLoading: false, isSuccess: true);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> deleteDepartment(String deptId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final user = _ref.read(currentUserProvider);
      if (user?.companyId == null)
        throw Exception('No authenticated company context.');
      await _repo.deleteDepartment(user!.companyId!, deptId);
      state = state.copyWith(isLoading: false, isSuccess: true);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  // Designation
  Future<bool> saveDesignation(DesignationEntity desig) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final user = _ref.read(currentUserProvider);
      if (user?.companyId == null)
        throw Exception('No authenticated company context.');
      final companyId = user!.companyId!;
      if (desig.id.isEmpty) {
        await _repo.createDesignation(
            companyId, desig.copyWith(companyId: companyId));
      } else {
        await _repo.updateDesignation(companyId, desig);
      }
      state = state.copyWith(isLoading: false, isSuccess: true);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> deleteDesignation(String desigId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final user = _ref.read(currentUserProvider);
      if (user?.companyId == null)
        throw Exception('No authenticated company context.');
      await _repo.deleteDesignation(user!.companyId!, desigId);
      state = state.copyWith(isLoading: false, isSuccess: true);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  // Shift
  Future<bool> saveShift(ShiftEntity shift) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final user = _ref.read(currentUserProvider);
      if (user?.companyId == null)
        throw Exception('No authenticated company context.');
      final companyId = user!.companyId!;
      if (shift.id.isEmpty) {
        await _repo.createShift(
            companyId, shift.copyWith(companyId: companyId));
      } else {
        await _repo.updateShift(companyId, shift);
      }
      state = state.copyWith(isLoading: false, isSuccess: true);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> deleteShift(String shiftId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final user = _ref.read(currentUserProvider);
      if (user?.companyId == null)
        throw Exception('No authenticated company context.');
      await _repo.deleteShift(user!.companyId!, shiftId);
      state = state.copyWith(isLoading: false, isSuccess: true);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }
}

final hrSettingsControllerProvider =
    StateNotifierProvider.autoDispose<HrSettingsController, HrFormState>((ref) {
  return HrSettingsController(ref.watch(hrRepositoryProvider), ref);
});

// Attendance clocking controller
class AttendanceClockController extends StateNotifier<HrFormState> {
  final HrRepository _repo;
  final Ref _ref;

  AttendanceClockController(this._repo, this._ref) : super(const HrFormState());

  Future<bool> clockIn(String employeeId) async {
    state =
        state.copyWith(isLoading: true, errorMessage: null, isSuccess: false);
    try {
      final user = _ref.read(currentUserProvider);
      if (user?.companyId == null)
        throw Exception('No authenticated company context.');
      final companyId = user!.companyId!;

      final now = DateTime.now();
      // Check if attendance already exists for YYYY-MM-DD
      final todayDate = DateTime(now.year, now.month, now.day);
      final existing = await _repo.getAttendance(companyId, date: todayDate);
      final empAttendance = existing.where((a) => a.employeeId == employeeId);

      if (empAttendance.isNotEmpty) {
        throw Exception('Employee is already clocked in or recorded today.');
      }

      final attendance = AttendanceEntity(
        id: '',
        companyId: companyId,
        employeeId: employeeId,
        date: todayDate,
        checkIn: now,
        status: now.hour >= 10
            ? 'late'
            : 'present', // Late if clocks in after 10 AM
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _repo.saveAttendance(companyId, attendance);
      await _writeHrAuditLog(
        _ref,
        entityType: 'attendance',
        entityId: employeeId,
        action: 'employee_clock_in',
        description: 'Employee checked in today at ${now.toIso8601String()}.',
      );
      state = state.copyWith(isLoading: false, isSuccess: true);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> clockOut(String employeeId) async {
    state =
        state.copyWith(isLoading: true, errorMessage: null, isSuccess: false);
    try {
      final user = _ref.read(currentUserProvider);
      if (user?.companyId == null)
        throw Exception('No authenticated company context.');
      final companyId = user!.companyId!;

      final now = DateTime.now();
      final todayDate = DateTime(now.year, now.month, now.day);
      final existing = await _repo.getAttendance(companyId, date: todayDate);
      final empAttendanceList =
          existing.where((a) => a.employeeId == employeeId).toList();

      if (empAttendanceList.isEmpty) {
        throw Exception('No clock-in record found for today.');
      }

      final record = empAttendanceList.first;
      if (record.checkOut != null) {
        throw Exception('Employee has already clocked out today.');
      }

      final diffMinutes = now.difference(record.checkIn!).inMinutes;

      final updated = record.copyWith(
        checkOut: now,
        durationMinutes: diffMinutes,
        updatedAt: DateTime.now(),
      );

      await _repo.saveAttendance(companyId, updated);
      await _writeHrAuditLog(
        _ref,
        entityType: 'attendance',
        entityId: employeeId,
        action: 'employee_clock_out',
        description:
            'Employee checked out today. Duration: $diffMinutes minutes.',
      );
      state = state.copyWith(isLoading: false, isSuccess: true);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }
}

final attendanceClockControllerProvider =
    StateNotifierProvider.autoDispose<AttendanceClockController, HrFormState>(
        (ref) {
  return AttendanceClockController(ref.watch(hrRepositoryProvider), ref);
});
