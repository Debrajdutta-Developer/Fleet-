import { appendFile, mkdir, readFile } from 'node:fs/promises';
import { dirname } from 'node:path';
import type { NormalizedTelemetry } from './telemetry.js';

export interface TelemetryHistoryQuery {
  companyId: string;
  vehicleId?: string;
  from?: string;
  to?: string;
  limit?: number;
}

export interface TelemetryRepository {
  append(reading: NormalizedTelemetry): Promise<void>;
  history(query: TelemetryHistoryQuery): Promise<NormalizedTelemetry[]>;
}

export class InMemoryTelemetryRepository implements TelemetryRepository {
  private readonly rows: NormalizedTelemetry[] = [];

  async append(reading: NormalizedTelemetry): Promise<void> {
    this.rows.push(reading);
  }

  async history(query: TelemetryHistoryQuery): Promise<NormalizedTelemetry[]> {
    return filterHistory(this.rows, query);
  }
}

export class JsonlTelemetryRepository implements TelemetryRepository {
  constructor(private readonly filePath: string) {}

  async append(reading: NormalizedTelemetry): Promise<void> {
    await mkdir(dirname(this.filePath), { recursive: true });
    await appendFile(this.filePath, `${JSON.stringify(reading)}\n`, 'utf8');
  }

  async history(query: TelemetryHistoryQuery): Promise<NormalizedTelemetry[]> {
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
    return filterHistory(rows, query);
  }
}

function filterHistory(rows: NormalizedTelemetry[], query: TelemetryHistoryQuery): NormalizedTelemetry[] {
  const fromMs = query.from ? Date.parse(query.from) : Number.NEGATIVE_INFINITY;
  const toMs = query.to ? Date.parse(query.to) : Number.POSITIVE_INFINITY;
  const limit = Math.max(1, Math.min(query.limit ?? 500, 5000));

  return rows
    .filter((row) => row.companyId === query.companyId)
    .filter((row) => !query.vehicleId || row.vehicleId === query.vehicleId)
    .filter((row) => {
      const t = Date.parse(row.recordedAt);
      return Number.isFinite(t) && t >= fromMs && t <= toMs;
    })
    .sort((a, b) => Date.parse(b.recordedAt) - Date.parse(a.recordedAt))
    .slice(0, limit);
}

export function createTelemetryRepository(): TelemetryRepository {
  const path = process.env.FLEETOS_TELEMETRY_HISTORY_FILE?.trim();
  return path ? new JsonlTelemetryRepository(path) : new InMemoryTelemetryRepository();
}
