import React, { useState } from 'react';
import { useFleet } from '../../context/FleetContext';
import { Employee } from '../../types';
import {
  X,
  User,
  Briefcase,
  DollarSign,
  Calendar,
  Clock,
  FileText,
  Shield,
  Truck,
  Phone,
  Mail,
  Edit2,
  Trash2,
  CheckCircle2,
  AlertTriangle,
  History,
  Building,
  CreditCard
} from 'lucide-react';

interface EmployeeDetailDrawerProps {
  employee: Employee;
  onClose: () => void;
  onEdit: (employee: Employee) => void;
}

export const EmployeeDetailDrawer: React.FC<EmployeeDetailDrawerProps> = ({
  employee,
  onClose,
  onEdit,
}) => {
  const {
    departments,
    designations,
    shifts,
    drivers,
    attendanceRecords,
    leaveRequests,
    payrollRecords,
    auditLogs,
    softDeleteEmployee,
  } = useFleet();

  const [activeTab, setActiveTab] = useState<'overview' | 'attendance' | 'payroll' | 'leaves' | 'audit'>('overview');
  const [showDeleteConfirm, setShowDeleteConfirm] = useState(false);

  const dept = departments.find((d) => d.id === employee.departmentId);
  const desig = designations.find((d) => d.id === employee.designationId);
  const shift = shifts.find((s) => s.id === employee.shiftId);
  const driver = drivers.find((d) => d.id === employee.linkedDriverId || d.employeeId === employee.id);

  const empAttendance = attendanceRecords.filter((a) => a.employeeId === employee.id);
  const empLeaves = leaveRequests.filter((l) => l.employeeId === employee.id);
  const empPayrolls = payrollRecords.filter((p) => p.employeeId === employee.id);
  const empAuditLogs = auditLogs.filter((l) => l.documentId === employee.id || l.summary.includes(employee.fullName));

  // Compute metrics
  const totalDaysPresent = empAttendance.filter((a) => a.status === 'present' || a.status === 'late').length;
  const totalOTHours = empAttendance.reduce((acc, a) => acc + (a.overtimeHours || 0), 0);
  const totalAllowances =
    (employee.salaryStructure.hraAllowance || 0) +
    (employee.salaryStructure.transportAllowance || 0) +
    (employee.salaryStructure.medicalAllowance || 0) +
    (employee.salaryStructure.specialAllowance || 0);
  const grossMonthly = employee.salaryStructure.baseSalary + totalAllowances;

  const handleDelete = () => {
    softDeleteEmployee(employee.id);
    onClose();
  };

  return (
    <div className="fixed inset-0 z-50 overflow-hidden bg-slate-900/60 backdrop-blur-xs flex justify-end animate-in fade-in duration-150">
      <div className="w-full max-w-2xl bg-white dark:bg-slate-900 h-full shadow-2xl border-l border-slate-200 dark:border-slate-800 flex flex-col overflow-hidden animate-in slide-in-from-right duration-200">
        {/* Drawer Header */}
        <div className="p-6 border-b border-slate-200 dark:border-slate-800 bg-slate-50/70 dark:bg-slate-800/40">
          <div className="flex items-start justify-between">
            <div className="flex items-center space-x-4">
              <div className="h-14 w-14 rounded-2xl bg-blue-600 text-white flex items-center justify-center font-bold text-xl shadow-md shadow-blue-500/20">
                {employee.fullName.split(' ').map((n) => n[0]).join('').slice(0, 2)}
              </div>
              <div>
                <div className="flex items-center space-x-2">
                  <h2 className="text-xl font-bold text-slate-900 dark:text-white font-display">
                    {employee.fullName}
                  </h2>
                  <span
                    className={`text-[11px] font-semibold px-2 py-0.5 rounded-full capitalize ${
                      employee.status === 'active'
                        ? 'bg-emerald-100 text-emerald-800 dark:bg-emerald-900/40 dark:text-emerald-300'
                        : employee.status === 'on_leave'
                        ? 'bg-amber-100 text-amber-800 dark:bg-amber-900/40 dark:text-amber-300'
                        : 'bg-rose-100 text-rose-800 dark:bg-rose-900/40 dark:text-rose-300'
                    }`}
                  >
                    {employee.status.replace('_', ' ')}
                  </span>
                </div>
                <p className="text-xs text-slate-500 dark:text-slate-400 mt-0.5">
                  <span className="font-mono text-slate-700 dark:text-slate-300 font-semibold">{employee.employeeCode}</span> &bull; {desig?.title || 'Staff'} &bull; {dept?.name || 'Operations'}
                </p>
              </div>
            </div>

            <div className="flex items-center space-x-2">
              <button
                onClick={() => onEdit(employee)}
                className="p-2 text-slate-600 hover:text-blue-600 dark:text-slate-400 dark:hover:text-blue-400 rounded-lg hover:bg-slate-100 dark:hover:bg-slate-800 transition"
                title="Edit Employee Profile"
              >
                <Edit2 className="h-4 w-4" />
              </button>
              <button
                onClick={() => setShowDeleteConfirm(true)}
                className="p-2 text-slate-600 hover:text-rose-600 dark:text-slate-400 dark:hover:text-rose-400 rounded-lg hover:bg-slate-100 dark:hover:bg-slate-800 transition"
                title="Offboard / Terminate"
              >
                <Trash2 className="h-4 w-4" />
              </button>
              <button
                onClick={onClose}
                className="p-2 text-slate-400 hover:text-slate-600 dark:hover:text-slate-200 rounded-lg hover:bg-slate-100 dark:hover:bg-slate-800 transition"
              >
                <X className="h-5 w-5" />
              </button>
            </div>
          </div>

          {/* Quick Contact Chips */}
          <div className="grid grid-cols-2 sm:grid-cols-3 gap-2 mt-4 text-xs">
            <div className="flex items-center space-x-1.5 text-slate-600 dark:text-slate-400 truncate">
              <Mail className="h-3.5 w-3.5 text-slate-400 shrink-0" />
              <span className="truncate">{employee.email}</span>
            </div>
            <div className="flex items-center space-x-1.5 text-slate-600 dark:text-slate-400">
              <Phone className="h-3.5 w-3.5 text-slate-400 shrink-0" />
              <span>{employee.phone}</span>
            </div>
            <div className="flex items-center space-x-1.5 text-slate-600 dark:text-slate-400">
              <Calendar className="h-3.5 w-3.5 text-slate-400 shrink-0" />
              <span>Joined {employee.joiningDate || employee.joinDate ? new Date(employee.joiningDate ?? employee.joinDate!).toLocaleDateString() : '—'}</span>
            </div>
          </div>
        </div>

        {/* Delete Confirmation Banner */}
        {showDeleteConfirm && (
          <div className="p-4 bg-rose-50 dark:bg-rose-950/40 border-b border-rose-200 dark:border-rose-800 flex items-center justify-between text-xs">
            <div className="flex items-center space-x-2 text-rose-800 dark:text-rose-200 font-medium">
              <AlertTriangle className="h-4 w-4 text-rose-600 shrink-0" />
              <span>Are you sure you want to offboard/terminate this employee record?</span>
            </div>
            <div className="flex items-center space-x-2 shrink-0">
              <button
                onClick={() => setShowDeleteConfirm(false)}
                className="px-2.5 py-1 text-slate-600 dark:text-slate-300 font-medium hover:underline"
              >
                Cancel
              </button>
              <button
                onClick={handleDelete}
                className="px-3 py-1 bg-rose-600 hover:bg-rose-700 text-white rounded-lg font-semibold shadow-xs transition"
              >
                Confirm Terminate
              </button>
            </div>
          </div>
        )}

        {/* Tab Navigation */}
        <div className="flex border-b border-slate-200 dark:border-slate-800 px-6 bg-white dark:bg-slate-900 shrink-0">
          <button
            onClick={() => setActiveTab('overview')}
            className={`py-3 px-3 text-xs font-semibold border-b-2 transition ${
              activeTab === 'overview'
                ? 'border-blue-600 text-blue-600 dark:text-blue-400'
                : 'border-transparent text-slate-500 hover:text-slate-800 dark:hover:text-slate-200'
            }`}
          >
            Overview
          </button>
          <button
            onClick={() => setActiveTab('attendance')}
            className={`py-3 px-3 text-xs font-semibold border-b-2 transition ${
              activeTab === 'attendance'
                ? 'border-blue-600 text-blue-600 dark:text-blue-400'
                : 'border-transparent text-slate-500 hover:text-slate-800 dark:hover:text-slate-200'
            }`}
          >
            Attendance ({empAttendance.length})
          </button>
          <button
            onClick={() => setActiveTab('payroll')}
            className={`py-3 px-3 text-xs font-semibold border-b-2 transition ${
              activeTab === 'payroll'
                ? 'border-blue-600 text-blue-600 dark:text-blue-400'
                : 'border-transparent text-slate-500 hover:text-slate-800 dark:hover:text-slate-200'
            }`}
          >
            Payroll & Slips ({empPayrolls.length})
          </button>
          <button
            onClick={() => setActiveTab('leaves')}
            className={`py-3 px-3 text-xs font-semibold border-b-2 transition ${
              activeTab === 'leaves'
                ? 'border-blue-600 text-blue-600 dark:text-blue-400'
                : 'border-transparent text-slate-500 hover:text-slate-800 dark:hover:text-slate-200'
            }`}
          >
            Leaves ({empLeaves.length})
          </button>
          <button
            onClick={() => setActiveTab('audit')}
            className={`py-3 px-3 text-xs font-semibold border-b-2 transition ${
              activeTab === 'audit'
                ? 'border-blue-600 text-blue-600 dark:text-blue-400'
                : 'border-transparent text-slate-500 hover:text-slate-800 dark:hover:text-slate-200'
            }`}
          >
            Audit Trail
          </button>
        </div>

        {/* Content Body */}
        <div className="flex-1 overflow-y-auto p-6 space-y-6">
          {activeTab === 'overview' && (
            <div className="space-y-6">
              {/* Linked Driver Box if available */}
              {driver && (
                <div className="p-4 bg-blue-50 dark:bg-blue-950/30 border border-blue-200 dark:border-blue-800/60 rounded-xl space-y-3">
                  <div className="flex items-center justify-between">
                    <div className="flex items-center space-x-2">
                      <Truck className="h-4 w-4 text-blue-600 dark:text-blue-400" />
                      <span className="text-xs font-bold text-blue-900 dark:text-blue-200">
                        Linked Fleet Driver Telemetry Profile
                      </span>
                    </div>
                    <span className="text-xs font-bold px-2 py-0.5 rounded-full bg-blue-100 dark:bg-blue-900 text-blue-700 dark:text-blue-300 capitalize">
                      {driver.status}
                    </span>
                  </div>
                  <div className="grid grid-cols-2 sm:grid-cols-4 gap-2 text-xs">
                    <div className="p-2 bg-white dark:bg-slate-800 rounded-lg">
                      <span className="text-slate-500 text-[10px]">License Number</span>
                      <p className="font-semibold text-slate-800 dark:text-slate-200">{driver.licenseNumber}</p>
                    </div>
                    <div className="p-2 bg-white dark:bg-slate-800 rounded-lg">
                      <span className="text-slate-500 text-[10px]">CDL Class</span>
                      <p className="font-semibold text-slate-800 dark:text-slate-200">{driver.cdlClass}</p>
                    </div>
                    <div className="p-2 bg-white dark:bg-slate-800 rounded-lg">
                      <span className="text-slate-500 text-[10px]">Safety Score</span>
                      <p className="font-bold text-emerald-600 dark:text-emerald-400">{driver.safetyScore}/100</p>
                    </div>
                    <div className="p-2 bg-white dark:bg-slate-800 rounded-lg">
                      <span className="text-slate-500 text-[10px]">Trips Done</span>
                      <p className="font-semibold text-slate-800 dark:text-slate-200">{driver.totalTripsCompleted}</p>
                    </div>
                  </div>
                </div>
              )}

              {/* Job & Org Details */}
              <div className="bg-slate-50 dark:bg-slate-800/40 rounded-xl p-4 border border-slate-200 dark:border-slate-800 space-y-3">
                <h3 className="text-xs font-bold text-slate-800 dark:text-slate-200 flex items-center space-x-1.5">
                  <Briefcase className="h-4 w-4 text-blue-600" />
                  <span>Job & Organization Profile</span>
                </h3>
                <div className="grid grid-cols-2 sm:grid-cols-3 gap-3 text-xs">
                  <div>
                    <span className="text-slate-500 text-[11px]">Department</span>
                    <p className="font-semibold text-slate-800 dark:text-slate-200">{dept?.name || 'N/A'}</p>
                  </div>
                  <div>
                    <span className="text-slate-500 text-[11px]">Designation</span>
                    <p className="font-semibold text-slate-800 dark:text-slate-200">{desig?.title || 'Staff'}</p>
                  </div>
                  <div>
                    <span className="text-slate-500 text-[11px]">Employment Type</span>
                    <p className="font-semibold text-slate-800 dark:text-slate-200 capitalize">{employee.employmentType.replace('_', ' ')}</p>
                  </div>
                  <div>
                    <span className="text-slate-500 text-[11px]">Shift Assignment</span>
                    <p className="font-semibold text-slate-800 dark:text-slate-200">{shift?.name || 'General'} ({shift?.startTime}-{shift?.endTime})</p>
                  </div>
                  <div>
                    <span className="text-slate-500 text-[11px]">System RBAC Role</span>
                    <p className="font-semibold text-blue-600 dark:text-blue-400 capitalize">{employee.role.replace('_', ' ')}</p>
                  </div>
                  <div>
                    <span className="text-slate-500 text-[11px]">Gender</span>
                    <p className="font-semibold text-slate-800 dark:text-slate-200 capitalize">{employee.gender || 'Not specified'}</p>
                  </div>
                </div>
              </div>

              {/* Salary Structure */}
              <div className="bg-slate-50 dark:bg-slate-800/40 rounded-xl p-4 border border-slate-200 dark:border-slate-800 space-y-3">
                <div className="flex items-center justify-between">
                  <h3 className="text-xs font-bold text-slate-800 dark:text-slate-200 flex items-center space-x-1.5">
                    <DollarSign className="h-4 w-4 text-emerald-600" />
                    <span>Compensation & Salary Structure</span>
                  </h3>
                  <span className="text-xs font-bold text-emerald-700 dark:text-emerald-300">
                    Gross: ${grossMonthly.toLocaleString()} / mo
                  </span>
                </div>
                <div className="grid grid-cols-2 sm:grid-cols-3 gap-2 text-xs">
                  <div className="p-2.5 bg-white dark:bg-slate-800 rounded-lg">
                    <span className="text-slate-500 text-[10px]">Base Pay</span>
                    <p className="font-bold text-slate-800 dark:text-slate-200">${employee.salaryStructure.baseSalary.toLocaleString()}</p>
                  </div>
                  <div className="p-2.5 bg-white dark:bg-slate-800 rounded-lg">
                    <span className="text-slate-500 text-[10px]">HRA Allowance</span>
                    <p className="font-semibold text-slate-800 dark:text-slate-200">${employee.salaryStructure.hraAllowance || 0}</p>
                  </div>
                  <div className="p-2.5 bg-white dark:bg-slate-800 rounded-lg">
                    <span className="text-slate-500 text-[10px]">Transport Allowance</span>
                    <p className="font-semibold text-slate-800 dark:text-slate-200">${employee.salaryStructure.transportAllowance || 0}</p>
                  </div>
                  <div className="p-2.5 bg-white dark:bg-slate-800 rounded-lg">
                    <span className="text-slate-500 text-[10px]">Medical Allowance</span>
                    <p className="font-semibold text-slate-800 dark:text-slate-200">${employee.salaryStructure.medicalAllowance || 0}</p>
                  </div>
                  <div className="p-2.5 bg-white dark:bg-slate-800 rounded-lg">
                    <span className="text-slate-500 text-[10px]">Provident Fund (PF)</span>
                    <p className="font-semibold text-rose-600 dark:text-rose-400">-${employee.salaryStructure.providentFundDeduction || 0}</p>
                  </div>
                  <div className="p-2.5 bg-white dark:bg-slate-800 rounded-lg">
                    <span className="text-slate-500 text-[10px]">Tax Deduction Rate</span>
                    <p className="font-semibold text-slate-800 dark:text-slate-200">{employee.salaryStructure.taxDeductionPercent}%</p>
                  </div>
                </div>
              </div>

              {/* Banking & Emergency */}
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                <div className="bg-slate-50 dark:bg-slate-800/40 rounded-xl p-4 border border-slate-200 dark:border-slate-800 space-y-2">
                  <h4 className="text-xs font-bold text-slate-800 dark:text-slate-200 flex items-center space-x-1.5">
                    <CreditCard className="h-3.5 w-3.5 text-teal-600" />
                    <span>Direct Deposit Account</span>
                  </h4>
                  <div className="text-xs space-y-1 text-slate-600 dark:text-slate-400">
                    <p><span className="text-slate-500">Bank:</span> {employee.bankAccount?.bankName || 'Not configured'}</p>
                    <p><span className="text-slate-500">Acct:</span> •••• {employee.bankAccount?.accountNumber ? employee.bankAccount.accountNumber.slice(-4) : 'N/A'}</p>
                    <p><span className="text-slate-500">Routing:</span> {employee.bankAccount?.routingNumber || 'N/A'}</p>
                  </div>
                </div>

                <div className="bg-slate-50 dark:bg-slate-800/40 rounded-xl p-4 border border-slate-200 dark:border-slate-800 space-y-2">
                  <h4 className="text-xs font-bold text-slate-800 dark:text-slate-200 flex items-center space-x-1.5">
                    <Shield className="h-3.5 w-3.5 text-amber-600" />
                    <span>Emergency Contact</span>
                  </h4>
                  <div className="text-xs space-y-1 text-slate-600 dark:text-slate-400">
                    <p><span className="text-slate-500">Contact:</span> {employee.emergencyContact?.name || 'Not provided'}</p>
                    <p><span className="text-slate-500">Relationship:</span> {employee.emergencyContact?.relationship || 'N/A'}</p>
                    <p><span className="text-slate-500">Phone:</span> {employee.emergencyContact?.phone || 'N/A'}</p>
                  </div>
                </div>
              </div>
            </div>
          )}

          {activeTab === 'attendance' && (
            <div className="space-y-4">
              <div className="flex items-center justify-between">
                <span className="text-xs font-semibold text-slate-700 dark:text-slate-300">
                  Recorded Attendance & Shift Clock-ins
                </span>
                <span className="text-xs text-slate-500">
                  {totalDaysPresent} days present &bull; {totalOTHours}h total overtime
                </span>
              </div>

              {empAttendance.length === 0 ? (
                <div className="p-8 text-center bg-slate-50 dark:bg-slate-800/30 rounded-xl border border-dashed border-slate-200 dark:border-slate-700 text-xs text-slate-500">
                  No attendance records logged yet for this employee.
                </div>
              ) : (
                <div className="space-y-2">
                  {empAttendance.map((att) => (
                    <div
                      key={att.id}
                      className="p-3 bg-white dark:bg-slate-800/80 border border-slate-200 dark:border-slate-700 rounded-xl flex items-center justify-between text-xs"
                    >
                      <div className="flex items-center space-x-3">
                        <div
                          className={`h-8 w-8 rounded-lg flex items-center justify-center font-bold text-xs ${
                            att.status === 'present'
                              ? 'bg-emerald-100 text-emerald-800 dark:bg-emerald-900/40 dark:text-emerald-300'
                              : att.status === 'late'
                              ? 'bg-amber-100 text-amber-800 dark:bg-amber-900/40 dark:text-amber-300'
                              : 'bg-rose-100 text-rose-800 dark:bg-rose-900/40 dark:text-rose-300'
                          }`}
                        >
                          <Clock className="h-4 w-4" />
                        </div>
                        <div>
                          <div className="flex items-center space-x-2">
                            <span className="font-semibold text-slate-800 dark:text-slate-200">{att.date}</span>
                            <span className="text-[10px] px-1.5 py-0.5 rounded capitalize bg-slate-100 dark:bg-slate-700 text-slate-700 dark:text-slate-300">
                              {att.status}
                            </span>
                          </div>
                          <p className="text-[11px] text-slate-500 mt-0.5">
                            In: {att.checkInTime} &bull; Out: {att.checkOutTime || 'Active Shift'} &bull; {att.locationName || 'Terminal'}
                          </p>
                        </div>
                      </div>

                      <div className="text-right">
                        <span className="font-bold text-slate-900 dark:text-white">{att.hoursWorked}h</span>
                        {att.overtimeHours ? (
                          <p className="text-[10px] text-blue-600 dark:text-blue-400 font-semibold">+{att.overtimeHours}h OT</p>
                        ) : null}
                      </div>
                    </div>
                  ))}
                </div>
              )}
            </div>
          )}

          {activeTab === 'payroll' && (
            <div className="space-y-4">
              <span className="text-xs font-semibold text-slate-700 dark:text-slate-300">
                Processed Payroll Disbursements & Slips
              </span>

              {empPayrolls.length === 0 ? (
                <div className="p-8 text-center bg-slate-50 dark:bg-slate-800/30 rounded-xl border border-dashed border-slate-200 dark:border-slate-700 text-xs text-slate-500">
                  No payroll batches generated for this employee yet.
                </div>
              ) : (
                <div className="space-y-3">
                  {empPayrolls.map((pr) => (
                    <div
                      key={pr.id}
                      className="p-4 bg-white dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-xl space-y-2"
                    >
                      <div className="flex items-center justify-between text-xs">
                        <div>
                          <span className="font-bold text-slate-900 dark:text-white">
                            Payroll Period: {pr.payrollMonth}
                          </span>
                          <p className="text-[11px] text-slate-500">
                            Status: <span className="capitalize font-semibold text-slate-700 dark:text-slate-300">{pr.status}</span> &bull; Txn: {pr.transactionRef || 'Pending'}
                          </p>
                        </div>
                        <div className="text-right">
                          <span className="text-base font-bold text-emerald-600 dark:text-emerald-400">
                            ${pr.netSalary.toLocaleString()}
                          </span>
                          <p className="text-[10px] text-slate-500">Net Disbursement</p>
                        </div>
                      </div>

                      <div className="grid grid-cols-4 gap-2 pt-2 border-t border-slate-100 dark:border-slate-700/60 text-[11px]">
                        <div>
                          <span className="text-slate-400 text-[10px]">Base</span>
                          <p className="font-semibold text-slate-700 dark:text-slate-300">${pr.baseSalary}</p>
                        </div>
                        <div>
                          <span className="text-slate-400 text-[10px]">Allowances</span>
                          <p className="font-semibold text-slate-700 dark:text-slate-300">+${pr.totalAllowances}</p>
                        </div>
                        <div>
                          <span className="text-slate-400 text-[10px]">Overtime</span>
                          <p className="font-semibold text-blue-600 dark:text-blue-400">+${pr.overtimePay}</p>
                        </div>
                        <div>
                          <span className="text-slate-400 text-[10px]">Deductions</span>
                          <p className="font-semibold text-rose-600 dark:text-rose-400">-${(pr.taxDeduction + pr.pfDeduction + (pr.otherDeductions || 0)).toFixed(0)}</p>
                        </div>
                      </div>
                    </div>
                  ))}
                </div>
              )}
            </div>
          )}

          {activeTab === 'leaves' && (
            <div className="space-y-4">
              <span className="text-xs font-semibold text-slate-700 dark:text-slate-300">
                Leave History & Requests
              </span>

              {empLeaves.length === 0 ? (
                <div className="p-8 text-center bg-slate-50 dark:bg-slate-800/30 rounded-xl border border-dashed border-slate-200 dark:border-slate-700 text-xs text-slate-500">
                  No leave requests submitted.
                </div>
              ) : (
                <div className="space-y-2">
                  {empLeaves.map((l) => (
                    <div
                      key={l.id}
                      className="p-3 bg-white dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-xl text-xs flex items-center justify-between"
                    >
                      <div>
                        <div className="flex items-center space-x-2">
                          <span className="font-semibold text-slate-800 dark:text-slate-200 capitalize">
                            {l.leaveType} Leave ({l.totalDays} days)
                          </span>
                          <span
                            className={`text-[10px] px-1.5 py-0.5 rounded-full capitalize font-semibold ${
                              l.status === 'approved'
                                ? 'bg-emerald-100 text-emerald-800 dark:bg-emerald-900/40 dark:text-emerald-300'
                                : l.status === 'pending'
                                ? 'bg-amber-100 text-amber-800 dark:bg-amber-900/40 dark:text-amber-300'
                                : 'bg-rose-100 text-rose-800 dark:bg-rose-900/40 dark:text-rose-300'
                            }`}
                          >
                            {l.status}
                          </span>
                        </div>
                        <p className="text-[11px] text-slate-500 mt-0.5">
                          {l.startDate} to {l.endDate} &bull; Reason: {l.reason}
                        </p>
                      </div>
                      {l.approvedBy && (
                        <span className="text-[10px] text-slate-400">By: {l.approvedBy}</span>
                      )}
                    </div>
                  ))}
                </div>
              )}
            </div>
          )}

          {activeTab === 'audit' && (
            <div className="space-y-4">
              <span className="text-xs font-semibold text-slate-700 dark:text-slate-300">
                Immutable Employee Audit Trail
              </span>

              {empAuditLogs.length === 0 ? (
                <div className="p-8 text-center bg-slate-50 dark:bg-slate-800/30 rounded-xl border border-dashed border-slate-200 dark:border-slate-700 text-xs text-slate-500">
                  No direct audit modifications recorded.
                </div>
              ) : (
                <div className="space-y-2">
                  {empAuditLogs.map((log) => (
                    <div
                      key={log.id}
                      className="p-3 bg-white dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-xl text-xs space-y-1"
                    >
                      <div className="flex items-center justify-between">
                        <span className="font-semibold text-slate-800 dark:text-slate-200">{log.summary}</span>
                        <span className="text-[10px] text-slate-400 font-mono">
                          {new Date(log.timestamp).toLocaleTimeString()}
                        </span>
                      </div>
                      <p className="text-[11px] text-slate-500">
                        By: {log.userEmail} &bull; Action: <span className="font-mono text-blue-600">{log.action}</span>
                      </p>
                    </div>
                  ))}
                </div>
              )}
            </div>
          )}
        </div>
      </div>
    </div>
  );
};
