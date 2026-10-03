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
  [key: string]: any;
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
  [key: string]: any;
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
  [key: string]: any;
}

export interface Trip {
  id: string;
  tripNumber: string;
  status: TripStatus;
  driverId: string;
  vehicleId: string;
  customerName: string;
  cargo: any;
  route: any;
  scheduledStart: string;
  scheduledEnd: string;
  actualStart?: string;
  actualEnd?: string;
  estimatedTollCost: number;
  revenue: number;
  notes?: string;
  createdAt: string;
  updatedAt: string;
  [key: string]: any;
}

export type FuelRiskStatus = 'normal' | 'suspicious' | 'verified' | 'flagged_discrepancy';

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
  riskStatus: FuelRiskStatus;
  riskReason?: string;
  receiptUrl?: string;
  [key: string]: any;
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
  [key: string]: any;
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
  [key: string]: any;
}

export type InvoiceStatus = 'draft' | 'sent' | 'unpaid' | 'paid' | 'overdue' | 'void';

export interface Invoice {
  id: string;
  invoiceNumber: string;
  customerName: string;
  status: InvoiceStatus;
  dueDate: string;
  [key: string]: any;
}

export interface AuditLog {
  id: string;
  timestamp: string;
  action: string;
  [key: string]: any;
}

export interface Department {
  id: string;
  companyId: string;
  name: string;
  createdAt: string;
  updatedAt: string;
  [key: string]: any;
}

export interface Designation {
  id: string;
  companyId: string;
  title: string;
  createdAt: string;
  updatedAt: string;
  [key: string]: any;
}

export interface Shift {
  id: string;
  companyId: string;
  name: string;
  startTime: string;
  endTime: string;
  workingDays: Array<number | string>;
  [key: string]: any;
}

export type EmployeeStatus = 'active' | 'inactive' | 'on_leave' | 'terminated' | 'suspended' | 'probation';
export type EmploymentType = 'full_time' | 'part_time' | 'contract' | 'intern';

export interface SalaryStructure {
  [key: string]: any;
}

export interface EmergencyContact {
  name?: string;
  phone?: string;
  relationship?: string;
  relation?: string;
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
  status: EmployeeStatus;
  employmentType: EmploymentType;
  joiningDate: string;
  createdAt: string;
  updatedAt: string;
  [key: string]: any;
}

export type AttendanceStatus = 'present' | 'late' | 'absent' | 'half_day' | 'leave' | 'on_leave';

export interface AttendanceRecord {
  id: string;
  companyId: string;
  employeeId: string;
  date: string;
  status: AttendanceStatus;
  [key: string]: any;
}

export type LeaveStatus = 'pending' | 'approved' | 'rejected';
export type LeaveType = 'casual' | 'sick' | 'earned' | 'unpaid' | 'annual';

export interface LeaveRequest {
  id: string;
  companyId: string;
  employeeId: string;
  leaveType: LeaveType;
  startDate: string;
  endDate: string;
  reason: string;
  status: LeaveStatus;
  appliedAt: string;
  [key: string]: any;
}

export type PayrollStatus = 'draft' | 'processed' | 'approved' | 'paid' | 'disbursed';
export type PaymentMethod = 'bank_transfer' | 'direct_deposit' | 'cash' | 'upi' | 'cheque';

export interface PayrollRecord {
  id: string;
  companyId: string;
  employeeId: string;
  payrollMonth: string;
  status: PayrollStatus;
  [key: string]: any;
}
