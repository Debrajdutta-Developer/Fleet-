import type { IncomingMessage } from 'node:http';
import type { TenantAuthorizer, TenantPrincipal, TenantRole } from './tenantAuth.js';

export type AuthorizationResult =
  | { ok: true; principal: TenantPrincipal }
  | { ok: false; status: 401 | 403; error: string };

function requestedCompanyId(req: IncomingMessage): string {
  const value = req.headers['x-fleetos-company-id'];
  return Array.isArray(value) ? (value[0] ?? '') : (value ?? '');
}

export async function authorizeTenantRequest(
  req: IncomingMessage,
  authorizer: TenantAuthorizer,
): Promise<AuthorizationResult> {
  const principal = await authorizer.authenticateAsync(req);
  if (!principal) return { ok: false, status: 401, error: 'authentication required' };

  const requested = requestedCompanyId(req).trim();
  if (requested && requested !== principal.companyId) {
    return { ok: false, status: 403, error: 'authenticated session is not authorized for the requested tenant' };
  }
  return { ok: true, principal };
}

export async function authorizeRoleRequest(
  req: IncomingMessage,
  authorizer: TenantAuthorizer,
  roles: ReadonlySet<TenantRole>,
  error = 'role is not authorized for this operation',
): Promise<AuthorizationResult> {
  const tenant = await authorizeTenantRequest(req, authorizer);
  if (!tenant.ok) return tenant;
  if (!roles.has(tenant.principal.role)) return { ok: false, status: 403, error };
  return tenant;
}
