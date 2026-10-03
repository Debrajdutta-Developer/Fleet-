export type VehicleOwnershipType = 'owned' | 'hired' | 'attached' | 'third_party';

export type TransportVertical = 'coal' | 'bulk_goods' | 'general_logistics' | 'contract_logistics';

export type IntegrationMode = 'official_api' | 'authorized_partner' | 'official_portal_deeplink' | 'manual_verification';

export type ComplianceDocumentType =
  | 'RC'
  | 'Insurance'
  | 'PUC'
  | 'Fitness'
  | 'National Permit'
  | 'State Permit'
  | 'Road Tax'
  | 'Driving Licence'
  | 'FASTag'
  | 'Challan';

export interface VehicleCommercialProfile {
  vehicleId: string;
  ownershipType: VehicleOwnershipType;
  ownerPartyId?: string;
  registrationState: string;
  vehicleClass: 'HGV' | 'MGV' | 'LMV' | 'TRAILER' | 'OTHER';
  grossVehicleWeightKg?: number;
  permittedPayloadKg?: number;
  hiredRateModel?: 'per_trip' | 'per_tonne' | 'per_km' | 'daily' | 'monthly';
  hiredRate?: number;
}

export interface CoalLoadRecord {
  tripId: string;
  sourceMineOrLoadingPoint: string;
  destination: string;
  material: string;
  grossWeightKg: number;
  tareWeightKg: number;
  netWeightKg: number;
  ratePerTonne: number;
  loadingSlipNumber?: string;
  challanReference?: string;
  royaltyReference?: string;
  shortageKg?: number;
  detentionAmount?: number;
  loadingAmount?: number;
  unloadingAmount?: number;
}

export interface TripExpenseBreakdown {
  diesel: number;
  toll: number;
  driverAdvance: number;
  maintenance: number;
  loading: number;
  unloading: number;
  detention: number;
  hiredVehicleCost: number;
  challan: number;
  other: number;
}

export interface CoalTripFinancials {
  freightRevenue: number;
  totalExpenses: number;
  netProfit: number;
  marginPercent: number;
  billableTonnes: number;
}

export interface ComplianceRecord {
  id: string;
  vehicleId?: string;
  driverId?: string;
  documentType: ComplianceDocumentType;
  documentNumber?: string;
  issueDate?: string;
  expiryDate?: string;
  status: 'valid' | 'expiring' | 'expired' | 'pending_verification';
  integrationMode: IntegrationMode;
  providerName?: string;
  officialPortalUrl?: string;
  lastVerifiedAt?: string;
  receiptUrl?: string;
}

export type ComplianceAlertLevel = 'none' | '30_day' | '15_day' | '7_day' | '1_day' | 'expired';

export interface ComplianceAlert {
  level: ComplianceAlertLevel;
  daysRemaining: number | null;
  requiresAttention: boolean;
}

export interface GovernmentIntegrationCapability {
  key: 'vehicle_records' | 'challan' | 'fastag' | 'road_tax' | 'permit' | 'insurance' | 'puc';
  mode: IntegrationMode;
  canRead: boolean;
  canPayOrRenew: boolean;
  canVerify: boolean;
  notes: string;
}

