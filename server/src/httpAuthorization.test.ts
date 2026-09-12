import test from 'node:test';
import assert from 'node:assert/strict';
import type { IncomingMessage } from 'node:http';
import type { TenantAuthorizer, TenantPrincipal, TenantRole } from './tenantAuth.js';
import { authorizeRoleRequest, authorizeTenantRequest } from './httpAuthorization.js';

function req(companyId?: string): IncomingMessage {
  return { headers: companyId ? { 'x-fleetos-company-id': companyId } : {} } as IncomingMessage;
}

function authorizer(principal: TenantPrincipal | null): TenantAuthorizer {
  return {
    async authenticateAsync() { return principal; },
  } as unknown as TenantAuthorizer;
}

test('returns 401 when the request is not authenticated', async () => {
  const result = await authorizeTenantRequest(req('company-a'), authorizer(null));
  assert.deepEqual(result, { ok: false, status: 401, error: 'authentication required' });
});

test('returns 403 for a valid identity scoped to another tenant', async () => {
  const principal: TenantPrincipal = { sub: 'user-1', companyId: 'company-a', role: 'manager' };
  const result = await authorizeTenantRequest(req('company-b'), authorizer(principal));
  assert.deepEqual(result, {
    ok: false,
    status: 403,
    error: 'authenticated session is not authorized for the requested tenant',
  });
});

test('returns 403 when an authenticated tenant user lacks the required role', async () => {
  const principal: TenantPrincipal = { sub: 'user-1', companyId: 'company-a', role: 'driver' };
  const roles = new Set<TenantRole>(['owner', 'manager', 'accountant']);
  const result = await authorizeRoleRequest(req('company-a'), authorizer(principal), roles, 'finance access denied');
  assert.deepEqual(result, { ok: false, status: 403, error: 'finance access denied' });
});
