const API_URL = (import.meta.env.VITE_TELEMETRY_API_URL as string | undefined)?.replace(/\/$/, '') || '';

async function post(path: string, body: unknown): Promise<any> {
  const response = await fetch(`${API_URL}${path}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(body),
  });
  const data = await response.json().catch(() => ({}));
  if (!response.ok) throw new Error(data.error || 'Request failed');
  return data;
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
