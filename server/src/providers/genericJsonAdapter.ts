import type { ProviderTelemetryPayload } from '../telemetry.js';
import type { IntegrationKind, ProviderAdapter, ProviderContext } from './types.js';

export interface NumericFieldMapping {
  path: string;
  multiply?: number;
  add?: number;
}

export type NumericField = string | NumericFieldMapping;

export interface FieldMap {
  deviceId: string;
  vehicleId: string;
  recordedAt: string;
  latitude?: NumericField;
  longitude?: NumericField;
  speedKph?: NumericField;
  ignitionOn?: string;
  engineRpm?: NumericField;
  odometerKm?: NumericField;
  fuelLevelPercent?: NumericField;
  fuelUsedLitresTrip?: NumericField;
  grossWeightKg?: NumericField;
  tareWeightKg?: NumericField;
  netLoadKg?: NumericField;
  sourceEvidenceId?: string;
}

export interface GenericJsonProviderConfig {
  providerId: string;
  kind?: Exclude<IntegrationKind, 'fastag' | 'government_authority'>;
  map: FieldMap;
  arrayPath?: string;
}

function getPath(input: unknown, path?: string): unknown {
  if (!path) return undefined;
  return path.split('.').reduce<unknown>((value, key) => {
    if (value && typeof value === 'object' && key in value) {
      return (value as Record<string, unknown>)[key];
    }
    return undefined;
  }, input);
}

function asString(value: unknown): string | undefined {
  if (typeof value === 'string') return value;
  if (typeof value === 'number' && Number.isFinite(value)) return String(value);
  return undefined;
}

function asNumber(value: unknown): number | undefined {
  if (typeof value === 'number' && Number.isFinite(value)) return value;
  if (typeof value === 'string' && value.trim() !== '') {
    const parsed = Number(value);
    return Number.isFinite(parsed) ? parsed : undefined;
  }
  return undefined;
}

function mappedNumber(row: unknown, mapping?: NumericField): number | undefined {
  if (!mapping) return undefined;
  const descriptor = typeof mapping === 'string' ? { path: mapping } : mapping;
  const value = asNumber(getPath(row, descriptor.path));
  if (value === undefined) return undefined;
  return value * (descriptor.multiply ?? 1) + (descriptor.add ?? 0);
}

function asBoolean(value: unknown): boolean | undefined {
  if (typeof value === 'boolean') return value;
  if (typeof value === 'number') return value !== 0;
  if (typeof value === 'string') {
    const normalized = value.trim().toLowerCase();
    if (['1', 'true', 'on', 'yes', 'ignition_on'].includes(normalized)) return true;
    if (['0', 'false', 'off', 'no', 'ignition_off'].includes(normalized)) return false;
  }
  return undefined;
}

export class GenericJsonTelemetryAdapter implements ProviderAdapter {
  readonly id: string;
  readonly kind: Exclude<IntegrationKind, 'fastag' | 'government_authority'>;
  readonly transports = ['webhook', 'polling'] as const;
  readonly authoritative = false;

  constructor(private readonly config: GenericJsonProviderConfig) {
    this.id = `generic:${config.providerId}`;
    this.kind = config.kind ?? 'gps';
  }

  canHandle(providerId: string): boolean {
    return providerId === this.config.providerId;
  }

  toTelemetry(payload: unknown, context: ProviderContext): ProviderTelemetryPayload[] {
    const candidate = this.config.arrayPath ? getPath(payload, this.config.arrayPath) : payload;
    const rows = Array.isArray(candidate) ? candidate : [candidate];

    return rows.map((row) => {
      const deviceId = asString(getPath(row, this.config.map.deviceId));
      const vehicleId = asString(getPath(row, this.config.map.vehicleId));
      const recordedAt = asString(getPath(row, this.config.map.recordedAt));
      if (!deviceId || !vehicleId || !recordedAt) {
        throw new Error(`provider ${context.providerId} payload is missing deviceId, vehicleId, or recordedAt`);
      }

      return {
        provider: context.providerId,
        deviceId,
        vehicleId,
        recordedAt,
        latitude: mappedNumber(row, this.config.map.latitude),
        longitude: mappedNumber(row, this.config.map.longitude),
        speedKph: mappedNumber(row, this.config.map.speedKph),
        ignitionOn: asBoolean(getPath(row, this.config.map.ignitionOn)),
        engineRpm: mappedNumber(row, this.config.map.engineRpm),
        odometerKm: mappedNumber(row, this.config.map.odometerKm),
        fuelLevelPercent: mappedNumber(row, this.config.map.fuelLevelPercent),
        fuelUsedLitresTrip: mappedNumber(row, this.config.map.fuelUsedLitresTrip),
        grossWeightKg: mappedNumber(row, this.config.map.grossWeightKg),
        tareWeightKg: mappedNumber(row, this.config.map.tareWeightKg),
        netLoadKg: mappedNumber(row, this.config.map.netLoadKg),
        sourceEvidenceId: asString(getPath(row, this.config.map.sourceEvidenceId)),
      };
    });
  }
}
