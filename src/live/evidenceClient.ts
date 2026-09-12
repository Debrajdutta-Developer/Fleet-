import { getSessionToken } from '../auth/session';

const configuredBase = (import.meta.env.VITE_TELEMETRY_API_URL as string | undefined)?.trim() ?? '';
const API_BASE = configuredBase.replace(/\/$/, '');

export type EvidenceType = 'fuel_receipt' | 'toll_receipt' | 'repair_receipt' | 'pod' | 'weighment' | 'other';

export interface TripEvidenceRecord {
  id: string;
  companyId: string;
  tripId: string;
  uploadedBy: string;
  uploaderRole: string;
  evidenceType: EvidenceType;
  originalFileName: string;
  contentType: string;
  sizeBytes: number;
  createdAt: string;
}

function headers(companyId: string): HeadersInit {
  const token = getSessionToken();
  if (!token) throw new Error('Secure sign-in is required before uploading trip evidence');
  return {
    authorization: `Bearer ${token}`,
    'x-fleetos-company-id': companyId,
    accept: 'application/json',
  };
}

export async function uploadTripEvidence(companyId: string, tripId: string, type: EvidenceType, file: File): Promise<TripEvidenceRecord> {
  const response = await fetch(`${API_BASE}/api/trips/${encodeURIComponent(tripId)}/evidence?type=${encodeURIComponent(type)}`, {
    method: 'POST',
    headers: { ...headers(companyId), 'content-type': file.type, 'x-file-name': file.name },
    body: file,
  });
  const payload = await response.json().catch(() => ({})) as { evidence?: TripEvidenceRecord; error?: string };
  if (!response.ok || !payload.evidence) throw new Error(payload.error || `Evidence upload failed (${response.status})`);
  return payload.evidence;
}

export async function listTripEvidence(companyId: string, tripId: string): Promise<TripEvidenceRecord[]> {
  const response = await fetch(`${API_BASE}/api/trips/${encodeURIComponent(tripId)}/evidence`, {
    method: 'GET',
    headers: headers(companyId),
  });
  const payload = await response.json().catch(() => ({})) as { evidence?: TripEvidenceRecord[]; error?: string };
  if (!response.ok) throw new Error(payload.error || `Evidence lookup failed (${response.status})`);
  return payload.evidence ?? [];
}
