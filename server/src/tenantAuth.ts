import type { IncomingMessage } from 'node:http';

export interface TenantPrincipal {
  companyId: string;
  role: 'owner' | 'manager' | 'dispatcher' | 'driver' | 'accountant' | 'compliance';
}

interface TokenConfigEntry {
  token: string;
  companyId: string;
  role?: TenantPrincipal['role'];
}

export class TenantAuthorizer {
  private readonly byToken = new Map<string, TenantPrincipal>();

  constructor(rawConfig = process.env.FLEETOS_TENANT_READ_TOKENS_JSON?.trim() ?? '') {
    if (!rawConfig) return;
    const parsed = JSON.parse(rawConfig) as unknown;
    if (!Array.isArray(parsed)) throw new Error('FLEETOS_TENANT_READ_TOKENS_JSON must be a JSON array');

    for (const item of parsed) {
      const entry = item as Partial<TokenConfigEntry>;
      if (!entry.token?.trim() || !entry.companyId?.trim()) {
        throw new Error('tenant token entries require token and companyId');
      }
      this.byToken.set(entry.token.trim(), {
        companyId: entry.companyId.trim(),
        role: entry.role ?? 'manager',
      });
    }
  }

  authenticate(req: IncomingMessage): TenantPrincipal | null {
    const header = req.headers.authorization ?? '';
    if (!header.startsWith('Bearer ')) return null;
    return this.byToken.get(header.slice(7).trim()) ?? null;
  }

  get configuredCount(): number {
    return this.byToken.size;
  }
}
