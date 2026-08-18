import React, { useState } from 'react';
import { useFleet } from '../../context/FleetContext';
import { Employee, EmploymentType, UserRole } from '../../types';
import { X, User, Briefcase, DollarSign, Shield, Truck, AlertCircle } from 'lucide-react';

interface EmployeeModalProps {
  employee?: Employee | null;
  onClose: () => void;
}

export const EmployeeModal: React.FC<EmployeeModalProps> = ({ employee, onClose }) => {
  const {
    currentCompany,
    departments,
    designations,
    shifts,
    drivers,
    addEmployee,
    updateEmployee,
  } = useFleet();

  const isEditing = Boolean(employee);

  // Basic Details
  const [employeeCode, setEmployeeCode] = useState(employee?.employeeCode || `EMP-${Math.floor(1000 + Math.random() * 9000)}`);
  const [fullName, setFullName] = useState(employee?.fullName || '');
  const [email, setEmail] = useState(employee?.email || '');
  const [phone, setPhone] = useState(employee?.phone || '+1 (555) ');
  const [dateOfBirth, setDateOfBirth] = useState(employee?.dateOfBirth || '1992-05-15');
  const [gender, setGender] = useState<'male' | 'female' | 'other'>(employee?.gender || 'male');
  const [joiningDate, setJoiningDate] = useState(employee?.joiningDate || new Date().toISOString().split('T')[0]);
  const [employmentType, setEmploymentType] = useState<EmploymentType>(employee?.employmentType || 'full_time');
  const [departmentId, setDepartmentId] = useState(employee?.departmentId || (departments[0]?.id || ''));
  const [designationId, setDesignationId] = useState(employee?.designationId || (designations[0]?.id || ''));
  const [shiftId, setShiftId] = useState(employee?.shiftId || (shifts[0]?.id || ''));
  const [role, setRole] = useState<UserRole>(employee?.role || 'driver');
  const [status, setStatus] = useState<Employee['status']>(employee?.status || 'active');

  // Driver linkage
  const [isDriver, setIsDriver] = useState(employee?.isDriver ?? true);
  const [linkedDriverId, setLinkedDriverId] = useState(employee?.linkedDriverId || '');

  // Salary Structure
  const [baseSalary, setBaseSalary] = useState(employee?.salaryStructure.baseSalary || 4500);
  const [hraAllowance, setHraAllowance] = useState(employee?.salaryStructure.hraAllowance || 600);
  const [transportAllowance, setTransportAllowance] = useState(employee?.salaryStructure.transportAllowance || 400);
  const [medicalAllowance, setMedicalAllowance] = useState(employee?.salaryStructure.medicalAllowance || 250);
  const [specialAllowance, setSpecialAllowance] = useState(employee?.salaryStructure.specialAllowance || 150);
  const [taxDeductionPercent, setTaxDeductionPercent] = useState(employee?.salaryStructure.taxDeductionPercent || 12);
  const [providentFundDeduction, setProvidentFundDeduction] = useState(employee?.salaryStructure.providentFundDeduction || 200);

  // Bank & Emergency
  const [bankName, setBankName] = useState(employee?.bankAccount?.bankName || 'JPMorgan Chase');
  const [accountNumber, setAccountNumber] = useState(employee?.bankAccount?.accountNumber || '8472910394');
  const [routingNumber, setRoutingNumber] = useState(employee?.bankAccount?.routingNumber || '021000021');
  const [emergencyName, setEmergencyName] = useState(employee?.emergencyContact?.name || '');
  const [emergencyPhone, setEmergencyPhone] = useState(employee?.emergencyContact?.phone || '');
  const [emergencyRelation, setEmergencyRelation] = useState(employee?.emergencyContact?.relationship || 'Spouse');

  const [activeTab, setActiveTab] = useState<'basic' | 'job' | 'salary' | 'bank'>('basic');
  const [error, setError] = useState<string | null>(null);

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);

    if (!fullName.trim() || !email.trim() || !employeeCode.trim()) {
      setError('Please fill in all mandatory identification fields.');
      return;
    }

    const payload = {
      employeeCode,
      fullName,
      email,
      phone,
      dateOfBirth,
      gender,
      joiningDate,
      employmentType,
      departmentId,
      designationId,
      shiftId,
      role,
      status,
      isDriver,
      linkedDriverId: isDriver ? linkedDriverId || undefined : undefined,
      salaryStructure: {
        baseSalary: Number(baseSalary),
        hraAllowance: Number(hraAllowance),
        transportAllowance: Number(transportAllowance),
        medicalAllowance: Number(medicalAllowance),
        specialAllowance: Number(specialAllowance),
        performanceBonus: 0,
        taxDeductionPercent: Number(taxDeductionPercent),
        providentFundDeduction: Number(providentFundDeduction),
      },
      bankAccount: {
        bankName,
        accountNumber,
        routingNumber,
        accountHolderName: fullName,
      },
      emergencyContact: emergencyName
        ? {
            name: emergencyName,
            phone: emergencyPhone,
            relationship: emergencyRelation,
          }
        : undefined,
    };

    if (isEditing && employee) {
      const res = updateEmployee(employee.id, payload);
      if (!res.success) {
        setError(res.error || 'Failed to update employee.');
        return;
      }
    } else {
      const res = addEmployee(payload);
      if (!res.success) {
        setError(res.error || 'Failed to create employee.');
        return;
      }
    }

    onClose();
  };

  const totalAllowances = Number(hraAllowance) + Number(transportAllowance) + Number(medicalAllowance) + Number(specialAllowance);
  const grossMonthly = Number(baseSalary) + totalAllowances;
  const taxEst = (grossMonthly * Number(taxDeductionPercent)) / 100;
  const netMonthly = grossMonthly - taxEst - Number(providentFundDeduction);

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-900/60 backdrop-blur-xs overflow-y-auto">
      <div className="bg-white dark:bg-slate-900 rounded-2xl shadow-2xl border border-slate-200 dark:border-slate-800 w-full max-w-3xl max-h-[90vh] flex flex-col overflow-hidden animate-in fade-in zoom-in-95 duration-150">
        {/* Header */}
        <div className="px-6 py-4 border-b border-slate-100 dark:border-slate-800 flex items-center justify-between bg-slate-50/50 dark:bg-slate-800/40">
          <div className="flex items-center space-x-3">
            <div className="h-10 w-10 rounded-xl bg-blue-100 dark:bg-blue-900/40 text-blue-600 dark:text-blue-400 flex items-center justify-center">
              <User className="h-5 w-5" />
            </div>
            <div>
              <h2 className="text-lg font-bold text-slate-900 dark:text-white">
                {isEditing ? `Edit Employee: ${employee.fullName}` : 'Onboard New Employee'}
              </h2>
              <p className="text-xs text-slate-500 dark:text-slate-400">
                Company: <span className="font-semibold text-slate-700 dark:text-slate-300">{currentCompany.name}</span>
              </p>
            </div>
          </div>
          <button
            onClick={onClose}
            className="p-1.5 text-slate-400 hover:text-slate-600 dark:hover:text-slate-200 rounded-lg hover:bg-slate-100 dark:hover:bg-slate-800 transition"
          >
            <X className="h-5 w-5" />
          </button>
        </div>

        {/* Tab Navigation */}
        <div className="flex border-b border-slate-200 dark:border-slate-800 px-6 bg-slate-50 dark:bg-slate-900">
          <button
            type="button"
            onClick={() => setActiveTab('basic')}
            className={`py-3 px-4 text-xs font-semibold border-b-2 flex items-center space-x-2 transition ${
              activeTab === 'basic'
                ? 'border-blue-600 text-blue-600 dark:text-blue-400'
                : 'border-transparent text-slate-500 hover:text-slate-800 dark:hover:text-slate-200'
            }`}
          >
            <User className="h-3.5 w-3.5" />
            <span>Personal Info</span>
          </button>
          <button
            type="button"
            onClick={() => setActiveTab('job')}
            className={`py-3 px-4 text-xs font-semibold border-b-2 flex items-center space-x-2 transition ${
              activeTab === 'job'
                ? 'border-blue-600 text-blue-600 dark:text-blue-400'
                : 'border-transparent text-slate-500 hover:text-slate-800 dark:hover:text-slate-200'
            }`}
          >
            <Briefcase className="h-3.5 w-3.5" />
            <span>Role & Designation</span>
          </button>
          <button
            type="button"
            onClick={() => setActiveTab('salary')}
            className={`py-3 px-4 text-xs font-semibold border-b-2 flex items-center space-x-2 transition ${
              activeTab === 'salary'
                ? 'border-blue-600 text-blue-600 dark:text-blue-400'
                : 'border-transparent text-slate-500 hover:text-slate-800 dark:hover:text-slate-200'
            }`}
          >
            <DollarSign className="h-3.5 w-3.5" />
            <span>Salary & Compensation</span>
          </button>
          <button
            type="button"
            onClick={() => setActiveTab('bank')}
            className={`py-3 px-4 text-xs font-semibold border-b-2 flex items-center space-x-2 transition ${
              activeTab === 'bank'
                ? 'border-blue-600 text-blue-600 dark:text-blue-400'
                : 'border-transparent text-slate-500 hover:text-slate-800 dark:hover:text-slate-200'
            }`}
          >
            <Shield className="h-3.5 w-3.5" />
            <span>Bank & Emergency</span>
          </button>
        </div>

        {/* Form Body */}
        <form onSubmit={handleSubmit} className="flex-1 overflow-y-auto p-6 space-y-4">
          {error && (
            <div className="p-3 bg-rose-50 dark:bg-rose-900/30 border border-rose-200 dark:border-rose-800 rounded-xl text-xs text-rose-700 dark:text-rose-300 flex items-center space-x-2">
              <AlertCircle className="h-4 w-4 shrink-0" />
              <span>{error}</span>
            </div>
          )}

          {activeTab === 'basic' && (
            <div className="space-y-4">
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                <div>
                  <label className="block text-xs font-medium text-slate-700 dark:text-slate-300 mb-1">
                    Employee Code *
                  </label>
                  <input
                    type="text"
                    required
                    value={employeeCode}
                    onChange={(e) => setEmployeeCode(e.target.value)}
                    className="w-full px-3 py-2 text-sm bg-white dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-lg focus:ring-2 focus:ring-blue-500 outline-none"
                    placeholder="e.g. EMP-1044"
                  />
                </div>
                <div>
                  <label className="block text-xs font-medium text-slate-700 dark:text-slate-300 mb-1">
                    Full Legal Name *
                  </label>
                  <input
                    type="text"
                    required
                    value={fullName}
                    onChange={(e) => setFullName(e.target.value)}
                    className="w-full px-3 py-2 text-sm bg-white dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-lg focus:ring-2 focus:ring-blue-500 outline-none"
                    placeholder="e.g. Marcus Vance"
                  />
                </div>
              </div>

              <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                <div>
                  <label className="block text-xs font-medium text-slate-700 dark:text-slate-300 mb-1">
                    Work Email *
                  </label>
                  <input
                    type="email"
                    required
                    value={email}
                    onChange={(e) => setEmail(e.target.value)}
                    className="w-full px-3 py-2 text-sm bg-white dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-lg focus:ring-2 focus:ring-blue-500 outline-none"
                    placeholder="e.g. marcus@apexlogistics.com"
                  />
                </div>
                <div>
                  <label className="block text-xs font-medium text-slate-700 dark:text-slate-300 mb-1">
                    Contact Phone *
                  </label>
                  <input
                    type="text"
                    required
                    value={phone}
                    onChange={(e) => setPhone(e.target.value)}
                    className="w-full px-3 py-2 text-sm bg-white dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-lg focus:ring-2 focus:ring-blue-500 outline-none"
                    placeholder="+1 (555) 000-0000"
                  />
                </div>
              </div>

              <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
                <div>
                  <label className="block text-xs font-medium text-slate-700 dark:text-slate-300 mb-1">
                    Date of Birth
                  </label>
                  <input
                    type="date"
                    value={dateOfBirth}
                    onChange={(e) => setDateOfBirth(e.target.value)}
                    className="w-full px-3 py-2 text-sm bg-white dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-lg focus:ring-2 focus:ring-blue-500 outline-none"
                  />
                </div>
                <div>
                  <label className="block text-xs font-medium text-slate-700 dark:text-slate-300 mb-1">
                    Gender
                  </label>
                  <select
                    value={gender}
                    onChange={(e) => setGender(e.target.value as any)}
                    className="w-full px-3 py-2 text-sm bg-white dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-lg focus:ring-2 focus:ring-blue-500 outline-none"
                  >
                    <option value="male">Male</option>
                    <option value="female">Female</option>
                    <option value="other">Other / Prefer not to say</option>
                  </select>
                </div>
                <div>
                  <label className="block text-xs font-medium text-slate-700 dark:text-slate-300 mb-1">
                    Joining Date
                  </label>
                  <input
                    type="date"
                    value={joiningDate}
                    onChange={(e) => setJoiningDate(e.target.value)}
                    className="w-full px-3 py-2 text-sm bg-white dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-lg focus:ring-2 focus:ring-blue-500 outline-none"
                  />
                </div>
              </div>

              <div>
                <label className="block text-xs font-medium text-slate-700 dark:text-slate-300 mb-1">
                  Employee Status
                </label>
                <div className="grid grid-cols-4 gap-2">
                  {(['active', 'probation', 'on_leave', 'suspended'] as const).map((st) => (
                    <button
                      key={st}
                      type="button"
                      onClick={() => setStatus(st)}
                      className={`py-2 text-xs font-medium rounded-lg capitalize border transition ${
                        status === st
                          ? 'bg-blue-50 dark:bg-blue-900/40 border-blue-600 text-blue-600 dark:text-blue-400 font-semibold'
                          : 'border-slate-200 dark:border-slate-700 text-slate-600 dark:text-slate-400 hover:bg-slate-50 dark:hover:bg-slate-800'
                      }`}
                    >
                      {st.replace('_', ' ')}
                    </button>
                  ))}
                </div>
              </div>
            </div>
          )}

          {activeTab === 'job' && (
            <div className="space-y-4">
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                <div>
                  <label className="block text-xs font-medium text-slate-700 dark:text-slate-300 mb-1">
                    Department *
                  </label>
                  <select
                    value={departmentId}
                    onChange={(e) => setDepartmentId(e.target.value)}
                    className="w-full px-3 py-2 text-sm bg-white dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-lg focus:ring-2 focus:ring-blue-500 outline-none"
                  >
                    {departments
                      .filter((d) => !d.deletedAt)
                      .map((dept) => (
                        <option key={dept.id} value={dept.id}>
                          {dept.name} ({dept.code})
                        </option>
                      ))}
                  </select>
                </div>
                <div>
                  <label className="block text-xs font-medium text-slate-700 dark:text-slate-300 mb-1">
                    Designation *
                  </label>
                  <select
                    value={designationId}
                    onChange={(e) => setDesignationId(e.target.value)}
                    className="w-full px-3 py-2 text-sm bg-white dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-lg focus:ring-2 focus:ring-blue-500 outline-none"
                  >
                    {designations
                      .filter((d) => !d.deletedAt)
                      .map((desig) => (
                        <option key={desig.id} value={desig.id}>
                          {desig.title} (L{desig.level})
                        </option>
                      ))}
                  </select>
                </div>
              </div>

              <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
                <div>
                  <label className="block text-xs font-medium text-slate-700 dark:text-slate-300 mb-1">
                    Employment Type
                  </label>
                  <select
                    value={employmentType}
                    onChange={(e) => setEmploymentType(e.target.value as any)}
                    className="w-full px-3 py-2 text-sm bg-white dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-lg focus:ring-2 focus:ring-blue-500 outline-none"
                  >
                    <option value="full_time">Full Time</option>
                    <option value="part_time">Part Time</option>
                    <option value="contract">Contract</option>
                    <option value="internship">Internship</option>
                  </select>
                </div>

                <div>
                  <label className="block text-xs font-medium text-slate-700 dark:text-slate-300 mb-1">
                    Shift Schedule *
                  </label>
                  <select
                    value={shiftId}
                    onChange={(e) => setShiftId(e.target.value)}
                    className="w-full px-3 py-2 text-sm bg-white dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-lg focus:ring-2 focus:ring-blue-500 outline-none"
                  >
                    {shifts.map((s) => (
                      <option key={s.id} value={s.id}>
                        {s.name} ({s.startTime} - {s.endTime})
                      </option>
                    ))}
                  </select>
                </div>

                <div>
                  <label className="block text-xs font-medium text-slate-700 dark:text-slate-300 mb-1">
                    System RBAC Role *
                  </label>
                  <select
                    value={role}
                    onChange={(e) => setRole(e.target.value as any)}
                    className="w-full px-3 py-2 text-sm bg-white dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-lg focus:ring-2 focus:ring-blue-500 outline-none"
                  >
                    <option value="driver">Driver</option>
                    <option value="dispatcher">Dispatcher</option>
                    <option value="safety_officer">Safety Officer</option>
                    <option value="financial_auditor">Financial Auditor</option>
                    <option value="fleet_manager">Fleet Manager</option>
                    <option value="super_admin">Super Admin</option>
                  </select>
                </div>
              </div>

              {/* Driver Cross-Integration Box */}
              <div className="p-4 bg-blue-50/70 dark:bg-blue-950/30 border border-blue-200 dark:border-blue-800/60 rounded-xl space-y-3">
                <div className="flex items-center justify-between">
                  <div className="flex items-center space-x-2">
                    <Truck className="h-4 w-4 text-blue-600 dark:text-blue-400" />
                    <span className="text-xs font-semibold text-blue-900 dark:text-blue-200">
                      Fleet Driver Role Integration
                    </span>
                  </div>
                  <label className="relative inline-flex items-center cursor-pointer">
                    <input
                      type="checkbox"
                      checked={isDriver}
                      onChange={(e) => setIsDriver(e.target.checked)}
                      className="sr-only peer"
                    />
                    <div className="w-9 h-5 bg-slate-200 peer-focus:outline-none rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-slate-300 after:border after:rounded-full after:h-4 after:w-4 after:transition-all peer-checked:bg-blue-600"></div>
                  </label>
                </div>

                {isDriver && (
                  <div>
                    <p className="text-xs text-blue-700 dark:text-blue-300 mb-2">
                      When enabled, this employee will be mapped to a Driver entity for vehicle assignments, trip telematics, and safety infractions tracking.
                    </p>
                    <div>
                      <label className="block text-xs font-medium text-blue-900 dark:text-blue-200 mb-1">
                        Link to Existing Driver Record (Optional)
                      </label>
                      <select
                        value={linkedDriverId}
                        onChange={(e) => setLinkedDriverId(e.target.value)}
                        className="w-full px-3 py-2 text-xs bg-white dark:bg-slate-800 border border-blue-200 dark:border-blue-800 rounded-lg outline-none"
                      >
                        <option value="">Auto-create new Driver profile</option>
                        {drivers.map((drv) => (
                          <option key={drv.id} value={drv.id}>
                            {drv.fullName} ({drv.licenseNumber} - {drv.cdlClass})
                          </option>
                        ))}
                      </select>
                    </div>
                  </div>
                )}
              </div>
            </div>
          )}

          {activeTab === 'salary' && (
            <div className="space-y-4">
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                <div>
                  <label className="block text-xs font-medium text-slate-700 dark:text-slate-300 mb-1">
                    Base Salary ($/month) *
                  </label>
                  <input
                    type="number"
                    required
                    min={0}
                    value={baseSalary}
                    onChange={(e) => setBaseSalary(Number(e.target.value))}
                    className="w-full px-3 py-2 text-sm bg-white dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-lg focus:ring-2 focus:ring-blue-500 outline-none"
                  />
                </div>
                <div>
                  <label className="block text-xs font-medium text-slate-700 dark:text-slate-300 mb-1">
                    House Rent Allowance (HRA) ($)
                  </label>
                  <input
                    type="number"
                    min={0}
                    value={hraAllowance}
                    onChange={(e) => setHraAllowance(Number(e.target.value))}
                    className="w-full px-3 py-2 text-sm bg-white dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-lg focus:ring-2 focus:ring-blue-500 outline-none"
                  />
                </div>
              </div>

              <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
                <div>
                  <label className="block text-xs font-medium text-slate-700 dark:text-slate-300 mb-1">
                    Transport Allowance ($)
                  </label>
                  <input
                    type="number"
                    min={0}
                    value={transportAllowance}
                    onChange={(e) => setTransportAllowance(Number(e.target.value))}
                    className="w-full px-3 py-2 text-sm bg-white dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-lg focus:ring-2 focus:ring-blue-500 outline-none"
                  />
                </div>
                <div>
                  <label className="block text-xs font-medium text-slate-700 dark:text-slate-300 mb-1">
                    Medical Allowance ($)
                  </label>
                  <input
                    type="number"
                    min={0}
                    value={medicalAllowance}
                    onChange={(e) => setMedicalAllowance(Number(e.target.value))}
                    className="w-full px-3 py-2 text-sm bg-white dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-lg focus:ring-2 focus:ring-blue-500 outline-none"
                  />
                </div>
                <div>
                  <label className="block text-xs font-medium text-slate-700 dark:text-slate-300 mb-1">
                    Special Allowance ($)
                  </label>
                  <input
                    type="number"
                    min={0}
                    value={specialAllowance}
                    onChange={(e) => setSpecialAllowance(Number(e.target.value))}
                    className="w-full px-3 py-2 text-sm bg-white dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-lg focus:ring-2 focus:ring-blue-500 outline-none"
                  />
                </div>
              </div>

              <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                <div>
                  <label className="block text-xs font-medium text-slate-700 dark:text-slate-300 mb-1">
                    Est. Tax Deduction Rate (%)
                  </label>
                  <input
                    type="number"
                    min={0}
                    max={50}
                    value={taxDeductionPercent}
                    onChange={(e) => setTaxDeductionPercent(Number(e.target.value))}
                    className="w-full px-3 py-2 text-sm bg-white dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-lg focus:ring-2 focus:ring-blue-500 outline-none"
                  />
                </div>
                <div>
                  <label className="block text-xs font-medium text-slate-700 dark:text-slate-300 mb-1">
                    Provident Fund (PF) / 401k ($)
                  </label>
                  <input
                    type="number"
                    min={0}
                    value={providentFundDeduction}
                    onChange={(e) => setProvidentFundDeduction(Number(e.target.value))}
                    className="w-full px-3 py-2 text-sm bg-white dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-lg focus:ring-2 focus:ring-blue-500 outline-none"
                  />
                </div>
              </div>

              {/* Salary Summary Card */}
              <div className="p-4 bg-emerald-50 dark:bg-emerald-950/30 border border-emerald-200 dark:border-emerald-800/60 rounded-xl">
                <div className="flex items-center justify-between text-xs font-semibold text-emerald-900 dark:text-emerald-200 mb-2">
                  <span>Monthly Compensation Calculation</span>
                  <span className="text-emerald-700 dark:text-emerald-300">Live Breakdown</span>
                </div>
                <div className="grid grid-cols-3 gap-2 text-center text-xs">
                  <div className="p-2 bg-white dark:bg-slate-800 rounded-lg shadow-xs">
                    <span className="text-slate-500 text-[10px]">Gross Salary</span>
                    <p className="font-bold text-slate-900 dark:text-white mt-0.5">${grossMonthly.toLocaleString()}</p>
                  </div>
                  <div className="p-2 bg-white dark:bg-slate-800 rounded-lg shadow-xs">
                    <span className="text-slate-500 text-[10px]">Total Deductions</span>
                    <p className="font-bold text-rose-600 dark:text-rose-400 mt-0.5">${(taxEst + Number(providentFundDeduction)).toLocaleString()}</p>
                  </div>
                  <div className="p-2 bg-emerald-600 text-white rounded-lg shadow-xs">
                    <span className="text-emerald-100 text-[10px]">Est. Net Take-home</span>
                    <p className="font-bold mt-0.5">${netMonthly.toLocaleString()}</p>
                  </div>
                </div>
              </div>
            </div>
          )}

          {activeTab === 'bank' && (
            <div className="space-y-4">
              <div className="p-3 bg-slate-50 dark:bg-slate-800/40 rounded-xl space-y-3">
                <h4 className="text-xs font-semibold text-slate-800 dark:text-slate-200">
                  Payroll Direct Deposit Bank Account
                </h4>
                <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
                  <div>
                    <label className="block text-xs font-medium text-slate-600 dark:text-slate-400 mb-1">
                      Bank Institution
                    </label>
                    <input
                      type="text"
                      value={bankName}
                      onChange={(e) => setBankName(e.target.value)}
                      className="w-full px-3 py-2 text-xs bg-white dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-lg outline-none"
                    />
                  </div>
                  <div>
                    <label className="block text-xs font-medium text-slate-600 dark:text-slate-400 mb-1">
                      Account Number
                    </label>
                    <input
                      type="text"
                      value={accountNumber}
                      onChange={(e) => setAccountNumber(e.target.value)}
                      className="w-full px-3 py-2 text-xs bg-white dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-lg outline-none"
                    />
                  </div>
                  <div>
                    <label className="block text-xs font-medium text-slate-600 dark:text-slate-400 mb-1">
                      Routing / SWIFT
                    </label>
                    <input
                      type="text"
                      value={routingNumber}
                      onChange={(e) => setRoutingNumber(e.target.value)}
                      className="w-full px-3 py-2 text-xs bg-white dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-lg outline-none"
                    />
                  </div>
                </div>
              </div>

              <div className="p-3 bg-slate-50 dark:bg-slate-800/40 rounded-xl space-y-3">
                <h4 className="text-xs font-semibold text-slate-800 dark:text-slate-200">
                  Emergency Contact Reference
                </h4>
                <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
                  <div>
                    <label className="block text-xs font-medium text-slate-600 dark:text-slate-400 mb-1">
                      Contact Name
                    </label>
                    <input
                      type="text"
                      placeholder="e.g. Laura Vance"
                      value={emergencyName}
                      onChange={(e) => setEmergencyName(e.target.value)}
                      className="w-full px-3 py-2 text-xs bg-white dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-lg outline-none"
                    />
                  </div>
                  <div>
                    <label className="block text-xs font-medium text-slate-600 dark:text-slate-400 mb-1">
                      Emergency Phone
                    </label>
                    <input
                      type="text"
                      placeholder="+1 (555) 888-9999"
                      value={emergencyPhone}
                      onChange={(e) => setEmergencyPhone(e.target.value)}
                      className="w-full px-3 py-2 text-xs bg-white dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-lg outline-none"
                    />
                  </div>
                  <div>
                    <label className="block text-xs font-medium text-slate-600 dark:text-slate-400 mb-1">
                      Relationship
                    </label>
                    <input
                      type="text"
                      placeholder="Spouse / Parent / Sibling"
                      value={emergencyRelation}
                      onChange={(e) => setEmergencyRelation(e.target.value)}
                      className="w-full px-3 py-2 text-xs bg-white dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-lg outline-none"
                    />
                  </div>
                </div>
              </div>
            </div>
          )}

          {/* Footer Buttons */}
          <div className="pt-4 border-t border-slate-100 dark:border-slate-800 flex items-center justify-between">
            <button
              type="button"
              onClick={onClose}
              className="px-4 py-2 text-xs font-semibold text-slate-600 dark:text-slate-400 hover:bg-slate-100 dark:hover:bg-slate-800 rounded-lg transition"
            >
              Cancel
            </button>
            <div className="flex items-center space-x-2">
              {activeTab !== 'basic' && (
                <button
                  type="button"
                  onClick={() => {
                    if (activeTab === 'bank') setActiveTab('salary');
                    else if (activeTab === 'salary') setActiveTab('job');
                    else if (activeTab === 'job') setActiveTab('basic');
                  }}
                  className="px-3 py-2 text-xs font-semibold border border-slate-200 dark:border-slate-700 text-slate-700 dark:text-slate-300 rounded-lg hover:bg-slate-50 dark:hover:bg-slate-800 transition"
                >
                  &larr; Back
                </button>
              )}
              {activeTab !== 'bank' ? (
                <button
                  type="button"
                  onClick={() => {
                    if (activeTab === 'basic') setActiveTab('job');
                    else if (activeTab === 'job') setActiveTab('salary');
                    else if (activeTab === 'salary') setActiveTab('bank');
                  }}
                  className="px-4 py-2 text-xs font-semibold bg-slate-900 dark:bg-slate-100 text-white dark:text-slate-900 rounded-lg hover:bg-slate-800 transition"
                >
                  Continue &rarr;
                </button>
              ) : (
                <button
                  type="submit"
                  className="px-5 py-2 text-xs font-semibold bg-blue-600 hover:bg-blue-700 text-white rounded-lg shadow-sm transition"
                >
                  {isEditing ? 'Save Employee Profile' : 'Complete Onboarding'}
                </button>
              )}
            </div>
          </div>
        </form>
      </div>
    </div>
  );
};
