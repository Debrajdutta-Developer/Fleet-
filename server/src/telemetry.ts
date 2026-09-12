export type VehicleMotionState = 'moving' | 'idling' | 'stopped' | 'offline';
export type TelemetryFreshness = 'live' | 'recent' | 'stale' | 'offline';

export interface ProviderTelemetryPayload {
  companyId: string;
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
  companyId: string;
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

const bounded = (value: number | undefined, min: number, max: number, field: string): number | undefined => {
  if (value === undefined) return undefined;
  if (value < min || value > max) throw new Error(`${field} is outside valid range`);
  return value;
};

const clamp = (value: number | undefined, min: number, max: number): number | undefined =>
  value === undefined ? undefined : Math.min(max, Math.max(min, value));

const nonNegative = (value: number | undefined): number | undefined =>
  value === undefined ? undefined : Math.max(0, value);

export function freshnessFrom(recordedAt: string, now = new Date()): TelemetryFreshness {
  const timestamp = Date.parse(recordedAt);
  if (!Number.isFinite(timestamp)) return 'offline';
  const ageSec = Math.max(0, (now.getTime() - timestamp) / 1000);
  if (ageSec <= 30) return 'live';
  if (ageSec <= 120) return 'recent';
  if (ageSec <= 600) return 'stale';
  return 'offline';
}

export function motionFrom(
  input: Pick<ProviderTelemetryPayload, 'speedKph' | 'ignitionOn'>,
  freshness: TelemetryFreshness,
): VehicleMotionState {
  if (freshness === 'offline') return 'offline';
  const speed = asFinite(input.speedKph);
  if (speed !== undefined && speed >= 3) return 'moving';
  if (input.ignitionOn === true) return 'idling';
  return 'stopped';
}

export function normalizeTelemetry(payload: ProviderTelemetryPayload, receivedAt = new Date()): NormalizedTelemetry {
  if (!payload || typeof payload !== 'object') throw new Error('telemetry payload is required');
  if (typeof payload.companyId !== 'string' || !payload.companyId.trim()) throw new Error('companyId is required');
  if (typeof payload.provider !== 'string' || !payload.provider.trim()) throw new Error('provider is required');
  if (typeof payload.deviceId !== 'string' || !payload.deviceId.trim()) throw new Error('deviceId is required');
  if (typeof payload.vehicleId !== 'string' || !payload.vehicleId.trim()) throw new Error('vehicleId is required');
  if (typeof payload.recordedAt !== 'string' || !Number.isFinite(Date.parse(payload.recordedAt))) {
    throw new Error('recordedAt must be a valid ISO timestamp');
  }

  const freshness = freshnessFrom(payload.recordedAt, receivedAt);
  const grossWeightKg = nonNegative(asFinite(payload.grossWeightKg));
  const tareWeightKg = nonNegative(asFinite(payload.tareWeightKg));
  const explicitNetLoadKg = nonNegative(asFinite(payload.netLoadKg));
  const derivedNet = grossWeightKg !== undefined && tareWeightKg !== undefined
    ? Math.max(0, grossWeightKg - tareWeightKg)
    : undefined;

  return {
    companyId: payload.companyId.trim(),
    provider: payload.provider.trim(),
    deviceId: payload.deviceId.trim(),
    vehicleId: payload.vehicleId.trim(),
    recordedAt: new Date(payload.recordedAt).toISOString(),
    receivedAt: receivedAt.toISOString(),
    latitude: bounded(asFinite(payload.latitude), -90, 90, 'latitude'),
    longitude: bounded(asFinite(payload.longitude), -180, 180, 'longitude'),
    speedKph: nonNegative(asFinite(payload.speedKph)),
    ignitionOn: typeof payload.ignitionOn === 'boolean' ? payload.ignitionOn : undefined,
    engineRpm: nonNegative(asFinite(payload.engineRpm)),
    odometerKm: nonNegative(asFinite(payload.odometerKm)),
    fuelLevelPercent: clamp(asFinite(payload.fuelLevelPercent), 0, 100),
    fuelUsedLitresTrip: nonNegative(asFinite(payload.fuelUsedLitresTrip)),
    grossWeightKg,
    tareWeightKg,
    netLoadKg: explicitNetLoadKg ?? derivedNet,
    motionState: motionFrom(payload, freshness),
    freshness,
    sourceEvidenceId: typeof payload.sourceEvidenceId === 'string' ? payload.sourceEvidenceId : undefined,
  };
}

function refreshState(reading: NormalizedTelemetry, now = new Date()): NormalizedTelemetry {
  const freshness = freshnessFrom(reading.recordedAt, now);
  return {
    ...reading,
    freshness,
    motionState: motionFrom(reading, freshness),
  };
}

const keyFor = (companyId: string, vehicleId: string) => `${companyId}::${vehicleId}`;

export class TelemetryStore {
  private readonly latestByTenantVehicle = new Map<string, NormalizedTelemetry>();

  upsert(reading: NormalizedTelemetry): void {
    const key = keyFor(reading.companyId, reading.vehicleId);
    const current = this.latestByTenantVehicle.get(key);
    if (!current || Date.parse(reading.recordedAt) >= Date.parse(current.recordedAt)) {
      this.latestByTenantVehicle.set(key, reading);
    }
  }

  get(companyId: string, vehicleId: string, now = new Date()): NormalizedTelemetry | undefined {
    const reading = this.latestByTenantVehicle.get(keyFor(companyId, vehicleId));
    return reading ? refreshState(reading, now) : undefined;
  }

  list(companyId: string, now = new Date()): NormalizedTelemetry[] {
    return [...this.latestByTenantVehicle.values()]
      .filter((reading) => reading.companyId === companyId)
      .map((reading) => refreshState(reading, now))
      .sort((a, b) => a.vehicleId.localeCompare(b.vehicleId));
  }
}
