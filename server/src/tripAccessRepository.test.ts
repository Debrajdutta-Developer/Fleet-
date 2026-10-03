import test from 'node:test';
import assert from 'node:assert/strict';
import { InMemoryTripAccessRepository, normalizeTripAssignment } from './tripAccessRepository.js';
import type { TenantPrincipal } from './tenantAuth.js';

const repo = () => new InMemoryTripAccessRepository();

function principal(sub: string, companyId: string, role: TenantPrincipal['role']): TenantPrincipal {
  return { sub, companyId, role };
}

test('assigned driver can access only the assigned trip', async () => {
  const repository = repo();
  await repository.upsert(normalizeTripAssignment('company-a', 'trip-1', { driverSubject: 'driver-1' }, 'manager-1'));
  await repository.upsert(normalizeTripAssignment('company-a', 'trip-2', { driverSubject: 'driver-2' }, 'manager-1'));

  assert.equal(await repository.canAccess(principal('driver-1', 'company-a', 'driver'), 'trip-1'), true);
  assert.equal(await repository.canAccess(principal('driver-1', 'company-a', 'driver'), 'trip-2'), false);
});

test('assigned khalashi can access only their assigned trip', async () => {
  const repository = repo();
  await repository.upsert(normalizeTripAssignment('company-a', 'trip-1', { khalashiSubject: 'helper-1' }, 'manager-1'));
  await repository.upsert(normalizeTripAssignment('company-a', 'trip-2', { khalashiSubject: 'helper-2' }, 'manager-1'));

  assert.equal(await repository.canAccess(principal('helper-1', 'company-a', 'khalashi'), 'trip-1'), true);
  assert.equal(await repository.canAccess(principal('helper-1', 'company-a', 'khalashi'), 'trip-2'), false);
});

test('same subject cannot cross tenant boundary', async () => {
  const repository = repo();
  await repository.upsert(normalizeTripAssignment('company-a', 'trip-1', { driverSubject: 'driver-1' }, 'manager-1'));

  assert.equal(await repository.canAccess(principal('driver-1', 'company-b', 'driver'), 'trip-1'), false);
});

test('owner and manager can access tenant trips without impersonating a worker', async () => {
  const repository = repo();
  assert.equal(await repository.canAccess(principal('owner-1', 'company-a', 'owner'), 'trip-any'), true);
  assert.equal(await repository.canAccess(principal('manager-1', 'company-a', 'manager'), 'trip-any'), true);
});
