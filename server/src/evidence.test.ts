import test from 'node:test';
import assert from 'node:assert/strict';
import { mkdtemp, rm } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { Readable } from 'node:stream';
import type { IncomingMessage } from 'node:http';
import { EvidenceStore } from './evidence.js';
import type { TenantPrincipal } from './tenantAuth.js';

function request(body: Buffer, contentType = 'image/jpeg', fileName = 'proof.jpg'): IncomingMessage {
  const stream = Readable.from([body]) as unknown as IncomingMessage;
  Object.assign(stream, {
    headers: {
      'content-type': contentType,
      'x-file-name': fileName,
    },
  });
  return stream;
}

const driver: TenantPrincipal = {
  sub: 'driver-1',
  companyId: 'company-a',
  role: 'driver',
};

test('stores evidence inside the authenticated tenant and trip scope', async () => {
  const root = await mkdtemp(join(tmpdir(), 'fleetos-evidence-'));
  try {
    const store = new EvidenceStore(root);
    const record = await store.upload(request(Buffer.from('proof')), driver, 'trip-1', 'pod');

    assert.equal(record.companyId, 'company-a');
    assert.equal(record.tripId, 'trip-1');
    assert.equal(record.uploadedBy, 'driver-1');
    assert.equal(record.evidenceType, 'pod');

    const own = await store.list('company-a', 'trip-1');
    const otherTenant = await store.list('company-b', 'trip-1');
    const otherTrip = await store.list('company-a', 'trip-2');

    assert.equal(own.length, 1);
    assert.equal(otherTenant.length, 0);
    assert.equal(otherTrip.length, 0);
  } finally {
    await rm(root, { recursive: true, force: true });
  }
});

test('rejects unsupported evidence content types', async () => {
  const root = await mkdtemp(join(tmpdir(), 'fleetos-evidence-'));
  try {
    const store = new EvidenceStore(root);
    await assert.rejects(
      store.upload(request(Buffer.from('x'), 'text/plain', 'notes.txt'), driver, 'trip-1', 'other'),
      /only JPEG, PNG, WEBP and PDF evidence is accepted/,
    );
  } finally {
    await rm(root, { recursive: true, force: true });
  }
});

test('rejects roles that cannot upload trip evidence', async () => {
  const root = await mkdtemp(join(tmpdir(), 'fleetos-evidence-'));
  try {
    const store = new EvidenceStore(root);
    const principal: TenantPrincipal = { ...driver, sub: 'compliance-1', role: 'compliance' };
    await assert.rejects(
      store.upload(request(Buffer.from('proof')), principal, 'trip-1', 'pod'),
      /role is not allowed to upload trip evidence/,
    );
  } finally {
    await rm(root, { recursive: true, force: true });
  }
});
