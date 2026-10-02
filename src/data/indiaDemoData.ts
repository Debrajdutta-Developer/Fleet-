import type {
  AttendanceRecord,
  AuditLog,
  Company,
  ComplianceDocument,
  Department,
  Designation,
  Driver,
  Employee,
  FuelLog,
  Invoice,
  LeaveRequest,
  MaintenanceTicket,
  PayrollRecord,
  Shift,
  Trip,
  User,
  Vehicle,
} from '../types';

/**
 * Production data boundary.
 *
 * FleetOS must never seed a tenant with fabricated company, user, fleet,
 * finance, HR, compliance, or telemetry records. Real records are loaded
 * from authenticated backend/provider integrations only.
 */
export const DEMO_SEED_VERSION = 'disabled';

export const initialCompanies: Company[] = [{
  id: '',
  name: '',
  industry: '',
  fleetSizeTier: '',
  subscriptionTier: 'growth',
  isActive: false,
  currency: 'INR',
  fastagBalance: 0,
}];

export const initialUsers: User[] = [];
export const initialVehicles: Vehicle[] = [];
export const initialDrivers: Driver[] = [];
export const initialTrips: Trip[] = [];
export const initialFuelLogs: FuelLog[] = [];
export const initialMaintenanceTickets: MaintenanceTicket[] = [];
export const initialComplianceDocuments: ComplianceDocument[] = [];
export const initialInvoices: Invoice[] = [];
export const initialAuditLogs: AuditLog[] = [];
export const initialDepartments: Department[] = [];
export const initialDesignations: Designation[] = [];
export const initialShifts: Shift[] = [];
export const initialEmployees: Employee[] = [];
export const initialAttendanceRecords: AttendanceRecord[] = [];
export const initialLeaveRequests: LeaveRequest[] = [];
export const initialPayrollRecords: PayrollRecord[] = [];
