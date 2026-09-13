import { clearFleetAccessToken, setFleetAccessToken } from './runtimeSession';
import type { SecurePrincipal } from './securePrincipal';

const configuredBase = (import.meta.env.VITE_TELEMETRY_API_URL as string | undefined)?.trim() ?? '';
const API_BASE = configuredBase.replace(/\/$/, '');

export interface NativeLoginResult {
  accessToken: string;
  principal: SecurePrincipal;
  user: {
    id: string;
    email: string;
    companyId: string;
    role: SecurePrincipal['role'];
    displayName: string;
    active: boolean;
  };
}

export async function nativeFleetLogin(email: string, password: string): Promise<NativeLoginResult> {
  const response = await fetch(`${API_BASE}/api/auth/login`, {
    method: 'POST',
    headers: {
      accept: 'application/json',
      'content-type': 'application/json',
    },
    body: JSON.stringify({ email, password }),
  });
  const payload = await response.json() as Partial<NativeLoginResult> & { error?: string };
  if (!response.ok || !payload.accessToken || !payload.principal) {
    throw new Error(payload.error || `FleetOS sign-in failed (${response.status})`);
  }
  setFleetAccessToken(payload.accessToken);
  return payload as NativeLoginResult;
}

export function nativeFleetLogout(): void {
  clearFleetAccessToken();
}
