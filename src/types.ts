export type UserRole =
  | 'super_admin'
  | 'company_admin'
  | 'owner'
  | 'manager'
  | 'fleet_manager'
  | 'dispatcher'
  | 'driver'
  | 'khalashi'
  | 'accountant'
  | 'compliance'
  | 'hr_manager';

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
    checkpoints: Checkpoint[];
    estimatedDurationSec?: number;
  };
  scheduledStart: string;
  scheduledEnd: string;
  actualStart?: string;
  actualEnd?: string;
  estimatedTollCost: number;
  revenue: number;
  notes?: string;
  createdAt: string;
  updatedAt: string;

  // Compatibility aliases used by the richer operations UI. New code should
  // prefer route.checkpoints, scheduledStart, estimatedTollCost and revenue.
  checkpoints?: Checkpoint[];
  scheduledDeparture?: string;
  tollFeesEstimated?: number;
  freightRevenue?: number;
}

export interface FuelLog {
  id: string;
  vehicleId: string;
  driverId: string;
  date: string;
  gallons: number;
  costPerGallon: number;
  totalCost: number;
  odometer: number;
  fuelStationName: string;
  paymentMethod: 'company_card' | 'driver_card' | 'cash';
  riskStatus: 'normal' | 'suspicious' | 'verified';
  riskReason?: string;
  receiptUrl?: string;

  // Compatibility aliases for India-first fuel views.
  fuelStation?: string;
  timestamp?: string;
  fuelAmountLiters?: number;
  calcEconomyKmPerLiter?: number;
  odometerReading?: number;
  auditNotes?: string;
}

export type MaintenancePriority = 'low' | 'medium' | 'high' | 'critical';
export type MaintenanceStatus = 'open' | 'in_progress' | 'completed' | 'deferred' | 'closed';

export interface MaintenanceTicket {
  id: string;
  ticketNumber: string;
  vehicleId: string;
  title: string;
  description: string;
  priority: MaintenancePriority;
  status: MaintenanceStatus;
  estimatedCost: number;
  actualCost?: number;
  reportedAt: string;
  scheduledFor?: string;
  completedAt?: string;
  createdAt: string;

  // Optional compatibility fields retained while legacy maintenance forms are migrated.
  type?: string;
  issueDescription?: string;
  reportedBy?: string;
}

export interface ComplianceDocument {
  id: string;
  vehicleId?: string;
  driverId?: string;
  documentType: string;
  documentNumber: string;
  issueDate: string;
  expiryDate: string;
  verificationStatus: 'verified' | 'pending' | 'expired' | 'rejected';
  fileUrl?: string;
  verifiedAt?: string;
  verifiedBy?: string;
}

export type InvoiceStatus = 'draft' | 'sent' | 'paid' | 'overdue' | 'void';

export interface Invoice {
  id: string;
  invoiceNumber: string;
  customerName: string;
  tripIds: string[];
  subtotal: number;
  tax: number;
  total: number;
  status: InvoiceStatus;
  issuedDate: string;
  dueDate: string;
  paidDate?: string;
}

export interface AuditLog {
  id: string;
  timestamp: string;
  userId: string;
  userName: string;
  action: string;
  entityType: string;
  entityId: string;
  details: string;
}

export interface Department {
  id: string;
  companyId: string;
  name: string;
  code?: string;
  description?: string;
  managerEmployeeId?: string;
  isActive?: boolean;
  createdAt: string;
  updatedAt: string;
  deletedAt?: string | null;
}

export interface Designation {
  id: string;
  companyId: string;
  title: string;
  name?: string;
  code?: string;
  departmentId?: string;
  level?: number;
  description?: string;
  isActive?: boolean;
  createdAt: string;
  updatedAt: string;
  deletedAt?: string | null;
}

export interface Shift {
  id: string;
  companyId: string;
  name: string;
  startTime: string;
  endTime: string;
  gracePeriodMinutes?: number;
  gracePeriodMins?: number;
  breakMinutes?: number;
  workingDays: number[];
  isNightShift?: boolean;
  isActive?: boolean;
}

export type EmployeeStatus = 'active' | 'inactive' | 'on_leave' | 'terminated';
export type EmploymentType = 'full_time' | 'part_time' | 'contract' | 'intern';

export interface SalaryStructure {
  basicMonthly: number;
  hraMonthly?: number;
  transportAllowanceMonthly?: number;
  otherAllowanceMonthly?: number;
  deductionsMonthly?: number;
  basicSalary?: number;
  allowances?: number;
  deductions?: number;
  overtimeRatePerHour?: number;
}

export interface Employee {
  id: string;
  companyId: string;
  employeeCode: string;
  fullName: string;
  email: string;
  phone: string;
  departmentId: string;
  designationId: string;
  shiftId?: string;
  status: EmployeeStatus;
  employmentType: EmploymentType;
  joiningDate: string;
  dateOfBirth?: string;
  address?: string;
  emergencyContact?: string;
  salary: SalaryStructure;
  createdAt: string;
  updatedAt: string;
  deletedAt?: string | null;
}

export interface AttendanceRecord {
  id: string;
  companyId: string;
  employeeId: string;
  date: string;
  clockIn?: string;
  clockOut?: string;
  status: 'present' | 'late' | 'absent' | 'half_day' | 'leave';
  workMinutes?: number;
  locationName?: string;
  latitude?: number;
  longitude?: number;

  // Legacy/richer HR UI aliases.
  checkInTime?: string;
  checkOutTime?: string;
  hoursWorked?: number;
  overtimeHours?: number;
}

export type LeaveStatus = 'pending' | 'approved' | 'rejected';

export interface LeaveRequest {
  id: string;
  companyId: string;
  employeeId: string;
  leaveType: 'casual' | 'sick' | 'earned' | 'unpaid';
  startDate: string;
  endDate: string;
  reason: string;
  status: LeaveStatus;
  appliedAt: string;
  reviewedAt?: string;
  reviewedBy?: string;
  rejectionReason?: string;
  totalDays?: number;
}

export type PayrollStatus = 'draft' | 'processed' | 'approved' | 'paid' | 'disbursed';
export type PaymentMethod = 'bank_transfer' | 'cash' | 'upi' | 'cheque';

export interface PayrollRecord {
  id: string;
  companyId: string;
  employeeId: string;
  payrollMonth: string;
  basicSalary: number;
  allowances: number;
  overtimeAmount: number;
  deductions: number;
  grossSalary: number;
  netSalary: number;
  status: PayrollStatus;
  generatedAt: string;
  paidAt?: string;
  paymentMethod?: PaymentMethod;
  transactionRef?: string;

  // Compatibility aliases for the richer payroll ledger UI.
  baseSalary?: number;
  totalAllowances?: number;
  overtimePay?: number;
  overtimeHours?: number;
  taxDeduction?: number;
  pfDeduction?: number;
  otherDeductions?: number;
}
