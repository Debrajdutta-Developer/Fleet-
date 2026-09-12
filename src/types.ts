export type UserRole = 'super_admin' | 'company_admin' | 'fleet_manager' | 'dispatcher' | 'driver' | 'hr_manager';

export type UserStatus = 'active' | 'suspended' | 'pending';

export interface User {
  uid: string;
  email: string;
  displayName: string;
  role: UserRole;
  companyId: string;
  status: UserStatus;
  avatarUrl?: string;
}

export interface Company {
  id: string;
  name: string;
  logoUrl?: string;
  industry: string;
  fleetSizeTier: string;
  subscriptionTier: 'growth' | 'scale' | 'enterprise';
  isActive: boolean;
  currency: string;
  fastagBalance: number;
}

export type VehicleStatus = 'registration' | 'active' | 'maintenance' | 'idle' | 'sold' | 'archived';
export type FuelType = 'diesel' | 'unleaded' | 'electric' | 'cng';

export interface VehicleTelemetry {
  latitude: number;
  longitude: number;
  speed: number;
  heading: number;
  fuelLevelPercent: number;
  batteryHealthPercent: number;
  engineTempC: number;
  updatedAt: string;
  locationName: string;
}

export interface Vehicle {
  id: string;
  vin: string;
  licensePlate: string;
  make: string;
  model: string;
  year: number;
  status: VehicleStatus;
  statusTag?: string;
  fuelType: FuelType;
  odometer: number;
  maxPayloadKg: number;
  gvwrLbs: number;
  cdlRequired: 'Class A' | 'Class B' | 'Standard';
  lastServiceDate: string;
  lastServiceOdometer: number;
  engineHours: number;
  assignedDriverId?: string;
  telemetry: VehicleTelemetry;
  createdAt: string;
  updatedAt: string;
  deletedAt?: string | null;
}

export type DriverStatus = 'available' | 'on_duty' | 'suspended' | 'off_duty';

export interface Driver {
  id: string;
  employeeId?: string;
  fullName: string;
  phone: string;
  email: string;
  licenseNumber: string;
  cdlClass: 'Class A' | 'Class B' | 'Standard';
  licenseExpiry: string;
  status: DriverStatus;
  safetyScore: number;
  assignedVehicleId?: string;
  totalTripsCompleted: number;
  hoursDrivenThisWeek: number;
  infractions: {
    hardBrakingCount: number;
    speedingCount: number;
    rapidAccelCount: number;
  };
  createdAt: string;
  updatedAt: string;
  deletedAt?: string | null;
}

export type TripStatus = 'planned' | 'assigned' | 'in_transit' | 'completed' | 'cancelled';

export interface Checkpoint {
  id: string;
  address: string;
  locationName: string;
  latitude: number;
  longitude: number;
  status: 'pending' | 'passed' | 'delayed';
  passedAt?: string;
  scheduledArrival: string;
}

export interface Trip {
  id: string;
  tripNumber: string;
  status: TripStatus;
  driverId: string;
  vehicleId: string;
  customerName: string;
  cargo: {
    description: string;
    weightKg: number;
    hazardClass?: string;
  };
  route: {
    startLocationName: string;
    endLocationName: string;
    distanceKm: number;
    estimatedDurationSec: number;
    actualDurationSec?: number;
  };
  checkpoints: Checkpoint[];
  scheduledDeparture: string;
  startedAt?: string;
  completedAt?: string;
  tollFeesEstimated: number;
  freightRevenue: number;
  createdAt: string;
  updatedAt: string;
  deletedAt?: string | null;
}

export interface FuelLog {
  id: string;
  vehicleId: string;
  driverId: string;
  timestamp: string;
  fuelStation: string;
  stationLatitude: number;
  stationLongitude: number;
  fuelAmountLiters: number;
  totalCost: number;
  odometerReading: number;
  calcEconomyKmPerLiter: number;
  riskStatus: 'verified' | 'flagged_discrepancy' | 'high_risk_location';
  auditNotes?: string;
}

export interface MaintenanceTicket {
  id: string;
  ticketNumber: string;
  vehicleId: string;
  type: 'scheduled_pm' | 'breakdown' | 'repair' | 'inspection';
  priority: 'low' | 'medium' | 'high' | 'critical';
  status: 'open' | 'in_progress' | 'waiting_parts' | 'closed';
  issueDescription: string;
  reportedBy: string;
  technicianName?: string;
  estimatedCost: number;
  actualCost?: number;
  serviceOdometer: number;
  createdAt: string;
  closedAt?: string;
  partsReplaced?: string[];
}

export interface ComplianceDocument {
  id: string;
  vehicleId: string;
  documentType: 'RC' | 'Insurance' | 'PUC' | 'Fitness' | 'National Permit' | 'Road Tax';
  documentNumber: string;
  issueDate: string;
  expiryDate: string;
  verificationStatus: 'verified' | 'pending' | 'expired';
  verifiedBy?: string;
  fileUrl?: string;
}

export interface Invoice {
  id: string;
  invoiceNumber: string;
  customerName: string;
  tripId?: string;
  amount: number;
  tax: number;
  totalAmount: number;
  issueDate: string;
  dueDate: string;
  status: 'paid' | 'unpaid' | 'overdue';
  items: {
    description: string;
    rate: number;
    quantity: number;
    amount: number;
  }[];
}

