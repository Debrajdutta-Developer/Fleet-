export type VehicleMotionState = 'moving' | 'idling' | 'stopped' | 'offline';
export type TelemetryFreshness = 'live' | 'recent' | 'stale' | 'offline';

export interface ProviderTelemetryPayload {
  provider: string;
  deviceId: string;
  vehicleId: string;
  recordedAt: string;
  latitude?: number;
  longitude?: number;
  speedKph?: number;
  ignitionOn?: boolean;
  engineRpm?: number;
  odometerKm?: number;
  fuelLevelPercent?: number;
  fuelUsedLitresTrip?: number;
  grossWeightKg?: number;
  tareWeightKg?: number;
  netLoadKg?: number;
  sourceEvidenceId?: string;
}

export interface NormalizedTelemetry {
  provider: string;
  deviceId: string;
  vehicleId: string;
  recordedAt: string;
  receivedAt: string;
  latitude?: number;
  longitude?: number;
  speedKph?: number;
  ignitionOn?: boolean;
  engineRpm?: number;
  odometerKm?: number;
  fuelLevelPercent?: number;
  fuelUsedLitresTrip?: number;
  grossWeightKg?: number;
  tareWeightKg?: number;
  netLoadKg?: number;
  motionState: VehicleMotionState;
  freshness: TelemetryFreshness;
  sourceEvidenceId?: string;
}

const asFinite = (value: unknown): number | undefined =>
  typeof value === 'number' && Number.isFinite(value) ? value : undefined;

const clamp = (value: number | undefined, min: number, max: number): number | undefined =>
  value === undefined ? undefined : Math.min(max, Math.max(min, value));

export function freshnessFrom(recordedAt: string, now = new Date()): TelemetryFreshness {
  const timestamp = Date.parse(recordedAt);
  if (!Number.isFinite(timestamp)) return 'offline';
  const ageSec = Math.max(0, (now.getTime() - timestamp) / 1000);
  if (ageSec <= 30) return 'live';
  if (ageSec <= 120) return 'recent';
  if (ageSec <= 600) return 'stale';
  return 'offline';
}

export function motionFrom(input: Pick<ProviderTelemetryPayload, 'speedKph' | 'ignitionOn'>, freshness: TelemetryFreshness): VehicleMotionState {
  if (freshness === 'offline') return 'offline';
  const speed = asFinite(input.speedKph) ?? 0;
  if (speed >= 3) return 'moving';
  if (input.ignitionOn) return 'idling';
  return 'stopped';
}

export function normalizeTelemetry(payload: ProviderTelemetryPayload, receivedAt = new Date()): NormalizedTelemetry {
  if (!payload.provider.trim()) throw new Error('provider is required');
  if (!payload.deviceId.trim()) throw new Error('deviceId is required');
  if (!payload.vehicleId.trim()) throw new Error('vehicleId is required');
  if (!Number.isFinite(Date.parse(payload.recordedAt))) throw new Error('recordedAt must be a valid ISO timestamp');

  const freshness = freshnessFrom(payload.recordedAt, receivedAt);
  const grossWeightKg = asFinite(payload.grossWeightKg);
  const tareWeightKg = asFinite(payload.tareWeightKg);
  const explicitNetLoadKg = asFinite(payload.netLoadKg);
  const derivedNet = grossWeightKg !== undefined && tareWeightKg !== undefined
    ? Math.max(0, grossWeightKg - tareWeightKg)
    : undefined;

  return {
    provider: payload.provider.trim(),
    deviceId: payload.deviceId.trim(),
    vehicleId: payload.vehicleId.trim(),
    recordedAt: new Date(payload.recordedAt).toISOString(),
    receivedAt: receivedAt.toISOString(),
    latitude: clamp(asFinite(payload.latitude), -90, 90),
    longitude: clamp(asFinite(payload.longitude), -180, 180),
    speedKph: Math.max(0, asFinite(payload.speedKph) ?? 0),
    ignitionOn: payload.ignitionOn,
    engineRpm: Math.max(0, asFinite(payload.engineRpm) ?? 0),
    odometerKm: Math.max(0, asFinite(payload.odometerKm) ?? 0),
    fuelLevelPercent: clamp(asFinite(payload.fuelLevelPercent), 0, 100),
    fuelUsedLitresTrip: Math.max(0, asFinite(payload.fuelUsedLitresTrip) ?? 0),
    grossWeightKg,
    tareWeightKg,
    netLoadKg: explicitNetLoadKg ?? derivedNet,
    motionState: motionFrom(payload, freshness),
    freshness,
    sourceEvidenceId: payload.sourceEvidenceId,
  };
}

export class TelemetryStore {
  private readonly latestByVehicle = new Map<string, NormalizedTelemetry>();

  upsert(reading: NormalizedTelemetry): void {
    const current = this.latestByVehicle.get(reading.vehicleId);
    if (!current || Date.parse(reading.recordedAt) >= Date.parse(current.recordedAt)) {
      this.latestByVehicle.set(reading.vehicleId, reading);
    }
  }

  get(vehicleId: string): NormalizedTelemetry | undefined {
    return this.latestByVehicle.get(vehicleId);
  }

  list(): NormalizedTelemetry[] {
    return [...this.latestByVehicle.values()].sort((a, b) => a.vehicleId.localeCompare(b.vehicleId));
  }
}
