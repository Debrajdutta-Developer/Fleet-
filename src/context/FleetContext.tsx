import React, { createContext, useContext, useState, useEffect, useCallback } from 'react';
import {
  Company,
  User,
  UserRole,
  Vehicle,
  VehicleStatus,
  Driver,
  Trip,
  FuelLog,
  MaintenanceTicket,
  ComplianceDocument,
  Invoice,
  AuditLog,
  Department,
  Designation,
  Shift,
  Employee,
  AttendanceRecord,
  LeaveRequest,
  PayrollRecord,
  LeaveStatus,
  PayrollStatus,
  PaymentMethod
} from '../types';
import {
  initialCompanies,
  initialUsers,
  initialVehicles,
  initialDrivers,
  initialTrips,
  initialFuelLogs,
  initialMaintenanceTickets,
  initialComplianceDocuments,
  initialInvoices,
  initialAuditLogs,
  initialDepartments,
  initialDesignations,
  initialShifts,
  initialEmployees,
  initialAttendanceRecords,
  initialLeaveRequests,
  initialPayrollRecords
} from '../data/mockData';

interface ToastNotification {
  id: string;
  type: 'success' | 'error' | 'warning' | 'info';
  title: string;
  message: string;
  timestamp: string;
}

interface FleetContextType {
  // Tenancy & Session
  currentCompany: Company;
  setCurrentCompany: (company: Company) => void;
  companies: Company[];
  currentUser: User;
  setCurrentUserRole: (role: UserRole) => void;

  // Data Collections
  vehicles: Vehicle[];
  drivers: Driver[];
  trips: Trip[];
  fuelLogs: FuelLog[];
  maintenanceTickets: MaintenanceTicket[];
  complianceDocs: ComplianceDocument[];
  invoices: Invoice[];
  auditLogs: AuditLog[];
  toasts: ToastNotification[];

  // HR Collections
  departments: Department[];
  designations: Designation[];
  shifts: Shift[];
  employees: Employee[];
  attendanceRecords: AttendanceRecord[];
  leaveRequests: LeaveRequest[];
  payrollRecords: PayrollRecord[];

  // Simulation
  isLiveSimulating: boolean;
  setIsLiveSimulating: (sim: boolean) => void;

  // UI Toast helpers
  dismissToast: (id: string) => void;
  showToast: (type: ToastNotification['type'], title: string, message: string) => void;

  // Domain Actions
  addVehicle: (vehicle: Omit<Vehicle, 'id' | 'createdAt' | 'updatedAt'>) => { success: boolean; error?: string };
  updateVehicleStatus: (vehicleId: string, newStatus: VehicleStatus, reason?: string) => { success: boolean; error?: string };
  softDeleteVehicle: (vehicleId: string) => void;
  
  addDriver: (driver: Omit<Driver, 'id' | 'createdAt' | 'updatedAt'>) => { success: boolean; error?: string };
  assignDriverToVehicle: (driverId: string, vehicleId: string | null) => { success: boolean; error?: string };

  createTrip: (tripData: Omit<Trip, 'id' | 'tripNumber' | 'createdAt' | 'updatedAt'>) => { success: boolean; error?: string };
  updateTripStatus: (tripId: string, status: Trip['status']) => void;
  advanceCheckpoint: (tripId: string, checkpointId: string) => void;

  addFuelLog: (log: Omit<FuelLog, 'id'>) => { success: boolean; riskStatus: FuelLog['riskStatus']; note: string };
  createMaintenanceTicket: (ticket: Omit<MaintenanceTicket, 'id' | 'ticketNumber' | 'createdAt'>) => void;
  resolveMaintenanceTicket: (ticketId: string, actualCost: number) => void;

  addComplianceDoc: (doc: Omit<ComplianceDocument, 'id'>) => void;
  verifyComplianceDoc: (docId: string) => void;

  topUpFastag: (amount: number) => void;
  createInvoice: (invoice: Omit<Invoice, 'id' | 'invoiceNumber'>) => void;
  markInvoicePaid: (invoiceId: string) => void;
  updateInvoiceStatus: (invoiceId: string, status: Invoice['status']) => void;

  // HR Domain Actions
  addEmployee: (employee: Omit<Employee, 'id' | 'companyId' | 'createdAt' | 'updatedAt'>) => { success: boolean; error?: string };
  updateEmployee: (employeeId: string, updates: Partial<Employee>) => { success: boolean; error?: string };
  softDeleteEmployee: (employeeId: string) => void;

  addDepartment: (department: Omit<Department, 'id' | 'companyId' | 'createdAt' | 'updatedAt'>) => { success: boolean; error?: string };
  updateDepartment: (deptId: string, updates: Partial<Department>) => { success: boolean; error?: string };
  softDeleteDepartment: (deptId: string) => void;

  addDesignation: (designation: Omit<Designation, 'id' | 'companyId' | 'createdAt' | 'updatedAt'>) => { success: boolean; error?: string };
  updateDesignation: (desigId: string, updates: Partial<Designation>) => { success: boolean; error?: string };
  softDeleteDesignation: (desigId: string) => void;

  addShift: (shift: Omit<Shift, 'id' | 'companyId'>) => { success: boolean; error?: string };
  updateShift: (shiftId: string, updates: Partial<Shift>) => { success: boolean; error?: string };

  recordAttendance: (attendance: Omit<AttendanceRecord, 'id' | 'companyId'>) => void;
  clockInEmployee: (employeeId: string, locationName?: string, coords?: { lat: number; lng: number }) => { success: boolean; error?: string };
  clockOutEmployee: (attendanceId: string) => { success: boolean; error?: string };

  applyLeaveRequest: (leave: Omit<LeaveRequest, 'id' | 'companyId' | 'appliedAt' | 'status'>) => { success: boolean; error?: string };
  updateLeaveStatus: (leaveId: string, status: LeaveStatus, rejectionReason?: string) => void;

  generatePayrollForMonth: (payrollMonth: string) => { count: number; totalGross: number; totalNet: number };
  updatePayrollStatus: (payrollId: string, status: PayrollStatus, paymentMethod?: PaymentMethod, transactionRef?: string) => void;

  resetDemoData: () => void;
}

const FleetContext = createContext<FleetContextType | undefined>(undefined);

