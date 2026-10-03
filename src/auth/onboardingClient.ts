import { getFleetAccessToken } from './runtimeSession';

const API_URL = (import.meta.env.VITE_TELEMETRY_API_URL as string | undefined)?.replace(/\/$/, '') || '';

async function request(path: string, init: RequestInit): Promise<any> {
  const response = await fetch(`${API_URL}${path}`, init);
  const data = await response.json().catch(() => ({}));
  if (!response.ok) throw new Error(data.error || 'Request failed');
  return data;
}

async function post(path: string, body: unknown, extraHeaders: Record<string, string> = {}): Promise<any> {
  return request(path, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', ...extraHeaders },
    body: JSON.stringify(body),
  });
}

export function submitCompanyApplication(input: {
  legalName: string; tradeName?: string; ownerName: string; ownerEmail: string; ownerPhone: string;
  gstin?: string; pan?: string; address: string; state: string; fleetSize: number; transportType: string;
  vehicleRegistrations: string[];
}) {
  return post('/api/onboarding/companies', input);
}

export function registerDriverProfile(input: {
  fullName: string; email: string; phone: string; password: string; drivingLicenceNumber: string; aadhaarLast4: string;
}) {
  return post('/api/onboarding/drivers', input);
}

export function activateApprovedOwner(input: { applicationId: string; activationToken: string; password: string }) {
  return post('/api/onboarding/activate-owner', input);
}

export function linkExistingDriver(input: { email: string; drivingLicenceNumber: string; aadhaarLast4: string }) {
  const token = getFleetAccessToken();
  if (!token) throw new Error('Sign in as a company owner or manager first');
  return post('/api/onboarding/link-driver', input, { Authorization: `Bearer ${token}` });
}

export async function listPlatformApplications(adminToken: string) {
  return request('/api/platform/applications', {
    headers: { 'X-FleetOS-Platform-Admin-Token': adminToken },
  });
}

export async function approvePlatformApplication(applicationId: string, adminToken: string) {
  return post(`/api/platform/applications/${encodeURIComponent(applicationId)}/approve`, {}, {
    'X-FleetOS-Platform-Admin-Token': adminToken,
  });
}
