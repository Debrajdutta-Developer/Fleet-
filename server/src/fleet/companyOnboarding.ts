export type CompanyVerificationStatus = 'draft' | 'pending' | 'verified' | 'rejected';
export type VehicleRelationship = 'owned' | 'hired' | 'attached' | 'third_party';
export type VehicleVerificationStatus = 'unverified' | 'verified' | 'conflict';

export interface CompanyRegistrationInput {
  legalName: string;
  tradeName?: string;
  ownerName: string;
  ownerPhone: string;
  ownerEmail: string;
  pan?: string;
  gstin?: string;
  registeredAddress: string;
  stateCode: string;
  consentToRegistryLookup: boolean;
  consentToFleetSync: boolean;
}

export interface CompanyAccount {
  id: string;
  legalName: string;
  tradeName?: string;
  ownerName: string;
  ownerPhone: string;
  ownerEmail: string;
  pan?: string;
  gstin?: string;
  registeredAddress: string;
  stateCode: string;
  verificationStatus: CompanyVerificationStatus;
  consentToRegistryLookup: boolean;
  consentToFleetSync: boolean;
  createdAt: string;
  updatedAt: string;
}

export interface RegistryVehicleRecord {
  registrationNumber: string;
  make?: string;
  model?: string;
  vehicleClass?: string;
  fuelType?: string;
  grossVehicleWeightKg?: number;
  unladenWeightKg?: number;
  fitnessValidUntil?: string;
  insuranceValidUntil?: string;
  pucValidUntil?: string;
  permitValidUntil?: string;
  taxValidUntil?: string;
  chassisLastDigits?: string;
  ownerMatch?: boolean;
  source: string;
  sourceReferenceId?: string;
  verifiedAt: string;
}

export interface FleetVehicleRecord extends RegistryVehicleRecord {
  companyId: string;
  relationship: VehicleRelationship;
  verificationStatus: VehicleVerificationStatus;
  discoveredAutomatically: boolean;
  firstSeenAt: string;
  lastSeenAt: string;
}

export interface VehicleRegistryGateway {
  readonly id: string;
  lookupByRegistration(registrationNumber: string, company: CompanyAccount): Promise<RegistryVehicleRecord | null>;
  listVehiclesForVerifiedCompany?(company: CompanyAccount): Promise<RegistryVehicleRecord[]>;
}

export interface FleetSyncResult {
  discovered: FleetVehicleRecord[];
  updated: FleetVehicleRecord[];
  unchanged: FleetVehicleRecord[];
  missingFromLatestRegistry: FleetVehicleRecord[];
  source: string;
  syncedAt: string;
}

export function normalizeRegistrationNumber(value: string): string {
  return value.toUpperCase().replace(/[^A-Z0-9]/g, '');
}

export function validateCompanyRegistration(input: CompanyRegistrationInput): string[] {
  const errors: string[] = [];
  if (!input.legalName.trim()) errors.push('legalName is required');
  if (!input.ownerName.trim()) errors.push('ownerName is required');
  if (!input.ownerPhone.trim()) errors.push('ownerPhone is required');
  if (!input.ownerEmail.includes('@')) errors.push('ownerEmail must be valid');
  if (!input.registeredAddress.trim()) errors.push('registeredAddress is required');
  if (!input.stateCode.trim()) errors.push('stateCode is required');
  if (!input.consentToRegistryLookup) errors.push('registry lookup consent is required for automatic vehicle discovery');
  return errors;
}

export class CompanyOnboardingStore {
  private readonly companies = new Map<string, CompanyAccount>();
  private readonly vehiclesByCompany = new Map<string, Map<string, FleetVehicleRecord>>();

  create(input: CompanyRegistrationInput, now = new Date()): CompanyAccount {
    const errors = validateCompanyRegistration(input);
    if (errors.length) throw new Error(errors.join('; '));

    const id = `company-${now.getTime()}-${Math.random().toString(36).slice(2, 8)}`;
    const account: CompanyAccount = {
      id,
      ...input,
      verificationStatus: 'pending',
      createdAt: now.toISOString(),
      updatedAt: now.toISOString(),
    };
    this.companies.set(id, account);
    this.vehiclesByCompany.set(id, new Map());
    return account;
  }

