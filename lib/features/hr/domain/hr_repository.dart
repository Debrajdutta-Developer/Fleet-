import 'employee_entity.dart';
import 'department_entity.dart';
import 'designation_entity.dart';
import 'attendance_entity.dart';
import 'shift_entity.dart';
import 'leave_entity.dart';
import 'payroll_entity.dart';

abstract class HrRepository {
  // Employees
  Stream<List<EmployeeEntity>> watchEmployees(String companyId);
  Future<List<EmployeeEntity>> getEmployees(String companyId);
  Future<EmployeeEntity?> getEmployeeById(String companyId, String employeeId);
  Future<EmployeeEntity> createEmployee(
      String companyId, EmployeeEntity employee);
  Future<void> updateEmployee(String companyId, EmployeeEntity employee);
  Future<void> deleteEmployee(String companyId, String employeeId);

  // Departments
  Stream<List<DepartmentEntity>> watchDepartments(String companyId);
  Future<List<DepartmentEntity>> getDepartments(String companyId);
  Future<DepartmentEntity> createDepartment(
      String companyId, DepartmentEntity dept);
  Future<void> updateDepartment(String companyId, DepartmentEntity dept);
  Future<void> deleteDepartment(String companyId, String deptId);

  // Designations
  Stream<List<DesignationEntity>> watchDesignations(String companyId);
  Future<List<DesignationEntity>> getDesignations(String companyId);
  Future<DesignationEntity> createDesignation(
      String companyId, DesignationEntity desig);
  Future<void> updateDesignation(String companyId, DesignationEntity desig);
  Future<void> deleteDesignation(String companyId, String desigId);

  // Attendance
  Stream<List<AttendanceEntity>> watchAttendance(String companyId,
      {DateTime? date});
  Future<List<AttendanceEntity>> getAttendance(String companyId,
      {DateTime? date});
  Future<AttendanceEntity> saveAttendance(
      String companyId, AttendanceEntity attendance);

  // Shifts
  Stream<List<ShiftEntity>> watchShifts(String companyId);
  Future<List<ShiftEntity>> getShifts(String companyId);
  Future<ShiftEntity> createShift(String companyId, ShiftEntity shift);
  Future<void> updateShift(String companyId, ShiftEntity shift);
  Future<void> deleteShift(String companyId, String shiftId);

  // Leaves
  Stream<List<LeaveEntity>> watchLeaves(String companyId);
  Future<List<LeaveEntity>> getLeaves(String companyId);
  Future<LeaveEntity> createLeave(String companyId, LeaveEntity leave);
  Future<void> updateLeave(String companyId, LeaveEntity leave);

  // Payroll
  Stream<List<PayrollEntity>> watchPayroll(
      String companyId, int month, int year);
  Future<List<PayrollEntity>> getPayroll(String companyId, int month, int year);
  Future<PayrollEntity> savePayroll(String companyId, PayrollEntity payroll);
  Future<void> preparePayroll(String companyId, int month, int year);
}
