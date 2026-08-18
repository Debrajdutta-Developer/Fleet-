import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fleet_os_erp/features/auth/presentation/auth_providers.dart';
import 'package:fleet_os_erp/features/auth/domain/user_entity.dart';
import 'package:fleet_os_erp/features/hr/domain/employee_entity.dart';
import 'package:fleet_os_erp/features/hr/domain/department_entity.dart';
import 'package:fleet_os_erp/features/hr/domain/designation_entity.dart';
import 'package:fleet_os_erp/features/hr/domain/shift_entity.dart';
import 'package:fleet_os_erp/features/hr/domain/leave_entity.dart';
import 'package:fleet_os_erp/features/hr/domain/payroll_entity.dart';
import 'package:fleet_os_erp/features/hr/presentation/hr_providers.dart';
import 'package:fleet_os_erp/features/hr/presentation/screens/employee_list_screen.dart';
import 'package:fleet_os_erp/features/hr/presentation/screens/attendance_screen.dart';
import 'package:fleet_os_erp/features/hr/presentation/screens/leave_screen.dart';
import 'package:fleet_os_erp/features/hr/presentation/screens/payroll_screen.dart';
import 'package:fleet_os_erp/features/hr/presentation/screens/hr_settings_screen.dart';
import 'hr_providers_test.dart';

void main() {
  late MockHrRepository mockRepo;
  final now = DateTime.now();

  final testEmployee = EmployeeEntity(
    id: 'emp_test_1',
    companyId: 'c_1',
    firstName: 'Alice',
    lastName: 'Smith',
    email: 'alice@fleet.com',
    phone: '1234567890',
    status: 'active',
    role: 'driver',
    baseSalary: 3000.0,
    allowance: 200.0,
    deductions: 100.0,
    hiredAt: now,
    createdAt: now,
    updatedAt: now,
  );

  final testDept = DepartmentEntity(
    id: 'dept_test_1',
    companyId: 'c_1',
    name: 'Logistics',
    description: 'Fleet Logistics Dept',
    createdAt: now,
    updatedAt: now,
  );

  final testDesig = DesignationEntity(
    id: 'desig_test_1',
    companyId: 'c_1',
    title: 'Senior Driver',
    description: 'Lead operator of heavy vehicles',
    departmentId: 'dept_test_1',
    createdAt: now,
    updatedAt: now,
  );

  final testShift = ShiftEntity(
    id: 'shift_test_1',
    companyId: 'c_1',
    name: 'Night Shift',
    startTime: '22:00',
    endTime: '06:00',
    createdAt: now,
    updatedAt: now,
  );

  final testLeave = LeaveEntity(
    id: 'leave_test_1',
    companyId: 'c_1',
    employeeId: 'emp_test_1',
    leaveType: 'sick',
    startDate: now,
    endDate: now.add(const Duration(days: 2)),
    reason: 'Fever',
    status: 'pending',
    createdAt: now,
    updatedAt: now,
  );

  final testPayroll = PayrollEntity(
    id: 'pr_emp_test_1_${now.year}_${now.month}',
    companyId: 'c_1',
    employeeId: 'emp_test_1',
    employeeName: 'Alice Smith',
    month: now.month,
    year: now.year,
    baseSalary: 3000.0,
    allowances: 200.0,
    deductions: 100.0,
    netSalary: 3100.0,
    status: 'draft',
    createdAt: now,
    updatedAt: now,
  );

  setUp(() {
    mockRepo = MockHrRepository();
    mockRepo.employees.add(testEmployee);
    mockRepo.departments.add(testDept);
    mockRepo.designations.add(testDesig);
    mockRepo.shifts.add(testShift);
    mockRepo.leaves.add(testLeave);
    mockRepo.payrolls.add(testPayroll);
  });

  Widget createTestWidget(Widget child) {
    return ProviderScope(
      overrides: [
        currentUserProvider.overrideWith((ref) => UserEntity(
              uid: 'u_1',
              email: 'operator@fleet.com',
              displayName: 'Operator John',
              role: 'admin',
              companyId: 'c_1',
              createdAt: now,
            )),
        hrRepositoryProvider.overrideWithValue(mockRepo),
      ],
      child: MaterialApp(
        home: child,
      ),
    );
  }

  testWidgets('EmployeeListScreen renders and lists employees',
      (WidgetTester tester) async {
    await tester.pumpWidget(createTestWidget(const EmployeeListScreen()));
    await tester.pumpAndSettle();

    expect(find.text('HR & Employee Management'), findsOneWidget);
    expect(find.text('Alice Smith'), findsOneWidget);
    expect(find.textContaining('DRIVER'), findsOneWidget);
  });

  testWidgets('AttendanceScreen renders and allows checking details',
      (WidgetTester tester) async {
    await tester.pumpWidget(createTestWidget(const AttendanceScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Attendance Logs'), findsOneWidget);
    expect(find.text('Alice Smith'), findsOneWidget);
  });

  testWidgets('LeaveScreen renders and lists leaves',
      (WidgetTester tester) async {
    await tester.pumpWidget(createTestWidget(const LeaveScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Leave Management'), findsOneWidget);
    expect(find.text('Alice Smith'), findsOneWidget);
  });

  testWidgets('PayrollScreen renders and lists payroll records',
      (WidgetTester tester) async {
    await tester.pumpWidget(createTestWidget(const PayrollScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Payroll Preparation'), findsOneWidget);
    expect(find.text('Alice Smith'), findsOneWidget);
  });

  testWidgets('HrSettingsScreen renders tabs correctly',
      (WidgetTester tester) async {
    await tester.pumpWidget(createTestWidget(const HrSettingsScreen()));
    await tester.pumpAndSettle();

    expect(find.text('HR Organization Settings'), findsOneWidget);
    expect(find.text('Departments'), findsAny);
    expect(find.text('Designations'), findsAny);
    expect(find.text('Shifts'), findsAny);
  });
}