export const FleetProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  // Persistence states
  const [companies] = useState<Company[]>(() => {
    const saved = localStorage.getItem('fleetos_companies');
    return saved ? JSON.parse(saved) : initialCompanies;
  });

  const [currentCompany, setCurrentCompany] = useState<Company>(() => {
    const saved = localStorage.getItem('fleetos_current_company');
    return saved ? JSON.parse(saved) : companies[0];
  });

  const [currentUser, setCurrentUser] = useState<User>(() => {
    const saved = localStorage.getItem('fleetos_current_user');
    return saved ? JSON.parse(saved) : initialUsers[0];
  });

  const [vehicles, setVehicles] = useState<Vehicle[]>(() => {
    const saved = localStorage.getItem('fleetos_vehicles');
    return saved ? JSON.parse(saved) : initialVehicles;
  });

  const [drivers, setDrivers] = useState<Driver[]>(() => {
    const saved = localStorage.getItem('fleetos_drivers');
    return saved ? JSON.parse(saved) : initialDrivers;
  });

  const [trips, setTrips] = useState<Trip[]>(() => {
    const saved = localStorage.getItem('fleetos_trips');
    return saved ? JSON.parse(saved) : initialTrips;
  });

  const [fuelLogs, setFuelLogs] = useState<FuelLog[]>(() => {
    const saved = localStorage.getItem('fleetos_fuel_logs');
    return saved ? JSON.parse(saved) : initialFuelLogs;
  });

  const [maintenanceTickets, setMaintenanceTickets] = useState<MaintenanceTicket[]>(() => {
    const saved = localStorage.getItem('fleetos_maintenance');
    return saved ? JSON.parse(saved) : initialMaintenanceTickets;
  });

  const [complianceDocs, setComplianceDocs] = useState<ComplianceDocument[]>(() => {
    const saved = localStorage.getItem('fleetos_compliance');
    return saved ? JSON.parse(saved) : initialComplianceDocuments;
  });

  const [invoices, setInvoices] = useState<Invoice[]>(() => {
    const saved = localStorage.getItem('fleetos_invoices');
    return saved ? JSON.parse(saved) : initialInvoices;
  });

  const [auditLogs, setAuditLogs] = useState<AuditLog[]>(() => {
    const saved = localStorage.getItem('fleetos_audit_logs');
    return saved ? JSON.parse(saved) : initialAuditLogs;
  });

  // HR Module States
  const [departments, setDepartments] = useState<Department[]>(() => {
    const saved = localStorage.getItem('fleetos_departments');
    return saved ? JSON.parse(saved) : initialDepartments;
  });

  const [designations, setDesignations] = useState<Designation[]>(() => {
    const saved = localStorage.getItem('fleetos_designations');
    return saved ? JSON.parse(saved) : initialDesignations;
  });

  const [shifts, setShifts] = useState<Shift[]>(() => {
    const saved = localStorage.getItem('fleetos_shifts');
    return saved ? JSON.parse(saved) : initialShifts;
  });

  const [employees, setEmployees] = useState<Employee[]>(() => {
    const saved = localStorage.getItem('fleetos_employees');
    return saved ? JSON.parse(saved) : initialEmployees;
  });

  const [attendanceRecords, setAttendanceRecords] = useState<AttendanceRecord[]>(() => {
    const saved = localStorage.getItem('fleetos_attendance');
    return saved ? JSON.parse(saved) : initialAttendanceRecords;
  });

  const [leaveRequests, setLeaveRequests] = useState<LeaveRequest[]>(() => {
    const saved = localStorage.getItem('fleetos_leaves');
    return saved ? JSON.parse(saved) : initialLeaveRequests;
  });

  const [payrollRecords, setPayrollRecords] = useState<PayrollRecord[]>(() => {
    const saved = localStorage.getItem('fleetos_payroll');
    return saved ? JSON.parse(saved) : initialPayrollRecords;
  });

  const [toasts, setToasts] = useState<ToastNotification[]>([]);
  const [isLiveSimulating, setIsLiveSimulating] = useState<boolean>(() => import.meta.env.VITE_ENABLE_DEMO_TELEMETRY === 'true');

  // Sync to local storage
  useEffect(() => {
    localStorage.setItem('fleetos_current_company', JSON.stringify(currentCompany));
  }, [currentCompany]);

  useEffect(() => {
    localStorage.setItem('fleetos_current_user', JSON.stringify(currentUser));
  }, [currentUser]);

  useEffect(() => {
    localStorage.setItem('fleetos_vehicles', JSON.stringify(vehicles));
  }, [vehicles]);

  useEffect(() => {
    localStorage.setItem('fleetos_drivers', JSON.stringify(drivers));
  }, [drivers]);

  useEffect(() => {
    localStorage.setItem('fleetos_trips', JSON.stringify(trips));
  }, [trips]);

  useEffect(() => {
    localStorage.setItem('fleetos_fuel_logs', JSON.stringify(fuelLogs));
  }, [fuelLogs]);

  useEffect(() => {
    localStorage.setItem('fleetos_maintenance', JSON.stringify(maintenanceTickets));
  }, [maintenanceTickets]);

  useEffect(() => {
    localStorage.setItem('fleetos_compliance', JSON.stringify(complianceDocs));
  }, [complianceDocs]);

  useEffect(() => {
    localStorage.setItem('fleetos_invoices', JSON.stringify(invoices));
  }, [invoices]);

  useEffect(() => {
    localStorage.setItem('fleetos_audit_logs', JSON.stringify(auditLogs));
  }, [auditLogs]);

  useEffect(() => {
    localStorage.setItem('fleetos_departments', JSON.stringify(departments));
  }, [departments]);

  useEffect(() => {
    localStorage.setItem('fleetos_designations', JSON.stringify(designations));
  }, [designations]);

  useEffect(() => {
    localStorage.setItem('fleetos_shifts', JSON.stringify(shifts));
  }, [shifts]);

  useEffect(() => {
    localStorage.setItem('fleetos_employees', JSON.stringify(employees));
  }, [employees]);

  useEffect(() => {
    localStorage.setItem('fleetos_attendance', JSON.stringify(attendanceRecords));
  }, [attendanceRecords]);

  useEffect(() => {
    localStorage.setItem('fleetos_leaves', JSON.stringify(leaveRequests));
  }, [leaveRequests]);

  useEffect(() => {
    localStorage.setItem('fleetos_payroll', JSON.stringify(payrollRecords));
  }, [payrollRecords]);

  const showToast = useCallback((type: ToastNotification['type'], title: string, message: string) => {
    const id = `toast-${Date.now()}-${Math.random().toString(36).substring(2, 5)}`;
    setToasts((prev) => [...prev, { id, type, title, message, timestamp: new Date().toLocaleTimeString() }]);
    setTimeout(() => {
      setToasts((prev) => prev.filter((t) => t.id !== id));
    }, 5000);
  }, []);

  const dismissToast = useCallback((id: string) => {
    setToasts((prev) => prev.filter((t) => t.id !== id));
  }, []);

  const logAudit = useCallback((
    action: AuditLog['action'],
    collection: AuditLog['collection'],
    documentId: string,
    summary: string,
    changes: AuditLog['changes']
  ) => {
    const newLog: AuditLog = {
      id: `log-${Date.now()}`,
      userId: currentUser.uid,
      userEmail: currentUser.email,
      action,
      collection,
      documentId,
      summary,
      changes,
      ipAddress: '198.51.100.' + Math.floor(Math.random() * 200 + 10),
      timestamp: new Date().toISOString(),
    };
    setAuditLogs((prev) => [newLog, ...prev]);
  }, [currentUser]);

  const setCurrentUserRole = (role: UserRole) => {
    setCurrentUser((prev) => ({ ...prev, role }));
    showToast('info', 'Role Switched', `Active operator role changed to ${role.replace('_', ' ').toUpperCase()}`);
  };

  // Demo-only movement ticker. Production telemetry stays provider-authoritative unless explicitly enabled.
  useEffect(() => {
    if (!isLiveSimulating) return;

    const interval = setInterval(() => {
      setVehicles((prev) =>
        prev.map((v) => {
          if (v.status !== 'active' || v.deletedAt) return v;

          // Subtle coordinate drift along road corridors
          const speedVariance = Math.floor(Math.random() * 7) - 3;
          const newSpeed = Math.max(45, Math.min(75, v.telemetry.speed + speedVariance));
          const latDelta = (Math.random() - 0.48) * 0.002;
          const lngDelta = (Math.random() - 0.48) * 0.002;

          return {
            ...v,
            telemetry: {
              ...v.telemetry,
              speed: newSpeed,
              latitude: Number((v.telemetry.latitude + latDelta).toFixed(5)),
              longitude: Number((v.telemetry.longitude + lngDelta).toFixed(5)),
              fuelLevelPercent: Math.max(15, Number((v.telemetry.fuelLevelPercent - 0.02).toFixed(2))),
              updatedAt: new Date().toISOString(),
            },
          };
        })
      );
    }, 4000);

    return () => clearInterval(interval);
  }, [isLiveSimulating]);

  // Vehicle Management
  const addVehicle = (data: Omit<Vehicle, 'id' | 'createdAt' | 'updatedAt'>) => {
    // Check VIN uniqueness
    const exists = vehicles.some((v) => v.vin.toUpperCase() === data.vin.toUpperCase() && !v.deletedAt);
    if (exists) {
      showToast('error', 'Vehicle Registration Blocked', `A vehicle with VIN ${data.vin} is already registered.`);
      return { success: false, error: 'Duplicate VIN found' };
    }

    const id = `veh-${Date.now().toString().slice(-4)}`;
    const newVehicle: Vehicle = {
      ...data,
      id,
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString(),
    };

    setVehicles((prev) => [newVehicle, ...prev]);
    logAudit('CREATE', 'vehicles', id, `Onboarded new vehicle ${newVehicle.licensePlate} (${newVehicle.make} ${newVehicle.model})`, {
      after: { vin: newVehicle.vin, status: newVehicle.status },
    });
    showToast('success', 'Vehicle Registered', `${newVehicle.make} ${newVehicle.model} [${newVehicle.licensePlate}] onboarded.`);
    return { success: true };
  };

  const updateVehicleStatus = (vehicleId: string, newStatus: VehicleStatus, reason?: string) => {
    const vehicle = vehicles.find((v) => v.id === vehicleId);
    if (!vehicle) return { success: false, error: 'Vehicle not found' };

    // Business rule: registration -> active requires verified documents
    if (vehicle.status === 'registration' && newStatus === 'active') {
      const hasVerifiedDocs = complianceDocs.some((d) => d.vehicleId === vehicleId && d.verificationStatus === 'verified');
      if (!hasVerifiedDocs) {
        showToast('warning', 'Compliance Gate', 'Vehicle requires at least one verified compliance document before activation.');
        return { success: false, error: 'Verified compliance document required before activation' };
      }
    }

    // Business rule: active -> maintenance unlinks assigned driver
    if (newStatus === 'maintenance' && vehicle.assignedDriverId) {
      setDrivers((prev) =>
        prev.map((d) => (d.id === vehicle.assignedDriverId ? { ...d, status: 'available', assignedVehicleId: undefined } : d))
      );
    }

    setVehicles((prev) =>
      prev.map((v) => {
        if (v.id === vehicleId) {
          return {
            ...v,
            status: newStatus,
            statusTag: reason || (newStatus === 'active' ? undefined : v.statusTag),
            assignedDriverId: newStatus === 'maintenance' || newStatus === 'sold' ? undefined : v.assignedDriverId,
            updatedAt: new Date().toISOString(),
          };
        }
        return v;
      })
    );

    logAudit('STATUS_CHANGE', 'vehicles', vehicleId, `Vehicle ${vehicle.licensePlate} status changed to ${newStatus.toUpperCase()}`, {
      before: { status: vehicle.status },
      after: { status: newStatus, reason },
    });
    showToast('info', 'Status Updated', `Vehicle ${vehicle.licensePlate} is now in ${newStatus.toUpperCase()} state.`);
    return { success: true };
  };

  const softDeleteVehicle = (vehicleId: string) => {
    const vehicle = vehicles.find((v) => v.id === vehicleId);
    if (!vehicle) return;

    setVehicles((prev) =>
      prev.map((v) =>
        v.id === vehicleId ? { ...v, status: 'archived', deletedAt: new Date().toISOString(), assignedDriverId: undefined } : v
      )
    );

    if (vehicle.assignedDriverId) {
      setDrivers((prev) =>
        prev.map((d) => (d.id === vehicle.assignedDriverId ? { ...d, status: 'available', assignedVehicleId: undefined } : d))
      );
    }

    logAudit('DELETE', 'vehicles', vehicleId, `Archived (soft-deleted) vehicle ${vehicle.licensePlate}`, {
      before: { status: vehicle.status },
      after: { status: 'archived', deletedAt: new Date().toISOString() },
    });
    showToast('warning', 'Vehicle Archived', `Vehicle ${vehicle.licensePlate} moved to audit archive.`);
  };

  // Driver Management
  const addDriver = (data: Omit<Driver, 'id' | 'createdAt' | 'updatedAt'>) => {
    const id = `drv-${Date.now().toString().slice(-4)}`;
    const newDriver: Driver = {
      ...data,
      id,
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString(),
    };
    setDrivers((prev) => [newDriver, ...prev]);
    logAudit('CREATE', 'drivers', id, `Registered driver ${newDriver.fullName} (${newDriver.cdlClass})`, {
      after: { fullName: newDriver.fullName, cdlClass: newDriver.cdlClass },
    });
    showToast('success', 'Driver Enrolled', `${newDriver.fullName} added to roster.`);
    return { success: true };
  };

  const assignDriverToVehicle = (driverId: string, vehicleId: string | null) => {
    const driver = drivers.find((d) => d.id === driverId);
    if (!driver) return { success: false, error: 'Driver not found' };

    if (!vehicleId) {
      // Unlink
      const oldVehicleId = driver.assignedVehicleId;
      setDrivers((prev) => prev.map((d) => (d.id === driverId ? { ...d, assignedVehicleId: undefined, status: 'available' } : d)));
      if (oldVehicleId) {
        setVehicles((prev) => prev.map((v) => (v.id === oldVehicleId ? { ...v, assignedDriverId: undefined } : v)));
      }
      showToast('info', 'Driver Unassigned', `${driver.fullName} is now available.`);
      return { success: true };
    }

    const vehicle = vehicles.find((v) => v.id === vehicleId);
    if (!vehicle) return { success: false, error: 'Target vehicle not found' };

    // Business rule: vehicle must be active
    if (vehicle.status !== 'active' && vehicle.status !== 'idle') {
      showToast('error', 'Assignment Failed', `Cannot assign driver to vehicle in '${vehicle.status}' state.`);
      return { success: false, error: `Vehicle is ${vehicle.status}` };
    }

    // Business rule: safety score check for Class A heavy vehicles
    if (vehicle.cdlRequired === 'Class A' && driver.safetyScore < 70) {
      showToast('error', 'Safety Gate Block', `Driver safety score (${driver.safetyScore}%) is below the 70% threshold required for Class A vehicles.`);
      return { success: false, error: 'Safety score below 70% threshold' };
    }

    // Unassign previous vehicle if any
    setVehicles((prev) =>
      prev.map((v) => {
        if (v.id === vehicleId) return { ...v, assignedDriverId: driverId, status: 'active' };
        if (v.assignedDriverId === driverId) return { ...v, assignedDriverId: undefined };
        return v;
      })
    );

    setDrivers((prev) =>
      prev.map((d) => {
        if (d.id === driverId) return { ...d, assignedVehicleId: vehicleId, status: 'on_duty' };
        if (d.assignedVehicleId === vehicleId) return { ...d, assignedVehicleId: undefined, status: 'available' };
        return d;
      })
    );

    logAudit('UPDATE', 'drivers', driverId, `Assigned driver ${driver.fullName} to vehicle ${vehicle.licensePlate}`, {
      after: { assignedVehicleId: vehicleId },
    });
    showToast('success', 'Assignment Complete', `${driver.fullName} linked to ${vehicle.licensePlate}.`);
    return { success: true };
  };

  // Trip Dispatch Management
  const createTrip = (tripData: Omit<Trip, 'id' | 'tripNumber' | 'createdAt' | 'updatedAt'>) => {
    const vehicle = vehicles.find((v) => v.id === tripData.vehicleId);
    const driver = drivers.find((d) => d.id === tripData.driverId);

    if (!vehicle || !driver) {
      showToast('error', 'Dispatch Error', 'Valid vehicle and driver must be selected.');
      return { success: false, error: 'Invalid vehicle or driver' };
    }

    // Business Rule 1: Vehicle state gate
    if (vehicle.status !== 'active' && vehicle.status !== 'idle') {
      showToast('error', 'Vehicle Ineligible', `Vehicle ${vehicle.licensePlate} is currently in '${vehicle.status}' state.`);
      return { success: false, error: `Vehicle is ${vehicle.status}` };
    }

    // Business Rule 2: 90% legal payload safety limit
    const maxSafePayload = vehicle.maxPayloadKg * 0.9;
    if (tripData.cargo.weightKg > maxSafePayload) {
      showToast('error', 'Payload Overload Block', `Cargo weight (${tripData.cargo.weightKg} kg) exceeds 90% legal safety payload limit (${maxSafePayload.toFixed(0)} kg).`);
      return { success: false, error: 'Payload exceeds 90% capacity' };
    }

    // Business Rule 3: Safety score gate
    if (vehicle.cdlRequired === 'Class A' && driver.safetyScore < 70) {
      showToast('error', 'Driver Safety Gate', `Driver ${driver.fullName} score (${driver.safetyScore}%) is below 70% required for Class A.`);
      return { success: false, error: 'Driver safety score too low' };
    }

    // Business Rule 4: FASTag balance warning
    if (currentCompany.fastagBalance < tripData.tollFeesEstimated) {
      showToast('warning', 'Low Toll Balance', `Company FASTag balance ($${currentCompany.fastagBalance}) is below estimated toll fees ($${tripData.tollFeesEstimated}). Please top-up soon.`);
    }

    const tripNum = `TRIP-00${Math.floor(1000 + Math.random() * 9000)}`;
    const id = `trp-${Date.now().toString().slice(-4)}`;

    const newTrip: Trip = {
      ...tripData,
      id,
      tripNumber: tripNum,
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString(),
    };

    setTrips((prev) => [newTrip, ...prev]);
    // Set driver and vehicle to on_duty / active
    setVehicles((prev) => prev.map((v) => (v.id === vehicle.id ? { ...v, status: 'active', assignedDriverId: driver.id } : v)));
    setDrivers((prev) => prev.map((d) => (d.id === driver.id ? { ...d, status: 'on_duty', assignedVehicleId: vehicle.id } : d)));

    logAudit('CREATE', 'trips', id, `Dispatched trip ${tripNum} (${newTrip.route.startLocationName} -> ${newTrip.route.endLocationName})`, {
      after: { tripNumber: tripNum, vehicleId: vehicle.id, driverId: driver.id, cargoWeight: tripData.cargo.weightKg },
    });
    showToast('success', 'Trip Dispatched', `Manifest ${tripNum} created for ${tripData.customerName}.`);
    return { success: true };
  };

  const updateTripStatus = (tripId: string, newStatus: Trip['status']) => {
    const trip = trips.find((t) => t.id === tripId);
    if (!trip) return;

    setTrips((prev) =>
      prev.map((t) => {
        if (t.id === tripId) {
          return {
            ...t,
            status: newStatus,
            startedAt: newStatus === 'in_transit' && !t.startedAt ? new Date().toISOString() : t.startedAt,
            completedAt: newStatus === 'completed' ? new Date().toISOString() : t.completedAt,
            updatedAt: new Date().toISOString(),
          };
        }
        return t;
      })
    );

    if (newStatus === 'completed') {
      // Free driver and auto-generate invoice
      const invoiceNum = `INV-2026-${Math.floor(1000 + Math.random() * 9000)}`;
      const newInvoice: Invoice = {
        id: `inv-${Date.now()}`,
        invoiceNumber: invoiceNum,
        customerName: trip.customerName,
        tripId: trip.id,
        amount: trip.freightRevenue,
        tax: Number((trip.freightRevenue * 0.08).toFixed(2)),
        totalAmount: Number((trip.freightRevenue * 1.08).toFixed(2)),
        issueDate: new Date().toISOString().split('T')[0],
        dueDate: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000).toISOString().split('T')[0],
        status: 'unpaid',
        items: [
          { description: `Freight Haulage: ${trip.route.startLocationName} to ${trip.route.endLocationName}`, rate: trip.freightRevenue, quantity: 1, amount: trip.freightRevenue },
        ],
      };
      setInvoices((prev) => [newInvoice, ...prev]);

      setDrivers((prev) =>
        prev.map((d) =>
          d.id === trip.driverId
            ? { ...d, totalTripsCompleted: d.totalTripsCompleted + 1, status: 'available', assignedVehicleId: undefined }
            : d
        )
      );

      setVehicles((prev) => prev.map((v) => (v.id === trip.vehicleId ? { ...v, status: 'idle', assignedDriverId: undefined } : v)));
      showToast('success', 'Trip Completed', `Manifest ${trip.tripNumber} completed. Invoice ${invoiceNum} generated.`);
    }

    logAudit('STATUS_CHANGE', 'trips', tripId, `Trip ${trip.tripNumber} status changed to ${newStatus.toUpperCase()}`, {
      before: { status: trip.status },
      after: { status: newStatus },
    });
  };

  const advanceCheckpoint = (tripId: string, checkpointId: string) => {
    setTrips((prev) =>
      prev.map((t) => {
        if (t.id === tripId) {
          const updatedCheckpoints = t.checkpoints.map((c) =>
            c.id === checkpointId ? { ...c, status: 'passed' as const, passedAt: new Date().toISOString() } : c
          );
          const allPassed = updatedCheckpoints.every((c) => c.status === 'passed');
          return {
            ...t,
            checkpoints: updatedCheckpoints,
            status: allPassed ? 'completed' : t.status,
            completedAt: allPassed ? new Date().toISOString() : t.completedAt,
            updatedAt: new Date().toISOString(),
          };
        }
        return t;
      })
    );
    showToast('info', 'Checkpoint Reached', 'Checkpoint arrival validated and logged.');
  };

  // Fuel Log with 3-factor fraud check
  const addFuelLog = (logData: Omit<FuelLog, 'id'>) => {
    const vehicle = vehicles.find((v) => v.id === logData.vehicleId);
    let risk: FuelLog['riskStatus'] = 'verified';
    let notes = 'All three fraud audit checkpoints verified.';

    if (vehicle) {
      // Check 1: Odometer progression
      if (logData.odometerReading <= vehicle.odometer) {
        risk = 'flagged_discrepancy';
        notes = `Odometer rollback detected! Entered: ${logData.odometerReading} km <= current recorded ${vehicle.odometer} km.`;
      }

      // Check 2: Fuel consumption rate anomaly (>20% deviation)
      const expectedBaseline = vehicle.fuelType === 'diesel' ? 3.4 : 8.0;
      const deviation = Math.abs(logData.calcEconomyKmPerLiter - expectedBaseline) / expectedBaseline;
      if (deviation > 0.20) {
        risk = 'flagged_discrepancy';
        notes = `Consumption deviation ${(deviation * 100).toFixed(1)}% exceeds 20% tolerance baseline. Flagged for sensor diagnostic.`;
      }
    }

    const id = `fl-${Date.now().toString().slice(-4)}`;
    const newLog: FuelLog = {
      ...logData,
      id,
      riskStatus: risk,
      auditNotes: notes,
    };

    setFuelLogs((prev) => [newLog, ...prev]);

    // Update vehicle odometer
    if (vehicle && logData.odometerReading > vehicle.odometer) {
      setVehicles((prev) =>
        prev.map((v) => (v.id === vehicle.id ? { ...v, odometer: logData.odometerReading, updatedAt: new Date().toISOString() } : v))
      );
    }

    logAudit('CREATE', 'vehicles', logData.vehicleId, `Logged fuel refill of ${logData.fuelAmountLiters}L at ${logData.fuelStation} (${risk})`, {
      after: { liters: logData.fuelAmountLiters, cost: logData.totalCost, riskStatus: risk },
    });

    if (risk === 'flagged_discrepancy') {
      showToast('warning', 'Fuel Audit Warning', notes);
    } else {
      showToast('success', 'Fuel Log Verified', `Refill of ${logData.fuelAmountLiters}L registered successfully.`);
    }

    return { success: true, riskStatus: risk, note: notes };
  };

  // Maintenance & Service
  const createMaintenanceTicket = (ticketData: Omit<MaintenanceTicket, 'id' | 'ticketNumber' | 'createdAt'>) => {
    const ticketNum = `WO-${Math.floor(80000 + Math.random() * 19999)}`;
    const id = `mnt-${Date.now().toString().slice(-4)}`;
    const newTicket: MaintenanceTicket = {
      ...ticketData,
      id,
      ticketNumber: ticketNum,
      createdAt: new Date().toISOString(),
    };

    setMaintenanceTickets((prev) => [newTicket, ...prev]);
    // Switch vehicle to maintenance state
    updateVehicleStatus(ticketData.vehicleId, 'maintenance', `Work Order ${ticketNum}: ${ticketData.issueDescription.slice(0, 40)}`);
    showToast('info', 'Work Order Created', `${ticketNum} opened for vehicle.`);
  };

  const resolveMaintenanceTicket = (ticketId: string, actualCost: number) => {
    const ticket = maintenanceTickets.find((t) => t.id === ticketId);
    if (!ticket) return;

    setMaintenanceTickets((prev) =>
      prev.map((t) => (t.id === ticketId ? { ...t, status: 'closed', actualCost, closedAt: new Date().toISOString() } : t))
    );

    // Update vehicle status back to idle/active and reset last service metrics
    setVehicles((prev) =>
      prev.map((v) => {
        if (v.id === ticket.vehicleId) {
          return {
            ...v,
            status: 'idle',
            statusTag: undefined,
            lastServiceDate: new Date().toISOString().split('T')[0],
            lastServiceOdometer: v.odometer,
            updatedAt: new Date().toISOString(),
          };
        }
        return v;
      })
    );

    logAudit('STATUS_CHANGE', 'maintenance', ticketId, `Closed Work Order ${ticket.ticketNumber} (Actual Cost: $${actualCost})`, {
      after: { status: 'closed', actualCost },
    });
    showToast('success', 'Maintenance Resolved', `Work order ${ticket.ticketNumber} marked closed. Vehicle returned to fleet pool.`);
  };

  // Compliance
  const addComplianceDoc = (doc: Omit<ComplianceDocument, 'id'>) => {
    const id = `doc-${Date.now().toString().slice(-4)}`;
    const newDoc: ComplianceDocument = { ...doc, id };
    setComplianceDocs((prev) => [newDoc, ...prev]);
    logAudit('CREATE', 'compliance', id, `Added ${doc.documentType} document #${doc.documentNumber}`, {
      after: { docType: doc.documentType, expiryDate: doc.expiryDate },
    });
    showToast('success', 'Document Uploaded', `${doc.documentType} #${doc.documentNumber} registered.`);
  };

  const verifyComplianceDoc = (docId: string) => {
    setComplianceDocs((prev) =>
      prev.map((d) => (d.id === docId ? { ...d, verificationStatus: 'verified', verifiedBy: currentUser.displayName } : d))
    );
    showToast('success', 'Document Verified', 'Compliance certificate verified and approved.');
  };

  // FASTag & Billing
  const topUpFastag = (amount: number) => {
    setCurrentCompany((prev) => ({ ...prev, fastagBalance: prev.fastagBalance + amount }));
    showToast('success', 'FASTag Recharge Successful', `Added $${amount.toFixed(2)} to toll balance.`);
  };

  const createInvoice = (inv: Omit<Invoice, 'id' | 'invoiceNumber'>) => {
    const invoiceNum = `INV-2026-${Math.floor(1000 + Math.random() * 9000)}`;
    const newInvoice: Invoice = {
      ...inv,
      id: `inv-${Date.now().toString().slice(-4)}`,
      invoiceNumber: invoiceNum,
    };
    setInvoices((prev) => [newInvoice, ...prev]);
    showToast('success', 'Invoice Generated', `Invoice ${invoiceNum} created for ${inv.customerName}.`);
  };

  const markInvoicePaid = (invoiceId: string) => {
    setInvoices((prev) => prev.map((i) => (i.id === invoiceId ? { ...i, status: 'paid' } : i)));
    showToast('success', 'Payment Received', 'Invoice marked as paid.');
  };

  const updateInvoiceStatus = (invoiceId: string, status: Invoice['status']) => {
    setInvoices((prev) => prev.map((i) => (i.id === invoiceId ? { ...i, status } : i)));
    showToast('info', 'Invoice Status Updated', `Invoice status set to ${status.toUpperCase()}.`);
  };

  // ================= HR DOMAIN ACTIONS =================

  // Employee CRUD & Driver Linking
  const addEmployee = (empData: Omit<Employee, 'id' | 'companyId' | 'createdAt' | 'updatedAt'>) => {
    if (employees.some((e) => e.employeeCode.toLowerCase() === empData.employeeCode.toLowerCase() && !e.deletedAt)) {
      return { success: false, error: 'Employee Code must be unique.' };
    }
    if (employees.some((e) => e.email.toLowerCase() === empData.email.toLowerCase() && !e.deletedAt)) {
      return { success: false, error: 'Email address already registered to another employee.' };
    }

    const newEmpId = `emp-${Date.now().toString().slice(-4)}`;
    const newEmployee: Employee = {
      ...empData,
      id: newEmpId,
      companyId: currentCompany.id,
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString(),
    };

    // If employee is designated as a driver, link or create driver profile
    if (newEmployee.isDriver) {
      if (!newEmployee.linkedDriverId) {
        // Automatically create a corresponding Driver record
        const newDriverId = `drv-${Date.now().toString().slice(-4)}`;
        const autoDriver: Driver = {
          id: newDriverId,
          employeeId: newEmpId,
          fullName: newEmployee.fullName,
          phone: newEmployee.phone,
          email: newEmployee.email,
          licenseNumber: `DL-${Math.floor(1000000 + Math.random() * 9000000)}`,
          cdlClass: 'Class A',
          licenseExpiry: '2028-12-31',
          status: 'available',
          safetyScore: 95,
          totalTripsCompleted: 0,
          hoursDrivenThisWeek: 0,
          infractions: { hardBrakingCount: 0, speedingCount: 0, rapidAccelCount: 0 },
          createdAt: new Date().toISOString(),
          updatedAt: new Date().toISOString(),
        };
        newEmployee.linkedDriverId = newDriverId;
        setDrivers((prev) => [autoDriver, ...prev]);
        logAudit('CREATE', 'drivers', newDriverId, `Auto-enrolled Driver profile for Employee ${newEmployee.fullName}`, {
          after: autoDriver as unknown as Record<string, any>,
        });
      } else {
        // Link existing driver to this employee
        setDrivers((prev) =>
          prev.map((d) => (d.id === newEmployee.linkedDriverId ? { ...d, employeeId: newEmpId } : d))
        );
      }
    }

    setEmployees((prev) => [newEmployee, ...prev]);
    logAudit('CREATE', 'employees', newEmpId, `Onboarded Employee ${newEmployee.fullName} (${newEmployee.employeeCode})`, {
      after: newEmployee as unknown as Record<string, any>,
    });
    showToast('success', 'Employee Onboarded', `${newEmployee.fullName} (${newEmployee.employeeCode}) added to organization.`);
    return { success: true };
  };

  const updateEmployee = (employeeId: string, updates: Partial<Employee>) => {
    const emp = employees.find((e) => e.id === employeeId);
    if (!emp) return { success: false, error: 'Employee not found.' };

    const before = { ...emp };
    const updated: Employee = {
      ...emp,
      ...updates,
      updatedAt: new Date().toISOString(),
    };

    setEmployees((prev) => prev.map((e) => (e.id === employeeId ? updated : e)));

    // Synchronize driver record if driver link exists
    if (updated.linkedDriverId) {
      setDrivers((prev) =>
        prev.map((d) =>
          d.id === updated.linkedDriverId
            ? {
                ...d,
                fullName: updated.fullName,
                phone: updated.phone,
                email: updated.email,
                status: updated.status === 'active' ? d.status : 'suspended',
              }
            : d
        )
      );
    }

    logAudit('UPDATE', 'employees', employeeId, `Updated Employee profile for ${updated.fullName}`, {
      before: before as unknown as Record<string, any>,
      after: updated as unknown as Record<string, any>,
    });
    showToast('success', 'Employee Updated', `Changes to ${updated.fullName} saved.`);
    return { success: true };
  };

  const softDeleteEmployee = (employeeId: string) => {
    const emp = employees.find((e) => e.id === employeeId);
    if (!emp) return;

    setEmployees((prev) =>
      prev.map((e) =>
        e.id === employeeId
          ? { ...e, status: 'terminated', deletedAt: new Date().toISOString() }
          : e
      )
    );

    // Deactivate linked driver if present
    if (emp.linkedDriverId) {
      setDrivers((prev) =>
        prev.map((d) => (d.id === emp.linkedDriverId ? { ...d, status: 'suspended', deletedAt: new Date().toISOString() } : d))
      );
    }

    logAudit('DELETE', 'employees', employeeId, `Soft deleted / Terminated Employee ${emp.fullName}`, {
      before: emp as unknown as Record<string, any>,
    });
    showToast('warning', 'Employee Offboarded', `${emp.fullName} has been archived and marked terminated.`);
  };

  // Department Actions
  const addDepartment = (deptData: Omit<Department, 'id' | 'companyId' | 'createdAt' | 'updatedAt'>) => {
    if (departments.some((d) => d.code.toLowerCase() === deptData.code.toLowerCase() && !d.deletedAt)) {
      return { success: false, error: 'Department code must be unique.' };
    }

    const newDept: Department = {
      ...deptData,
      id: `dept-${Date.now().toString().slice(-4)}`,
      companyId: currentCompany.id,
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString(),
    };

    setDepartments((prev) => [newDept, ...prev]);
    logAudit('CREATE', 'departments', newDept.id, `Created Department ${newDept.name} (${newDept.code})`, {
      after: newDept as unknown as Record<string, any>,
    });
    showToast('success', 'Department Created', `${newDept.name} added.`);
    return { success: true };
  };

  const updateDepartment = (deptId: string, updates: Partial<Department>) => {
    const dept = departments.find((d) => d.id === deptId);
    if (!dept) return { success: false, error: 'Department not found.' };

    const updated = { ...dept, ...updates, updatedAt: new Date().toISOString() };
    setDepartments((prev) => prev.map((d) => (d.id === deptId ? updated : d)));
    logAudit('UPDATE', 'departments', deptId, `Updated Department ${updated.name}`, {
      before: dept as unknown as Record<string, any>,
      after: updated as unknown as Record<string, any>,
    });
    showToast('success', 'Department Updated', `${updated.name} settings saved.`);
    return { success: true };
  };

  const softDeleteDepartment = (deptId: string) => {
    const dept = departments.find((d) => d.id === deptId);
    if (!dept) return;

    setDepartments((prev) =>
      prev.map((d) => (d.id === deptId ? { ...d, deletedAt: new Date().toISOString() } : d))
    );
    logAudit('DELETE', 'departments', deptId, `Archived Department ${dept.name}`, {
      before: dept as unknown as Record<string, any>,
    });
    showToast('warning', 'Department Archived', `${dept.name} marked deleted.`);
  };

  // Designation Actions
  const addDesignation = (desigData: Omit<Designation, 'id' | 'companyId' | 'createdAt' | 'updatedAt'>) => {
    const newDesig: Designation = {
      ...desigData,
      id: `desig-${Date.now().toString().slice(-4)}`,
      companyId: currentCompany.id,
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString(),
    };

    setDesignations((prev) => [newDesig, ...prev]);
    logAudit('CREATE', 'designations', newDesig.id, `Created Designation ${newDesig.title}`, {
      after: newDesig as unknown as Record<string, any>,
    });
    showToast('success', 'Designation Created', `${newDesig.title} added.`);
    return { success: true };
  };

  const updateDesignation = (desigId: string, updates: Partial<Designation>) => {
    const desig = designations.find((d) => d.id === desigId);
    if (!desig) return { success: false, error: 'Designation not found.' };

    const updated = { ...desig, ...updates, updatedAt: new Date().toISOString() };
    setDesignations((prev) => prev.map((d) => (d.id === desigId ? updated : d)));
    logAudit('UPDATE', 'designations', desigId, `Updated Designation ${updated.title}`, {
      before: desig as unknown as Record<string, any>,
      after: updated as unknown as Record<string, any>,
    });
    showToast('success', 'Designation Updated', `${updated.title} updated.`);
    return { success: true };
  };

  const softDeleteDesignation = (desigId: string) => {
    const desig = designations.find((d) => d.id === desigId);
    if (!desig) return;

    setDesignations((prev) =>
      prev.map((d) => (d.id === desigId ? { ...d, deletedAt: new Date().toISOString() } : d))
    );
    logAudit('DELETE', 'designations', desigId, `Archived Designation ${desig.title}`, {
      before: desig as unknown as Record<string, any>,
    });
    showToast('warning', 'Designation Archived', `${desig.title} marked deleted.`);
  };

  // Shift Scheduling Actions
  const addShift = (shiftData: Omit<Shift, 'id' | 'companyId'>) => {
    const newShift: Shift = {
      ...shiftData,
      id: `shift-${Date.now().toString().slice(-4)}`,
      companyId: currentCompany.id,
    };
    setShifts((prev) => [newShift, ...prev]);
    logAudit('CREATE', 'shifts', newShift.id, `Created Shift schedule ${newShift.name} (${newShift.startTime}-${newShift.endTime})`, {
      after: newShift as unknown as Record<string, any>,
    });
    showToast('success', 'Shift Schedule Created', `${newShift.name} added.`);
    return { success: true };
  };

  const updateShift = (shiftId: string, updates: Partial<Shift>) => {
    const shift = shifts.find((s) => s.id === shiftId);
    if (!shift) return { success: false, error: 'Shift schedule not found.' };

    const updated = { ...shift, ...updates };
    setShifts((prev) => prev.map((s) => (s.id === shiftId ? updated : s)));
    logAudit('UPDATE', 'shifts', shiftId, `Updated Shift schedule ${updated.name}`, {
      before: shift as unknown as Record<string, any>,
      after: updated as unknown as Record<string, any>,
    });
    showToast('success', 'Shift Updated', `${updated.name} schedule modified.`);
    return { success: true };
  };

  // Attendance Management
  const recordAttendance = (attData: Omit<AttendanceRecord, 'id' | 'companyId'>) => {
    const newRecord: AttendanceRecord = {
      ...attData,
      id: `att-${Date.now().toString().slice(-4)}`,
      companyId: currentCompany.id,
    };
    setAttendanceRecords((prev) => [newRecord, ...prev]);
    logAudit('CREATE', 'attendance', newRecord.id, `Attendance logged for Employee ${attData.employeeId} on ${attData.date} (${attData.status})`, {
      after: newRecord as unknown as Record<string, any>,
    });
    showToast('success', 'Attendance Logged', `Recorded ${attData.status.toUpperCase()} for ${attData.date}`);
  };

  const clockInEmployee = (employeeId: string, locationName?: string, coords?: { lat: number; lng: number }) => {
    const emp = employees.find((e) => e.id === employeeId);
    if (!emp) return { success: false, error: 'Employee not found.' };

    const todayStr = new Date().toISOString().split('T')[0];
    const existing = attendanceRecords.find((a) => a.employeeId === employeeId && a.date === todayStr);
    if (existing) {
      return { success: false, error: 'Employee has already clocked in today.' };
    }

    const now = new Date();
    const hours = String(now.getHours()).padStart(2, '0');
    const minutes = String(now.getMinutes()).padStart(2, '0');
    const checkInTime = `${hours}:${minutes}`;

    // Determine status (check if late against shift grace period)
    const empShift = shifts.find((s) => s.id === emp.shiftId);
    let status: AttendanceRecord['status'] = 'present';
    if (empShift) {
      const [shiftHour, shiftMin] = empShift.startTime.split(':').map(Number);
      const shiftStartInMins = shiftHour * 60 + shiftMin + (empShift.gracePeriodMins || 15);
      const checkInInMins = now.getHours() * 60 + now.getMinutes();
      if (checkInInMins > shiftStartInMins) {
        status = 'late';
      }
    }

    const newAtt: AttendanceRecord = {
      id: `att-${Date.now().toString().slice(-4)}`,
      companyId: currentCompany.id,
      employeeId,
      date: todayStr,
      checkInTime,
      status,
      shiftId: emp.shiftId,
      hoursWorked: 0,
      overtimeHours: 0,
      clockInLatitude: coords?.lat,
      clockInLongitude: coords?.lng,
      locationName: locationName || 'Apex Fleet Logistics Terminal',
      notes: `Mobile / Web check-in at ${checkInTime}`,
    };

    setAttendanceRecords((prev) => [newAtt, ...prev]);
    logAudit('CREATE', 'attendance', newAtt.id, `Employee ${emp.fullName} clocked in at ${checkInTime} (${status})`, {
      after: newAtt as unknown as Record<string, any>,
    });
    showToast('success', 'Clock-In Successful', `${emp.fullName} clocked in at ${checkInTime} (${status.toUpperCase()})`);
    return { success: true };
  };

  const clockOutEmployee = (attendanceId: string) => {
    const att = attendanceRecords.find((a) => a.id === attendanceId);
    if (!att) return { success: false, error: 'Attendance record not found.' };

    const now = new Date();
    const hours = String(now.getHours()).padStart(2, '0');
    const minutes = String(now.getMinutes()).padStart(2, '0');
    const checkOutTime = `${hours}:${minutes}`;

    // Calculate hours worked from check-in
    const [inH, inM] = att.checkInTime.split(':').map(Number);
    const inTotalMins = inH * 60 + inM;
    const outTotalMins = now.getHours() * 60 + now.getMinutes();
    const totalMinutes = Math.max(0, outTotalMins - inTotalMins);
    const rawHours = Number((totalMinutes / 60).toFixed(1));
    const overtimeHours = rawHours > 8 ? Number((rawHours - 8).toFixed(1)) : 0;

    const updated: AttendanceRecord = {
      ...att,
      checkOutTime,
      hoursWorked: rawHours,
      overtimeHours,
    };

    setAttendanceRecords((prev) => prev.map((a) => (a.id === attendanceId ? updated : a)));
    logAudit('UPDATE', 'attendance', attendanceId, `Clock-out recorded at ${checkOutTime} (${rawHours}h worked, ${overtimeHours}h OT)`, {
      before: att as unknown as Record<string, any>,
      after: updated as unknown as Record<string, any>,
    });
    showToast('success', 'Clock-Out Completed', `Worked ${rawHours}h (Overtime: ${overtimeHours}h)`);
    return { success: true };
  };

  // Leave Management
  const applyLeaveRequest = (leaveData: Omit<LeaveRequest, 'id' | 'companyId' | 'appliedAt' | 'status'>) => {
    const newLeave: LeaveRequest = {
      ...leaveData,
      id: `leave-${Date.now().toString().slice(-4)}`,
      companyId: currentCompany.id,
      status: 'pending',
      appliedAt: new Date().toISOString(),
    };

    setLeaveRequests((prev) => [newLeave, ...prev]);
    const emp = employees.find((e) => e.id === leaveData.employeeId);
    logAudit('CREATE', 'leaves', newLeave.id, `Leave application filed by ${emp?.fullName || leaveData.employeeId} (${leaveData.leaveType}, ${leaveData.totalDays} days)`, {
      after: newLeave as unknown as Record<string, any>,
    });
    showToast('info', 'Leave Request Submitted', `Submitted for ${leaveData.totalDays} day(s) of ${leaveData.leaveType} leave.`);
    return { success: true };
  };

  const updateLeaveStatus = (leaveId: string, status: LeaveStatus, rejectionReason?: string) => {
    const leave = leaveRequests.find((l) => l.id === leaveId);
    if (!leave) return;

    const updated: LeaveRequest = {
      ...leave,
      status,
      approvedBy: status === 'approved' ? `${currentUser.displayName} (${currentUser.role.toUpperCase()})` : undefined,
      rejectionReason: status === 'rejected' ? rejectionReason : undefined,
      reviewedAt: new Date().toISOString(),
    };

    setLeaveRequests((prev) => prev.map((l) => (l.id === leaveId ? updated : l)));

    // If approved and start date is active, update employee status to on_leave
    if (status === 'approved') {
      setEmployees((prev) =>
        prev.map((e) => (e.id === leave.employeeId ? { ...e, status: 'on_leave' } : e))
      );
    }

    logAudit('STATUS_CHANGE', 'leaves', leaveId, `Leave request marked ${status.toUpperCase()}`, {
      before: { status: leave.status },
      after: { status, rejectionReason },
    });
    showToast(status === 'approved' ? 'success' : 'warning', `Leave Request ${status.toUpperCase()}`, `Leave request has been ${status}.`);
  };

  // Payroll Preparation & Feeds from Attendance
  const generatePayrollForMonth = (payrollMonth: string) => {
    const activeEmployees = employees.filter((e) => !e.deletedAt && e.companyId === currentCompany.id);
    let count = 0;
    let totalGross = 0;
    let totalNet = 0;

    const newPayrolls: PayrollRecord[] = [];

    activeEmployees.forEach((emp) => {
      // Calculate attendance statistics for this month
      const empAttendance = attendanceRecords.filter(
        (a) => a.employeeId === emp.id && a.date.startsWith(payrollMonth)
      );

      const daysPresent = empAttendance.filter((a) => a.status === 'present' || a.status === 'late' || a.status === 'half_day').length;
      const totalOTHours = empAttendance.reduce((acc, a) => acc + (a.overtimeHours || 0), 0);

      // Hourly base calculation based on 160 std monthly hours
      const hourlyRate = (emp.salaryStructure.baseSalary || 4000) / 160;
      const overtimePay = Number((totalOTHours * hourlyRate * 1.5).toFixed(2));

      const totalAllowances =
        (emp.salaryStructure.hraAllowance || 0) +
        (emp.salaryStructure.transportAllowance || 0) +
        (emp.salaryStructure.medicalAllowance || 0) +
        (emp.salaryStructure.specialAllowance || 0) +
        (emp.salaryStructure.performanceBonus || 0);

      const grossSalary = Number((emp.salaryStructure.baseSalary + totalAllowances + overtimePay).toFixed(2));
      const taxRate = (emp.salaryStructure.taxDeductionPercent || 10) / 100;
      const taxDeduction = Number((grossSalary * taxRate).toFixed(2));
      const pfDeduction = emp.salaryStructure.providentFundDeduction || 0;
      const netSalary = Number((grossSalary - taxDeduction - pfDeduction).toFixed(2));

      const existingPr = payrollRecords.find((p) => p.employeeId === emp.id && p.payrollMonth === payrollMonth);
      if (!existingPr) {
        const prRecord: PayrollRecord = {
          id: `pr-${payrollMonth}-${emp.id}`,
          companyId: currentCompany.id,
          payrollMonth,
          employeeId: emp.id,
          baseSalary: emp.salaryStructure.baseSalary,
          totalAllowances,
          overtimePay,
          grossSalary,
          taxDeduction,
          pfDeduction,
          otherDeductions: 0,
          netSalary,
          daysPresent: daysPresent > 0 ? daysPresent : 20, // default if month mid
          daysAbsent: 0,
          daysOnLeave: 0,
          overtimeHours: totalOTHours,
          status: 'draft',
          paymentMethod: 'direct_deposit',
          notes: `Payroll batch auto-computed from attendance telemetry (${daysPresent} days present, ${totalOTHours}h OT)`,
          createdAt: new Date().toISOString(),
          updatedAt: new Date().toISOString(),
        };
        newPayrolls.push(prRecord);
        count++;
        totalGross += grossSalary;
        totalNet += netSalary;
      }
    });

    if (newPayrolls.length > 0) {
      setPayrollRecords((prev) => [...newPayrolls, ...prev]);
      logAudit('CREATE', 'payroll', `batch-${payrollMonth}`, `Generated ${count} payroll ledger drafts for month ${payrollMonth}`, {
        after: { count, totalGross, totalNet },
      });
      showToast('success', 'Payroll Prepared', `Generated ${count} payroll drafts (${totalNet.toLocaleString()} net disbursement).`);
    } else {
      showToast('info', 'Payroll Up-to-date', `Payroll for ${payrollMonth} already generated.`);
    }

    return { count, totalGross, totalNet };
  };

  const updatePayrollStatus = (payrollId: string, status: PayrollStatus, paymentMethod?: PaymentMethod, transactionRef?: string) => {
    const pr = payrollRecords.find((p) => p.id === payrollId);
    if (!pr) return;

    const updated: PayrollRecord = {
      ...pr,
      status,
      paymentMethod: paymentMethod || pr.paymentMethod,
      transactionRef: transactionRef || (status === 'disbursed' ? `TXN-${Date.now().toString().slice(-6)}` : pr.transactionRef),
      paymentDate: status === 'disbursed' ? new Date().toISOString().split('T')[0] : pr.paymentDate,
      updatedAt: new Date().toISOString(),
    };

    setPayrollRecords((prev) => prev.map((p) => (p.id === payrollId ? updated : p)));
    logAudit('STATUS_CHANGE', 'payroll', payrollId, `Payroll ${payrollId} moved to ${status.toUpperCase()}`, {
      before: { status: pr.status },
      after: { status, transactionRef: updated.transactionRef },
    });
    showToast(status === 'disbursed' ? 'success' : 'info', `Payroll ${status.toUpperCase()}`, `Salary payment moved to ${status}.`);
  };

  const resetDemoData = () => {
    localStorage.clear();
    setVehicles(initialVehicles);
    setDrivers(initialDrivers);
    setTrips(initialTrips);
    setFuelLogs(initialFuelLogs);
    setMaintenanceTickets(initialMaintenanceTickets);
    setComplianceDocs(initialComplianceDocuments);
    setInvoices(initialInvoices);
    setAuditLogs(initialAuditLogs);
    setDepartments(initialDepartments);
    setDesignations(initialDesignations);
    setShifts(initialShifts);
    setEmployees(initialEmployees);
    setAttendanceRecords(initialAttendanceRecords);
    setLeaveRequests(initialLeaveRequests);
    setPayrollRecords(initialPayrollRecords);
    showToast('info', 'System Reset', 'All enterprise records have been reset to factory baseline.');
  };

  return (
    <FleetContext.Provider
      value={{
        currentCompany,
        setCurrentCompany,
        companies,
        currentUser,
        setCurrentUserRole,
        vehicles,
        drivers,
        trips,
        fuelLogs,
        maintenanceTickets,
        complianceDocs,
        invoices,
        auditLogs,
        toasts,
        departments,
        designations,
        shifts,
        employees,
        attendanceRecords,
        leaveRequests,
        payrollRecords,
        isLiveSimulating,
        setIsLiveSimulating,
        dismissToast,
        showToast,
        addVehicle,
        updateVehicleStatus,
        softDeleteVehicle,
        addDriver,
        assignDriverToVehicle,
        createTrip,
        updateTripStatus,
        advanceCheckpoint,
        addFuelLog,
        createMaintenanceTicket,
        resolveMaintenanceTicket,
        addComplianceDoc,
        verifyComplianceDoc,
        topUpFastag,
        createInvoice,
        markInvoicePaid,
        updateInvoiceStatus,
        addEmployee,
        updateEmployee,
        softDeleteEmployee,
        addDepartment,
        updateDepartment,
        softDeleteDepartment,
        addDesignation,
        updateDesignation,
        softDeleteDesignation,
        addShift,
        updateShift,
        recordAttendance,
        clockInEmployee,
        clockOutEmployee,
        applyLeaveRequest,
        updateLeaveStatus,
        generatePayrollForMonth,
        updatePayrollStatus,
        resetDemoData,
      }}
    >
      {children}
    </FleetContext.Provider>
  );
};

export const useFleet = () => {
  const context = useContext(FleetContext);
  if (!context) {
    throw new Error('useFleet must be used within a FleetProvider');
  }
  return context;
};
