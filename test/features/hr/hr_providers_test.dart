import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fleet_os_erp/features/auth/presentation/auth_providers.dart';
import 'package:fleet_os_erp/features/auth/domain/user_entity.dart';
import 'package:fleet_os_erp/features/hr/domain/employee_entity.dart';
import 'package:fleet_os_erp/features/hr/domain/department_entity.dart';
import 'package:fleet_os_erp/features/hr/domain/designation_entity.dart';
import 'package:fleet_os_erp/features/hr/domain/attendance_entity.dart';
import 'package:fleet_os_erp/features/hr/domain/shift_entity.dart';
import 'package:fleet_os_erp/features/hr/domain/leave_entity.dart';
import 'package:fleet_os_erp/features/hr/domain/payroll_entity.dart';
import 'package:fleet_os_erp/features/hr/domain/hr_repository.dart';
import 'package:fleet_os_erp/features/hr/presentation/hr_providers.dart';

class MockHrRepository implements HrRepository {
  final List<EmployeeEntity> employees = [];
  final List<DepartmentEntity> departments = [];
  final List<DesignationEntity> designations = [];
  final List<AttendanceEntity> attendanceLogs = [];
  final List<ShiftEntity> shifts = [];
  final List<LeaveEntity> leaves = [];
  final List<PayrollEntity> payrolls = [];

  @override
  Stream<List<EmployeeEntity>> watchEmployees(String companyId) =>
      Stream.value(employees);

  @override
  Future<List<EmployeeEntity>> getEmployees(String companyId) async =>
      employees;

  @override
  Future<EmployeeEntity?> getEmployeeById(
      String companyId, String employeeId) async {
    final list = employees.where((e) => e.id == employeeId).toList();
    return list.isNotEmpty ? list.first : null;
  }

  @override
  Future<EmployeeEntity> createEmployee(
      String companyId, EmployeeEntity employee) async {
    final emp = employee.id.isEmpty
        ? employee.copyWith(id: 'emp_${employees.length + 1}')
        : employee;
    employees.add(emp);
    return emp;
  }

  @override
  Future<void> updateEmployee(String companyId, EmployeeEntity employee) async {
    final idx = employees.indexWhere((e) => e.id == employee.id);
    if (idx != -1) {
      employees[idx] = employee;
    }
  }

  @override
  Future<void> deleteEmployee(String companyId, String employeeId) async {
    final idx = employees.indexWhere((e) => e.id == employeeId);
    if (idx != -1) {
      employees[idx] = employees[idx]
          .copyWith(deletedAt: DateTime.now(), status: 'terminated');
    }
  }

  @override
  Stream<List<DepartmentEntity>> watchDepartments(String companyId) =>
      Stream.value(departments);

  @override
  Future<List<DepartmentEntity>> getDepartments(String companyId) async =>
      departments;

  @override
  Future<DepartmentEntity> createDepartment(
      String companyId, DepartmentEntity dept) async {
    final d = dept.id.isEmpty
        ? dept.copyWith(id: 'dept_${departments.length + 1}')
        : dept;
    departments.add(d);
    return d;
  }

  @override
  Future<void> updateDepartment(String companyId, DepartmentEntity dept) async {
    final idx = departments.indexWhere((d) => d.id == dept.id);
    if (idx != -1) {
      departments[idx] = dept;
    }
  }

  @override
  Future<void> deleteDepartment(String companyId, String deptId) async {
    departments.removeWhere((d) => d.id == deptId);
  }

  @override
  Stream<List<DesignationEntity>> watchDesignations(String companyId) =>
      Stream.value(designations);

  @override
  Future<List<DesignationEntity>> getDesignations(String companyId) async =>
      designations;

  @override
  Future<DesignationEntity> createDesignation(
      String companyId, DesignationEntity desig) async {
    final d = desig.id.isEmpty
        ? desig.copyWith(id: 'desig_${designations.length + 1}')
        : desig;
    designations.add(d);
    return d;
  }

  @override
  Future<void> updateDesignation(
      String companyId, DesignationEntity desig) async {
    final idx = designations.indexWhere((d) => d.id == desig.id);
    if (idx != -1) {
      designations[idx] = desig;
    }
  }

  @override
  Future<void> deleteDesignation(String companyId, String desigId) async {
    designations.removeWhere((d) => d.id == desigId);
  }

  @override
  Stream<List<AttendanceEntity>> watchAttendance(String companyId,
          {DateTime? date}) =>
      Stream.value(attendanceLogs);

  @override
  Future<List<AttendanceEntity>> getAttendance(String companyId,
          {DateTime? date}) async =>
      attendanceLogs;

  @override
  Future<AttendanceEntity> saveAttendance(
      String companyId, AttendanceEntity attendance) async {
    final a = attendance.id.isEmpty
        ? attendance.copyWith(id: 'att_${attendanceLogs.length + 1}')
        : attendance;
    final idx = attendanceLogs.indexWhere((x) => x.id == a.id);
    if (idx != -1) {
      attendanceLogs[idx] = a;
    } else {
      attendanceLogs.add(a);
    }
    return a;
  }

