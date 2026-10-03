export type TelemetrySource =
  | 'ais140_gps'
  | 'oem_telematics'
  | 'obd_can'
  | 'fuel_sensor'
  | 'weighbridge'
  | 'onboard_load_sensor'
  | 'fastag'
  | 'driver_app'
  | 'manual_verified';

export type DataFreshness = 'live' | 'recent' | 'stale' | 'offline';

export interface SourceEvidence {
  source: TelemetrySource;
  provider?: string;
  deviceId?: string;
  receivedAt: string;
  measuredAt: string;
  authoritative: boolean;
}

export interface LivePosition {
  latitude: number;
  longitude: number;
  speedKph?: number;
  headingDeg?: number;
  accuracyMeters?: number;
  locationLabel?: string;
  ignitionOn?: boolean;
  engineOn?: boolean;
  measuredAt: string;
  evidence: SourceEvidence;
}

export interface FuelTelemetry {
  levelLitres?: number;
  levelPercent?: number;
  consumedLitresTrip?: number;
  instantaneousKmPerLitre?: number;
  averageKmPerLitre?: number;
  refillDetectedLitres?: number;
  drainDetectedLitres?: number;
  measuredAt: string;
  evidence: SourceEvidence;
}

export interface LoadTelemetry {
  grossWeightKg?: number;
  tareWeightKg?: number;
  netLoadKg?: number;
  axleWeightsKg?: number[];
  loadStatus: 'unknown' | 'empty' | 'loading' | 'loaded' | 'unloading';
  measuredAt: string;
  evidence: SourceEvidence;
}

export interface VehicleMotionState {
  state: 'moving' | 'idling' | 'stopped' | 'offline' | 'unknown';
  stoppedSince?: string;
  idleSince?: string;
  durationSeconds?: number;
  lastMovementAt?: string;
}

export interface TripRealtimeState {
  tripId: string;
  vehicleId: string;
  driverId?: string;
  position?: LivePosition;
  fuel?: FuelTelemetry;
  load?: LoadTelemetry;
  motion: VehicleMotionState;
  odometerKm?: number;
  engineHours?: number;
  distanceTravelledKm?: number;
  remainingDistanceKm?: number;
  eta?: string;
  freshness: DataFreshness;
  lastUpdatedAt: string;
}

export interface TelemetryEnvelope<T> {
  companyId: string;
  vehicleId: string;
  tripId?: string;
  payload: T;
  idempotencyKey: string;
  receivedAt: string;
}

export interface TelemetryProviderAdapter {
  readonly providerName: string;
  readonly supportedSources: TelemetrySource[];
  normalize(rawPayload: unknown): TelemetryEnvelope<unknown>[];
  verifyWebhook?(headers: Record<string, string>, rawBody: string): boolean;
}

export interface VehicleLiveSummary {
  vehicleId: string;
  tripId?: string;
  position?: LivePosition;
  fuel?: FuelTelemetry;
  load?: LoadTelemetry;
  motion: VehicleMotionState;
  freshness: DataFreshness;
  lastUpdatedAt: string;
  warnings: string[];
}

const ageSeconds = (iso: string, now: Date): number =>
  Math.max(0, Math.floor((now.getTime() - new Date(iso).getTime()) / 1000));

export const classifyFreshness = (lastUpdatedAt: string, now = new Date()): DataFreshness => {
  const age = ageSeconds(lastUpdatedAt, now);
  if (age <= 30) return 'live';
  if (age <= 120) return 'recent';
  if (age <= 600) return 'stale';
  return 'offline';
};

export const deriveMotionState = (
  position: Pick<LivePosition, 'speedKph' | 'ignitionOn' | 'engineOn' | 'measuredAt'>,
  previous?: VehicleMotionState,
  now = new Date()
): VehicleMotionState => {
  const speed = position.speedKph;
  const running = position.engineOn ?? position.ignitionOn;

  if (speed != null && speed >= 3) {
    return { state: 'moving', lastMovementAt: position.measuredAt };
  }

  if (running === true) {
    const idleSince = previous?.state === 'idling' && previous.idleSince ? previous.idleSince : position.measuredAt;
    return {
      state: 'idling', idleSince, durationSeconds: ageSeconds(idleSince, now), lastMovementAt: previous?.lastMovementAt,
    };
  }

  if (speed == null && running == null) {
    return { state: 'unknown', lastMovementAt: previous?.lastMovementAt };
  }

  const stoppedSince = previous?.state === 'stopped' && previous.stoppedSince ? previous.stoppedSince : position.measuredAt;
  return {
    state: 'stopped', stoppedSince, durationSeconds: ageSeconds(stoppedSince, now), lastMovementAt: previous?.lastMovementAt,
  };
};

export const validateLoadReading = (reading: LoadTelemetry): string[] => {
  const errors: string[] = [];
  if (reading.grossWeightKg != null && reading.grossWeightKg < 0) errors.push('Gross weight cannot be negative');
  if (reading.tareWeightKg != null && reading.tareWeightKg < 0) errors.push('Tare weight cannot be negative');
  if (reading.netLoadKg != null && reading.netLoadKg < 0) errors.push('Net load cannot be negative');
  if (reading.grossWeightKg != null && reading.tareWeightKg != null && reading.netLoadKg != null) {
    const expected = reading.grossWeightKg - reading.tareWeightKg;
    if (Math.abs(expected - reading.netLoadKg) > 50) errors.push('Net load does not match gross minus tare within 50 kg tolerance');
  }
  return errors;
};

export const buildLiveWarnings = (summary: Omit<VehicleLiveSummary, 'warnings'>): string[] => {
  const warnings: string[] = [];
  if (summary.freshness === 'stale') warnings.push('Telemetry is stale');
  if (summary.freshness === 'offline') warnings.push('Vehicle telemetry is offline');
  if (summary.motion.state === 'unknown') warnings.push('Motion state is unknown because speed/ignition evidence is missing');
  if (summary.motion.state === 'idling' && (summary.motion.durationSeconds ?? 0) >= 900) warnings.push('Engine idling for 15+ minutes');
  if (summary.fuel?.levelPercent != null && summary.fuel.levelPercent <= 15) warnings.push('Low fuel');
  if ((summary.fuel?.drainDetectedLitres ?? 0) >= 5) warnings.push('Possible fuel drain detected');
  warnings.push(...validateLoadReading(summary.load ?? {
    loadStatus: 'unknown', measuredAt: summary.lastUpdatedAt,
    evidence: { source: 'manual_verified', receivedAt: summary.lastUpdatedAt, measuredAt: summary.lastUpdatedAt, authoritative: false },
  }));
  return warnings;
};
