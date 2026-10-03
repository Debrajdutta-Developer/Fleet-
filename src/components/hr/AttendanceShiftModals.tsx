import React, { useState } from 'react';
import { useFleet } from '../../context/FleetContext';
import { Shift, LeaveType, AttendanceStatus, PayrollRecord } from '../../types';
import {
  X,
  Clock,
  Calendar,
  DollarSign,
  CheckCircle2,
  AlertCircle,
  FileText,
  MapPin,
  Send,
  Building,
  User
} from 'lucide-react';

// ================= SHIFT MODAL =================
interface ShiftModalProps {
  shift?: Shift | null;
  onClose: () => void;
}

export const ShiftModal: React.FC<ShiftModalProps> = ({ shift, onClose }) => {
  const { addShift, updateShift } = useFleet();
  const isEditing = Boolean(shift);

  const [name, setName] = useState(shift?.name || '');
  const [startTime, setStartTime] = useState(shift?.startTime || '08:00');
  const [endTime, setEndTime] = useState(shift?.endTime || '17:00');
  const [gracePeriodMins, setGracePeriodMins] = useState(shift?.gracePeriodMins || 15);
  const [isNightShift, setIsNightShift] = useState(shift?.isNightShift || false);
  const [error, setError] = useState<string | null>(null);

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!name.trim()) {
      setError('Shift name is required.');
      return;
    }

    if (isEditing && shift) {
      const res = updateShift(shift.id, {
        name,
        startTime,
        endTime,
        gracePeriodMins: Number(gracePeriodMins),
        isNightShift,
      });
      if (!res.success) {
        setError(res.error || 'Failed to update shift.');
        return;
      }
    } else {
      const res = addShift({
        name,
        startTime,
        endTime,
        gracePeriodMins: Number(gracePeriodMins),
        isNightShift,
        workingDays: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'],
      });
      if (!res.success) {
        setError(res.error || 'Failed to create shift.');
        return;
      }
    }
    onClose();
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-900/60 backdrop-blur-xs">
      <div className="bg-white dark:bg-slate-900 rounded-2xl shadow-2xl border border-slate-200 dark:border-slate-800 w-full max-w-md overflow-hidden animate-in fade-in zoom-in-95 duration-150">
        <div className="px-6 py-4 border-b border-slate-100 dark:border-slate-800 flex items-center justify-between bg-slate-50/50 dark:bg-slate-800/40">
          <div className="flex items-center space-x-3">
            <div className="h-9 w-9 rounded-xl bg-blue-100 dark:bg-blue-900/40 text-blue-600 dark:text-blue-400 flex items-center justify-center">
              <Clock className="h-5 w-5" />
            </div>
            <h2 className="text-base font-bold text-slate-900 dark:text-white">
              {isEditing ? `Edit Shift: ${shift?.name ?? ''}` : 'Create Shift Schedule'}
            </h2>
          </div>
          <button onClick={onClose} className="text-slate-400 hover:text-slate-600 dark:hover:text-slate-200">
            <X className="h-5 w-5" />
          </button>
        </div>

        <form onSubmit={handleSubmit} className="p-6 space-y-4">
          {error && (
            <div className="p-3 bg-rose-50 dark:bg-rose-900/30 border border-rose-200 dark:border-rose-800 rounded-lg text-xs text-rose-700 dark:text-rose-300">
              {error}
            </div>
          )}

          <div>
            <label className="block text-xs font-medium text-slate-700 dark:text-slate-300 mb-1">
              Shift Name *
            </label>
            <input
              type="text"
              required
              value={name}
              onChange={(e) => setName(e.target.value)}
              placeholder="e.g. Morning Dispatch Shift"
              className="w-full px-3 py-2 text-xs bg-white dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-lg outline-none"
            />
          </div>

          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-xs font-medium text-slate-700 dark:text-slate-300 mb-1">
                Start Time
              </label>
              <input
                type="time"
                value={startTime}
                onChange={(e) => setStartTime(e.target.value)}
                className="w-full px-3 py-2 text-xs bg-white dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-lg outline-none"
              />
            </div>
            <div>
              <label className="block text-xs font-medium text-slate-700 dark:text-slate-300 mb-1">
                End Time
              </label>
              <input
                type="time"
                value={endTime}
                onChange={(e) => setEndTime(e.target.value)}
                className="w-full px-3 py-2 text-xs bg-white dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-lg outline-none"
              />
            </div>
          </div>

          <div className="grid grid-cols-2 gap-4 items-center">
            <div>
              <label className="block text-xs font-medium text-slate-700 dark:text-slate-300 mb-1">
                Grace Period (Mins)
              </label>
              <input
                type="number"
                min={0}
                max={60}
                value={gracePeriodMins}
                onChange={(e) => setGracePeriodMins(Number(e.target.value))}
                className="w-full px-3 py-2 text-xs bg-white dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-lg outline-none"
              />
            </div>
            <div className="pt-4">
              <label className="flex items-center space-x-2 text-xs font-medium text-slate-700 dark:text-slate-300 cursor-pointer">
                <input
                  type="checkbox"
                  checked={isNightShift}
                  onChange={(e) => setIsNightShift(e.target.checked)}
                  className="rounded text-blue-600 focus:ring-blue-500"
                />
                <span>Overnight / Night Shift</span>
              </label>
            </div>
          </div>

          <div className="pt-4 border-t border-slate-100 dark:border-slate-800 flex justify-end space-x-2">
            <button
              type="button"
              onClick={onClose}
              className="px-4 py-2 text-xs font-semibold text-slate-600 dark:text-slate-400 hover:bg-slate-100 dark:hover:bg-slate-800 rounded-lg"
            >
              Cancel
            </button>
            <button
              type="submit"
              className="px-4 py-2 text-xs font-semibold bg-blue-600 hover:bg-blue-700 text-white rounded-lg shadow-sm"
            >
              {isEditing ? 'Save Shift' : 'Create Shift'}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
};

