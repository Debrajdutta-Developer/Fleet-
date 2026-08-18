import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/errors/failure.dart';
import '../domain/employee_entity.dart';
import '../domain/department_entity.dart';
import '../domain/designation_entity.dart';
import '../domain/attendance_entity.dart';
import '../domain/shift_entity.dart';
import '../domain/leave_entity.dart';
import '../domain/payroll_entity.dart';
import '../domain/hr_repository.dart';

class HrRepositoryImpl implements HrRepository {
  final FirebaseFirestore _firestore;
  final Uuid _uuid;

  HrRepositoryImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _uuid = const Uuid();

  // Employees
  @override
  Stream<List<EmployeeEntity>> watchEmployees(String companyId) {
    return _firestore
        .collection('companies')
        .doc(companyId)
        .collection('employees')
        .where('deletedAt', isNull: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => EmployeeEntity.fromMap(doc.data()))
          .toList();
    });
  }

  @override
  Future<List<EmployeeEntity>> getEmployees(String companyId) async {
    try {
      final snapshot = await _firestore
          .collection('companies')
          .doc(companyId)
          .collection('employees')
          .where('deletedAt', isNull: true)
          .get();

      return snapshot.docs
          .map((doc) => EmployeeEntity.fromMap(doc.data()))
          .toList();
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  @override
  Future<EmployeeEntity?> getEmployeeById(
      String companyId, String employeeId) async {
    try {
      final doc = await _firestore
          .collection('companies')
          .doc(companyId)
          .collection('employees')
          .doc(employeeId)
          .get();

      if (!doc.exists) return null;
      final data = doc.data();
      if (data == null || data['deletedAt'] != null) return null;
      return EmployeeEntity.fromMap(data);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  @override
  Future<EmployeeEntity> createEmployee(
      String companyId, EmployeeEntity employee) async {
    try {
      final id = employee.id.isEmpty ? _uuid.v4() : employee.id;
      final newEmployee = employee.copyWith(
        id: id,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection('companies')
          .doc(companyId)
          .collection('employees')
          .doc(id)
          .set(newEmployee.toMap());

      return newEmployee;
    } on FirebaseException catch (e) {
      throw ServerFailure.fromFirebaseException(e.code, e.message);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  @override
  Future<void> updateEmployee(String companyId, EmployeeEntity employee) async {
    try {
      final updated = employee.copyWith(updatedAt: DateTime.now());
      await _firestore
          .collection('companies')
          .doc(companyId)
          .collection('employees')
          .doc(employee.id)
          .update(updated.toMap());
    } on FirebaseException catch (e) {
      throw ServerFailure.fromFirebaseException(e.code, e.message);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  @override
  Future<void> deleteEmployee(String companyId, String employeeId) async {
    try {
      await _firestore
          .collection('companies')
          .doc(companyId)
          .collection('employees')
          .doc(employeeId)
          .update({
        'deletedAt': DateTime.now().toIso8601String(),
        'status': 'terminated',
      });
    } on FirebaseException catch (e) {
      throw ServerFailure.fromFirebaseException(e.code, e.message);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  // Departments
  @override
  Stream<List<DepartmentEntity>> watchDepartments(String companyId) {
    return _firestore
        .collection('companies')
        .doc(companyId)
        .collection('departments')
        .where('deletedAt', isNull: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => DepartmentEntity.fromMap(doc.data()))
            .toList());
  }

  @override
  Future<List<DepartmentEntity>> getDepartments(String companyId) async {
    try {
      final snapshot = await _firestore
          .collection('companies')
          .doc(companyId)
          .collection('departments')
          .where('deletedAt', isNull: true)
          .get();
      return snapshot.docs
          .map((doc) => DepartmentEntity.fromMap(doc.data()))
          .toList();
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  @override
  Future<DepartmentEntity> createDepartment(
      String companyId, DepartmentEntity dept) async {
    try {
      final id = dept.id.isEmpty ? _uuid.v4() : dept.id;
      final newDept = dept.copyWith(
        id: id,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await _firestore
          .collection('companies')
          .doc(companyId)
          .collection('departments')
          .doc(id)
          .set(newDept.toMap());
      return newDept;
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  @override
  Future<void> updateDepartment(String companyId, DepartmentEntity dept) async {
    try {
      final updated = dept.copyWith(updatedAt: DateTime.now());
      await _firestore
          .collection('companies')
          .doc(companyId)
          .collection('departments')
          .doc(dept.id)
          .update(updated.toMap());
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  @override
  Future<void> deleteDepartment(String companyId, String deptId) async {
    try {
      await _firestore
          .collection('companies')
          .doc(companyId)
          .collection('departments')
          .doc(deptId)
          .update({
        'deletedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  // Designations
  @override
  Stream<List<DesignationEntity>> watchDesignations(String companyId) {
    return _firestore
        .collection('companies')
        .doc(companyId)
        .collection('designations')
        .where('deletedAt', isNull: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => DesignationEntity.fromMap(doc.data()))
            .toList());
  }

  @override
  Future<List<DesignationEntity>> getDesignations(String companyId) async {
    try {
      final snapshot = await _firestore
          .collection('companies')
          .doc(companyId)
          .collection('designations')
          .where('deletedAt', isNull: true)
          .get();
      return snapshot.docs
          .map((doc) => DesignationEntity.fromMap(doc.data()))
          .toList();
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  @override
  Future<DesignationEntity> createDesignation(
      String companyId, DesignationEntity desig) async {
    try {
      final id = desig.id.isEmpty ? _uuid.v4() : desig.id;
      final newDesig = desig.copyWith(
        id: id,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await _firestore
          .collection('companies')
          .doc(companyId)
          .collection('designations')
          .doc(id)
          .set(newDesig.toMap());
      return newDesig;
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  @override
  Future<void> updateDesignation(
      String companyId, DesignationEntity desig) async {
    try {
      final updated = desig.copyWith(updatedAt: DateTime.now());
      await _firestore
          .collection('companies')
          .doc(companyId)
          .collection('designations')
          .doc(desig.id)
          .update(updated.toMap());
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  @override
  Future<void> deleteDesignation(String companyId, String desigId) async {
    try {
      await _firestore
          .collection('companies')
          .doc(companyId)
          .collection('designations')
          .doc(desigId)
          .update({
        'deletedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  // Attendance
  @override
  Stream<List<AttendanceEntity>> watchAttendance(String companyId,
      {DateTime? date}) {
    var query = _firestore
        .collection('companies')
        .doc(companyId)
        .collection('attendance');

    if (date != null) {
      final start = DateTime(date.year, date.month, date.day);
      final end = DateTime(date.year, date.month, date.day, 23, 59, 59);
      query = query
              .where('date', isGreaterThanOrEqualTo: start.toIso8601String())
              .where('date', isLessThanOrEqualTo: end.toIso8601String())
          as CollectionReference<Map<String, dynamic>>;
    }

    return query.snapshots().map((snapshot) => snapshot.docs
        .map((doc) => AttendanceEntity.fromMap(doc.data()))
        .toList());
  }

  @override
  Future<List<AttendanceEntity>> getAttendance(String companyId,
      {DateTime? date}) async {
    try {
      var query = _firestore
          .collection('companies')
          .doc(companyId)
          .collection('attendance');

      if (date != null) {
        final start = DateTime(date.year, date.month, date.day);
        final end = DateTime(date.year, date.month, date.day, 23, 59, 59);
        final snapshot = await query
            .where('date', isGreaterThanOrEqualTo: start.toIso8601String())
            .where('date', isLessThanOrEqualTo: end.toIso8601String())
            .get();
        return snapshot.docs
            .map((doc) => AttendanceEntity.fromMap(doc.data()))
            .toList();
      }

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => AttendanceEntity.fromMap(doc.data()))
          .toList();
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  @override
  Future<AttendanceEntity> saveAttendance(
      String companyId, AttendanceEntity attendance) async {
    try {
      final id = attendance.id.isEmpty ? _uuid.v4() : attendance.id;
      final saved = attendance.copyWith(
        id: id,
        createdAt: attendance.createdAt,
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection('companies')
          .doc(companyId)
          .collection('attendance')
          .doc(id)
          .set(saved.toMap());

      return saved;
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  // Shifts
  @override
  Stream<List<ShiftEntity>> watchShifts(String companyId) {
    return _firestore
        .collection('companies')
        .doc(companyId)
        .collection('shifts')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ShiftEntity.fromMap(doc.data()))
            .toList());
  }

  @override
  Future<List<ShiftEntity>> getShifts(String companyId) async {
    try {
      final snapshot = await _firestore
          .collection('companies')
          .doc(companyId)
          .collection('shifts')
          .get();
      return snapshot.docs
          .map((doc) => ShiftEntity.fromMap(doc.data()))
          .toList();
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  @override
  Future<ShiftEntity> createShift(String companyId, ShiftEntity shift) async {
    try {
      final id = shift.id.isEmpty ? _uuid.v4() : shift.id;
      final newShift = shift.copyWith(
        id: id,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await _firestore
          .collection('companies')
          .doc(companyId)
          .collection('shifts')
          .doc(id)
          .set(newShift.toMap());
      return newShift;
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  @override
  Future<void> updateShift(String companyId, ShiftEntity shift) async {
    try {
      final updated = shift.copyWith(updatedAt: DateTime.now());
      await _firestore
          .collection('companies')
          .doc(companyId)
          .collection('shifts')
          .doc(shift.id)
          .update(updated.toMap());
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  @override
  Future<void> deleteShift(String companyId, String shiftId) async {
    try {
      await _firestore
          .collection('companies')
          .doc(companyId)
          .collection('shifts')
          .doc(shiftId)
          .delete();
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  // Leaves
  @override
  Stream<List<LeaveEntity>> watchLeaves(String companyId) {
    return _firestore
        .collection('companies')
        .doc(companyId)
        .collection('leaves')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => LeaveEntity.fromMap(doc.data()))
            .toList());
  }

  @override
  Future<List<LeaveEntity>> getLeaves(String companyId) async {
    try {
      final snapshot = await _firestore
          .collection('companies')
          .doc(companyId)
          .collection('leaves')
          .get();
      return snapshot.docs
          .map((doc) => LeaveEntity.fromMap(doc.data()))
          .toList();
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  @override
  Future<LeaveEntity> createLeave(String companyId, LeaveEntity leave) async {
    try {
      final id = leave.id.isEmpty ? _uuid.v4() : leave.id;
      final newLeave = leave.copyWith(
        id: id,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await _firestore
          .collection('companies')
          .doc(companyId)
          .collection('leaves')
          .doc(id)
          .set(newLeave.toMap());
      return newLeave;
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  @override
  Future<void> updateLeave(String companyId, LeaveEntity leave) async {
    try {
      final updated = leave.copyWith(updatedAt: DateTime.now());
      await _firestore
          .collection('companies')
          .doc(companyId)
          .collection('leaves')
          .doc(leave.id)
          .update(updated.toMap());
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  // Payroll
  @override
  Stream<List<PayrollEntity>> watchPayroll(
      String companyId, int month, int year) {
    return _firestore
        .collection('companies')
        .doc(companyId)
        .collection('payroll')
        .where('month', isEqualTo: month)
        .where('year', isEqualTo: year)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PayrollEntity.fromMap(doc.data()))
            .toList());
  }

  @override
  Future<List<PayrollEntity>> getPayroll(
      String companyId, int month, int year) async {
    try {
      final snapshot = await _firestore
          .collection('companies')
          .doc(companyId)
          .collection('payroll')
          .where('month', isEqualTo: month)
          .where('year', isEqualTo: year)
          .get();
      return snapshot.docs
          .map((doc) => PayrollEntity.fromMap(doc.data()))
          .toList();
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  @override
  Future<PayrollEntity> savePayroll(
      String companyId, PayrollEntity payroll) async {
    try {
      final id = payroll.id.isEmpty ? _uuid.v4() : payroll.id;
      final saved = payroll.copyWith(
        id: id,
        updatedAt: DateTime.now(),
      );
      await _firestore
          .collection('companies')
          .doc(companyId)
          .collection('payroll')
          .doc(id)
          .set(saved.toMap());
      return saved;
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  @override
  Future<void> preparePayroll(String companyId, int month, int year) async {
    try {
      // Execute within a transaction for data consistency
      await _firestore.runTransaction((transaction) async {
        final employeeSnapshot = await _firestore
            .collection('companies')
            .doc(companyId)
            .collection('employees')
            .where('deletedAt', isNull: true)
            .get();

        final employees = employeeSnapshot.docs
            .map((doc) => EmployeeEntity.fromMap(doc.data()))
            .toList();

        final attendanceSnapshot = await _firestore
            .collection('companies')
            .doc(companyId)
            .collection('attendance')
            .get();

        final attendance = attendanceSnapshot.docs
            .map((doc) => AttendanceEntity.fromMap(doc.data()))
            .toList();

        final leaveSnapshot = await _firestore
            .collection('companies')
            .doc(companyId)
            .collection('leaves')
            .where('status', isEqualTo: 'approved')
            .get();

        final approvedLeaves = leaveSnapshot.docs
            .map((doc) => LeaveEntity.fromMap(doc.data()))
            .toList();

        for (final emp in employees) {
          // Calculate attendance deductions
          // Get absent records in the target month/year
          final empAbsences = attendance
              .where((a) =>
                  a.employeeId == emp.id &&
                  a.date.month == month &&
                  a.date.year == year &&
                  a.status == 'absent')
              .length;

          // Get unpaid leave days in this month/year
          int unpaidLeaveDays = 0;
          final empUnpaidLeaves = approvedLeaves
              .where((l) => l.employeeId == emp.id && l.leaveType == 'unpaid');
          for (final l in empUnpaidLeaves) {
            final start = l.startDate.isBefore(DateTime(year, month, 1))
                ? DateTime(year, month, 1)
                : l.startDate;
            final lastDay = DateTime(year, month + 1, 0).day;
            final end = l.endDate.isAfter(DateTime(year, month, lastDay))
                ? DateTime(year, month, lastDay)
                : l.endDate;

            if (end.isAfter(start) || end.isAtSameMomentAs(start)) {
              unpaidLeaveDays += end.difference(start).inDays + 1;
            }
          }

          final totalUnpaidAbsences = empAbsences + unpaidLeaveDays;

          // Deduct daily rate for unpaid absences/absents (assuming 30 day month)
          final dailyRate = emp.baseSalary / 30.0;
          final attendanceDeduction = totalUnpaidAbsences * dailyRate;

          final totalDeduction = emp.deductions + attendanceDeduction;
          final netSalary = emp.baseSalary + emp.allowance - totalDeduction;

          // Generate unique ID based on employee ID and month/year to prevent duplicate payroll lines
          final payrollId = 'pr_${emp.id}_${year}_$month';
          final payrollRef = _firestore
              .collection('companies')
              .doc(companyId)
              .collection('payroll')
              .doc(payrollId);

          final payroll = PayrollEntity(
            id: payrollId,
            companyId: companyId,
            employeeId: emp.id,
            employeeName: emp.fullName,
            month: month,
            year: year,
            baseSalary: emp.baseSalary,
            allowances: emp.allowance,
            deductions: totalDeduction,
            netSalary: netSalary < 0.0 ? 0.0 : netSalary,
            status: 'draft',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );

          transaction.set(payrollRef, payroll.toMap());
        }
      });
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }
}
