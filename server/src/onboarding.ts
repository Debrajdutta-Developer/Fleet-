import { createHash, randomBytes, randomUUID } from 'node:crypto';
import { Pool } from 'pg';
import type { TenantPrincipal } from './tenantAuth.js';
import { NativeAuthService, normalizeAuthEmail, normalizeAuthPassword } from './nativeAuth.js';

export interface CompanyApplication {
  id: string;
  legalName: string;
  tradeName: string;
  ownerName: string;
  ownerEmail: string;
  ownerPhone: string;
  gstin?: string;
  pan?: string;
  address: string;
  state: string;
  fleetSize: number;
  transportType: string;
  vehicleRegistrations: string[];
  status: 'pending' | 'approved' | 'rejected';
  autoDiscoveryStatus: 'pending_provider' | 'not_requested';
  createdAt: string;
  reviewedAt?: string;
}

function normalizeText(value: unknown, field: string, max = 160): string {
  const text = typeof value === 'string' ? value.trim() : '';
  if (!text) throw new Error(`${field} is required`);
  return text.slice(0, max);
}

function normalizePhone(value: unknown): string {
  const phone = typeof value === 'string' ? value.replace(/\s+/g, '').trim() : '';
  if (!/^\+?[0-9]{8,15}$/.test(phone)) throw new Error('valid owner phone is required');
  return phone;
}

function normalizeVehicleRegistrations(value: unknown): string[] {
  if (!Array.isArray(value)) return [];
  return [...new Set(value.map((v) => String(v).toUpperCase().replace(/[^A-Z0-9]/g, '')).filter(Boolean))].slice(0, 500);
}

function normalizeDl(value: unknown): string {
  const dl = typeof value === 'string' ? value.toUpperCase().replace(/[^A-Z0-9]/g, '') : '';
  if (dl.length < 6 || dl.length > 24) throw new Error('valid driving licence number is required');
  return dl;
}

function normalizeAadhaarLast4(value: unknown): string {
  const last4 = typeof value === 'string' ? value.replace(/\D/g, '') : '';
  if (!/^\d{4}$/.test(last4)) throw new Error('Aadhaar last 4 digits are required');
  return last4;
}

function hashIdentity(value: string): string {
  return createHash('sha256').update(value).digest('hex');
}

export class OnboardingService {
  private readonly pool: Pool;
  private schemaReady: Promise<void> | null = null;
  constructor(private readonly auth: NativeAuthService, connectionString = process.env.DATABASE_URL?.trim() ?? '') {
    if (!connectionString) throw new Error('onboarding requires DATABASE_URL');
    this.pool = new Pool({ connectionString, max: 6 });
  }

  private async ensureSchema(): Promise<void> {
    if (!this.schemaReady) {
      this.schemaReady = (async () => {
        await this.pool.query(`
          CREATE TABLE IF NOT EXISTS fleetos_company_applications (
            id TEXT PRIMARY KEY,
            legal_name TEXT NOT NULL,
            trade_name TEXT NOT NULL DEFAULT '',
            owner_name TEXT NOT NULL,
            owner_email TEXT NOT NULL,
            owner_phone TEXT NOT NULL,
            gstin TEXT,
            pan TEXT,
            address TEXT NOT NULL,
            state TEXT NOT NULL,
            fleet_size INTEGER NOT NULL DEFAULT 0,
            transport_type TEXT NOT NULL DEFAULT 'general_logistics',
            vehicle_registrations JSONB NOT NULL DEFAULT '[]'::jsonb,
            status TEXT NOT NULL DEFAULT 'pending',
            auto_discovery_status TEXT NOT NULL DEFAULT 'pending_provider',
            activation_token_hash TEXT,
            created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
            reviewed_at TIMESTAMPTZ
          )
        `);
        await this.pool.query('CREATE INDEX IF NOT EXISTS fleetos_company_applications_status_idx ON fleetos_company_applications(status, created_at)');
        await this.pool.query(`
          CREATE TABLE IF NOT EXISTS fleetos_driver_profiles (
            user_id TEXT PRIMARY KEY,
            email TEXT NOT NULL UNIQUE,
            full_name TEXT NOT NULL,
            phone TEXT NOT NULL,
            dl_number TEXT NOT NULL UNIQUE,
            aadhaar_last4_hash TEXT NOT NULL,
            verification_status TEXT NOT NULL DEFAULT 'self_declared',
            linked_company_id TEXT,
            created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
            updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
          )
        `);
      })();
    }
    return this.schemaReady;
  }

