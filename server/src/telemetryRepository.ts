import { appendFile, mkdir, readFile } from 'node:fs/promises';
import { dirname } from 'node:path';
import { Pool } from 'pg';
import type { NormalizedTelemetry } from './telemetry.js';

export interface TelemetryHistoryQuery {
  companyId: string;
  vehicleId?: string;
  from?: string;
  to?: string;
  limit?: number;
}

export interface NormalizedTelemetryHistoryQuery extends TelemetryHistoryQuery {
  limit: number;
}

export interface TelemetryRepository {
  readonly kind: 'memory' | 'jsonl' | 'postgres';
  append(reading: NormalizedTelemetry): Promise<void>;
  history(query: TelemetryHistoryQuery): Promise<NormalizedTelemetry[]>;
}

function validTimestamp(value: string | undefined, field: string): string | undefined {
  if (!value) return undefined;
  if (!Number.isFinite(Date.parse(value))) throw new Error(`${field} must be a valid timestamp`);
  return new Date(value).toISOString();
}

export function normalizeTelemetryHistoryQuery(query: TelemetryHistoryQuery): NormalizedTelemetryHistoryQuery {
  const companyId = query.companyId?.trim();
  if (!companyId) throw new Error('companyId is required');

  const rawLimit = query.limit ?? 500;
  if (!Number.isFinite(rawLimit)) throw new Error('limit must be a finite number');
  const limit = Math.max(1, Math.min(Math.trunc(rawLimit), 5000));
  const from = validTimestamp(query.from?.trim(), 'from');
  const to = validTimestamp(query.to?.trim(), 'to');
  if (from && to && Date.parse(from) > Date.parse(to)) throw new Error('from must not be after to');

  return {
    companyId,
    vehicleId: query.vehicleId?.trim() || undefined,
    from,
    to,
    limit,
  };
}

export class InMemoryTelemetryRepository implements TelemetryRepository {
  readonly kind = 'memory' as const;
  private readonly rows: NormalizedTelemetry[] = [];

  async append(reading: NormalizedTelemetry): Promise<void> {
    this.rows.push(reading);
  }

  async history(query: TelemetryHistoryQuery): Promise<NormalizedTelemetry[]> {
    return filterHistory(this.rows, normalizeTelemetryHistoryQuery(query));
  }
}

export class JsonlTelemetryRepository implements TelemetryRepository {
  readonly kind = 'jsonl' as const;

  constructor(private readonly filePath: string) {}

  async append(reading: NormalizedTelemetry): Promise<void> {
    await mkdir(dirname(this.filePath), { recursive: true });
    await appendFile(this.filePath, `${JSON.stringify(reading)}\n`, 'utf8');
  }

  async history(query: TelemetryHistoryQuery): Promise<NormalizedTelemetry[]> {
    const normalized = normalizeTelemetryHistoryQuery(query);
    let text = '';
    try {
      text = await readFile(this.filePath, 'utf8');
    } catch (error) {
      if ((error as NodeJS.ErrnoException).code === 'ENOENT') return [];
      throw error;
    }

    const rows: NormalizedTelemetry[] = [];
    for (const line of text.split('\n')) {
      if (!line.trim()) continue;
      try {
        rows.push(JSON.parse(line) as NormalizedTelemetry);
      } catch {
        // Skip malformed historical lines instead of crashing live telemetry reads.
      }
    }
    return filterHistory(rows, normalized);
  }
}

export class PostgresTelemetryRepository implements TelemetryRepository {
  readonly kind = 'postgres' as const;
  private readonly pool: Pool;
  private schemaReady: Promise<void> | null = null;

  constructor(connectionString: string) {
    this.pool = new Pool({ connectionString, max: 10 });
  }

  private ensureSchema(): Promise<void> {
    if (!this.schemaReady) {
      this.schemaReady = this.pool.query(`
        CREATE TABLE IF NOT EXISTS fleetos_telemetry_history (
          id BIGSERIAL PRIMARY KEY,
          company_id TEXT NOT NULL,
          vehicle_id TEXT NOT NULL,
          recorded_at TIMESTAMPTZ NOT NULL,
          received_at TIMESTAMPTZ NOT NULL,
          payload JSONB NOT NULL,
          created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
        );
        CREATE INDEX IF NOT EXISTS fleetos_telemetry_company_recorded_idx
          ON fleetos_telemetry_history (company_id, recorded_at DESC);
        CREATE INDEX IF NOT EXISTS fleetos_telemetry_company_vehicle_recorded_idx
          ON fleetos_telemetry_history (company_id, vehicle_id, recorded_at DESC);
      `).then(() => undefined).catch((error) => {
        this.schemaReady = null;
        throw error;
      });
    }
    return this.schemaReady;
  }

  async append(reading: NormalizedTelemetry): Promise<void> {
    await this.ensureSchema();
    await this.pool.query(
      `INSERT INTO fleetos_telemetry_history
        (company_id, vehicle_id, recorded_at, received_at, payload)
       VALUES ($1, $2, $3, $4, $5::jsonb)`,
      [reading.companyId, reading.vehicleId, reading.recordedAt, reading.receivedAt, JSON.stringify(reading)],
    );
  }

  async history(query: TelemetryHistoryQuery): Promise<NormalizedTelemetry[]> {
    const normalized = normalizeTelemetryHistoryQuery(query);
    await this.ensureSchema();
    const values: unknown[] = [normalized.companyId];
    const clauses = ['company_id = $1'];

    if (normalized.vehicleId) {
      values.push(normalized.vehicleId);
      clauses.push(`vehicle_id = $${values.length}`);
    }
    if (normalized.from) {
      values.push(normalized.from);
      clauses.push(`recorded_at >= $${values.length}::timestamptz`);
    }
    if (normalized.to) {
      values.push(normalized.to);
      clauses.push(`recorded_at <= $${values.length}::timestamptz`);
    }

    values.push(normalized.limit);
    const result = await this.pool.query<{ payload: NormalizedTelemetry }>(
      `SELECT payload
       FROM fleetos_telemetry_history
       WHERE ${clauses.join(' AND ')}
       ORDER BY recorded_at DESC
       LIMIT $${values.length}`,
      values,
    );
    return result.rows.map((row) => row.payload);
  }
}

function filterHistory(rows: NormalizedTelemetry[], query: NormalizedTelemetryHistoryQuery): NormalizedTelemetry[] {
  const fromMs = query.from ? Date.parse(query.from) : Number.NEGATIVE_INFINITY;
  const toMs = query.to ? Date.parse(query.to) : Number.POSITIVE_INFINITY;

  return rows
    .filter((row) => row.companyId === query.companyId)
    .filter((row) => !query.vehicleId || row.vehicleId === query.vehicleId)
    .filter((row) => {
      const t = Date.parse(row.recordedAt);
      return Number.isFinite(t) && t >= fromMs && t <= toMs;
    })
    .sort((a, b) => Date.parse(b.recordedAt) - Date.parse(a.recordedAt))
    .slice(0, query.limit);
}

export function createTelemetryRepository(): TelemetryRepository {
  const databaseUrl = process.env.DATABASE_URL?.trim();
  if (databaseUrl) return new PostgresTelemetryRepository(databaseUrl);

  const path = process.env.FLEETOS_TELEMETRY_HISTORY_FILE?.trim();
  return path ? new JsonlTelemetryRepository(path) : new InMemoryTelemetryRepository();
}