export const DEFAULT_INDIA_INTEGRATION_CAPABILITIES: GovernmentIntegrationCapability[] = [
  {
    key: 'vehicle_records',
    mode: 'manual_verification',
    canRead: false,
    canPayOrRenew: false,
    canVerify: false,
    notes: 'Use only an official or contractually authorized data source before enabling vehicle-record lookup.',
  },
  {
    key: 'challan',
    mode: 'official_portal_deeplink',
    canRead: false,
    canPayOrRenew: false,
    canVerify: false,
    notes: 'Do not hard-code discounts or settlement rules. Show live terms only when returned by an authorized integration.',
  },
  {
    key: 'fastag',
    mode: 'authorized_partner',
    canRead: false,
    canPayOrRenew: false,
    canVerify: false,
    notes: 'Balance, transaction and recharge support depends on the FASTag issuer or authorized partner API contract.',
  },
  {
    key: 'road_tax',
    mode: 'official_portal_deeplink',
    canRead: false,
    canPayOrRenew: false,
    canVerify: false,
    notes: 'Until an authorized API is configured, route the user to the relevant official portal and store proof after confirmation.',
  },
  {
    key: 'permit',
    mode: 'official_portal_deeplink',
    canRead: false,
    canPayOrRenew: false,
    canVerify: false,
    notes: 'Permit renewal must remain provider/state aware and must not be marked successful until confirmed by the source system.',
  },
  {
    key: 'insurance',
    mode: 'authorized_partner',
    canRead: false,
    canPayOrRenew: false,
    canVerify: false,
    notes: 'Enable quote/renewal only through an authorized insurer or intermediary integration.',
  },
  {
    key: 'puc',
    mode: 'official_portal_deeplink',
    canRead: false,
    canPayOrRenew: false,
    canVerify: false,
    notes: 'Expiry tracking can run from stored records; external verification requires an approved source.',
  },
];

const finiteNonNegative = (value: number) => Number.isFinite(value) && value >= 0;

export function calculateCoalTripFinancials(
  load: CoalLoadRecord,
  expenses: TripExpenseBreakdown,
): CoalTripFinancials {
  const billableTonnes = load.netWeightKg / 1000;
  const freightRevenue = billableTonnes * load.ratePerTonne + (load.detentionAmount ?? 0);

  const values = Object.values(expenses);
  if (!finiteNonNegative(load.netWeightKg) || !finiteNonNegative(load.ratePerTonne) || values.some((value) => !finiteNonNegative(value))) {
    throw new Error('Coal trip financial inputs must be finite, non-negative numbers.');
  }

  const totalExpenses = values.reduce((sum, value) => sum + value, 0);
  const netProfit = freightRevenue - totalExpenses;
  const marginPercent = freightRevenue === 0 ? 0 : (netProfit / freightRevenue) * 100;

  return {
    freightRevenue,
    totalExpenses,
    netProfit,
    marginPercent,
    billableTonnes,
  };
}

export function validateCoalWeights(load: Pick<CoalLoadRecord, 'grossWeightKg' | 'tareWeightKg' | 'netWeightKg'>): {
  valid: boolean;
  calculatedNetWeightKg: number;
  differenceKg: number;
} {
  const calculatedNetWeightKg = load.grossWeightKg - load.tareWeightKg;
  const differenceKg = Math.abs(calculatedNetWeightKg - load.netWeightKg);

  return {
    valid: calculatedNetWeightKg >= 0 && differenceKg <= 1,
    calculatedNetWeightKg,
    differenceKg,
  };
}

export function getComplianceAlert(expiryDate?: string, now = new Date()): ComplianceAlert {
  if (!expiryDate) {
    return { level: 'none', daysRemaining: null, requiresAttention: false };
  }

  const expiry = new Date(`${expiryDate}T23:59:59`);
  if (Number.isNaN(expiry.getTime())) {
    return { level: 'none', daysRemaining: null, requiresAttention: false };
  }

  const millisecondsPerDay = 86_400_000;
  const daysRemaining = Math.ceil((expiry.getTime() - now.getTime()) / millisecondsPerDay);

  if (daysRemaining < 0) return { level: 'expired', daysRemaining, requiresAttention: true };
  if (daysRemaining <= 1) return { level: '1_day', daysRemaining, requiresAttention: true };
  if (daysRemaining <= 7) return { level: '7_day', daysRemaining, requiresAttention: true };
  if (daysRemaining <= 15) return { level: '15_day', daysRemaining, requiresAttention: true };
  if (daysRemaining <= 30) return { level: '30_day', daysRemaining, requiresAttention: true };

  return { level: 'none', daysRemaining, requiresAttention: false };
}

export function canMarkExternalActionSuccessful(
  mode: IntegrationMode,
  providerConfirmed: boolean,
): boolean {
  if (mode === 'manual_verification' || mode === 'official_portal_deeplink') {
    return providerConfirmed;
  }

  return providerConfirmed;
}
