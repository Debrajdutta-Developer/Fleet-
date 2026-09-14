import { randomBytes, randomUUID, scrypt as scryptCallback, timingSafeEqual } from 'node:crypto';
import { promisify } from 'node:util';
import { SignJWT } from 'jose';
import { Pool } from 'pg';
import type { TenantPrincipal, TenantRole } from './tenantAuth.js';

const scrypt = promisify(scryptCallback);
const ROLES = new Set<TenantRole>(['owner', 'manager', 'dispatcher', 'driver', 'khalashi', 'accountant', 'compliance']);

export interface NativeAuthUser {
  id: string;
  email: string;
  companyId: string;
  role: TenantRole;
  displayName: string;
  active: boolean;
}

interface StoredUser extends NativeAuthUser {
  passwordHash: string;
}

export function normalizeAuthEmail(value: unknown): string {
  const email = typeof value === 'string' ? value.trim().toLowerCase() : '';
  if (!email || !email.includes('@') || email.length > 254) throw new Error('valid email is required');
  return email;
}

export function normalizeAuthPassword(value: unknown): string {
  const password = typeof value === 'string' ? value : '';
  if (password.length < 10) throw new Error('password must be at least 10 characters');
  if (password.length > 200) throw new Error('password is too long');
  return password;
}

function normalizeRole(value: unknown): TenantRole {
  if (typeof value !== 'string' || !ROLES.has(value as TenantRole)) throw new Error('invalid role');
  return value as TenantRole;
}

export async function hashAuthPassword(password: string): Promise<string> {
  const salt = randomBytes(16);
  const derived = await scrypt(password, salt, 64) as Buffer;
  return `scrypt$${salt.toString('base64url')}$${derived.toString('base64url')}`;
}

async function verifyPassword(password: string, encoded: string): Promise<boolean> {
  const [algorithm, saltEncoded, hashEncoded] = encoded.split('$');
  if (algorithm !== 'scrypt' || !saltEncoded || !hashEncoded) return false;
  try {
    const salt = Buffer.from(saltEncoded, 'base64url');
    const expected = Buffer.from(hashEncoded, 'base64url');
    const actual = await scrypt(password, salt, expected.length) as Buffer;
    return actual.length === expected.length && timingSafeEqual(actual, expected);
  } catch {
    return false;
  }
}

export class NativeAuthService {
  private readonly pool: Pool | null;
  private schemaReady: Promise<void> | null = null;
  private readonly jwtSecret = process.env.FLEETOS_JWT_SECRET?.trim() ?? '';
  private readonly issuer = process.env.FLEETOS_JWT_ISSUER?.trim() || 'fleetos';
  private readonly audience = process.env.FLEETOS_JWT_AUDIENCE?.trim() || 'fleetos-web';

  constructor(connectionString = process.env.DATABASE_URL?.trim() ?? '') {
    this.pool = connectionString ? new Pool({ connectionString, max: 10 }) : null;
  }

  get enabled(): boolean {
    return Boolean(this.pool && this.jwtSecret);
  }

  private async ensureSchema(): Promise<void> {
    if (!this.pool) throw new Error('native auth requires DATABASE_URL');
    if (!this.schemaReady) {
      this.schemaReady = (async () => {
        await this.pool!.query(`
          CREATE TABLE IF NOT EXISTS fleetos_auth_users (
            id TEXT PRIMARY KEY,
            email TEXT NOT NULL UNIQUE,
            password_hash TEXT NOT NULL,
            company_id TEXT NOT NULL,
            role TEXT NOT NULL,
            display_name TEXT NOT NULL DEFAULT '',
            active BOOLEAN NOT NULL DEFAULT TRUE,
            created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
            updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
          )
        `);
        await this.pool!.query('CREATE INDEX IF NOT EXISTS fleetos_auth_users_company_idx ON fleetos_auth_users(company_id)');
      })();
    }
    return this.schemaReady;
  }

  private rowToUser(row: Record<string, unknown>): StoredUser {
    return {
      id: String(row.id),
      email: String(row.email),
      passwordHash: String(row.password_hash),
      companyId: String(row.company_id),
      role: normalizeRole(row.role),
      displayName: String(row.display_name ?? ''),
      active: Boolean(row.active),
    };
  }

  async login(raw: unknown): Promise<{ accessToken: string; principal: TenantPrincipal; user: NativeAuthUser }> {
    if (!this.enabled) throw new Error('native auth is not configured');
    await this.ensureSchema();
    const input = (raw && typeof raw === 'object' ? raw : {}) as Record<string, unknown>;
    const email = normalizeAuthEmail(input.email);
    const password = typeof input.password === 'string' ? input.password : '';
    if (!password) throw new Error('password is required');

    const result = await this.pool!.query('SELECT * FROM fleetos_auth_users WHERE email = $1 LIMIT 1', [email]);
    if (!result.rows.length) throw new Error('invalid email or password');
    const stored = this.rowToUser(result.rows[0] as Record<string, unknown>);
    if (!stored.active || !(await verifyPassword(password, stored.passwordHash))) throw new Error('invalid email or password');

    const principal: TenantPrincipal = { sub: stored.id, companyId: stored.companyId, role: stored.role };
    const secret = new TextEncoder().encode(this.jwtSecret);
    const accessToken = await new SignJWT({ companyId: stored.companyId, role: stored.role })
      .setProtectedHeader({ alg: 'HS256', typ: 'JWT' })
      .setSubject(stored.id)
      .setIssuer(this.issuer)
      .setAudience(this.audience)
      .setIssuedAt()
      .setExpirationTime('8h')
      .sign(secret);

    const { passwordHash: _passwordHash, ...user } = stored;
    return { accessToken, principal, user };
  }