  async submitCompany(raw: unknown): Promise<CompanyApplication> {
    await this.ensureSchema();
    const input = (raw && typeof raw === 'object' ? raw : {}) as Record<string, unknown>;
    const id = randomUUID();
    const legalName = normalizeText(input.legalName, 'legal name');
    const tradeName = typeof input.tradeName === 'string' ? input.tradeName.trim().slice(0, 160) : '';
    const ownerName = normalizeText(input.ownerName, 'owner name');
    const ownerEmail = normalizeAuthEmail(input.ownerEmail);
    const ownerPhone = normalizePhone(input.ownerPhone);
    const gstin = typeof input.gstin === 'string' ? input.gstin.trim().toUpperCase().slice(0, 20) : '';
    const pan = typeof input.pan === 'string' ? input.pan.trim().toUpperCase().slice(0, 12) : '';
    const address = normalizeText(input.address, 'address', 500);
    const state = normalizeText(input.state, 'state', 80);
    const fleetSize = Math.max(0, Math.min(100000, Math.floor(Number(input.fleetSize ?? 0)) || 0));
    const transportType = typeof input.transportType === 'string' ? input.transportType.trim().slice(0, 80) : 'general_logistics';
    const vehicleRegistrations = normalizeVehicleRegistrations(input.vehicleRegistrations);
    const result = await this.pool.query(
      `INSERT INTO fleetos_company_applications
       (id, legal_name, trade_name, owner_name, owner_email, owner_phone, gstin, pan, address, state, fleet_size, transport_type, vehicle_registrations)
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13::jsonb)
       RETURNING *`,
      [id, legalName, tradeName, ownerName, ownerEmail, ownerPhone, gstin || null, pan || null, address, state, fleetSize, transportType, JSON.stringify(vehicleRegistrations)],
    );
    return this.rowToApplication(result.rows[0]);
  }

  async listApplications(adminToken: string): Promise<CompanyApplication[]> {
    this.assertAdmin(adminToken);
    await this.ensureSchema();
    const result = await this.pool.query('SELECT * FROM fleetos_company_applications ORDER BY created_at DESC LIMIT 500');
    return result.rows.map((r) => this.rowToApplication(r));
  }

  async approveApplication(id: string, adminToken: string): Promise<{ application: CompanyApplication; activationToken: string; companyId: string }> {
    this.assertAdmin(adminToken);
    await this.ensureSchema();
    const token = randomBytes(32).toString('base64url');
    const tokenHash = hashIdentity(token);
    const companyId = `company_${id.replace(/-/g, '').slice(0, 20)}`;
    const result = await this.pool.query(
      `UPDATE fleetos_company_applications SET status='approved', activation_token_hash=$2, reviewed_at=NOW()
       WHERE id=$1 AND status='pending' RETURNING *`,
      [id, tokenHash],
    );
    if (!result.rows.length) throw new Error('pending application not found');
    return { application: this.rowToApplication(result.rows[0]), activationToken: token, companyId };
  }

  async activateOwner(raw: unknown): Promise<{ email: string; companyId: string }> {
    await this.ensureSchema();
    const input = (raw && typeof raw === 'object' ? raw : {}) as Record<string, unknown>;
    const applicationId = normalizeText(input.applicationId, 'applicationId', 80);
    const activationToken = normalizeText(input.activationToken, 'activationToken', 200);
    const password = normalizeAuthPassword(input.password);
    const result = await this.pool.query('SELECT * FROM fleetos_company_applications WHERE id=$1 AND status=\'approved\' LIMIT 1', [applicationId]);
    if (!result.rows.length) throw new Error('approved application not found');
    const row = result.rows[0] as Record<string, unknown>;
    if (!row.activation_token_hash || String(row.activation_token_hash) !== hashIdentity(activationToken)) throw new Error('invalid activation token');
    const companyId = `company_${applicationId.replace(/-/g, '').slice(0, 20)}`;
    const user = await this.auth.provisionUser({ email: String(row.owner_email), password, companyId, role: 'owner', displayName: String(row.owner_name) });
    await this.pool.query('UPDATE fleetos_company_applications SET activation_token_hash=NULL WHERE id=$1', [applicationId]);
    return { email: user.email, companyId };
  }

