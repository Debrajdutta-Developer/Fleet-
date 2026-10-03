import type { AuthorityAdapter, AuthorityRecord, ProviderContext } from './types.js';

export interface GenericAuthorityAdapterConfig {
  id: string;
  providerId: string;
  source: AuthorityRecord['source'];
  arrayPath?: string;
  map: {
    vehicleId?: string;
    registrationNumber?: string;
    documentType?: string;
    status?: string;
    validUntil?: string;
    referenceId?: string;
    verifiedAt: string;
  };
}

function getPath(value: unknown, path?: string): unknown {
  if (!path) return value;
  return path.split('.').reduce<unknown>((current, part) => {
    if (!current || typeof current !== 'object') return undefined;
    return (current as Record<string, unknown>)[part];
  }, value);
}

function asString(value: unknown): string | undefined {
  if (typeof value === 'string') {
    const normalized = value.trim();
    return normalized || undefined;
  }
  if (typeof value === 'number' && Number.isFinite(value)) return String(value);
  return undefined;
}

function normalizeRegistration(value: unknown): string | undefined {
  const text = asString(value);
  return text ? text.toUpperCase().replace(/[^A-Z0-9]/g, '') : undefined;
}

export class GenericAuthorityAdapter implements AuthorityAdapter {
  readonly authoritative = true as const;
  readonly id: string;

  constructor(private readonly config: GenericAuthorityAdapterConfig) {
    this.id = config.id.trim();
    if (!this.id || !config.providerId.trim()) throw new Error('authority adapter id and providerId are required');
    if (!config.map.verifiedAt?.trim()) throw new Error('authority adapter verifiedAt mapping is required');
  }

  canHandle(providerId: string): boolean {
    return providerId === this.config.providerId;
  }

  toAuthorityRecords(payload: unknown, context: ProviderContext): AuthorityRecord[] {
    const candidate = this.config.arrayPath ? getPath(payload, this.config.arrayPath) : payload;
    const rows = Array.isArray(candidate) ? candidate : [candidate];

    return rows.flatMap((row) => {
      if (!row || typeof row !== 'object') return [];
      const verifiedAt = asString(getPath(row, this.config.map.verifiedAt));
      if (!verifiedAt || !Number.isFinite(Date.parse(verifiedAt))) return [];

      const registrationNumber = normalizeRegistration(getPath(row, this.config.map.registrationNumber));
      const vehicleId = asString(getPath(row, this.config.map.vehicleId));
      if (!registrationNumber && !vehicleId) return [];

      const record: AuthorityRecord = {
        providerId: context.providerId,
        source: this.config.source,
        vehicleId,
        registrationNumber,
        documentType: asString(getPath(row, this.config.map.documentType)),
        status: asString(getPath(row, this.config.map.status)),
        validUntil: asString(getPath(row, this.config.map.validUntil)),
        referenceId: asString(getPath(row, this.config.map.referenceId)),
        verifiedAt,
      };
      return [record];
    });
  }
}
