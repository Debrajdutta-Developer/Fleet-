import { getFleetAccessToken } from '../auth/runtimeSession';
import type { VehicleSettlementTerms } from '../domain/vehicleSettlement';

const configuredBase = (import.meta.env.VITE_TELEMETRY_API_URL as string | undefined)?.trim() ?? '';
const API_BASE = configuredBase.replace(/\/$/, '');

export interface PersistedVehicleSettlementTerms extends VehicleSettlementTerms {
  companyId: string;
  updatedAt: string;
  updatedBy: string;
}

function headers(companyId: string): HeadersInit {
  const token = getFleetAccessToken();
  if (!token) throw new Error('Secure sign-in is required for finance settlement access');
  return {
    accept: 'application/json',
    authorization: `Bearer ${token}`,
    'content-type': 'application/json',
    'x-fleetos-company-id': companyId,
  };
}

export async function listSettlementTerms(companyId: string): Promise<PersistedVehicleSettlementTerms[]> {
  const response = await fetch(`${API_BASE}/api/finance/settlement-terms`, {
    method: 'GET',
    headers: headers(companyId),
  });
  const payload = await response.json().catch(() => ({})) as {
    companyId?: string;
    terms?: PersistedVehicleSettlementTerms[];
    error?: string;
  };
  if (!response.ok) throw new Error(payload.error || `Settlement lookup failed (${response.status})`);
  if (payload.companyId !== companyId || !Array.isArray(payload.terms)) {
    throw new Error('Settlement API returned an invalid or cross-tenant payload');
  }
  return payload.terms;
}

export async function saveSettlementTerms(
  companyId: string,
  terms: VehicleSettlementTerms,
): Promise<PersistedVehicleSettlementTerms> {
  const response = await fetch(`${API_BASE}/api/finance/settlement-terms/${encodeURIComponent(terms.vehicleId)}`, {
    method: 'PUT',
    headers: headers(companyId),
    body: JSON.stringify(terms),
  });
  const payload = await response.json().catch(() => ({})) as {
    terms?: PersistedVehicleSettlementTerms;
    error?: string;
  };
  if (!response.ok || !payload.terms) {
    throw new Error(payload.error || `Settlement save failed (${response.status})`);
  }
  if (payload.terms.companyId !== companyId || payload.terms.vehicleId !== terms.vehicleId) {
    throw new Error('Settlement API returned an invalid or cross-tenant record');
  }
  return payload.terms;
}
