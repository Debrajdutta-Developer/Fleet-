import { getFleetAccessToken } from '../auth/runtimeSession';

export type LiveMotionState = 'moving' | 'idling' | 'stopped' | 'offline';
export type LiveFreshness = 'live' | 'recent' | 'stale' | 'offline';

export interface LiveTelemetryReading {
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
  motionState: LiveMotionState;
  freshness: LiveFreshness;
  sourceEvidenceId?: string;
}

interface LiveTelemetryResponse {
  companyId: string;
  vehicles: LiveTelemetryReading[];
  generatedAt: string;
}

export interface TelemetryHistoryResponse {
  companyId: string;
  readings: LiveTelemetryReading[];
  count: number;
}

const configuredBase = (import.meta.env.VITE_TELEMETRY_API_URL as string | undefined)?.trim() ?? '';
const API_BASE = configuredBase.replace(/\/$/, '');

function authorizedHeaders(companyId: string): HeadersInit {
  const token = getFleetAccessToken();
  if (!token) throw new Error('FleetOS sign-in session required for live telemetry');
  return {
    accept: 'application/json',
    authorization: `Bearer ${token}`,
    'x-fleetos-company-id': companyId,
  };
}

export async function fetchLiveTelemetry(companyId: string, signal?: AbortSignal): Promise<LiveTelemetryResponse> {
  const response = await fetch(`${API_BASE}/api/telemetry/live`, {
    method: 'GET',
    headers: authorizedHeaders(companyId),
    signal,
  });

  if (!response.ok) {
    throw new Error(`Telemetry API returned ${response.status}`);
  }

  const payload = (await response.json()) as LiveTelemetryResponse;
  if (!payload || payload.companyId !== companyId || !Array.isArray(payload.vehicles)) {
    throw new Error('Telemetry API returned an invalid or cross-tenant payload');
  }
  return payload;
}

export async function fetchTelemetryHistory(
  companyId: string,
  options: { vehicleId?: string; from?: string; to?: string; limit?: number } = {},
  signal?: AbortSignal,
): Promise<TelemetryHistoryResponse> {
  const params = new URLSearchParams();
  if (options.vehicleId) params.set('vehicleId', options.vehicleId);
  if (options.from) params.set('from', options.from);
  if (options.to) params.set('to', options.to);
  if (options.limit) params.set('limit', String(options.limit));
  const suffix = params.size ? `?${params.toString()}` : '';

  const response = await fetch(`${API_BASE}/api/telemetry/history${suffix}`, {
    method: 'GET',
    headers: authorizedHeaders(companyId),
    signal,
  });

  if (!response.ok) throw new Error(`Telemetry history API returned ${response.status}`);
  const payload = (await response.json()) as TelemetryHistoryResponse;
  if (!payload || payload.companyId !== companyId || !Array.isArray(payload.readings)) {
    throw new Error('Telemetry history API returned an invalid or cross-tenant payload');
  }
  return payload;
}
