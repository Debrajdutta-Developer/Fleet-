export type LiveMotionState = 'moving' | 'idling' | 'stopped' | 'offline';
export type LiveFreshness = 'live' | 'recent' | 'stale' | 'offline';

export interface LiveTelemetryReading {
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
  motionState: LiveMotionState;
  freshness: LiveFreshness;
  sourceEvidenceId?: string;
}

interface LiveTelemetryResponse {
  vehicles: LiveTelemetryReading[];
  generatedAt: string;
}

const configuredBase = (import.meta.env.VITE_TELEMETRY_API_URL as string | undefined)?.trim() ?? '';
const API_BASE = configuredBase.replace(/\/$/, '');

export async function fetchLiveTelemetry(signal?: AbortSignal): Promise<LiveTelemetryResponse> {
  const response = await fetch(`${API_BASE}/api/telemetry/live`, {
    method: 'GET',
    headers: { accept: 'application/json' },
    signal,
  });

  if (!response.ok) {
    throw new Error(`Telemetry API returned ${response.status}`);
  }

  const payload = (await response.json()) as LiveTelemetryResponse;
  if (!payload || !Array.isArray(payload.vehicles)) {
    throw new Error('Telemetry API returned an invalid payload');
  }
  return payload;
}
