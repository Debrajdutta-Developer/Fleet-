export type CommercialVehicleRelation = 'owned' | 'hired' | 'attached' | 'third_party';

export type SettlementBasis =
  | 'per_trip'
  | 'per_tonne'
  | 'per_km'
  | 'fixed_daily'
  | 'revenue_share';

export interface VehicleSettlementTerms {
  vehicleId: string;
  relation: CommercialVehicleRelation;
  ownerName?: string;
  basis: SettlementBasis;
  rate: number;
  revenueSharePercent?: number;
  driverAdvance?: number;
  ownerAdvance?: number;
  retentionAmount?: number;
}

export interface TripSettlementInput {
  tripId: string;
  vehicleId: string;
  freightRevenue: number;
  distanceKm: number;
  netLoadKg: number;
  fuelCost: number;
  tollCost: number;
  maintenanceAllocated: number;
  loadingCost: number;
  unloadingCost: number;
  detentionCost: number;
  otherTripCost: number;
}

export interface TripSettlementResult {
  tripId: string;
  vehicleId: string;
  relation: CommercialVehicleRelation;
  grossRevenue: number;
  operatingCostsBeforeOwnerSettlement: number;
  ownerGrossSettlement: number;
  ownerNetPayable: number;
  companyOperatingContribution: number;
  settlementBasis: SettlementBasis;
  warnings: string[];
}

function money(value: number): number {
  return Number(Math.max(0, value).toFixed(2));
}

export function calculateOwnerGrossSettlement(
  terms: VehicleSettlementTerms,
  trip: TripSettlementInput,
): number {
  if (terms.relation === 'owned') return 0;

  switch (terms.basis) {
    case 'per_trip':
      return money(terms.rate);
    case 'per_tonne':
      return money((trip.netLoadKg / 1000) * terms.rate);
    case 'per_km':
      return money(trip.distanceKm * terms.rate);
    case 'fixed_daily':
      return money(terms.rate);
    case 'revenue_share': {
      const percent = terms.revenueSharePercent ?? terms.rate;
      return money(trip.freightRevenue * (percent / 100));
    }
  }
}

export function calculateTripSettlement(
  terms: VehicleSettlementTerms,
  trip: TripSettlementInput,
): TripSettlementResult {
  if (terms.vehicleId !== trip.vehicleId) {
    throw new Error('Settlement terms do not belong to this vehicle');
  }

  const warnings: string[] = [];
  const operatingCostsBeforeOwnerSettlement = money(
    trip.fuelCost +
      trip.tollCost +
      trip.maintenanceAllocated +
      trip.loadingCost +
      trip.unloadingCost +
      trip.detentionCost +
      trip.otherTripCost,
  );

  const ownerGrossSettlement = calculateOwnerGrossSettlement(terms, trip);
  const deductions = money((terms.ownerAdvance ?? 0) + (terms.retentionAmount ?? 0));
  const ownerNetPayable = money(Math.max(0, ownerGrossSettlement - deductions));

  if (terms.relation !== 'owned' && !terms.ownerName) {
    warnings.push('External vehicle owner name is missing.');
  }
  if (terms.basis === 'per_tonne' && trip.netLoadKg <= 0) {
    warnings.push('Per-tonne settlement requires a verified positive net load.');
  }
  if (terms.basis === 'per_km' && trip.distanceKm <= 0) {
    warnings.push('Per-km settlement requires a positive trip distance.');
  }
  if (ownerGrossSettlement > trip.freightRevenue && terms.relation !== 'owned') {
    warnings.push('Owner settlement exceeds recorded freight revenue.');
  }

  const companyOperatingContribution = money(
    trip.freightRevenue - operatingCostsBeforeOwnerSettlement - ownerNetPayable,
  );

  return {
    tripId: trip.tripId,
    vehicleId: trip.vehicleId,
    relation: terms.relation,
    grossRevenue: money(trip.freightRevenue),
    operatingCostsBeforeOwnerSettlement,
    ownerGrossSettlement,
    ownerNetPayable,
    companyOperatingContribution,
    settlementBasis: terms.basis,
    warnings,
  };
}

export function canFinalizeSettlement(result: TripSettlementResult): boolean {
  return !result.warnings.some((warning) =>
    warning.includes('verified positive net load') || warning.includes('positive trip distance'),
  );
}
