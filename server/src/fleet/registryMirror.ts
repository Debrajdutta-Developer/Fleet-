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
  private readonly byRegistration = new Map<string, RegistryVehicleRecord>();

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

    const normalizedSnapshot: VerifiedCompanyFleetSnapshot = {
      ...snapshot,
      vehicles: normalizedVehicles,
    };

    this.byCompany.set(snapshot.companyExternalRef, normalizedSnapshot);
    for (const vehicle of normalizedVehicles) {
      this.byRegistration.set(vehicle.registrationNumber, vehicle);
    }
  }

  async lookupByRegistration(registrationNumber: string, _company: CompanyAccount): Promise<RegistryVehicleRecord | null> {
    return this.byRegistration.get(normalizeRegistrationNumber(registrationNumber)) ?? null;
  }

  async listVehiclesForVerifiedCompany(company: CompanyAccount): Promise<RegistryVehicleRecord[]> {
    const refs = [company.gstin, company.pan, company.id].filter((value): value is string => Boolean(value));
    for (const ref of refs) {
      const snapshot = this.byCompany.get(ref);
      if (snapshot) return snapshot.vehicles;
    }
    return [];
  }
}