// ================= LEAVE REQUEST MODAL =================
interface LeaveModalProps {
  onClose: () => void;
}

export const LeaveRequestModal: React.FC<LeaveModalProps> = ({ onClose }) => {
  const { employees, applyLeaveRequest } = useFleet();

  const [employeeId, setEmployeeId] = useState(employees[0]?.id || '');
  const [leaveType, setLeaveType] = useState<LeaveType>('annual');
  const [startDate, setStartDate] = useState(new Date().toISOString().split('T')[0]);
  const [endDate, setEndDate] = useState(new Date().toISOString().split('T')[0]);
  const [totalDays, setTotalDays] = useState(1);
  const [reason, setReason] = useState('');
  const [error, setError] = useState<string | null>(null);

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!reason.trim()) {
      setError('Please state the purpose of the leave request.');
      return;
    }

    const res = applyLeaveRequest({
      employeeId,
      leaveType,
      startDate,
      endDate,
      totalDays: Number(totalDays),
      reason,
    });

    if (!res.success) {
      setError(res.error || 'Failed to submit leave.');
      return;
    }

    onClose();
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-900/60 backdrop-blur-xs">
      <div className="bg-white dark:bg-slate-900 rounded-2xl shadow-2xl border border-slate-200 dark:border-slate-800 w-full max-w-md overflow-hidden animate-in fade-in zoom-in-95 duration-150">
        <div className="px-6 py-4 border-b border-slate-100 dark:border-slate-800 flex items-center justify-between bg-slate-50/50 dark:bg-slate-800/40">
          <div className="flex items-center space-x-3">
            <div className="h-9 w-9 rounded-xl bg-amber-100 dark:bg-amber-900/40 text-amber-600 dark:text-amber-400 flex items-center justify-center">
              <Calendar className="h-5 w-5" />
            </div>
            <h2 className="text-base font-bold text-slate-900 dark:text-white">
              Apply Employee Leave Request
            </h2>
          </div>
          <button onClick={onClose} className="text-slate-400 hover:text-slate-600 dark:hover:text-slate-200">
            <X className="h-5 w-5" />
          </button>
        </div>

        <form onSubmit={handleSubmit} className="p-6 space-y-4">
          {error && (
            <div className="p-3 bg-rose-50 dark:bg-rose-900/30 border border-rose-200 dark:border-rose-800 rounded-lg text-xs text-rose-700 dark:text-rose-300">
              {error}
            </div>
          )}

          <div>
            <label className="block text-xs font-medium text-slate-700 dark:text-slate-300 mb-1">
              Select Employee *
            </label>
            <select
              value={employeeId}
              onChange={(e) => setEmployeeId(e.target.value)}
              className="w-full px-3 py-2 text-xs bg-white dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-lg outline-none"
            >
              {employees
                .filter((e) => !e.deletedAt)
                .map((emp) => (
                  <option key={emp.id} value={emp.id}>
                    {emp.fullName} ({emp.employeeCode})
                  </option>
                ))}
            </select>
          </div>

          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-xs font-medium text-slate-700 dark:text-slate-300 mb-1">
                Leave Type
              </label>
              <select
                value={leaveType}
                onChange={(e) => setLeaveType(e.target.value as any)}
                className="w-full px-3 py-2 text-xs bg-white dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-lg outline-none"
              >
                <option value="annual">Annual / Vacation</option>
                <option value="sick">Medical / Sick</option>
                <option value="casual">Casual Leave</option>
                <option value="maternity">Maternity / Paternity</option>
                <option value="unpaid">Unpaid Leave</option>
              </select>
            </div>
            <div>
              <label className="block text-xs font-medium text-slate-700 dark:text-slate-300 mb-1">
                Total Days
              </label>
              <input
                type="number"
                min={0.5}
                step={0.5}
                value={totalDays}
                onChange={(e) => setTotalDays(Number(e.target.value))}
                className="w-full px-3 py-2 text-xs bg-white dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-lg outline-none"
              />
            </div>
          </div>

          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-xs font-medium text-slate-700 dark:text-slate-300 mb-1">
                Start Date
              </label>
              <input
                type="date"
                value={startDate}
                onChange={(e) => setStartDate(e.target.value)}
                className="w-full px-3 py-2 text-xs bg-white dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-lg outline-none"
              />
            </div>
            <div>
              <label className="block text-xs font-medium text-slate-700 dark:text-slate-300 mb-1">
                End Date
              </label>
              <input
                type="date"
                value={endDate}
                onChange={(e) => setEndDate(e.target.value)}
                className="w-full px-3 py-2 text-xs bg-white dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-lg outline-none"
              />
            </div>
          </div>

          <div>
            <label className="block text-xs font-medium text-slate-700 dark:text-slate-300 mb-1">
              Reason / Remarks *
            </label>
            <textarea
              required
              rows={2}
              value={reason}
              onChange={(e) => setReason(e.target.value)}
              placeholder="e.g. Scheduled medical appointment and recovery"
              className="w-full px-3 py-2 text-xs bg-white dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-lg outline-none"
            />
          </div>

          <div className="pt-4 border-t border-slate-100 dark:border-slate-800 flex justify-end space-x-2">
            <button
              type="button"
              onClick={onClose}
              className="px-4 py-2 text-xs font-semibold text-slate-600 dark:text-slate-400 hover:bg-slate-100 dark:hover:bg-slate-800 rounded-lg"
            >
              Cancel
            </button>
            <button
              type="submit"
              className="px-4 py-2 text-xs font-semibold bg-amber-600 hover:bg-amber-700 text-white rounded-lg shadow-sm"
            >
              Submit Application
            </button>
          </div>
        </form>
      </div>
    </div>
  );
};

