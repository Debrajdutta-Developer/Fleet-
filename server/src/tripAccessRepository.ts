import { Pool } from 'pg';
import type { TenantPrincipal } from './tenantAuth.js';

export interface TripAssignment {
  companyId: string;
  tripId: string;
  vehicleId?: string;
  driverSubject?: string;
  khalashiSubject?: string;
  updatedBy: string;
  updatedAt: string;
}

export interface TripAccessRepository {
  readonly kind: 'memory' | 'postgres';
  get(companyId: string, tripId: string): Promise<TripAssignment | null>;
  upsert(assignment: TripAssignment): Promise<TripAssignment>;
  listForPrincipal(principal: TenantPrincipal): Promise<TripAssignment[]>;
  canAccess(principal: TenantPrincipal, tripId: string): Promise<boolean>;
  canAccessVehicle(principal: TenantPrincipal, vehicleId: string): Promise<boolean>;
}

const BROAD_TRIP_ROLES = new Set<TenantPrincipal['role']>([
  'owner',
  'manager',
  'dispatcher',
  'accountant',
  'compliance',
]);

function clean(value: string | undefined): string | undefined {
  const trimmed = value?.trim();
  return trimmed || undefined;
}

export function normalizeTripAssignment(
  companyId: string,
  tripId: string,
  input: Partial<TripAssignment>,
  updatedBy: string,
  now = new Date(),
): TripAssignment {
  const company = companyId.trim();
  const trip = tripId.trim();
  if (!company) throw new Error('companyId is required');
  if (!trip) throw new Error('tripId is required');
  return {
    companyId: company,
    tripId: trip,
    vehicleId: clean(input.vehicleId),
    driverSubject: clean(input.driverSubject),
    khalashiSubject: clean(input.khalashiSubject),
    updatedBy: updatedBy.trim(),
    updatedAt: now.toISOString(),
  };
}

function subjectCanAccess(principal: TenantPrincipal, assignment: TripAssignment | null): boolean {
  if (BROAD_TRIP_ROLES.has(principal.role)) return true;
  if (!assignment) return false;
  if (principal.role === 'driver') return assignment.driverSubject === principal.sub;
  if (principal.role === 'khalashi') return assignment.khalashiSubject === principal.sub;
  return false;
}

function rowToAssignment(row: Record<string, unknown>): TripAssignment {
  return {
    companyId: String(row.company_id),
    tripId: String(row.trip_id),
    vehicleId: typeof row.vehicle_id === 'string' ? row.vehicle_id : undefined,
    driverSubject: typeof row.driver_subject === 'string' ? row.driver_subject : undefined,
    khalashiSubject: typeof row.khalashi_subject === 'string' ? row.khalashi_subject : undefined,
    updatedBy: String(row.updated_by),
    updatedAt: new Date(String(row.updated_at)).toISOString(),
  };
}

export class InMemoryTripAccessRepository implements TripAccessRepository {
  readonly kind = 'memory' as const;
  private readonly rows = new Map<string, TripAssignment>();

  private key(companyId: string, tripId: string): string {
    return `${companyId}::${tripId}`;
  }

  async get(companyId: string, tripId: string): Promise<TripAssignment | null> {
    return this.rows.get(this.key(companyId, tripId)) ?? null;
  }

  async upsert(assignment: TripAssignment): Promise<TripAssignment> {
    this.rows.set(this.key(assignment.companyId, assignment.tripId), assignment);
    return assignment;
  }

  async listForPrincipal(principal: TenantPrincipal): Promise<TripAssignment[]> {
    const companyRows = [...this.rows.values()].filter((row) => row.companyId === principal.companyId);
    if (BROAD_TRIP_ROLES.has(principal.role)) return companyRows;
    if (principal.role === 'driver') return companyRows.filter((row) => row.driverSubject === principal.sub);
    if (principal.role === 'khalashi') return companyRows.filter((row) => row.khalashiSubject === principal.sub);
    return [];
  }

  async canAccess(principal: TenantPrincipal, tripId: string): Promise<boolean> {
    const assignment = await this.get(principal.companyId, tripId);
    return subjectCanAccess(principal, assignment);
  }

  async canAccessVehicle(principal: TenantPrincipal, vehicleId: string): Promise<boolean> {
    if (BROAD_TRIP_ROLES.has(principal.role)) return true;
    const assignments = await this.listForPrincipal(principal);
    return assignments.some((row) => row.vehicleId === vehicleId);
  }
}

export class PostgresTripAccessRepository implements TripAccessRepository {
  readonly kind = 'postgres' as const;
  private readonly pool: Pool;
  private schemaReady: Promise<void> | null = null;