  @override
  Stream<List<ShiftEntity>> watchShifts(String companyId) =>
      Stream.value(shifts);

  @override
  Future<List<ShiftEntity>> getShifts(String companyId) async => shifts;

  @override
  Future<ShiftEntity> createShift(String companyId, ShiftEntity shift) async {
    final s = shift.id.isEmpty
        ? shift.copyWith(id: 'shift_${shifts.length + 1}')
        : shift;
    shifts.add(s);
    return s;
  }

  @override
  Future<void> updateShift(String companyId, ShiftEntity shift) async {
    final idx = shifts.indexWhere((s) => s.id == shift.id);
    if (idx != -1) {
      shifts[idx] = shift;
    }
  }

  @override
  Future<void> deleteShift(String companyId, String shiftId) async {
    shifts.removeWhere((s) => s.id == shiftId);
  }

  @override
  Stream<List<LeaveEntity>> watchLeaves(String companyId) =>
      Stream.value(leaves);

  @override
  Future<List<LeaveEntity>> getLeaves(String companyId) async => leaves;

  @override
  Future<LeaveEntity> createLeave(String companyId, LeaveEntity leave) async {
    final l = leave.id.isEmpty
        ? leave.copyWith(id: 'leave_${leaves.length + 1}')
        : leave;
    leaves.add(l);
    return l;
  }

  @override
  Future<void> updateLeave(String companyId, LeaveEntity leave) async {
    final idx = leaves.indexWhere((l) => l.id == leave.id);
    if (idx != -1) {
      leaves[idx] = leave;
    }
  }

  @override
  Stream<List<PayrollEntity>> watchPayroll(
          String companyId, int month, int year) =>
      Stream.value(
          payrolls.where((p) => p.month == month && p.year == year).toList());

  @override
  Future<List<PayrollEntity>> getPayroll(
          String companyId, int month, int year) async =>
      payrolls.where((p) => p.month == month && p.year == year).toList();

  @override
  Future<PayrollEntity> savePayroll(
      String companyId, PayrollEntity payroll) async {
    final p = payroll.id.isEmpty
        ? payroll.copyWith(id: 'pr_${payrolls.length + 1}')
        : payroll;
    final idx = payrolls.indexWhere((x) => x.id == p.id);
    if (idx != -1) {
      payrolls[idx] = p;
    } else {
      payrolls.add(p);
    }
    return p;
  }

