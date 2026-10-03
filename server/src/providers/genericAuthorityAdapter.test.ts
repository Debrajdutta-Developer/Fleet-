import test from 'node:test';
import assert from 'node:assert/strict';
import { GenericAuthorityAdapter } from './genericAuthorityAdapter.js';

const context = {
  providerId: 'apisetu-authorized',
  kind: 'government_authority' as const,
  receivedAt: '2026-09-12T00:00:00.000Z',
  headers: {},
};

test('normalizes an authorized authority record without inventing fields', () => {
  const adapter = new GenericAuthorityAdapter({
    id: 'apisetu-authorized-adapter',
    providerId: 'apisetu-authorized',
    source: 'apisetu',
    map: {
      registrationNumber: 'vehicle.registration',
      documentType: 'document.type',
      status: 'document.status',
      validUntil: 'document.validUntil',
      referenceId: 'reference',
      verifiedAt: 'verifiedAt',
    },
  });

  const [record] = adapter.toAuthorityRecords({
    vehicle: { registration: 'WB 11 AB 1234' },
    document: { type: 'fitness', status: 'valid', validUntil: '2027-01-01' },
    reference: 'ref-1',
    verifiedAt: '2026-09-12T00:00:00Z',
  }, context);

  assert.equal(record?.registrationNumber, 'WB11AB1234');
  assert.equal(record?.source, 'apisetu');
  assert.equal(record?.documentType, 'fitness');
  assert.equal(record?.status, 'valid');
});

test('drops rows without authoritative timestamp or vehicle identity', () => {
  const adapter = new GenericAuthorityAdapter({
    id: 'authority-test',
    providerId: 'apisetu-authorized',
    source: 'apisetu',
    arrayPath: 'items',
    map: { registrationNumber: 'registration', verifiedAt: 'verifiedAt' },
  });

  const records = adapter.toAuthorityRecords({ items: [
    { registration: 'WB11AB1234' },
    { verifiedAt: '2026-09-12T00:00:00Z' },
    { registration: 'WB22CD5678', verifiedAt: 'not-a-date' },
  ] }, context);
  assert.deepEqual(records, []);
});
