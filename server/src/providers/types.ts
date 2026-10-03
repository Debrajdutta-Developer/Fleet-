import type { ProviderTelemetryPayload } from '../telemetry.js';

export type IntegrationKind =
  | 'gps'
  | 'ais140'
  | 'can_obd'
  | 'fuel_sensor'
  | 'load_sensor'
  | 'weighbridge'
  | 'fastag'
  | 'government_authority';

export type IntegrationTransport = 'webhook' | 'polling' | 'tcp' | 'file_import' | 'manual_verified';

export interface ProviderContext {
  providerId: string;
  kind: IntegrationKind;
  receivedAt: string;
  headers: Record<string, string | string[] | undefined>;
}

export interface ProviderAdapter {
  readonly id: string;
  readonly kind: IntegrationKind;
  readonly transports: readonly IntegrationTransport[];
  readonly authoritative: boolean;
  canHandle(providerId: string): boolean;
  toTelemetry(payload: unknown, context: ProviderContext): ProviderTelemetryPayload[];
}

export interface AuthorityRecord {
  providerId: string;
  source: 'vahan' | 'apisetu' | 'fastag_issuer' | 'other_authorized';
  vehicleId?: string;
  registrationNumber?: string;
  documentType?: string;
  status?: string;
  validUntil?: string;
  referenceId?: string;
  verifiedAt: string;
  raw?: unknown;
}

export interface AuthorityAdapter {
  readonly id: string;
  readonly authoritative: true;
  canHandle(providerId: string): boolean;
  toAuthorityRecords(payload: unknown, context: ProviderContext): AuthorityRecord[];
}