  getCompany(companyId: string): CompanyAccount | undefined {
    return this.companies.get(companyId);
  }

  setVerificationStatus(companyId: string, status: CompanyVerificationStatus): CompanyAccount {
    const company = this.companies.get(companyId);
    if (!company) throw new Error('company not found');
    const next = { ...company, verificationStatus: status, updatedAt: new Date().toISOString() };
    this.companies.set(companyId, next);
    return next;
  }

  listVehicles(companyId: string): FleetVehicleRecord[] {
    return [...(this.vehiclesByCompany.get(companyId)?.values() ?? [])];
  }

  upsertVehicle(companyId: string, record: RegistryVehicleRecord, relationship: VehicleRelationship, discoveredAutomatically: boolean): FleetVehicleRecord {
    const bucket = this.vehiclesByCompany.get(companyId);
    if (!bucket) throw new Error('company not found');

    const key = normalizeRegistrationNumber(record.registrationNumber);
    const current = bucket.get(key);
    const now = new Date().toISOString();
    const next: FleetVehicleRecord = {
      ...current,
      ...record,
      registrationNumber: key,
      companyId,
      relationship,
      verificationStatus: record.ownerMatch === false ? 'conflict' : 'verified',
      discoveredAutomatically,
      firstSeenAt: current?.firstSeenAt ?? now,
      lastSeenAt: now,
    };
    bucket.set(key, next);
    return next;
  }
}

export class FleetDiscoveryService {
  constructor(
    private readonly store: CompanyOnboardingStore,
    private readonly registry: VehicleRegistryGateway,
  ) {}

  async lookupAndAttach(companyId: string, registrationNumber: string, relationship: VehicleRelationship): Promise<FleetVehicleRecord> {
    const company = this.requireVerifiedCompany(companyId);
    const normalized = normalizeRegistrationNumber(registrationNumber);
    if (!normalized) throw new Error('registration number is required');

    const record = await this.registry.lookupByRegistration(normalized, company);
    if (!record) throw new Error('vehicle could not be verified from the configured authoritative source');
    return this.store.upsertVehicle(companyId, record, relationship, false);
  }

  async syncOwnedFleet(companyId: string): Promise<FleetSyncResult> {
    const company = this.requireVerifiedCompany(companyId);
    if (!company.consentToFleetSync) throw new Error('company has not consented to automatic fleet sync');
    if (!this.registry.listVehiclesForVerifiedCompany) {
      throw new Error('configured registry provider does not support automatic company fleet discovery');
    }

    const latest = await this.registry.listVehiclesForVerifiedCompany(company);
    const previous = new Map(this.store.listVehicles(companyId).map((v) => [normalizeRegistrationNumber(v.registrationNumber), v]));
    const discovered: FleetVehicleRecord[] = [];
    const updated: FleetVehicleRecord[] = [];
    const unchanged: FleetVehicleRecord[] = [];

    for (const record of latest) {
      const key = normalizeRegistrationNumber(record.registrationNumber);
      const before = previous.get(key);
      const after = this.store.upsertVehicle(companyId, record, 'owned', true);
      previous.delete(key);
      if (!before) discovered.push(after);
      else if (JSON.stringify({ ...before, lastSeenAt: undefined }) !== JSON.stringify({ ...after, lastSeenAt: undefined })) updated.push(after);
      else unchanged.push(after);
    }

    return {
      discovered,
      updated,
      unchanged,
      missingFromLatestRegistry: [...previous.values()].filter((v) => v.relationship === 'owned'),
      source: this.registry.id,
      syncedAt: new Date().toISOString(),
    };
  }

  private requireVerifiedCompany(companyId: string): CompanyAccount {
    const company = this.store.getCompany(companyId);
    if (!company) throw new Error('company not found');
    if (company.verificationStatus !== 'verified') throw new Error('company verification is required');
    if (!company.consentToRegistryLookup) throw new Error('company has not consented to registry lookup');
    return company;
  }
}