  @override
  Future<void> preparePayroll(String companyId, int month, int year) async {
    for (final emp in employees) {
      final absences = attendanceLogs
          .where((a) =>
              a.employeeId == emp.id &&
              a.date.month == month &&
              a.date.year == year &&
              a.status == 'absent')
          .length;

      final dailyRate = emp.baseSalary / 30.0;
      final attendanceDeduction = absences * dailyRate;
      final totalDeduction = emp.deductions + attendanceDeduction;

      final netSalary = emp.baseSalary + emp.allowance - totalDeduction;

      final p = PayrollEntity(
        id: 'pr_${emp.id}_${year}_$month',
        companyId: companyId,
        employeeId: emp.id,
        employeeName: emp.fullName,
        month: month,
        year: year,
        baseSalary: emp.baseSalary,
        allowances: emp.allowance,
        deductions: totalDeduction,
        netSalary: netSalary < 0 ? 0.0 : netSalary,
        status: 'draft',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      payrolls.add(p);
    }
  }
}

void main() {
  late ProviderContainer container;
  late MockHrRepository mockRepo;

  setUp(() {
    mockRepo = MockHrRepository();
    container = ProviderContainer(
      overrides: [
        hrRepositoryProvider.overrideWithValue(mockRepo),
        currentUserProvider.overrideWith(
          (ref) => UserEntity(
            uid: 'u_1',
            email: 'admin@fleetos.com',
            displayName: 'Admin User',
            role: 'admin',
            companyId: 'comp_1',
            createdAt: DateTime.now(),
          ),
        ),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('HR Employees Management Tests', () {
    test('Create Employee Form saves successfully', () async {
      final notifier = container.read(employeeFormControllerProvider.notifier);
      final newEmp = EmployeeEntity(
        id: '',
        companyId: 'comp_1',
        firstName: 'John',
        lastName: 'Doe',
        email: 'john@fleetos.com',
        phone: '1234567890',
        status: 'active',
        role: 'driver',
        baseSalary: 3000.0,
        allowance: 200.0,
        deductions: 50.0,
        hiredAt: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final ok = await notifier.saveEmployee(newEmp);
      expect(ok, true);
      expect(mockRepo.employees.length, 1);
      expect(mockRepo.employees.first.fullName, 'John Doe');
      expect(mockRepo.employees.first.id.isNotEmpty, true);
    });

    test('Update Employee details successfully', () async {
      final notifier = container.read(employeeFormControllerProvider.notifier);
      final emp = EmployeeEntity(
        id: 'emp_1',
        companyId: 'comp_1',
        firstName: 'Jane',
        lastName: 'Doe',
        email: 'jane@fleetos.com',
        phone: '1234567890',
        status: 'active',
        role: 'manager',
        baseSalary: 5000.0,
        allowance: 500.0,
        deductions: 100.0,
        hiredAt: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      mockRepo.employees.add(emp);

      final updated = emp.copyWith(lastName: 'Smith', baseSalary: 5500.0);
      final ok = await notifier.saveEmployee(updated);
      expect(ok, true);
      expect(mockRepo.employees.first.fullName, 'Jane Smith');
      expect(mockRepo.employees.first.baseSalary, 5500.0);
    });

    test('Delete / Terminate Employee soft deletes successfully', () async {
      final notifier = container.read(employeeFormControllerProvider.notifier);
      final emp = EmployeeEntity(
        id: 'emp_1',
        companyId: 'comp_1',
        firstName: 'Bob',
        lastName: 'Builder',
        email: 'bob@fleetos.com',
        phone: '1234567890',
        status: 'active',
        role: 'driver',
        baseSalary: 2500.0,
        allowance: 100.0,
        deductions: 0.0,
        hiredAt: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      mockRepo.employees.add(emp);

      final ok = await notifier.deleteEmployee('emp_1');
      expect(ok, true);
      expect(mockRepo.employees.first.status, 'terminated');
      expect(mockRepo.employees.first.deletedAt, isNotNull);
    });
  });

  group('HR Attendance & Payout Flow Tests', () {
    test('Clock In and Clock Out attendance successfully', () async {
      final clockNotifier =
          container.read(attendanceClockControllerProvider.notifier);

      // Clock in
      final inOk = await clockNotifier.clockIn('emp_1');
      expect(inOk, true);
      expect(mockRepo.attendanceLogs.length, 1);
      expect(mockRepo.attendanceLogs.first.employeeId, 'emp_1');
      expect(mockRepo.attendanceLogs.first.checkOut, isNull);

      // Clock out
      final outOk = await clockNotifier.clockOut('emp_1');
      expect(outOk, true);
      expect(mockRepo.attendanceLogs.first.checkOut, isNotNull);
      expect(mockRepo.attendanceLogs.first.durationMinutes, isNotNull);
    });

    test('Prepare payroll generates drafts factoring absences', () async {
      final payrollNotifier =
          container.read(payrollFormControllerProvider.notifier);

      final emp = EmployeeEntity(
        id: 'emp_1',
        companyId: 'comp_1',
        firstName: 'Alice',
        lastName: 'Wonder',
        email: 'alice@fleetos.com',
        phone: '1234567890',
        status: 'active',
        role: 'accountant',
        baseSalary: 3000.0,
        allowance: 300.0,
        deductions: 100.0,
        hiredAt: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      mockRepo.employees.add(emp);

      // Log 2 absences for Alice in July 2026
      mockRepo.attendanceLogs.add(AttendanceEntity(
        id: 'att_1',
        companyId: 'comp_1',
        employeeId: 'emp_1',
        date: DateTime(2026, 7, 5),
        status: 'absent',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));
      mockRepo.attendanceLogs.add(AttendanceEntity(
        id: 'att_2',
        companyId: 'comp_1',
        employeeId: 'emp_1',
        date: DateTime(2026, 7, 6),
        status: 'absent',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));

      final ok = await payrollNotifier.prepareMonthlyPayroll(7, 2026);
      expect(ok, true);
      expect(mockRepo.payrolls.length, 1);

      final payrollRecord = mockRepo.payrolls.first;
      expect(payrollRecord.employeeId, 'emp_1');
      expect(payrollRecord.baseSalary, 3000.0);

      // Absence deduction: 2 * (3000/30) = 200. Total deduction = 100 (default) + 200 = 300
      expect(payrollRecord.deductions, 300.0);
      // Net salary = 3000 + 300 (allowance) - 300 (deductions) = 3000.0
      expect(payrollRecord.netSalary, 3000.0);
    });

    test('Record payout with reference ID', () async {
      final payrollNotifier =
          container.read(payrollFormControllerProvider.notifier);
      final payrollLine = PayrollEntity(
        id: 'pr_emp_1_2026_7',
        companyId: 'comp_1',
        employeeId: 'emp_1',
        employeeName: 'Alice Wonder',
        month: 7,
        year: 2026,
        baseSalary: 3000.0,
        allowances: 300.0,
        deductions: 300.0,
        netSalary: 3000.0,
        status: 'draft',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      mockRepo.payrolls.add(payrollLine);

      final ok =
          await payrollNotifier.processPayout(payrollLine, 'TXN_REF_999');
      expect(ok, true);
      expect(mockRepo.payrolls.first.status, 'paid');
      expect(mockRepo.payrolls.first.referenceId, 'TXN_REF_999');
      expect(mockRepo.payrolls.first.paidAt, isNotNull);
    });
  });
}
