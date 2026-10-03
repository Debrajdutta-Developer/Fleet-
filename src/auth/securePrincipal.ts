import { getFleetAccessToken } from './runtimeSession';

export type SecureRole = 'owner' | 'manager' | 'dispatcher' | 'driver' | 'khalashi' | 'accountant' | 'compliance';

export interface SecurePrincipal {
  sub: string;
  companyId: string;
  role: SecureRole;
}

const configuredBase = (import.meta.env.VITE_TELEMETRY_API_URL as string | undefined)?.trim() ?? '';
const API_BASE = configuredBase.replace(/\/$/, '');

export async function fetchSecurePrincipal(signal?: AbortSignal): Promise<SecurePrincipal> {
  const token = getFleetAccessToken();
  if (!token) throw new Error('FleetOS sign-in session is missing');

  const response = await fetch(`${API_BASE}/api/me`, {
    method: 'GET',
    headers: {
      accept: 'application/json',
      authorization: `Bearer ${token}`,
    },
    signal,
  });
  if (!response.ok) throw new Error(`FleetOS identity verification failed (${response.status})`);

  const payload = await response.json() as { principal?: SecurePrincipal };
  const principal = payload.principal;
  if (!principal?.sub || !principal.companyId || !principal.role) {
    throw new Error('FleetOS identity response is invalid');
  }
  return principal;
}
