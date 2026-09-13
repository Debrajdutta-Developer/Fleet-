import { createHmac, timingSafeEqual } from 'node:crypto';
import type { IncomingMessage } from 'node:http';
import { createRemoteJWKSet, jwtVerify, type JWTPayload } from 'jose';

export type TenantRole = 'owner' | 'manager' | 'dispatcher' | 'driver' | 'khalashi' | 'accountant' | 'compliance';

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

const ROLES = new Set<TenantRole>(['owner', 'manager', 'dispatcher', 'driver', 'khalashi', 'accountant', 'compliance']);

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

function bearer(req: IncomingMessage): string {
  const header = req.headers.authorization ?? '';
  return header.startsWith('Bearer ') ? header.slice(7).trim() : '';
}

function claim(payload: JWTPayload, name: string): unknown {
  return (payload as Record<string, unknown>)[name];
}

export class TenantAuthorizer {
  private readonly byToken = new Map<string, TenantPrincipal>();
  private readonly jwtSecret = process.env.FLEETOS_JWT_SECRET?.trim() ?? '';
  private readonly issuer = process.env.FLEETOS_JWT_ISSUER?.trim() ?? '';
  private readonly audience = process.env.FLEETOS_JWT_AUDIENCE?.trim() ?? '';
  private readonly allowDevTokens = process.env.FLEETOS_ALLOW_DEV_TOKENS === 'true';
  private readonly oidcJwksUrl = process.env.FLEETOS_OIDC_JWKS_URL?.trim() ?? '';
  private readonly oidcIssuer = process.env.FLEETOS_OIDC_ISSUER?.trim() ?? '';
  private readonly oidcAudience = process.env.FLEETOS_OIDC_AUDIENCE?.trim() ?? '';
  private readonly oidcCompanyClaim = process.env.FLEETOS_OIDC_COMPANY_CLAIM?.trim() || 'companyId';
  private readonly oidcRoleClaim = process.env.FLEETOS_OIDC_ROLE_CLAIM?.trim() || 'role';
  private readonly remoteJwks = this.oidcJwksUrl ? createRemoteJWKSet(new URL(this.oidcJwksUrl)) : null;

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
    const token = bearer(req);
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

  async authenticateAsync(req: IncomingMessage, now = new Date()): Promise<TenantPrincipal | null> {
    const local = this.authenticate(req, now);
    if (local) return local;
    const token = bearer(req);
    if (!token || !this.remoteJwks) return null;

    try {
      const { payload } = await jwtVerify(token, this.remoteJwks, {
        issuer: this.oidcIssuer || undefined,
        audience: this.oidcAudience || undefined,
        currentDate: now,
      });
      const sub = typeof payload.sub === 'string' ? payload.sub.trim() : '';
      const companyRaw = claim(payload, this.oidcCompanyClaim);
      const roleRaw = claim(payload, this.oidcRoleClaim);
      const companyId = typeof companyRaw === 'string' ? companyRaw.trim() : '';
      const role = asRole(roleRaw);
      return sub && companyId && role ? { sub, companyId, role } : null;
    } catch {
      return null;
    }
  }

  get configuredCount(): number {
    return this.byToken.size;
  }

  get jwtEnabled(): boolean {
    return Boolean(this.jwtSecret || this.remoteJwks);
  }

  get oidcEnabled(): boolean {
    return Boolean(this.remoteJwks);
  }
}