// ================= ITEM PAYSLIP MODAL =================
interface PayslipModalProps {
  payroll: PayrollRecord;
  onClose: () => void;
}

export const PayslipModal: React.FC<PayslipModalProps> = ({ payroll, onClose }) => {
  const { currentCompany, employees, departments, designations } = useFleet();
  const emp = employees.find((e) => e.id === payroll.employeeId);
  const dept = departments.find((d) => d.id === emp?.departmentId);
  const desig = designations.find((d) => d.id === emp?.designationId);

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-900/60 backdrop-blur-xs">
      <div className="bg-white dark:bg-slate-900 rounded-2xl shadow-2xl border border-slate-200 dark:border-slate-800 w-full max-w-2xl overflow-hidden animate-in fade-in zoom-in-95 duration-150">
        {/* Header */}
        <div className="p-6 bg-slate-900 text-white flex items-center justify-between">
          <div className="flex items-center space-x-3">
            <div className="h-10 w-10 rounded-xl bg-blue-600 flex items-center justify-center font-bold text-lg">
              <FileText className="h-5 w-5" />
            </div>
            <div>
              <h2 className="text-lg font-bold font-display">{currentCompany.name}</h2>
              <p className="text-xs text-slate-400">Enterprise Salary Statement & Payslip &bull; {payroll.payrollMonth}</p>
            </div>
          </div>
          <button onClick={onClose} className="text-slate-400 hover:text-white">
            <X className="h-5 w-5" />
          </button>
        </div>

        {/* Payslip Body */}
        <div className="p-6 space-y-6 max-h-[80vh] overflow-y-auto">
          {/* Employee Details Grid */}
          <div className="grid grid-cols-2 sm:grid-cols-4 gap-3 p-4 bg-slate-50 dark:bg-slate-800/40 rounded-xl text-xs">
            <div>
              <span className="text-slate-400 text-[10px]">Employee Name</span>
              <p className="font-bold text-slate-800 dark:text-slate-200">{emp?.fullName}</p>
            </div>
            <div>
              <span className="text-slate-400 text-[10px]">Employee Code</span>
              <p className="font-semibold text-slate-800 dark:text-slate-200 font-mono">{emp?.employeeCode}</p>
            </div>
            <div>
              <span className="text-slate-400 text-[10px]">Department</span>
              <p className="font-semibold text-slate-800 dark:text-slate-200">{dept?.name}</p>
            </div>
            <div>
              <span className="text-slate-400 text-[10px]">Designation</span>
              <p className="font-semibold text-slate-800 dark:text-slate-200">{desig?.title}</p>
            </div>
          </div>

          {/* Attendance telemetry breakdown */}
          <div className="grid grid-cols-3 gap-3 text-center text-xs">
            <div className="p-2.5 bg-blue-50 dark:bg-blue-950/30 border border-blue-200 dark:border-blue-800/60 rounded-xl">
              <span className="text-blue-700 dark:text-blue-300 text-[10px]">Days Present</span>
              <p className="font-bold text-blue-900 dark:text-blue-100 text-base">{payroll.daysPresent} Days</p>
            </div>
            <div className="p-2.5 bg-purple-50 dark:bg-purple-950/30 border border-purple-200 dark:border-purple-800/60 rounded-xl">
              <span className="text-purple-700 dark:text-purple-300 text-[10px]">Overtime Hours</span>
              <p className="font-bold text-purple-900 dark:text-purple-100 text-base">{payroll.overtimeHours} Hours</p>
            </div>
            <div className="p-2.5 bg-emerald-50 dark:bg-emerald-950/30 border border-emerald-200 dark:border-emerald-800/60 rounded-xl">
              <span className="text-emerald-700 dark:text-emerald-300 text-[10px]">Payment Status</span>
              <p className="font-bold text-emerald-900 dark:text-emerald-100 text-base capitalize">{payroll.status}</p>
            </div>
          </div>

          {/* Earnings vs Deductions Table */}
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4 text-xs">
            {/* Earnings */}
            <div className="border border-slate-200 dark:border-slate-700 rounded-xl p-4 space-y-2">
              <h4 className="font-bold text-slate-900 dark:text-white border-b pb-2 border-slate-100 dark:border-slate-700">
                Earnings (USD)
              </h4>
              <div className="flex justify-between py-1 border-b border-slate-50 dark:border-slate-800">
                <span className="text-slate-500">Base Monthly Salary</span>
                <span className="font-semibold">${payroll.baseSalary.toLocaleString()}</span>
              </div>
              <div className="flex justify-between py-1 border-b border-slate-50 dark:border-slate-800">
                <span className="text-slate-500">Allowances (HRA/Transport/Medical)</span>
                <span className="font-semibold">+${payroll.totalAllowances.toLocaleString()}</span>
              </div>
              <div className="flex justify-between py-1 border-b border-slate-50 dark:border-slate-800">
                <span className="text-slate-500">Overtime Premium</span>
                <span className="font-semibold text-blue-600">+${payroll.overtimePay.toLocaleString()}</span>
              </div>
              <div className="flex justify-between pt-2 font-bold text-slate-900 dark:text-white">
                <span>Gross Earnings</span>
                <span>${payroll.grossSalary.toLocaleString()}</span>
              </div>
            </div>

            {/* Deductions */}
            <div className="border border-slate-200 dark:border-slate-700 rounded-xl p-4 space-y-2">
              <h4 className="font-bold text-slate-900 dark:text-white border-b pb-2 border-slate-100 dark:border-slate-700">
                Deductions (USD)
              </h4>
              <div className="flex justify-between py-1 border-b border-slate-50 dark:border-slate-800">
                <span className="text-slate-500">Income Tax Withholding</span>
                <span className="font-semibold text-rose-600">-${payroll.taxDeduction.toLocaleString()}</span>
              </div>
              <div className="flex justify-between py-1 border-b border-slate-50 dark:border-slate-800">
                <span className="text-slate-500">Provident Fund (PF / 401k)</span>
                <span className="font-semibold text-rose-600">-${payroll.pfDeduction.toLocaleString()}</span>
              </div>
              <div className="flex justify-between py-1 border-b border-slate-50 dark:border-slate-800">
                <span className="text-slate-500">Other Deductions</span>
                <span className="font-semibold text-rose-600">-${payroll.otherDeductions || 0}</span>
              </div>
              <div className="flex justify-between pt-2 font-bold text-rose-600 dark:text-rose-400">
                <span>Total Deductions</span>
                <span>-${(payroll.taxDeduction + payroll.pfDeduction + (payroll.otherDeductions || 0)).toFixed(2)}</span>
              </div>
            </div>
          </div>

          {/* Net Take-home box */}
          <div className="p-4 bg-emerald-50 dark:bg-emerald-950/40 border border-emerald-200 dark:border-emerald-800 rounded-xl flex items-center justify-between">
            <div>
              <span className="text-xs text-emerald-800 dark:text-emerald-200 font-semibold">
                Net Disbursed Compensation
              </span>
              <p className="text-xs text-emerald-600 dark:text-emerald-400 mt-0.5">
                Method: <span className="capitalize">{payroll.paymentMethod.replace('_', ' ')}</span> &bull; Ref: {payroll.transactionRef || 'Pending Release'}
              </p>
            </div>
            <div className="text-right">
              <span className="text-2xl font-bold font-display text-emerald-700 dark:text-emerald-300">
                ${payroll.netSalary.toLocaleString()}
              </span>
            </div>
          </div>
        </div>

        {/* Footer */}
        <div className="px-6 py-4 bg-slate-50 dark:bg-slate-800/40 border-t border-slate-200 dark:border-slate-800 flex justify-end">
          <button
            onClick={onClose}
            className="px-4 py-2 bg-slate-900 dark:bg-slate-100 text-white dark:text-slate-900 text-xs font-semibold rounded-lg hover:opacity-90 transition"
          >
            Close Statement
          </button>
        </div>
      </div>
    </div>
  );
};
