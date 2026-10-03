import test from 'node:test';
import assert from 'node:assert/strict';
import { RegistryMirror } from './registryMirror.js';
import type { CompanyAccount, RegistryVehicleRecord } from './companyOnboarding.js';

const company = (id: string, gstin?: string): CompanyAccount => ({
  id, legalName: id, ownerName: 'Owner', ownerPhone: '9999999999', ownerEmail: 'owner@example.com',
  gstin, registeredAddress: 'Kolkata', stateCode: 'WB', verificationStatus: 'verified',
  consentToRegistryLookup: true, consentToFleetSync: true,
  createdAt: '2026-09-12T00:00:00.000Z', updatedAt: '2026-09-12T00:00:00.000Z',
});

const vehicle = (registrationNumber: string): RegistryVehicleRecord => ({
  registrationNumber, source: 'authorized-test-registry', verifiedAt: '2026-09-12T00:00:00.000Z',
});

test('does not leak a vehicle snapshot to another company', async () => {
  const mirror = new RegistryMirror();
  mirror.ingestCompanySnapshot({
    companyExternalRef: 'GST-A', source: 'authorized-test-registry', sourceReferenceId: 'snap-a',
    verifiedAt: '2026-09-12T00:00:00.000Z', vehicles: [vehicle('WB12AB1234')],
  });

  assert.ok(await mirror.lookupByRegistration('WB12AB1234', company('company-a', 'GST-A')));
  assert.equal(await mirror.lookupByRegistration('WB12AB1234', company('company-b', 'GST-B')), null);
});

test('allows an explicitly permitted hired-vehicle lookup only for that company', async () => {
  const mirror = new RegistryMirror();
  mirror.ingestPermittedLookupRecord('GST-B', vehicle('JH10XY9999'));

  assert.ok(await mirror.lookupByRegistration('JH10XY9999', company('company-b', 'GST-B')));
  assert.equal(await mirror.lookupByRegistration('JH10XY9999', company('company-a', 'GST-A')), null);
});