  async provisionUser(input: { email: string; password: string; companyId: string; role: TenantRole; displayName?: string }): Promise<NativeAuthUser> {
    if (!this.enabled) throw new Error('native auth is not configured');
    await this.ensureSchema();
    const email = normalizeAuthEmail(input.email);
    const passwordHash = await hashAuthPassword(normalizeAuthPassword(input.password));
    const role = normalizeRole(input.role);
    const companyId = input.companyId.trim();
    if (!companyId) throw new Error('companyId is required');
    const id = randomUUID();
    try {
      const result = await this.pool!.query(
        `INSERT INTO fleetos_auth_users (id, email, password_hash, company_id, role, display_name)
         VALUES ($1, $2, $3, $4, $5, $6)
         RETURNING id, email, company_id, role, display_name, active`,
        [id, email, passwordHash, companyId, role, input.displayName?.trim().slice(0, 120) || ''],
      );
      const row = result.rows[0] as Record<string, unknown>;
      return { id: String(row.id), email: String(row.email), companyId: String(row.company_id), role: normalizeRole(row.role), displayName: String(row.display_name ?? ''), active: Boolean(row.active) };
    } catch (error) {
      if (error && typeof error === 'object' && (error as { code?: string }).code === '23505') throw new Error('an account with that email already exists');
      throw error;
    }
  }

  async moveUserToCompany(userId: string, companyId: string, role: TenantRole): Promise<NativeAuthUser> {
    if (!this.enabled) throw new Error('native auth is not configured');
    await this.ensureSchema();
    const result = await this.pool!.query(
      `UPDATE fleetos_auth_users SET company_id = $2, role = $3, updated_at = NOW()
       WHERE id = $1 AND active = TRUE
       RETURNING id, email, company_id, role, display_name, active`,
      [userId, companyId.trim(), normalizeRole(role)],
    );
    if (!result.rows.length) throw new Error('user not found');
    const row = result.rows[0] as Record<string, unknown>;
    return { id: String(row.id), email: String(row.email), companyId: String(row.company_id), role: normalizeRole(row.role), displayName: String(row.display_name ?? ''), active: Boolean(row.active) };
  }

  async createUser(raw: unknown, actor: TenantPrincipal): Promise<NativeAuthUser> {
    if (actor.role !== 'owner') throw new Error('only an owner can create FleetOS users');
    const input = (raw && typeof raw === 'object' ? raw : {}) as Record<string, unknown>;
    return this.provisionUser({
      email: normalizeAuthEmail(input.email),
      password: normalizeAuthPassword(input.password),
      companyId: actor.companyId,
      role: normalizeRole(input.role),
      displayName: typeof input.displayName === 'string' ? input.displayName : '',
    });
  }

  async listUsers(actor: TenantPrincipal): Promise<NativeAuthUser[]> {
    if (!this.enabled) throw new Error('native auth is not configured');
    if (actor.role !== 'owner' && actor.role !== 'manager') throw new Error('user directory requires owner or manager role');
    await this.ensureSchema();
    const result = await this.pool!.query(`SELECT id, email, company_id, role, display_name, active FROM fleetos_auth_users WHERE company_id = $1 ORDER BY display_name, email`, [actor.companyId]);
    return result.rows.map((row: Record<string, unknown>) => ({ id: String(row.id), email: String(row.email), companyId: String(row.company_id), role: normalizeRole(row.role), displayName: String(row.display_name ?? ''), active: Boolean(row.active) }));
  }

  async bootstrapFromEnv(): Promise<boolean> {
    const email = process.env.FLEETOS_BOOTSTRAP_OWNER_EMAIL?.trim();
    const password = process.env.FLEETOS_BOOTSTRAP_OWNER_PASSWORD ?? '';
    const companyId = process.env.FLEETOS_BOOTSTRAP_COMPANY_ID?.trim();
    if (!email && !password && !companyId) return false;
    if (!email || !password || !companyId) throw new Error('bootstrap owner requires FLEETOS_BOOTSTRAP_OWNER_EMAIL, FLEETOS_BOOTSTRAP_OWNER_PASSWORD and FLEETOS_BOOTSTRAP_COMPANY_ID');
    if (!this.enabled) throw new Error('bootstrap owner requires DATABASE_URL and FLEETOS_JWT_SECRET');
    await this.ensureSchema();
    const normalizedEmail = normalizeAuthEmail(email);
    const existing = await this.pool!.query('SELECT id FROM fleetos_auth_users WHERE email = $1 LIMIT 1', [normalizedEmail]);
    if (existing.rows.length) return false;
    const passwordHash = await hashAuthPassword(normalizeAuthPassword(password));
    await this.pool!.query(`INSERT INTO fleetos_auth_users (id, email, password_hash, company_id, role, display_name) VALUES ($1, $2, $3, $4, 'owner', $5)`, [randomUUID(), normalizedEmail, passwordHash, companyId, process.env.FLEETOS_BOOTSTRAP_OWNER_NAME?.trim() || 'Fleet Owner']);
    return true;
  }
}
