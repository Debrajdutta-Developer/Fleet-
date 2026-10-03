import type { IntegrationKind, IntegrationTransport } from './types.js';

export type ProviderIntegrationStatus =
  | 'public_docs'
  | 'partner_onboarding'
  | 'customer_credentials'
  | 'generic_adapter'
  | 'manual_verified';

export interface ProviderCapabilityProfile {
  id: string;
  displayName: string;
  kinds: IntegrationKind[];
  transports: IntegrationTransport[];
  status: ProviderIntegrationStatus;
  supportsLiveLocation: boolean;
  supportsFuel?: boolean;
  supportsLoad?: boolean;
  supportsEvents?: boolean;
  supportsGeofences?: boolean;
  requiresProviderAgreement: boolean;
  notes: string;
}

/**
 * This catalog describes integration paths, not credentials.
 * A provider is only enabled for a tenant after authorized credentials/config are supplied.
 */
export const PROVIDER_CAPABILITY_CATALOG: ProviderCapabilityProfile[] = [
  {
    id: 'mappls-intouch',
    displayName: 'Mappls / MapmyIndia InTouch',
    kinds: ['gps', 'ais140', 'can_obd'],
    transports: ['polling', 'webhook'],
    status: 'partner_onboarding',
    supportsLiveLocation: true,
    supportsFuel: true,
    supportsEvents: true,
    supportsGeofences: true,
    requiresProviderAgreement: true,
    notes: 'Enterprise telematics integration path; enable only after authorized API credentials are issued.',
  },
  {
    id: 'letstrack',
    displayName: 'Letstrack',
    kinds: ['gps', 'ais140'],
    transports: ['polling'],
    status: 'customer_credentials',
    supportsLiveLocation: true,
    supportsEvents: true,
    requiresProviderAgreement: true,
    notes: 'REST/API integration is available for customer systems; credentials are tenant/provider specific.',
  },
  {
    id: 'wheelseye',
    displayName: 'WheelsEye',
    kinds: ['gps', 'ais140'],
    transports: ['polling', 'webhook'],
    status: 'partner_onboarding',
    supportsLiveLocation: true,
    requiresProviderAgreement: true,
    notes: 'Treat as partner integration until an authorized API contract/schema is available. Do not reverse engineer the consumer app.',
  },
  {
    id: 'ais140-generic',
    displayName: 'Generic AIS-140 VLT',
    kinds: ['ais140'],
    transports: ['tcp', 'webhook', 'polling'],
    status: 'generic_adapter',
    supportsLiveLocation: true,
    supportsEvents: true,
    requiresProviderAgreement: false,
    notes: 'Use an approved device/vendor protocol or authorized backend feed. Device/vendor-specific packet parsing may still be required.',
  },
  {
    id: 'generic-json-gps',
    displayName: 'Generic JSON GPS Provider',
    kinds: ['gps'],
    transports: ['webhook', 'polling'],
    status: 'generic_adapter',
    supportsLiveLocation: true,
    requiresProviderAgreement: false,
    notes: 'Maps arbitrary provider JSON fields and units into the FleetOS normalized telemetry schema.',
  },
  {
    id: 'generic-fuel-sensor',
    displayName: 'Generic Fuel Sensor / CAN Feed',
    kinds: ['fuel_sensor', 'can_obd'],
    transports: ['webhook', 'polling', 'tcp'],
    status: 'generic_adapter',
    supportsLiveLocation: false,
    supportsFuel: true,
    requiresProviderAgreement: false,
    notes: 'Accept calibrated sensor/CAN readings only; never infer exact fuel from GPS alone.',
  },
  {
    id: 'generic-load-weighbridge',
    displayName: 'Generic Load Sensor / Weighbridge',
    kinds: ['load_sensor', 'weighbridge'],
    transports: ['webhook', 'polling', 'file_import'],
    status: 'generic_adapter',
    supportsLiveLocation: false,
    supportsLoad: true,
    requiresProviderAgreement: false,
    notes: 'Supports gross/tare/net/axle feeds with source evidence and unit normalization.',
  },
];

export function getProviderProfile(providerId: string): ProviderCapabilityProfile | undefined {
  return PROVIDER_CAPABILITY_CATALOG.find((provider) => provider.id === providerId);
}