  constructor(connectionString: string) {
    this.pool = new Pool({ connectionString, max: 10 });
  }

  private async ensureSchema(): Promise<void> {
    if (!this.schemaReady) {
      this.schemaReady = this.pool.query(`
        CREATE TABLE IF NOT EXISTS fleetos_trip_assignments (
          company_id TEXT NOT NULL,
          trip_id TEXT NOT NULL,
          vehicle_id TEXT,
          driver_subject TEXT,
          khalashi_subject TEXT,
          updated_by TEXT NOT NULL,
          updated_at TIMESTAMPTZ NOT NULL,
          PRIMARY KEY (company_id, trip_id)
        );
        CREATE INDEX IF NOT EXISTS fleetos_trip_assignments_driver_idx
          ON fleetos_trip_assignments (company_id, driver_subject);
        CREATE INDEX IF NOT EXISTS fleetos_trip_assignments_khalashi_idx
          ON fleetos_trip_assignments (company_id, khalashi_subject);
        CREATE INDEX IF NOT EXISTS fleetos_trip_assignments_vehicle_idx
          ON fleetos_trip_assignments (company_id, vehicle_id);
      `).then(() => undefined);
    }
    await this.schemaReady;
  }

  async get(companyId: string, tripId: string): Promise<TripAssignment | null> {
    await this.ensureSchema();
    const result = await this.pool.query(
      `SELECT company_id, trip_id, vehicle_id, driver_subject, khalashi_subject, updated_by, updated_at
       FROM fleetos_trip_assignments
       WHERE company_id = $1 AND trip_id = $2`,
      [companyId, tripId],
    );
    return result.rows[0] ? rowToAssignment(result.rows[0]) : null;
  }

  async upsert(assignment: TripAssignment): Promise<TripAssignment> {
    await this.ensureSchema();
    await this.pool.query(
      `INSERT INTO fleetos_trip_assignments
       (company_id, trip_id, vehicle_id, driver_subject, khalashi_subject, updated_by, updated_at)
       VALUES ($1,$2,$3,$4,$5,$6,$7)
       ON CONFLICT (company_id, trip_id) DO UPDATE SET
         vehicle_id = EXCLUDED.vehicle_id,
         driver_subject = EXCLUDED.driver_subject,
         khalashi_subject = EXCLUDED.khalashi_subject,
         updated_by = EXCLUDED.updated_by,
         updated_at = EXCLUDED.updated_at`,
      [
        assignment.companyId,
        assignment.tripId,
        assignment.vehicleId ?? null,
        assignment.driverSubject ?? null,
        assignment.khalashiSubject ?? null,
        assignment.updatedBy,
        assignment.updatedAt,
      ],
    );
    return assignment;
  }

  async listForPrincipal(principal: TenantPrincipal): Promise<TripAssignment[]> {
    await this.ensureSchema();
    if (BROAD_TRIP_ROLES.has(principal.role)) {
      const result = await this.pool.query(
        `SELECT company_id, trip_id, vehicle_id, driver_subject, khalashi_subject, updated_by, updated_at
         FROM fleetos_trip_assignments WHERE company_id = $1 ORDER BY updated_at DESC`,
        [principal.companyId],
      );
      return result.rows.map(rowToAssignment);
    }

    if (principal.role !== 'driver' && principal.role !== 'khalashi') return [];
    const column = principal.role === 'driver' ? 'driver_subject' : 'khalashi_subject';
    const result = await this.pool.query(
      `SELECT company_id, trip_id, vehicle_id, driver_subject, khalashi_subject, updated_by, updated_at
       FROM fleetos_trip_assignments
       WHERE company_id = $1 AND ${column} = $2
       ORDER BY updated_at DESC`,
      [principal.companyId, principal.sub],
    );
    return result.rows.map(rowToAssignment);
  }

  async canAccess(principal: TenantPrincipal, tripId: string): Promise<boolean> {
    if (BROAD_TRIP_ROLES.has(principal.role)) return true;
    const assignment = await this.get(principal.companyId, tripId);
    return subjectCanAccess(principal, assignment);
  }

  async canAccessVehicle(principal: TenantPrincipal, vehicleId: string): Promise<boolean> {
    if (BROAD_TRIP_ROLES.has(principal.role)) return true;
    const assignments = await this.listForPrincipal(principal);
    return assignments.some((row) => row.vehicleId === vehicleId);
  }
}

export function createTripAccessRepository(): TripAccessRepository {
  const connectionString = process.env.DATABASE_URL?.trim();
  return connectionString
    ? new PostgresTripAccessRepository(connectionString)
    : new InMemoryTripAccessRepository();
}
