import { Pool } from 'pg';

export type CommercialVehicleRelation = 'owned' | 'hired' | 'attached' | 'third_party';
export type SettlementBasis = 'per_trip' | 'per_tonne' | 'per_km' | 'fixed_daily' | 'revenue_share';

export interface VehicleSettlementTermsRecord {
  companyId: string;
  vehicleId: string;
  relation: CommercialVehicleRelation;
  ownerName?: string;
  basis: SettlementBasis;
  rate: number;
  revenueSharePercent?: number;
  driverAdvance?: number;
  ownerAdvance?: number;
  retentionAmount?: number;
  updatedAt: string;
  updatedBy: string;
}

export interface SettlementRepository {
  readonly kind: 'memory' | 'postgres';
  list(companyId: string): Promise<VehicleSettlementTermsRecord[]>;
  get(companyId: string, vehicleId: string): Promise<VehicleSettlementTermsRecord | null>;
  upsert(record: VehicleSettlementTermsRecord): Promise<VehicleSettlementTermsRecord>;
}

const RELATIONS = new Set<CommercialVehicleRelation>(['owned', 'hired', 'attached', 'third_party']);
const BASES = new Set<SettlementBasis>(['per_trip', 'per_tonne', 'per_km', 'fixed_daily', 'revenue_share']);

function cleanOptionalText(value: unknown, max = 240): string | undefined {
  if (typeof value !== 'string') return undefined;
  const text = value.trim();
  return text ? text.slice(0, max) : undefined;
}

function nonNegativeNumber(value: unknown, field: string): number | undefined {
  if (value === undefined || value === null || value === '') return undefined;
  const number = Number(value);
  if (!Number.isFinite(number) || number < 0) throw new Error(`${field} must be a non-negative number`);
  return Number(number.toFixed(2));
}

export function normalizeSettlementTerms(
  companyId: string,
  vehicleId: string,
  raw: unknown,
  updatedBy: string,
): VehicleSettlementTermsRecord {
  if (!raw || typeof raw !== 'object') throw new Error('settlement terms payload is required');
  const input = raw as Record<string, unknown>;
  const relation = input.relation;
  const basis = input.basis;
  if (typeof relation !== 'string' || !RELATIONS.has(relation as CommercialVehicleRelation)) {
    throw new Error('unsupported vehicle relation');
  }
  if (typeof basis !== 'string' || !BASES.has(basis as SettlementBasis)) {
    throw new Error('unsupported settlement basis');
  }

  const rate = nonNegativeNumber(input.rate, 'rate') ?? 0;
  const revenueSharePercent = nonNegativeNumber(input.revenueSharePercent, 'revenueSharePercent');
  const effectiveShare = basis === 'revenue_share' ? (revenueSharePercent ?? rate) : revenueSharePercent;
  if (effectiveShare !== undefined && effectiveShare > 100) {
    throw new Error('revenue share cannot exceed 100%');
  }

  return {
    companyId,
    vehicleId,
    relation: relation as CommercialVehicleRelation,
    ownerName: relation === 'owned' ? undefined : cleanOptionalText(input.ownerName),
    basis: basis as SettlementBasis,
    rate,
    revenueSharePercent: effectiveShare,
    driverAdvance: nonNegativeNumber(input.driverAdvance, 'driverAdvance'),
    ownerAdvance: nonNegativeNumber(input.ownerAdvance, 'ownerAdvance'),
    retentionAmount: nonNegativeNumber(input.retentionAmount, 'retentionAmount'),
    updatedAt: new Date().toISOString(),
    updatedBy,
  };
}

export class InMemorySettlementRepository implements SettlementRepository {
  readonly kind = 'memory' as const;
  private readonly rows = new Map<string, VehicleSettlementTermsRecord>();

  private key(companyId: string, vehicleId: string): string {
    return `${companyId}\u0000${vehicleId}`;
  }

  async list(companyId: string): Promise<VehicleSettlementTermsRecord[]> {
    return [...this.rows.values()]
      .filter((row) => row.companyId === companyId)
      .sort((a, b) => a.vehicleId.localeCompare(b.vehicleId));
  }

  async get(companyId: string, vehicleId: string): Promise<VehicleSettlementTermsRecord | null> {
    return this.rows.get(this.key(companyId, vehicleId)) ?? null;
  }

  async upsert(record: VehicleSettlementTermsRecord): Promise<VehicleSettlementTermsRecord> {
    this.rows.set(this.key(record.companyId, record.vehicleId), record);
    return record;
  }
}

export class PostgresSettlementRepository implements SettlementRepository {
  readonly kind = 'postgres' as const;
  private readonly pool: Pool;
  private schemaReady: Promise<void> | null = null;

  constructor(connectionString: string) {
    this.pool = new Pool({ connectionString, max: 10 });
  }

  private ensureSchema(): Promise<void> {
    if (!this.schemaReady) {
      this.schemaReady = this.pool.query(`
        CREATE TABLE IF NOT EXISTS fleetos_vehicle_settlement_terms (
          company_id TEXT NOT NULL,
          vehicle_id TEXT NOT NULL,
          payload JSONB NOT NULL,
          updated_at TIMESTAMPTZ NOT NULL,
          updated_by TEXT NOT NULL,
          PRIMARY KEY (company_id, vehicle_id)
        );
        CREATE INDEX IF NOT EXISTS fleetos_settlement_company_updated_idx
          ON fleetos_vehicle_settlement_terms (company_id, updated_at DESC);
      `).then(() => undefined).catch((error) => {
        this.schemaReady = null;
        throw error;
      });
    }
    return this.schemaReady;
  }

  async list(companyId: string): Promise<VehicleSettlementTermsRecord[]> {
    await this.ensureSchema();
    const result = await this.pool.query<{ payload: VehicleSettlementTermsRecord }>(
      `SELECT payload FROM fleetos_vehicle_settlement_terms WHERE company_id = $1 ORDER BY vehicle_id`,
      [companyId],
    );
    return result.rows.map((row) => row.payload);
  }

  async get(companyId: string, vehicleId: string): Promise<VehicleSettlementTermsRecord | null> {
    await this.ensureSchema();
    const result = await this.pool.query<{ payload: VehicleSettlementTermsRecord }>(
      `SELECT payload FROM fleetos_vehicle_settlement_terms WHERE company_id = $1 AND vehicle_id = $2 LIMIT 1`,
      [companyId, vehicleId],
    );
    return result.rows[0]?.payload ?? null;
  }

  async upsert(record: VehicleSettlementTermsRecord): Promise<VehicleSettlementTermsRecord> {
    await this.ensureSchema();
    await this.pool.query(
      `INSERT INTO fleetos_vehicle_settlement_terms
        (company_id, vehicle_id, payload, updated_at, updated_by)
       VALUES ($1, $2, $3::jsonb, $4, $5)
       ON CONFLICT (company_id, vehicle_id)
       DO UPDATE SET payload = EXCLUDED.payload, updated_at = EXCLUDED.updated_at, updated_by = EXCLUDED.updated_by`,
      [record.companyId, record.vehicleId, JSON.stringify(record), record.updatedAt, record.updatedBy],
    );
    return record;
  }
}

export function createSettlementRepository(): SettlementRepository {
  const databaseUrl = process.env.DATABASE_URL?.trim();
  return databaseUrl ? new PostgresSettlementRepository(databaseUrl) : new InMemorySettlementRepository();
}
