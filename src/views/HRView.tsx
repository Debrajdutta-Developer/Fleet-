import React, { useState } from 'react';
import { useFleet } from '../context/FleetContext';
import {
  Employee,
  Department,
  Designation,
  Shift,
  AttendanceRecord,
  LeaveRequest,
  PayrollRecord,
  UserRole
} from '../types';
import { EmployeeModal } from '../components/hr/EmployeeModal';
import { EmployeeDetailDrawer } from '../components/hr/EmployeeDetailDrawer';
import { DepartmentModal, DesignationModal } from '../components/hr/DepartmentDesignationModals';
import { ShiftModal, LeaveRequestModal, PayslipModal } from '../components/hr/AttendanceShiftModals';
import {
  Users,
  Building,
  Award,
  Clock,
  Calendar,
  DollarSign,
  Shield,
  Search,
  Plus,
  Filter,
  CheckCircle2,
  AlertTriangle,
  XCircle,
  Clock3,
  MapPin,
  TrendingUp,
  CreditCard,
  ChevronRight,
  ChevronLeft,
  Briefcase,
  Truck,
  Eye,
  Edit2,
  Trash2,
  FileText,
  UserPlus
} from 'lucide-react';

export type HRSubTab =
  | 'employees'
  | 'departments'
  | 'attendance'
  | 'shifts'
  | 'leaves'
  | 'payroll'
  | 'rbac';

