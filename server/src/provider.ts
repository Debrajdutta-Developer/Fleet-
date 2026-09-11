import type { ProviderTelemetryPayload } from './telemetry.js';

export interface TelemetryProviderAdapter {
  readonly providerName: string;
  fetchVehicle(vehicleId: string): Promise<ProviderTelemetryPayload | null>;
}

export interface HttpProviderConfig {
  providerName: string;
  baseUrl: string;
  apiKey: string;
  vehiclePath: (vehicleId: string) => string;
  mapResponse: (vehicleId: string, raw: unknown) => ProviderTelemetryPayload;
}

/**
 * Generic adapter for an authorized GPS/telematics provider.
 * Credentials stay server-side. The adapter deliberately does not assume a
 * specific vendor response shape; production providers map their payload here.
 */
export class HttpTelemetryProvider implements TelemetryProviderAdapter {
  readonly providerName: string;

  constructor(private readonly config: HttpProviderConfig) {
    this.providerName = config.providerName;
  }

  async fetchVehicle(vehicleId: string): Promise<ProviderTelemetryPayload | null> {
    const path = this.config.vehiclePath(vehicleId);
    const url = new URL(path, this.config.baseUrl);
    const response = await fetch(url, {
      headers: {
        accept: 'application/json',
        authorization: `Bearer ${this.config.apiKey}`,
      },
      signal: AbortSignal.timeout(10_000),
    });

    if (response.status === 404) return null;
    if (!response.ok) {
      throw new Error(`${this.providerName} telemetry request failed: ${response.status}`);
    }

    const raw: unknown = await response.json();
    return this.config.mapResponse(vehicleId, raw);
  }
}