  async registerDriver(raw: unknown): Promise<{ userId: string; email: string }> {
    await this.ensureSchema();
    const input = (raw && typeof raw === 'object' ? raw : {}) as Record<string, unknown>;
    const email = normalizeAuthEmail(input.email);
    const password = normalizeAuthPassword(input.password);
    const fullName = normalizeText(input.fullName, 'full name');
    const phone = normalizePhone(input.phone);
    const dlNumber = normalizeDl(input.drivingLicenceNumber);
    const aadhaarLast4 = normalizeAadhaarLast4(input.aadhaarLast4);
    const poolCompanyId = `driver_pool_${randomUUID().replace(/-/g, '').slice(0, 20)}`;
    const user = await this.auth.provisionUser({ email, password, companyId: poolCompanyId, role: 'driver', displayName: fullName });
    try {
      await this.pool.query(
        `INSERT INTO fleetos_driver_profiles (user_id,email,full_name,phone,dl_number,aadhaar_last4_hash)
         VALUES ($1,$2,$3,$4,$5,$6)`,
        [user.id, email, fullName, phone, dlNumber, hashIdentity(aadhaarLast4)],
      );
    } catch (error) {
      throw error;
    }
    return { userId: user.id, email: user.email };
  }

  async linkDriver(raw: unknown, actor: TenantPrincipal): Promise<{ userId: string; email: string; companyId: string }> {
    if (actor.role !== 'owner' && actor.role !== 'manager') throw new Error('driver linking requires owner or manager role');
    await this.ensureSchema();
    const input = (raw && typeof raw === 'object' ? raw : {}) as Record<string, unknown>;
    const email = normalizeAuthEmail(input.email);
    const dlNumber = normalizeDl(input.drivingLicenceNumber);
    const aadhaarLast4 = normalizeAadhaarLast4(input.aadhaarLast4);
    const result = await this.pool.query('SELECT * FROM fleetos_driver_profiles WHERE email=$1 AND dl_number=$2 LIMIT 1', [email, dlNumber]);
    if (!result.rows.length) throw new Error('matching driver profile not found');
    const row = result.rows[0] as Record<string, unknown>;
    if (String(row.aadhaar_last4_hash) !== hashIdentity(aadhaarLast4)) throw new Error('driver identity verification failed');
    if (row.linked_company_id && String(row.linked_company_id) !== actor.companyId) throw new Error('driver is already linked to another company');
    await this.auth.moveUserToCompany(String(row.user_id), actor.companyId, 'driver');
    await this.pool.query('UPDATE fleetos_driver_profiles SET linked_company_id=$2, updated_at=NOW() WHERE user_id=$1', [row.user_id, actor.companyId]);
    return { userId: String(row.user_id), email: String(row.email), companyId: actor.companyId };
  }

  private assertAdmin(token: string): void {
    const expected = process.env.FLEETOS_PLATFORM_ADMIN_TOKEN?.trim() ?? '';
    if (!expected || !token || token !== expected) throw new Error('platform admin authorization required');
  }

  private rowToApplication(row: Record<string, unknown>): CompanyApplication {
    return {
      id: String(row.id), legalName: String(row.legal_name), tradeName: String(row.trade_name ?? ''), ownerName: String(row.owner_name), ownerEmail: String(row.owner_email), ownerPhone: String(row.owner_phone), gstin: row.gstin ? String(row.gstin) : undefined, pan: row.pan ? String(row.pan) : undefined, address: String(row.address), state: String(row.state), fleetSize: Number(row.fleet_size ?? 0), transportType: String(row.transport_type), vehicleRegistrations: Array.isArray(row.vehicle_registrations) ? row.vehicle_registrations.map(String) : [], status: String(row.status) as CompanyApplication['status'], autoDiscoveryStatus: String(row.auto_discovery_status) as CompanyApplication['autoDiscoveryStatus'], createdAt: new Date(String(row.created_at)).toISOString(), reviewedAt: row.reviewed_at ? new Date(String(row.reviewed_at)).toISOString() : undefined,
    };
  }
}