export const HRView: React.FC = () => {
  const {
    currentCompany,
    employees,
    departments,
    designations,
    shifts,
    attendanceRecords,
    leaveRequests,
    payrollRecords,
    clockInEmployee,
    clockOutEmployee,
    updateLeaveStatus,
    generatePayrollForMonth,
    updatePayrollStatus,
    softDeleteDepartment,
    softDeleteDesignation,
    softDeleteEmployee,
    currentUser,
  } = useFleet();

  const [activeSubTab, setActiveSubTab] = useState<HRSubTab>('employees');

  // Filter & Search states for Employees
  const [employeeSearch, setEmployeeSearch] = useState('');
  const [deptFilter, setDeptFilter] = useState('all');
  const [statusFilter, setStatusFilter] = useState('all');
  const [roleFilter, setRoleFilter] = useState('all');
  const [currentPage, setCurrentPage] = useState(1);
  const itemsPerPage = 8;

  // Modals & Drawers state
  const [selectedEmployee, setSelectedEmployee] = useState<Employee | null>(null);
  const [isEmployeeModalOpen, setIsEmployeeModalOpen] = useState(false);
  const [editingEmployee, setEditingEmployee] = useState<Employee | null>(null);

  const [isDeptModalOpen, setIsDeptModalOpen] = useState(false);
  const [editingDept, setEditingDept] = useState<Department | null>(null);

  const [isDesigModalOpen, setIsDesigModalOpen] = useState(false);
  const [editingDesig, setEditingDesig] = useState<Designation | null>(null);

  const [isShiftModalOpen, setIsShiftModalOpen] = useState(false);
  const [editingShift, setEditingShift] = useState<Shift | null>(null);

  const [isLeaveModalOpen, setIsLeaveModalOpen] = useState(false);
  const [selectedPayslip, setSelectedPayslip] = useState<PayrollRecord | null>(null);

  // Live Terminal Clock-In state
  const [terminalEmployeeId, setTerminalEmployeeId] = useState(employees[0]?.id || '');
  const [terminalLocation, setTerminalLocation] = useState('Apex Primary Terminal (Bay A)');

  // Payroll generation month state
  const currentMonthStr = new Date().toISOString().slice(0, 7);
  const [selectedPayrollMonth, setSelectedPayrollMonth] = useState(currentMonthStr);

  // Multi-tenant isolation: filter active company items
  const companyEmployees = employees.filter((e) => e.companyId === currentCompany.id);
  const companyDepts = departments.filter((d) => d.companyId === currentCompany.id && !d.deletedAt);
  const companyDesigs = designations.filter((d) => d.companyId === currentCompany.id && !d.deletedAt);
  const companyShifts = shifts.filter((s) => s.companyId === currentCompany.id);
  const companyLeaves = leaveRequests.filter((l) => l.companyId === currentCompany.id);
  const companyPayrolls = payrollRecords.filter((p) => p.companyId === currentCompany.id);
  const companyAttendance = attendanceRecords.filter((a) => a.companyId === currentCompany.id);

  // Aggregated HR KPI calculations
  const totalHeadcount = companyEmployees.filter((e) => !e.deletedAt && e.status !== 'terminated').length;
  const activeDriversCount = companyEmployees.filter((e) => !e.deletedAt && e.isDriver).length;
  const pendingLeavesCount = companyLeaves.filter((l) => l.status === 'pending').length;
  const todayStr = new Date().toISOString().split('T')[0];
  const todayAttendance = companyAttendance.filter((a) => a.date === todayStr);
  const presentTodayCount = todayAttendance.filter((a) => a.status === 'present' || a.status === 'late').length;
  const attendanceRate = totalHeadcount > 0 ? Math.round((presentTodayCount / totalHeadcount) * 100) : 100;
  const totalMonthlyPayrollOutlay = companyPayrolls
    .filter((p) => p.payrollMonth === selectedPayrollMonth)
    .reduce((acc, p) => acc + p.netSalary, 0);

  // Filtered employees for directory
  const filteredEmployees = companyEmployees.filter((emp) => {
    if (emp.deletedAt) return false;
    if (deptFilter !== 'all' && emp.departmentId !== deptFilter) return false;
    if (statusFilter !== 'all' && emp.status !== statusFilter) return false;
    if (roleFilter !== 'all' && emp.role !== roleFilter) return false;
    if (employeeSearch.trim()) {
      const q = employeeSearch.toLowerCase();
      return (
        emp.fullName.toLowerCase().includes(q) ||
        emp.employeeCode.toLowerCase().includes(q) ||
        emp.email.toLowerCase().includes(q)
      );
    }
    return true;
  });

  const totalPages = Math.ceil(filteredEmployees.length / itemsPerPage) || 1;
  const paginatedEmployees = filteredEmployees.slice(
    (currentPage - 1) * itemsPerPage,
    currentPage * itemsPerPage
  );

  const handleTerminalClockIn = () => {
    if (!terminalEmployeeId) return;
    clockInEmployee(terminalEmployeeId, terminalLocation, { lat: 37.7749, lng: -122.4194 });
  };

  const handleGeneratePayroll = () => {
    generatePayrollForMonth(selectedPayrollMonth);
  };

  return (
    <div className="space-y-6 pb-16">
      {/* Top Header & Tenant Info */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <div className="flex items-center space-x-2">
            <h1 className="text-2xl font-bold text-slate-900 dark:text-white font-display">
              HR & Workforce Operations
            </h1>
            <span className="px-2.5 py-0.5 rounded-full text-xs font-semibold bg-blue-100 text-blue-800 dark:bg-blue-900/40 dark:text-blue-300">
              Sprint 3.3
            </span>
          </div>
          <p className="text-sm text-slate-500 dark:text-slate-400 mt-0.5">
            Enterprise multi-tenant employee roster, attendance telemetry, shift scheduling & payroll ledger for{' '}
            <span className="font-semibold text-slate-800 dark:text-slate-200">{currentCompany.name}</span>
          </p>
        </div>

        <div className="flex items-center space-x-3">
          <button
            onClick={() => {
              setEditingEmployee(null);
              setIsEmployeeModalOpen(true);
            }}
            className="flex items-center space-x-2 px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-lg text-xs font-semibold shadow-sm transition"
          >
            <UserPlus className="h-4 w-4" />
            <span>Onboard Employee</span>
          </button>
        </div>
      </div>

      {/* Top HR KPI Metrics */}
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
        {/* Total Workforce */}
        <div className="bg-white dark:bg-slate-800/90 border border-slate-200 dark:border-slate-700/80 rounded-xl p-4 shadow-xs">
          <div className="flex items-center justify-between">
            <span className="text-xs font-medium text-slate-500 dark:text-slate-400 uppercase tracking-wider">
              Total Workforce
            </span>
            <div className="h-8 w-8 rounded-lg bg-blue-50 dark:bg-blue-900/30 text-blue-600 dark:text-blue-400 flex items-center justify-center">
              <Users className="h-4 w-4" />
            </div>
          </div>
          <div className="mt-3 flex items-baseline space-x-2">
            <span className="font-display text-2xl font-bold text-slate-900 dark:text-white">
              {totalHeadcount}
            </span>
            <span className="text-xs text-blue-600 dark:text-blue-400 font-semibold">
              {activeDriversCount} Fleet Drivers
            </span>
          </div>
          <p className="text-xs text-slate-500 dark:text-slate-400 mt-1">
            Across {companyDepts.length} organizational departments
          </p>
        </div>

        {/* Live Attendance */}
        <div className="bg-white dark:bg-slate-800/90 border border-slate-200 dark:border-slate-700/80 rounded-xl p-4 shadow-xs">
          <div className="flex items-center justify-between">
            <span className="text-xs font-medium text-slate-500 dark:text-slate-400 uppercase tracking-wider">
              Today's Attendance
            </span>
            <div className="h-8 w-8 rounded-lg bg-emerald-50 dark:bg-emerald-900/30 text-emerald-600 dark:text-emerald-400 flex items-center justify-center">
              <Clock className="h-4 w-4" />
            </div>
          </div>
          <div className="mt-3 flex items-baseline space-x-2">
            <span className="font-display text-2xl font-bold text-slate-900 dark:text-white">
              {presentTodayCount} / {totalHeadcount}
            </span>
            <span className="text-xs text-emerald-600 dark:text-emerald-400 font-semibold">
              {attendanceRate}% Clocked
            </span>
          </div>
          <p className="text-xs text-slate-500 dark:text-slate-400 mt-1">
            {todayAttendance.filter((a) => a.status === 'late').length} late check-ins logged
          </p>
        </div>

        {/* Leave Queue */}
        <div className="bg-white dark:bg-slate-800/90 border border-slate-200 dark:border-slate-700/80 rounded-xl p-4 shadow-xs">
          <div className="flex items-center justify-between">
            <span className="text-xs font-medium text-slate-500 dark:text-slate-400 uppercase tracking-wider">
              Leave Requests
            </span>
            <div className="h-8 w-8 rounded-lg bg-amber-50 dark:bg-amber-900/30 text-amber-600 dark:text-amber-400 flex items-center justify-center">
              <Calendar className="h-4 w-4" />
            </div>
          </div>
          <div className="mt-3 flex items-baseline space-x-2">
            <span className="font-display text-2xl font-bold text-slate-900 dark:text-white">
              {pendingLeavesCount}
            </span>
            <span className="text-xs text-amber-600 dark:text-amber-400 font-semibold">
              Pending Review
            </span>
          </div>
          <p className="text-xs text-slate-500 dark:text-slate-400 mt-1">
            {companyEmployees.filter((e) => e.status === 'on_leave').length} currently active on approved leave
          </p>
        </div>

        {/* Monthly Payroll */}
        <div className="bg-white dark:bg-slate-800/90 border border-slate-200 dark:border-slate-700/80 rounded-xl p-4 shadow-xs">
          <div className="flex items-center justify-between">
            <span className="text-xs font-medium text-slate-500 dark:text-slate-400 uppercase tracking-wider">
              Monthly Payroll Outlay
            </span>
            <div className="h-8 w-8 rounded-lg bg-purple-50 dark:bg-purple-900/30 text-purple-600 dark:text-purple-400 flex items-center justify-center">
              <DollarSign className="h-4 w-4" />
            </div>
          </div>
          <div className="mt-3 flex items-baseline space-x-2">
            <span className="font-display text-2xl font-bold text-slate-900 dark:text-white">
              ${totalMonthlyPayrollOutlay.toLocaleString()}
            </span>
            <span className="text-xs text-purple-600 dark:text-purple-400 font-semibold">
              {selectedPayrollMonth}
            </span>
          </div>
          <p className="text-xs text-slate-500 dark:text-slate-400 mt-1">
            Auto-calculated with overtime & allowances
          </p>
        </div>
      </div>

      {/* Main Sub-Navigation Bar */}
      <div className="border-b border-slate-200 dark:border-slate-800 flex overflow-x-auto gap-1 bg-white dark:bg-slate-900 p-1 rounded-xl shadow-xs">
        <button
          onClick={() => setActiveSubTab('employees')}
          className={`flex items-center space-x-2 px-3.5 py-2 rounded-lg text-xs font-semibold whitespace-nowrap transition ${
            activeSubTab === 'employees'
              ? 'bg-blue-600 text-white shadow-xs'
              : 'text-slate-600 dark:text-slate-400 hover:bg-slate-100 dark:hover:bg-slate-800'
          }`}
        >
          <Users className="h-3.5 w-3.5" />
          <span>Employees Directory ({companyEmployees.length})</span>
        </button>

        <button
          onClick={() => setActiveSubTab('departments')}
          className={`flex items-center space-x-2 px-3.5 py-2 rounded-lg text-xs font-semibold whitespace-nowrap transition ${
            activeSubTab === 'departments'
              ? 'bg-blue-600 text-white shadow-xs'
              : 'text-slate-600 dark:text-slate-400 hover:bg-slate-100 dark:hover:bg-slate-800'
          }`}
        >
          <Building className="h-3.5 w-3.5" />
          <span>Departments & Roles</span>
        </button>

        <button
          onClick={() => setActiveSubTab('attendance')}
          className={`flex items-center space-x-2 px-3.5 py-2 rounded-lg text-xs font-semibold whitespace-nowrap transition ${
            activeSubTab === 'attendance'
              ? 'bg-blue-600 text-white shadow-xs'
              : 'text-slate-600 dark:text-slate-400 hover:bg-slate-100 dark:hover:bg-slate-800'
          }`}
        >
          <Clock className="h-3.5 w-3.5" />
          <span>Attendance & Clock-In</span>
        </button>

        <button
          onClick={() => setActiveSubTab('shifts')}
          className={`flex items-center space-x-2 px-3.5 py-2 rounded-lg text-xs font-semibold whitespace-nowrap transition ${
            activeSubTab === 'shifts'
              ? 'bg-blue-600 text-white shadow-xs'
              : 'text-slate-600 dark:text-slate-400 hover:bg-slate-100 dark:hover:bg-slate-800'
          }`}
        >
          <Clock3 className="h-3.5 w-3.5" />
          <span>Shift Schedules</span>
        </button>

        <button
          onClick={() => setActiveSubTab('leaves')}
          className={`flex items-center space-x-2 px-3.5 py-2 rounded-lg text-xs font-semibold whitespace-nowrap transition ${
            activeSubTab === 'leaves'
              ? 'bg-blue-600 text-white shadow-xs'
              : 'text-slate-600 dark:text-slate-400 hover:bg-slate-100 dark:hover:bg-slate-800'
          }`}
        >
          <Calendar className="h-3.5 w-3.5" />
          <span>Leave Requests</span>
          {pendingLeavesCount > 0 && (
            <span className="px-1.5 py-0.2 bg-amber-500 text-white rounded-full text-[10px] font-bold">
              {pendingLeavesCount}
            </span>
          )}
        </button>

        <button
          onClick={() => setActiveSubTab('payroll')}
          className={`flex items-center space-x-2 px-3.5 py-2 rounded-lg text-xs font-semibold whitespace-nowrap transition ${
            activeSubTab === 'payroll'
              ? 'bg-blue-600 text-white shadow-xs'
              : 'text-slate-600 dark:text-slate-400 hover:bg-slate-100 dark:hover:bg-slate-800'
          }`}
        >
          <DollarSign className="h-3.5 w-3.5" />
          <span>Payroll Engine</span>
        </button>

        <button
          onClick={() => setActiveSubTab('rbac')}
          className={`flex items-center space-x-2 px-3.5 py-2 rounded-lg text-xs font-semibold whitespace-nowrap transition ${
            activeSubTab === 'rbac'
              ? 'bg-blue-600 text-white shadow-xs'
              : 'text-slate-600 dark:text-slate-400 hover:bg-slate-100 dark:hover:bg-slate-800'
          }`}
        >
          <Shield className="h-3.5 w-3.5" />
          <span>Role Matrix (RBAC)</span>
        </button>
      </div>

      {/* ================= TAB 1: EMPLOYEES DIRECTORY ================= */}
      {activeSubTab === 'employees' && (
        <div className="space-y-4">
          {/* Filter and Search Bar */}
          <div className="bg-white dark:bg-slate-900 p-4 rounded-xl border border-slate-200 dark:border-slate-800 flex flex-col md:flex-row gap-3 items-center justify-between">
            <div className="relative w-full md:w-80">
              <Search className="absolute left-3 top-2.5 h-4 w-4 text-slate-400" />
              <input
                type="text"
                placeholder="Search by name, code, email..."
                value={employeeSearch}
                onChange={(e) => {
                  setEmployeeSearch(e.target.value);
                  setCurrentPage(1);
                }}
                className="w-full pl-9 pr-3 py-2 text-xs bg-slate-50 dark:bg-slate-800/80 border border-slate-200 dark:border-slate-700 rounded-lg outline-none focus:ring-2 focus:ring-blue-500"
              />
            </div>

            <div className="flex flex-wrap items-center gap-2 w-full md:w-auto">
              <select
                value={deptFilter}
                onChange={(e) => {
                  setDeptFilter(e.target.value);
                  setCurrentPage(1);
                }}
                className="px-3 py-2 text-xs bg-slate-50 dark:bg-slate-800/80 border border-slate-200 dark:border-slate-700 rounded-lg outline-none"
              >
                <option value="all">All Departments</option>
                {companyDepts.map((d) => (
                  <option key={d.id} value={d.id}>
                    {d.name}
                  </option>
                ))}
              </select>

              <select
                value={statusFilter}
                onChange={(e) => {
                  setStatusFilter(e.target.value);
                  setCurrentPage(1);
                }}
                className="px-3 py-2 text-xs bg-slate-50 dark:bg-slate-800/80 border border-slate-200 dark:border-slate-700 rounded-lg outline-none"
              >
                <option value="all">All Statuses</option>
                <option value="active">Active</option>
                <option value="probation">Probation</option>
                <option value="on_leave">On Leave</option>
                <option value="suspended">Suspended</option>
              </select>

              <select
                value={roleFilter}
                onChange={(e) => {
                  setRoleFilter(e.target.value);
                  setCurrentPage(1);
                }}
                className="px-3 py-2 text-xs bg-slate-50 dark:bg-slate-800/80 border border-slate-200 dark:border-slate-700 rounded-lg outline-none"
              >
                <option value="all">All Roles</option>
                <option value="driver">Driver</option>
                <option value="dispatcher">Dispatcher</option>
                <option value="fleet_manager">Fleet Manager</option>
                <option value="safety_officer">Safety Officer</option>
                <option value="financial_auditor">Financial Auditor</option>
                <option value="super_admin">Super Admin</option>
              </select>
            </div>
          </div>

          {/* Employees Table */}
          <div className="bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800 overflow-hidden shadow-xs">
            <div className="overflow-x-auto">
              <table className="w-full text-left text-xs">
                <thead className="bg-slate-50 dark:bg-slate-800/60 text-slate-500 dark:text-slate-400 font-semibold border-b border-slate-200 dark:border-slate-800">
                  <tr>
                    <th className="px-4 py-3">Employee</th>
                    <th className="px-4 py-3">Department & Designation</th>
                    <th className="px-4 py-3">Role & Shift</th>
                    <th className="px-4 py-3">Compensation</th>
                    <th className="px-4 py-3">Status</th>
                    <th className="px-4 py-3 text-right">Actions</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-slate-100 dark:divide-slate-800">
                  {paginatedEmployees.length === 0 ? (
                    <tr>
                      <td colSpan={6} className="px-4 py-8 text-center text-slate-500">
                        No employees match the current search or filters.
                      </td>
                    </tr>
                  ) : (
                    paginatedEmployees.map((emp) => {
                      const dept = companyDepts.find((d) => d.id === emp.departmentId);
                      const desig = companyDesigs.find((d) => d.id === emp.designationId);
                      const shift = companyShifts.find((s) => s.id === emp.shiftId);
                      const totalAllowances =
                        (emp.salaryStructure.hraAllowance || 0) +
                        (emp.salaryStructure.transportAllowance || 0) +
                        (emp.salaryStructure.medicalAllowance || 0) +
                        (emp.salaryStructure.specialAllowance || 0);
                      const grossSalary = emp.salaryStructure.baseSalary + totalAllowances;

                      return (
                        <tr
                          key={emp.id}
                          className="hover:bg-slate-50/80 dark:hover:bg-slate-800/40 transition"
                        >
                          <td className="px-4 py-3">
                            <div className="flex items-center space-x-3">
                              <div className="h-9 w-9 rounded-xl bg-blue-100 dark:bg-blue-900/40 text-blue-700 dark:text-blue-300 flex items-center justify-center font-bold text-xs shrink-0">
                                {emp.fullName.split(' ').map((n) => n[0]).join('').slice(0, 2)}
                              </div>
                              <div>
                                <div className="flex items-center space-x-2">
                                  <span className="font-semibold text-slate-900 dark:text-white">
                                    {emp.fullName}
                                  </span>
                                  {emp.isDriver && (
                                    <span className="flex items-center space-x-1 px-1.5 py-0.5 rounded text-[10px] font-bold bg-blue-50 text-blue-700 dark:bg-blue-950/60 dark:text-blue-300">
                                      <Truck className="h-3 w-3" />
                                      <span>Driver</span>
                                    </span>
                                  )}
                                </div>
                                <p className="text-[11px] text-slate-500 font-mono mt-0.5">
                                  {emp.employeeCode} &bull; {emp.email}
                                </p>
                              </div>
                            </div>
                          </td>

                          <td className="px-4 py-3">
                            <span className="font-semibold text-slate-800 dark:text-slate-200">
                              {dept?.name || 'Operations'}
                            </span>
                            <p className="text-[11px] text-slate-500">{desig?.title || 'Staff'}</p>
                          </td>

                          <td className="px-4 py-3">
                            <span className="font-medium text-blue-600 dark:text-blue-400 capitalize">
                              {emp.role.replace('_', ' ')}
                            </span>
                            <p className="text-[11px] text-slate-500">
                              {shift?.name || 'General'} ({shift?.startTime}-{shift?.endTime})
                            </p>
                          </td>

                          <td className="px-4 py-3">
                            <span className="font-bold text-slate-900 dark:text-white">
                              ${grossSalary.toLocaleString()} / mo
                            </span>
                            <p className="text-[11px] text-slate-500">Base: ${emp.salaryStructure.baseSalary}</p>
                          </td>

                          <td className="px-4 py-3">
                            <span
                              className={`text-[11px] font-semibold px-2 py-0.5 rounded-full capitalize ${
                                emp.status === 'active'
                                  ? 'bg-emerald-100 text-emerald-800 dark:bg-emerald-900/40 dark:text-emerald-300'
                                  : emp.status === 'on_leave'
                                  ? 'bg-amber-100 text-amber-800 dark:bg-amber-900/40 dark:text-amber-300'
                                  : 'bg-rose-100 text-rose-800 dark:bg-rose-900/40 dark:text-rose-300'
                              }`}
                            >
                              {emp.status.replace('_', ' ')}
                            </span>
                          </td>

                          <td className="px-4 py-3 text-right">
                            <div className="flex items-center justify-end space-x-1">
                              <button
                                onClick={() => setSelectedEmployee(emp)}
                                className="p-1.5 text-slate-600 hover:text-blue-600 dark:text-slate-400 dark:hover:text-blue-400 hover:bg-slate-100 dark:hover:bg-slate-800 rounded-lg transition"
                                title="View Comprehensive Profile Drawer"
                              >
                                <Eye className="h-4 w-4" />
                              </button>
                              <button
                                onClick={() => {
                                  setEditingEmployee(emp);
                                  setIsEmployeeModalOpen(true);
                                }}
                                className="p-1.5 text-slate-600 hover:text-amber-600 dark:text-slate-400 dark:hover:text-amber-400 hover:bg-slate-100 dark:hover:bg-slate-800 rounded-lg transition"
                                title="Edit Employee"
                              >
                                <Edit2 className="h-4 w-4" />
                              </button>
                              <button
                                onClick={() => softDeleteEmployee(emp.id)}
                                className="p-1.5 text-slate-600 hover:text-rose-600 dark:text-slate-400 dark:hover:text-rose-400 hover:bg-slate-100 dark:hover:bg-slate-800 rounded-lg transition"
                                title="Terminate / Soft Delete"
                              >
                                <Trash2 className="h-4 w-4" />
                              </button>
                            </div>
                          </td>
                        </tr>
                      );
                    })
                  )}
                </tbody>
              </table>
            </div>

            {/* Pagination Controls */}
            {totalPages > 1 && (
              <div className="px-4 py-3 border-t border-slate-200 dark:border-slate-800 flex items-center justify-between text-xs text-slate-500">
                <span>
                  Showing {(currentPage - 1) * itemsPerPage + 1} to{' '}
                  {Math.min(currentPage * itemsPerPage, filteredEmployees.length)} of {filteredEmployees.length} records
                </span>
                <div className="flex items-center space-x-2">
                  <button
                    disabled={currentPage === 1}
                    onClick={() => setCurrentPage((p) => Math.max(1, p - 1))}
                    className="p-1.5 rounded-lg border border-slate-200 dark:border-slate-700 disabled:opacity-40"
                  >
                    <ChevronLeft className="h-4 w-4" />
                  </button>
                  <span>
                    Page {currentPage} of {totalPages}
                  </span>
                  <button
                    disabled={currentPage === totalPages}
                    onClick={() => setCurrentPage((p) => Math.min(totalPages, p + 1))}
                    className="p-1.5 rounded-lg border border-slate-200 dark:border-slate-700 disabled:opacity-40"
                  >
                    <ChevronRight className="h-4 w-4" />
                  </button>
                </div>
              </div>
            )}
          </div>
        </div>
      )}

      {/* ================= TAB 2: DEPARTMENTS & DESIGNATIONS ================= */}
      {activeSubTab === 'departments' && (
        <div className="space-y-6">
          {/* Departments Section */}
          <div className="space-y-3">
            <div className="flex items-center justify-between">
              <div>
                <h3 className="text-base font-bold text-slate-900 dark:text-white">
                  Organizational Departments
                </h3>
                <p className="text-xs text-slate-500">Operational divisions & cost centers</p>
              </div>
              <button
                onClick={() => {
                  setEditingDept(null);
                  setIsDeptModalOpen(true);
                }}
                className="flex items-center space-x-1.5 px-3 py-1.5 bg-purple-600 hover:bg-purple-700 text-white rounded-lg text-xs font-semibold"
              >
                <Plus className="h-4 w-4" />
                <span>Add Department</span>
              </button>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
              {companyDepts.map((dept) => {
                const count = companyEmployees.filter((e) => e.departmentId === dept.id && !e.deletedAt).length;
                return (
                  <div
                    key={dept.id}
                    className="bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-xl p-4 space-y-3 shadow-xs"
                  >
                    <div className="flex items-start justify-between">
                      <div className="flex items-center space-x-2.5">
                        <div className="h-9 w-9 rounded-xl bg-purple-100 dark:bg-purple-900/40 text-purple-700 dark:text-purple-300 flex items-center justify-center font-bold text-xs">
                          {dept.code}
                        </div>
                        <div>
                          <h4 className="font-bold text-slate-900 dark:text-white text-sm">
                            {dept.name}
                          </h4>
                          <p className="text-[11px] text-slate-500">Head: {dept.headOfDepartment || 'Unassigned'}</p>
                        </div>
                      </div>
                      <div className="flex items-center space-x-1">
                        <button
                          onClick={() => {
                            setEditingDept(dept);
                            setIsDeptModalOpen(true);
                          }}
                          className="p-1 text-slate-400 hover:text-purple-600 rounded"
                        >
                          <Edit2 className="h-3.5 w-3.5" />
                        </button>
                        <button
                          onClick={() => softDeleteDepartment(dept.id)}
                          className="p-1 text-slate-400 hover:text-rose-600 rounded"
                        >
                          <Trash2 className="h-3.5 w-3.5" />
                        </button>
                      </div>
                    </div>

                    <p className="text-xs text-slate-600 dark:text-slate-400 line-clamp-2">
                      {dept.description || 'Department management division'}
                    </p>

                    <div className="pt-2 border-t border-slate-100 dark:border-slate-800 flex items-center justify-between text-xs">
                      <span className="text-slate-500">{count} Active Employees</span>
                      <span className="font-semibold text-slate-700 dark:text-slate-300">
                        Budget: ${dept.budget?.toLocaleString()}
                      </span>
                    </div>
                  </div>
                );
              })}
            </div>
          </div>

          {/* Designations Hierarchy Table */}
          <div className="space-y-3">
            <div className="flex items-center justify-between">
              <div>
                <h3 className="text-base font-bold text-slate-900 dark:text-white">
                  Designations & Salary Bands
                </h3>
                <p className="text-xs text-slate-500">Standardized hierarchy and compensation brackets</p>
              </div>
              <button
                onClick={() => {
                  setEditingDesig(null);
                  setIsDesigModalOpen(true);
                }}
                className="flex items-center space-x-1.5 px-3 py-1.5 bg-amber-600 hover:bg-amber-700 text-white rounded-lg text-xs font-semibold"
              >
                <Plus className="h-4 w-4" />
                <span>Add Designation</span>
              </button>
            </div>

            <div className="bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800 overflow-hidden shadow-xs">
              <table className="w-full text-left text-xs">
                <thead className="bg-slate-50 dark:bg-slate-800/60 text-slate-500 font-semibold border-b border-slate-200 dark:border-slate-800">
                  <tr>
                    <th className="px-4 py-3">Designation Title</th>
                    <th className="px-4 py-3">Department</th>
                    <th className="px-4 py-3">Level</th>
                    <th className="px-4 py-3">Salary Band</th>
                    <th className="px-4 py-3">Employees</th>
                    <th className="px-4 py-3 text-right">Actions</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-slate-100 dark:divide-slate-800">
                  {companyDesigs.map((desig) => {
                    const dept = companyDepts.find((d) => d.id === desig.departmentId);
                    const count = companyEmployees.filter((e) => e.designationId === desig.id && !e.deletedAt).length;
                    return (
                      <tr key={desig.id} className="hover:bg-slate-50/60 dark:hover:bg-slate-800/40">
                        <td className="px-4 py-3 font-semibold text-slate-900 dark:text-white">
                          {desig.title}
                        </td>
                        <td className="px-4 py-3 text-slate-600 dark:text-slate-400">
                          {dept?.name || 'Operations'}
                        </td>
                        <td className="px-4 py-3">
                          <span className="px-2 py-0.5 rounded bg-amber-100 text-amber-800 dark:bg-amber-900/40 dark:text-amber-300 font-bold text-[10px]">
                            L{desig.level}
                          </span>
                        </td>
                        <td className="px-4 py-3 font-medium text-slate-800 dark:text-slate-200">
                          ${desig.minSalary?.toLocaleString()} - ${desig.maxSalary?.toLocaleString()} / mo
                        </td>
                        <td className="px-4 py-3 text-slate-600 dark:text-slate-400">{count} staff</td>
                        <td className="px-4 py-3 text-right">
                          <div className="flex items-center justify-end space-x-1">
                            <button
                              onClick={() => {
                                setEditingDesig(desig);
                                setIsDesigModalOpen(true);
                              }}
                              className="p-1 text-slate-400 hover:text-amber-600"
                            >
                              <Edit2 className="h-3.5 w-3.5" />
                            </button>
                            <button
                              onClick={() => softDeleteDesignation(desig.id)}
                              className="p-1 text-slate-400 hover:text-rose-600"
                            >
                              <Trash2 className="h-3.5 w-3.5" />
                            </button>
                          </div>
                        </td>
                      </tr>
                    );
                  })}
                </tbody>
              </table>
            </div>
          </div>
        </div>
      )}

      {/* ================= TAB 3: ATTENDANCE & TELEMETRY CLOCK-IN ================= */}
      {activeSubTab === 'attendance' && (
        <div className="space-y-6">
          {/* Live Terminal Clock-In Simulator Card */}
          <div className="bg-linear-to-r from-blue-900 to-indigo-900 text-white rounded-2xl p-6 shadow-lg space-y-4">
            <div className="flex items-start justify-between">
              <div>
                <span className="text-xs font-semibold uppercase tracking-wider text-blue-300">
                  Operations Floor Terminal
                </span>
                <h3 className="text-lg font-bold font-display mt-0.5">
                  Live Attendance Check-In / Clock-Out Gateway
                </h3>
                <p className="text-xs text-blue-200 mt-1">
                  Simulates GPS mobile and terminal biometric clock-ins for shift tracking and automated payroll feed.
                </p>
              </div>
              <div className="h-10 w-10 rounded-xl bg-white/10 flex items-center justify-center">
                <Clock className="h-5 w-5 text-blue-300" />
              </div>
            </div>

            <div className="grid grid-cols-1 sm:grid-cols-3 gap-3 pt-2">
              <div>
                <label className="block text-[11px] font-semibold text-blue-200 mb-1">
                  Select Employee
                </label>
                <select
                  value={terminalEmployeeId}
                  onChange={(e) => setTerminalEmployeeId(e.target.value)}
                  className="w-full px-3 py-2 text-xs bg-white/10 border border-white/20 rounded-lg text-white outline-none focus:bg-slate-900"
                >
                  {companyEmployees
                    .filter((e) => !e.deletedAt)
                    .map((emp) => (
                      <option key={emp.id} value={emp.id} className="text-slate-900">
                        {emp.fullName} ({emp.employeeCode})
                      </option>
                    ))}
                </select>
              </div>

              <div>
                <label className="block text-[11px] font-semibold text-blue-200 mb-1">
                  Terminal Terminal / Yard
                </label>
                <select
                  value={terminalLocation}
                  onChange={(e) => setTerminalLocation(e.target.value)}
                  className="w-full px-3 py-2 text-xs bg-white/10 border border-white/20 rounded-lg text-white outline-none focus:bg-slate-900"
                >
                  <option value="Apex Primary Terminal (Bay A)" className="text-slate-900">
                    Apex Primary Terminal (Bay A)
                  </option>
                  <option value="West Coast Staging Yard #4" className="text-slate-900">
                    West Coast Staging Yard #4
                  </option>
                  <option value="Chicago Cross-Dock Facility" className="text-slate-900">
                    Chicago Cross-Dock Facility
                  </option>
                  <option value="Mobile Driver App Check-In" className="text-slate-900">
                    Mobile Driver App Check-In
                  </option>
                </select>
              </div>

              <div className="flex items-end">
                <button
                  onClick={handleTerminalClockIn}
                  className="w-full py-2.5 bg-blue-500 hover:bg-blue-400 text-white rounded-lg text-xs font-bold shadow-md transition flex items-center justify-center space-x-2"
                >
                  <CheckCircle2 className="h-4 w-4" />
                  <span>Clock-In Now</span>
                </button>
              </div>
            </div>
          </div>

          {/* Today's Active Shifts & Attendance Log */}
          <div className="bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800 overflow-hidden shadow-xs space-y-3 p-4">
            <div className="flex items-center justify-between">
              <h4 className="text-sm font-bold text-slate-900 dark:text-white">
                Attendance Telemetry Logs ({companyAttendance.length})
              </h4>
              <span className="text-xs text-slate-500">Feeds directly into payroll generator</span>
            </div>

            <div className="overflow-x-auto">
              <table className="w-full text-left text-xs">
                <thead className="bg-slate-50 dark:bg-slate-800/60 text-slate-500 font-semibold border-b border-slate-200 dark:border-slate-800">
                  <tr>
                    <th className="px-4 py-3">Employee</th>
                    <th className="px-4 py-3">Date</th>
                    <th className="px-4 py-3">Check-In</th>
                    <th className="px-4 py-3">Check-Out</th>
                    <th className="px-4 py-3">Hours Worked</th>
                    <th className="px-4 py-3">Status</th>
                    <th className="px-4 py-3 text-right">Clock Out Action</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-slate-100 dark:divide-slate-800">
                  {companyAttendance.map((att) => {
                    const emp = companyEmployees.find((e) => e.id === att.employeeId);
                    return (
                      <tr key={att.id} className="hover:bg-slate-50/60 dark:hover:bg-slate-800/40">
                        <td className="px-4 py-3">
                          <span className="font-semibold text-slate-900 dark:text-white">
                            {emp?.fullName || att.employeeId}
                          </span>
                          <p className="text-[11px] text-slate-500">{emp?.employeeCode}</p>
                        </td>
                        <td className="px-4 py-3 font-mono text-slate-700 dark:text-slate-300">{att.date}</td>
                        <td className="px-4 py-3 font-semibold text-slate-800 dark:text-slate-200">
                          {att.checkInTime}
                        </td>
                        <td className="px-4 py-3 font-semibold text-slate-800 dark:text-slate-200">
                          {att.checkOutTime || (
                            <span className="text-emerald-600 dark:text-emerald-400 flex items-center space-x-1">
                              <span className="h-2 w-2 rounded-full bg-emerald-500 animate-pulse" />
                              <span>On Shift</span>
                            </span>
                          )}
                        </td>
                        <td className="px-4 py-3 font-bold text-slate-900 dark:text-white">
                          {att.hoursWorked}h
                          {att.overtimeHours ? (
                            <span className="text-blue-600 text-[11px] ml-1 font-semibold">
                              (+{att.overtimeHours}h OT)
                            </span>
                          ) : null}
                        </td>
                        <td className="px-4 py-3">
                          <span
                            className={`px-2 py-0.5 rounded-full capitalize font-semibold text-[10px] ${
                              att.status === 'present'
                                ? 'bg-emerald-100 text-emerald-800 dark:bg-emerald-900/40 dark:text-emerald-300'
                                : att.status === 'late'
                                ? 'bg-amber-100 text-amber-800 dark:bg-amber-900/40 dark:text-amber-300'
                                : 'bg-rose-100 text-rose-800 dark:bg-rose-900/40 dark:text-rose-300'
                            }`}
                          >
                            {att.status}
                          </span>
                        </td>
                        <td className="px-4 py-3 text-right">
                          {!att.checkOutTime ? (
                            <button
                              onClick={() => clockOutEmployee(att.id)}
                              className="px-2.5 py-1 bg-slate-900 hover:bg-slate-800 text-white rounded-lg text-xs font-semibold transition"
                            >
                              Clock Out
                            </button>
                          ) : (
                            <span className="text-slate-400 text-[11px]">Completed</span>
                          )}
                        </td>
                      </tr>
                    );
                  })}
                </tbody>
              </table>
            </div>
          </div>
        </div>
      )}

      {/* ================= TAB 4: SHIFTS ================= */}
      {activeSubTab === 'shifts' && (
        <div className="space-y-4">
          <div className="flex items-center justify-between">
            <div>
              <h3 className="text-base font-bold text-slate-900 dark:text-white">
                Fleet & Logistics Shift Schedules
              </h3>
              <p className="text-xs text-slate-500">Configured operational rosters and timing windows</p>
            </div>
            <button
              onClick={() => {
                setEditingShift(null);
                setIsShiftModalOpen(true);
              }}
              className="flex items-center space-x-1.5 px-3 py-1.5 bg-blue-600 hover:bg-blue-700 text-white rounded-lg text-xs font-semibold"
            >
              <Plus className="h-4 w-4" />
              <span>Create Shift</span>
            </button>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
            {companyShifts.map((shift) => {
              const assignedCount = companyEmployees.filter((e) => e.shiftId === shift.id && !e.deletedAt).length;
              return (
                <div
                  key={shift.id}
                  className="bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-xl p-5 space-y-3 shadow-xs"
                >
                  <div className="flex items-center justify-between">
                    <div className="flex items-center space-x-2">
                      <div className="h-8 w-8 rounded-lg bg-blue-50 dark:bg-blue-900/40 text-blue-600 dark:text-blue-400 flex items-center justify-center font-bold">
                        <Clock className="h-4 w-4" />
                      </div>
                      <h4 className="font-bold text-slate-900 dark:text-white text-sm">
                        {shift.name}
                      </h4>
                    </div>
                    <button
                      onClick={() => {
                        setEditingShift(shift);
                        setIsShiftModalOpen(true);
                      }}
                      className="p-1 text-slate-400 hover:text-blue-600"
                    >
                      <Edit2 className="h-3.5 w-3.5" />
                    </button>
                  </div>

                  <div className="p-3 bg-slate-50 dark:bg-slate-800/50 rounded-lg text-xs space-y-1">
                    <div className="flex justify-between">
                      <span className="text-slate-500">Working Window</span>
                      <span className="font-semibold text-slate-800 dark:text-slate-200">
                        {shift.startTime} &mdash; {shift.endTime}
                      </span>
                    </div>
                    <div className="flex justify-between">
                      <span className="text-slate-500">Grace Period</span>
                      <span className="font-semibold text-slate-800 dark:text-slate-200">
                        {shift.gracePeriodMins} minutes
                      </span>
                    </div>
                    <div className="flex justify-between">
                      <span className="text-slate-500">Type</span>
                      <span className="font-semibold text-slate-800 dark:text-slate-200">
                        {shift.isNightShift ? 'Overnight Shift' : 'Standard Day Shift'}
                      </span>
                    </div>
                  </div>

                  <div className="flex items-center justify-between text-xs text-slate-500 pt-2 border-t border-slate-100 dark:border-slate-800">
                    <span>{assignedCount} Assigned Staff</span>
                    <span className="text-blue-600 font-semibold">{shift.workingDays.join(', ')}</span>
                  </div>
                </div>
              );
            })}
          </div>
        </div>
      )}

      {/* ================= TAB 5: LEAVE MANAGEMENT ================= */}
      {activeSubTab === 'leaves' && (
        <div className="space-y-4">
          <div className="flex items-center justify-between">
            <div>
              <h3 className="text-base font-bold text-slate-900 dark:text-white">
                Leave Requests & Approval Queue
              </h3>
              <p className="text-xs text-slate-500">Vacation, medical, and emergency time-off requests</p>
            </div>
            <button
              onClick={() => setIsLeaveModalOpen(true)}
              className="flex items-center space-x-1.5 px-3 py-1.5 bg-amber-600 hover:bg-amber-700 text-white rounded-lg text-xs font-semibold"
            >
              <Plus className="h-4 w-4" />
              <span>Apply for Leave</span>
            </button>
          </div>

          <div className="bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800 overflow-hidden shadow-xs">
            <table className="w-full text-left text-xs">
              <thead className="bg-slate-50 dark:bg-slate-800/60 text-slate-500 font-semibold border-b border-slate-200 dark:border-slate-800">
                <tr>
                  <th className="px-4 py-3">Employee</th>
                  <th className="px-4 py-3">Leave Type</th>
                  <th className="px-4 py-3">Duration & Dates</th>
                  <th className="px-4 py-3">Reason</th>
                  <th className="px-4 py-3">Status</th>
                  <th className="px-4 py-3 text-right">Approval Actions</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-100 dark:divide-slate-800">
                {companyLeaves.length === 0 ? (
                  <tr>
                    <td colSpan={6} className="px-4 py-8 text-center text-slate-500">
                      No leave applications found.
                    </td>
                  </tr>
                ) : (
                  companyLeaves.map((leave) => {
                    const emp = companyEmployees.find((e) => e.id === leave.employeeId);
                    return (
                      <tr key={leave.id} className="hover:bg-slate-50/60 dark:hover:bg-slate-800/40">
                        <td className="px-4 py-3">
                          <span className="font-semibold text-slate-900 dark:text-white">
                            {emp?.fullName || leave.employeeId}
                          </span>
                          <p className="text-[11px] text-slate-500">{emp?.employeeCode}</p>
                        </td>
                        <td className="px-4 py-3">
                          <span className="capitalize font-semibold text-slate-800 dark:text-slate-200">
                            {leave.leaveType}
                          </span>
                        </td>
                        <td className="px-4 py-3">
                          <span className="font-semibold text-slate-900 dark:text-white">
                            {leave.totalDays} Day(s)
                          </span>
                          <p className="text-[11px] text-slate-500 font-mono">
                            {leave.startDate} to {leave.endDate}
                          </p>
                        </td>
                        <td className="px-4 py-3 max-w-xs truncate text-slate-600 dark:text-slate-400">
                          {leave.reason}
                        </td>
                        <td className="px-4 py-3">
                          <span
                            className={`px-2 py-0.5 rounded-full capitalize font-semibold text-[10px] ${
                              leave.status === 'approved'
                                ? 'bg-emerald-100 text-emerald-800 dark:bg-emerald-900/40 dark:text-emerald-300'
                                : leave.status === 'pending'
                                ? 'bg-amber-100 text-amber-800 dark:bg-amber-900/40 dark:text-amber-300'
                                : 'bg-rose-100 text-rose-800 dark:bg-rose-900/40 dark:text-rose-300'
                            }`}
                          >
                            {leave.status}
                          </span>
                        </td>
                        <td className="px-4 py-3 text-right">
                          {leave.status === 'pending' ? (
                            <div className="flex items-center justify-end space-x-1.5">
                              <button
                                onClick={() => updateLeaveStatus(leave.id, 'approved')}
                                className="px-2.5 py-1 bg-emerald-600 hover:bg-emerald-700 text-white rounded-lg text-xs font-semibold transition"
                              >
                                Approve
                              </button>
                              <button
                                onClick={() => updateLeaveStatus(leave.id, 'rejected', 'Capacity constraints')}
                                className="px-2.5 py-1 bg-rose-600 hover:bg-rose-700 text-white rounded-lg text-xs font-semibold transition"
                              >
                                Reject
                              </button>
                            </div>
                          ) : (
                            <span className="text-[11px] text-slate-400">Reviewed</span>
                          )}
                        </td>
                      </tr>
                    );
                  })
                )}
              </tbody>
            </table>
          </div>
        </div>
      )}

      {/* ================= TAB 6: PAYROLL ENGINE ================= */}
      {activeSubTab === 'payroll' && (
        <div className="space-y-4">
          <div className="bg-white dark:bg-slate-900 p-4 rounded-xl border border-slate-200 dark:border-slate-800 flex flex-col sm:flex-row items-center justify-between gap-4">
            <div>
              <h3 className="text-base font-bold text-slate-900 dark:text-white">
                Monthly Compensation & Payroll Ledger
              </h3>
              <p className="text-xs text-slate-500">
                Directly synchronized with attendance, overtime, tax withholding & benefits
              </p>
            </div>

            <div className="flex items-center space-x-3">
              <input
                type="month"
                value={selectedPayrollMonth}
                onChange={(e) => setSelectedPayrollMonth(e.target.value)}
                className="px-3 py-2 text-xs bg-slate-50 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-lg outline-none font-semibold text-slate-800 dark:text-slate-200"
              />
              <button
                onClick={handleGeneratePayroll}
                className="flex items-center space-x-2 px-4 py-2 bg-emerald-600 hover:bg-emerald-700 text-white rounded-lg text-xs font-semibold shadow-xs"
              >
                <DollarSign className="h-4 w-4" />
                <span>Compute Batch</span>
              </button>
            </div>
          </div>

          <div className="bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800 overflow-hidden shadow-xs">
            <table className="w-full text-left text-xs">
              <thead className="bg-slate-50 dark:bg-slate-800/60 text-slate-500 font-semibold border-b border-slate-200 dark:border-slate-800">
                <tr>
                  <th className="px-4 py-3">Employee</th>
                  <th className="px-4 py-3">Base & Allowances</th>
                  <th className="px-4 py-3">Overtime Telemetry</th>
                  <th className="px-4 py-3">Gross Salary</th>
                  <th className="px-4 py-3">Deductions (Tax + PF)</th>
                  <th className="px-4 py-3">Net Take-Home</th>
                  <th className="px-4 py-3">Status</th>
                  <th className="px-4 py-3 text-right">Actions</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-100 dark:divide-slate-800">
                {companyPayrolls.filter((p) => p.payrollMonth === selectedPayrollMonth).length === 0 ? (
                  <tr>
                    <td colSpan={8} className="px-4 py-8 text-center text-slate-500">
                      No payroll draft prepared for {selectedPayrollMonth}. Click "Compute Batch" to generate from attendance.
                    </td>
                  </tr>
                ) : (
                  companyPayrolls
                    .filter((p) => p.payrollMonth === selectedPayrollMonth)
                    .map((payroll) => {
                      const emp = companyEmployees.find((e) => e.id === payroll.employeeId);
                      const totalDeductions = payroll.taxDeduction + payroll.pfDeduction + (payroll.otherDeductions || 0);

                      return (
                        <tr key={payroll.id} className="hover:bg-slate-50/60 dark:hover:bg-slate-800/40">
                          <td className="px-4 py-3">
                            <span className="font-semibold text-slate-900 dark:text-white">
                              {emp?.fullName || payroll.employeeId}
                            </span>
                            <p className="text-[11px] text-slate-500">{emp?.employeeCode}</p>
                          </td>
                          <td className="px-4 py-3">
                            <span className="font-semibold text-slate-800 dark:text-slate-200">
                              ${payroll.baseSalary}
                            </span>
                            <p className="text-[11px] text-slate-500">+${payroll.totalAllowances} allowances</p>
                          </td>
                          <td className="px-4 py-3">
                            <span className="font-semibold text-blue-600">
                              +${payroll.overtimePay}
                            </span>
                            <p className="text-[11px] text-slate-500">{payroll.overtimeHours}h OT</p>
                          </td>
                          <td className="px-4 py-3 font-semibold text-slate-900 dark:text-white">
                            ${payroll.grossSalary.toLocaleString()}
                          </td>
                          <td className="px-4 py-3 font-semibold text-rose-600 dark:text-rose-400">
                            -${totalDeductions.toFixed(0)}
                          </td>
                          <td className="px-4 py-3">
                            <span className="text-sm font-bold text-emerald-600 dark:text-emerald-400">
                              ${payroll.netSalary.toLocaleString()}
                            </span>
                          </td>
                          <td className="px-4 py-3">
                            <span
                              className={`px-2 py-0.5 rounded-full capitalize font-semibold text-[10px] ${
                                payroll.status === 'disbursed'
                                  ? 'bg-emerald-100 text-emerald-800 dark:bg-emerald-900/40 dark:text-emerald-300'
                                  : payroll.status === 'approved'
                                  ? 'bg-blue-100 text-blue-800 dark:bg-blue-900/40 dark:text-blue-300'
                                  : 'bg-amber-100 text-amber-800 dark:bg-amber-900/40 dark:text-amber-300'
                              }`}
                            >
                              {payroll.status}
                            </span>
                          </td>
                          <td className="px-4 py-3 text-right">
                            <div className="flex items-center justify-end space-x-1.5">
                              <button
                                onClick={() => setSelectedPayslip(payroll)}
                                className="px-2 py-1 bg-slate-100 hover:bg-slate-200 dark:bg-slate-800 dark:hover:bg-slate-700 text-slate-800 dark:text-slate-200 rounded text-xs font-medium"
                              >
                                Payslip
                              </button>
                              {payroll.status !== 'disbursed' && (
                                <button
                                  onClick={() => updatePayrollStatus(payroll.id, 'disbursed')}
                                  className="px-2 py-1 bg-emerald-600 hover:bg-emerald-700 text-white rounded text-xs font-semibold shadow-2xs"
                                >
                                  Disburse
                                </button>
                              )}
                            </div>
                          </td>
                        </tr>
                      );
                    })
                )}
              </tbody>
            </table>
          </div>
        </div>
      )}

      {/* ================= TAB 7: RBAC ROLE MATRIX ================= */}
      {activeSubTab === 'rbac' && (
        <div className="bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800 p-6 space-y-6 shadow-xs">
          <div>
            <h3 className="text-base font-bold text-slate-900 dark:text-white">
              Enterprise Role & Permission Mapping (RBAC)
            </h3>
            <p className="text-xs text-slate-500">
              Module-level security and access control boundaries across FleetOS ERP.
            </p>
          </div>

          <div className="overflow-x-auto">
            <table className="w-full text-left text-xs">
              <thead className="bg-slate-50 dark:bg-slate-800/60 text-slate-500 font-semibold border-b border-slate-200 dark:border-slate-800">
                <tr>
                  <th className="px-4 py-3">System Role</th>
                  <th className="px-4 py-3">Fleet & GPS</th>
                  <th className="px-4 py-3">Trips & Dispatch</th>
                  <th className="px-4 py-3">HR & Employee Roster</th>
                  <th className="px-4 py-3">Payroll & Finance</th>
                  <th className="px-4 py-3">Maintenance</th>
                  <th className="px-4 py-3">Audit Logs</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-100 dark:divide-slate-800">
                {[
                  { role: 'Super Admin', fleet: 'Full Access', trips: 'Full Access', hr: 'Full Access', payroll: 'Full Access', maint: 'Full Access', audit: 'Full Access' },
                  { role: 'Fleet Manager', fleet: 'Full Access', trips: 'Full Access', hr: 'Read & Assign', payroll: 'View Only', maint: 'Full Access', audit: 'Read Only' },
                  { role: 'Dispatcher', fleet: 'View Only', trips: 'Full Access', hr: 'Driver Roster Only', payroll: 'No Access', maint: 'View Only', audit: 'No Access' },
                  { role: 'Driver', fleet: 'Assigned Vehicle', trips: 'Assigned Trip', hr: 'Self Profile & Clock', payroll: 'My Payslips', maint: 'Report Issues', audit: 'No Access' },
                  { role: 'Safety Officer', fleet: 'Telemetry Only', trips: 'View Only', hr: 'Driver Safety Roster', payroll: 'No Access', maint: 'Audit & Compliance', audit: 'Read Only' },
                  { role: 'Financial Auditor', fleet: 'Fuel & Tolls', trips: 'Billing Only', hr: 'Read Only', payroll: 'Full Disburse', maint: 'Cost Audit', audit: 'Full Access' },
                ].map((row) => (
                  <tr key={row.role} className="hover:bg-slate-50/60 dark:hover:bg-slate-800/40">
                    <td className="px-4 py-3 font-bold text-slate-900 dark:text-white flex items-center space-x-2">
                      <Shield className="h-3.5 w-3.5 text-blue-600" />
                      <span>{row.role}</span>
                    </td>
                    <td className="px-4 py-3 text-slate-700 dark:text-slate-300">{row.fleet}</td>
                    <td className="px-4 py-3 text-slate-700 dark:text-slate-300">{row.trips}</td>
                    <td className="px-4 py-3 text-blue-600 dark:text-blue-400 font-semibold">{row.hr}</td>
                    <td className="px-4 py-3 text-emerald-600 dark:text-emerald-400 font-semibold">{row.payroll}</td>
                    <td className="px-4 py-3 text-slate-700 dark:text-slate-300">{row.maint}</td>
                    <td className="px-4 py-3 text-slate-700 dark:text-slate-300">{row.audit}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      )}

      {/* Modals & Profile Drawers */}
      {isEmployeeModalOpen && (
        <EmployeeModal
          employee={editingEmployee}
          onClose={() => {
            setIsEmployeeModalOpen(false);
            setEditingEmployee(null);
          }}
        />
      )}

      {selectedEmployee && (
        <EmployeeDetailDrawer
          employee={selectedEmployee}
          onClose={() => setSelectedEmployee(null)}
          onEdit={(emp) => {
            setSelectedEmployee(null);
            setEditingEmployee(emp);
            setIsEmployeeModalOpen(true);
          }}
        />
      )}

      {isDeptModalOpen && (
        <DepartmentModal
          department={editingDept}
          onClose={() => {
            setIsDeptModalOpen(false);
            setEditingDept(null);
          }}
        />
      )}

      {isDesigModalOpen && (
        <DesignationModal
          designation={editingDesig}
          onClose={() => {
            setIsDesigModalOpen(false);
            setEditingDesig(null);
          }}
        />
      )}

      {isShiftModalOpen && (
        <ShiftModal
          shift={editingShift}
          onClose={() => {
            setIsShiftModalOpen(false);
            setEditingShift(null);
          }}
        />
      )}

      {isLeaveModalOpen && (
        <LeaveRequestModal
          onClose={() => setIsLeaveModalOpen(false)}
        />
      )}

      {selectedPayslip && (
        <PayslipModal
          payroll={selectedPayslip}
          onClose={() => setSelectedPayslip(null)}
        />
      )}
    </div>
  );
};
