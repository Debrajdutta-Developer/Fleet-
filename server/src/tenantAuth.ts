import { createHmac, timingSafeEqual } from 'node:crypto';
import type { IncomingMessage } from 'node:http';

export type TenantRole = 'owner' | 'manager' | 'dispatcher' | 'driver' | 'accountant' | 'compliance';

export interface TenantPrincipal {
  sub: string;
  companyId: string;
  role: TenantRole;
}

interface TokenConfigEntry {
  token: string;
  companyId: string;
  role?: TenantRole;
  sub?: string;
}

interface JwtClaims {
  sub?: unknown;
  companyId?: unknown;
  role?: unknown;
  exp?: unknown;
  nbf?: unknown;
  iss?: unknown;
  aud?: unknown;
}

const ROLES = new Set<TenantRole>(['owner', 'manager', 'dispatcher', 'driver', 'accountant', 'compliance']);

function decodeBase64Url(value: string): Buffer {
  return Buffer.from(value.replace(/-/g, '+').replace(/_/g, '/'), 'base64');
}

function safeJson(value: Buffer): unknown {
  return JSON.parse(value.toString('utf8')) as unknown;
}

function verifyHs256(token: string, secret: string): JwtClaims | null {
  const parts = token.split('.');
  if (parts.length !== 3) return null;
  const [headerPart, payloadPart, signaturePart] = parts;

  let header: unknown;
  let claims: unknown;
  try {
    header = safeJson(decodeBase64Url(headerPart));
    claims = safeJson(decodeBase64Url(payloadPart));
  } catch {
    return null;
  }

  if (!header || typeof header !== 'object' || (header as Record<string, unknown>).alg !== 'HS256') return null;
  if (!claims || typeof claims !== 'object') return null;

  const expected = createHmac('sha256', secret).update(`${headerPart}.${payloadPart}`).digest();
  const supplied = decodeBase64Url(signaturePart);
  if (expected.length !== supplied.length || !timingSafeEqual(expected, supplied)) return null;
  return claims as JwtClaims;
}

function asRole(value: unknown): TenantRole | null {
  return typeof value === 'string' && ROLES.has(value as TenantRole) ? value as TenantRole : null;
}

function audienceMatches(claim: unknown, expected: string): boolean {
  if (!expected) return true;
  if (typeof claim === 'string') return claim === expected;
  return Array.isArray(claim) && claim.some((item) => item === expected);
}

export class TenantAuthorizer {
  private readonly byToken = new Map<string, TenantPrincipal>();
  private readonly jwtSecret = process.env.FLEETOS_JWT_SECRET?.trim() ?? '';
  private readonly issuer = process.env.FLEETOS_JWT_ISSUER?.trim() ?? '';
  private readonly audience = process.env.FLEETOS_JWT_AUDIENCE?.trim() ?? '';
  private readonly allowDevTokens = process.env.FLEETOS_ALLOW_DEV_TOKENS === 'true';

  constructor(rawConfig = process.env.FLEETOS_TENANT_READ_TOKENS_JSON?.trim() ?? '') {
    if (!rawConfig) return;
    const parsed = JSON.parse(rawConfig) as unknown;
    if (!Array.isArray(parsed)) throw new Error('FLEETOS_TENANT_READ_TOKENS_JSON must be a JSON array');

    for (const item of parsed) {
      const entry = item as Partial<TokenConfigEntry>;
      if (!entry.token?.trim() || !entry.companyId?.trim()) {
        throw new Error('tenant token entries require token and companyId');
      }
      const role = entry.role ?? 'manager';
      if (!ROLES.has(role)) throw new Error(`unsupported tenant role: ${String(role)}`);
      this.byToken.set(entry.token.trim(), {
        sub: entry.sub?.trim() || `dev:${entry.companyId.trim()}`,
        companyId: entry.companyId.trim(),
        role,
      });
    }
  }

  authenticate(req: IncomingMessage, now = new Date()): TenantPrincipal | null {
    const header = req.headers.authorization ?? '';
    if (!header.startsWith('Bearer ')) return null;
    const token = header.slice(7).trim();
    if (!token) return null;

    if (this.jwtSecret) {
      const claims = verifyHs256(token, this.jwtSecret);
      if (claims) {
        const sub = typeof claims.sub === 'string' ? claims.sub.trim() : '';
        const companyId = typeof claims.companyId === 'string' ? claims.companyId.trim() : '';
        const role = asRole(claims.role);
        const nowSec = Math.floor(now.getTime() / 1000);
        const exp = typeof claims.exp === 'number' ? claims.exp : null;
        const nbf = typeof claims.nbf === 'number' ? claims.nbf : null;
        const issuerOk = !this.issuer || claims.iss === this.issuer;
        const audienceOk = audienceMatches(claims.aud, this.audience);

        if (sub && companyId && role && issuerOk && audienceOk && (exp === null || exp > nowSec) && (nbf === null || nbf <= nowSec)) {
          return { sub, companyId, role };
        }
      }
    }

    return this.allowDevTokens ? (this.byToken.get(token) ?? null) : null;
  }

  get configuredCount(): number {
    return this.byToken.size;
  }

  get jwtEnabled(): boolean {
    return Boolean(this.jwtSecret);
  }
}
