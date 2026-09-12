import assert from 'node:assert/strict';
import test from 'node:test';
import { InMemorySettlementRepository, normalizeSettlementTerms } from './settlementRepository.js';

test('settlement repository isolates tenants sharing the same vehicle id', async () => {
  const repository = new InMemorySettlementRepository();
  const a = normalizeSettlementTerms('company-a', 'truck-1', {
    relation: 'hired', basis: 'per_trip', rate: 12000, ownerName: 'Vendor A',
  }, 'owner-a');
  const b = normalizeSettlementTerms('company-b', 'truck-1', {
    relation: 'hired', basis: 'per_trip', rate: 15000, ownerName: 'Vendor B',
  }, 'owner-b');

  await repository.upsert(a);
  await repository.upsert(b);

  assert.equal((await repository.get('company-a', 'truck-1'))?.ownerName, 'Vendor A');
  assert.equal((await repository.get('company-b', 'truck-1'))?.ownerName, 'Vendor B');
  assert.equal((await repository.list('company-a')).length, 1);
});

test('revenue share validation rejects impossible percentages', () => {
  assert.throws(() => normalizeSettlementTerms('company-a', 'truck-2', {
    relation: 'attached', basis: 'revenue_share', rate: 101, ownerName: 'Vendor',
  }, 'manager-a'), /cannot exceed 100%/);
});

test('owned vehicles never persist an external owner name', () => {
  const terms = normalizeSettlementTerms('company-a', 'truck-3', {
    relation: 'owned', basis: 'per_trip', rate: 0, ownerName: 'Should disappear',
  }, 'owner-a');
  assert.equal(terms.ownerName, undefined);
});
