import type { CompanyAccount, RegistryVehicleRecord, VehicleRegistryGateway } from './companyOnboarding.js';
import { normalizeRegistrationNumber } from './companyOnboarding.js';

export interface VerifiedCompanyFleetSnapshot {
  companyExternalRef: string;
  source: string;
  sourceReferenceId: string;
  verifiedAt: string;
  vehicles: RegistryVehicleRecord[];
}

export class RegistryMirror implements VehicleRegistryGateway {
  readonly id = 'fleetos-registry-mirror';
  private readonly byCompany = new Map<string, VerifiedCompanyFleetSnapshot>();
  private readonly permittedLookupByCompany = new Map<string, Map<string, RegistryVehicleRecord>>();

  ingestCompanySnapshot(snapshot: VerifiedCompanyFleetSnapshot): void {
    if (!snapshot.companyExternalRef.trim()) throw new Error('companyExternalRef is required');
    if (!snapshot.source.trim()) throw new Error('source is required');
    if (!snapshot.sourceReferenceId.trim()) throw new Error('sourceReferenceId is required');
    if (!Number.isFinite(Date.parse(snapshot.verifiedAt))) throw new Error('verifiedAt must be a valid timestamp');

    const normalizedVehicles = snapshot.vehicles.map((vehicle) => ({
      ...vehicle,
      registrationNumber: normalizeRegistrationNumber(vehicle.registrationNumber),
      source: snapshot.source,
      verifiedAt: snapshot.verifiedAt,
      sourceReferenceId: vehicle.sourceReferenceId ?? snapshot.sourceReferenceId,
    }));

    this.byCompany.set(snapshot.companyExternalRef, { ...snapshot, vehicles: normalizedVehicles });
  }

  ingestPermittedLookupRecord(companyExternalRef: string, record: RegistryVehicleRecord): void {
    const ref = companyExternalRef.trim();
    if (!ref) throw new Error('companyExternalRef is required');
    const registrationNumber = normalizeRegistrationNumber(record.registrationNumber);
    if (!registrationNumber) throw new Error('registrationNumber is required');
    let bucket = this.permittedLookupByCompany.get(ref);
    if (!bucket) {
      bucket = new Map();
      this.permittedLookupByCompany.set(ref, bucket);
    }
    bucket.set(registrationNumber, { ...record, registrationNumber });
  }

  async lookupByRegistration(registrationNumber: string, company: CompanyAccount): Promise<RegistryVehicleRecord | null> {
    const registration = normalizeRegistrationNumber(registrationNumber);
    for (const ref of this.companyRefs(company)) {
      const snapshot = this.byCompany.get(ref);
      const owned = snapshot?.vehicles.find((vehicle) => vehicle.registrationNumber === registration);
      if (owned) return owned;

      const permitted = this.permittedLookupByCompany.get(ref)?.get(registration);
      if (permitted) return permitted;
    }
    return null;
  }

  async listVehiclesForVerifiedCompany(company: CompanyAccount): Promise<RegistryVehicleRecord[]> {
    for (const ref of this.companyRefs(company)) {
      const snapshot = this.byCompany.get(ref);
      if (snapshot) return snapshot.vehicles;
    }
    return [];
  }

  private companyRefs(company: CompanyAccount): string[] {
    return [company.gstin, company.pan, company.id].filter((value): value is string => Boolean(value));
  }
}