// Enterprise HR & Employee Management Models
// Compatibility aliases preserve legacy forms while the HR module is migrated.
export interface Department {
  id: string;
  companyId: string;
  name: string;
  code: string;
  description: string;
  headOfDepartmentId?: string;
  headOfDepartment?: string;
  location?: string;
  budget?: number;
  createdAt: string;
  updatedAt: string;
  deletedAt?: string | null;
}

export interface Designation {
  id: string;
  companyId: string;
  title: string;
  code?: string;
  departmentId: string;
  description?: string;
  level: 'entry' | 'mid' | 'senior' | 'lead' | 'executive' | number;
  minSalary: number;
  maxSalary: number;
  createdAt: string;
  updatedAt: string;
  deletedAt?: string | null;
}

export interface Shift {
  id: string;
  companyId: string;
  name: string;
  code?: string;
  startTime: string;
  endTime: string;
  breakDurationMins?: number;
  gracePeriodMins: number;
  workingDays: string[];
  isActive?: boolean;
  isNightShift?: boolean;
}

export interface SalaryStructure {
  baseSalary: number;
  hraAllowance: number;
  transportAllowance: number;
  medicalAllowance: number;
  specialAllowance: number;
  performanceBonus: number;
  taxDeductionPercent: number;
  providentFundDeduction: number;
  netMonthlySalary?: number;
}

export type EmploymentType = 'full_time' | 'contract' | 'part_time' | 'probation';
export type EmployeeStatus = 'active' | 'on_leave' | 'suspended' | 'terminated' | 'probation';

export interface Employee {
  id: string;
  companyId: string;
  employeeCode: string;
  firstName?: string;
  lastName?: string;
  fullName: string;
  email: string;
  phone: string;
  avatarUrl?: string;
  departmentId: string;
  designationId: string;
  role: UserRole;
  status: EmployeeStatus;
  employmentType: EmploymentType;
  joinDate?: string;
  joiningDate?: string;
  birthDate?: string;
  dateOfBirth?: string;
  gender?: 'male' | 'female' | 'other';
  shiftId: string;
  isDriver: boolean;
  linkedDriverId?: string;
  salaryStructure: SalaryStructure;
  bankDetails?: {
    bankName: string;
    accountNumber: string;
    routingOrIfsc: string;
  };
  bankAccount?: {
    bankName: string;
    accountNumber: string;
    routingNumber: string;
    accountHolderName?: string;
  };
  emergencyContact?: {
    name: string;
    relation?: string;
    relationship?: string;
    phone: string;
  };
  createdAt: string;
  updatedAt: string;
  deletedAt?: string | null;
}

export type AttendanceStatus = 'present' | 'late' | 'half_day' | 'absent' | 'on_leave';

export interface AttendanceRecord {
  id: string;
  companyId: string;
  employeeId: string;
  date: string;
  checkInTime: string;
  checkOutTime?: string;
  status: AttendanceStatus;
  shiftId?: string;
  hoursWorked: number;
  overtimeHours: number;
  clockInLatitude?: number;
  clockInLongitude?: number;
  locationName?: string;
  notes?: string;
}

export type LeaveType = 'annual' | 'sick' | 'casual' | 'maternity_paternity' | 'unpaid';
export type LeaveStatus = 'pending' | 'approved' | 'rejected';

export interface LeaveRequest {
  id: string;
  companyId: string;
  employeeId: string;
  leaveType: LeaveType;
  startDate: string;
  endDate: string;
  totalDays: number;
  reason: string;
  status: LeaveStatus;
  approvedBy?: string;
  rejectionReason?: string;
  appliedAt: string;
  reviewedAt?: string;
}

export type PayrollStatus = 'draft' | 'approved' | 'disbursed';
export type PaymentMethod = 'bank_transfer' | 'direct_deposit' | 'cheque';

export interface PayrollRecord {
  id: string;
  companyId: string;
  payrollMonth: string;
  employeeId: string;
  baseSalary: number;
  totalAllowances: number;
  overtimePay: number;
  grossSalary: number;
  taxDeduction: number;
  pfDeduction: number;
  otherDeductions: number;
  netSalary: number;
  daysPresent: number;
  daysAbsent: number;
  daysOnLeave: number;
  overtimeHours: number;
  status: PayrollStatus;
  paymentDate?: string;
  paymentMethod: PaymentMethod;
  transactionRef?: string;
  notes?: string;
  createdAt: string;
  updatedAt: string;
}

export interface AuditLog {
  id: string;
  userId: string;
  userEmail: string;
  action: 'CREATE' | 'UPDATE' | 'DELETE' | 'STATUS_CHANGE';
  collection:
    | 'vehicles'
    | 'trips'
    | 'drivers'
    | 'maintenance'
    | 'compliance'
    | 'billing'
    | 'employees'
    | 'departments'
    | 'designations'
    | 'attendance'
    | 'leaves'
    | 'payroll'
    | 'shifts';
  documentId: string;
  summary: string;
  changes: {
    before?: Record<string, any>;
    after?: Record<string, any>;
  };
  ipAddress: string;
  timestamp: string;
}
