import type { ProviderTelemetryPayload } from '../telemetry.js';
import type { ProviderAdapter, ProviderContext } from './types.js';

export interface FieldMap {
  deviceId: string;
  vehicleId: string;
  recordedAt: string;
  latitude?: string;
  longitude?: string;
  speedKph?: string;
  ignitionOn?: string;
  engineRpm?: string;
  odometerKm?: string;
  fuelLevelPercent?: string;
  fuelUsedLitresTrip?: string;
  grossWeightKg?: string;
  tareWeightKg?: string;
  netLoadKg?: string;
  sourceEvidenceId?: string;
}

export interface GenericJsonProviderConfig {
  providerId: string;
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
  readonly kind = 'gps' as const;
  readonly transports = ['webhook', 'polling'] as const;
  readonly authoritative = false;

  constructor(private readonly config: GenericJsonProviderConfig) {
    this.id = `generic:${config.providerId}`;
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
        latitude: asNumber(getPath(row, this.config.map.latitude)),
        longitude: asNumber(getPath(row, this.config.map.longitude)),
        speedKph: asNumber(getPath(row, this.config.map.speedKph)),
        ignitionOn: asBoolean(getPath(row, this.config.map.ignitionOn)),
        engineRpm: asNumber(getPath(row, this.config.map.engineRpm)),
        odometerKm: asNumber(getPath(row, this.config.map.odometerKm)),
        fuelLevelPercent: asNumber(getPath(row, this.config.map.fuelLevelPercent)),
        fuelUsedLitresTrip: asNumber(getPath(row, this.config.map.fuelUsedLitresTrip)),
        grossWeightKg: asNumber(getPath(row, this.config.map.grossWeightKg)),
        tareWeightKg: asNumber(getPath(row, this.config.map.tareWeightKg)),
        netLoadKg: asNumber(getPath(row, this.config.map.netLoadKg)),
        sourceEvidenceId: asString(getPath(row, this.config.map.sourceEvidenceId)),
      };
    });
  }
}
