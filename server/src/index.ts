import { createServer, type IncomingMessage, type ServerResponse } from 'node:http';
import { normalizeTelemetry, TelemetryStore, type ProviderTelemetryPayload } from './telemetry.js';
import { createTelemetryRepository } from './telemetryRepository.js';
import { registerConfiguredProviders } from './providers/config.js';
import { ProviderRegistry } from './providers/registry.js';
import type { ProviderContext } from './providers/types.js';
import { TenantAuthorizer, type TenantRole } from './tenantAuth.js';
import { EvidenceStore } from './evidence.js';
import { createSettlementRepository, normalizeSettlementTerms } from './settlementRepository.js';

const port = Number(process.env.PORT ?? 8787);
const ingestToken = process.env.FLEETOS_INGEST_TOKEN ?? '';
const allowedOrigin = process.env.FLEETOS_WEB_ORIGIN?.trim() ?? '';
const store = new TelemetryStore();
const historyRepository = createTelemetryRepository();
const settlementRepository = createSettlementRepository();
const providerRegistry = new ProviderRegistry();
const tenantAuthorizer = new TenantAuthorizer();
const evidenceStore = new EvidenceStore();
registerConfiguredProviders(providerRegistry);

const FINANCE_ROLES = new Set<TenantRole>(['owner', 'manager', 'accountant']);

function applyCors(req: IncomingMessage, res: ServerResponse): void {
  const origin = req.headers.origin;
  if (!origin || !allowedOrigin || origin !== allowedOrigin) return;
  res.setHeader('access-control-allow-origin', origin);
  res.setHeader('vary', 'Origin');
  res.setHeader('access-control-allow-methods', 'GET,POST,PUT,OPTIONS');
  res.setHeader('access-control-allow-headers', 'Authorization,Content-Type,Accept,X-FleetOS-Company-Id,X-File-Name');
  res.setHeader('access-control-max-age', '600');
}

function sendJson(req: IncomingMessage, res: ServerResponse, status: number, body: unknown): void {
  applyCors(req, res);
  res.statusCode = status;
  res.setHeader('content-type', 'application/json; charset=utf-8');
  res.end(JSON.stringify(body));
}

async function readJson(req: IncomingMessage): Promise<unknown> {
  const chunks: Buffer[] = [];
  let total = 0;
  for await (const chunk of req) {
    const buffer = Buffer.isBuffer(chunk) ? chunk : Buffer.from(chunk);
    total += buffer.length;
    if (total > 256 * 1024) throw new Error('payload too large');
    chunks.push(buffer);
  }
  if (chunks.length === 0) return null;
  return JSON.parse(Buffer.concat(chunks).toString('utf8'));
}

function bearerToken(req: IncomingMessage): string {
  const header = req.headers.authorization ?? '';
  return header.startsWith('Bearer ') ? header.slice(7) : '';
}

function providerIdFromPath(pathname: string): string | undefined {
  const prefix = '/api/providers/';
  const suffix = '/ingest';
  if (!pathname.startsWith(prefix) || !pathname.endsWith(suffix)) return undefined;
  const encoded = pathname.slice(prefix.length, -suffix.length);
  if (!encoded) return undefined;
  return decodeURIComponent(encoded);
}

function settlementVehicleIdFromPath(pathname: string): string | undefined {
  const prefix = '/api/finance/settlement-terms/';
  if (!pathname.startsWith(prefix)) return undefined;
  const encoded = pathname.slice(prefix.length);
  if (!encoded || encoded.includes('/')) return undefined;
  return decodeURIComponent(encoded).trim() || undefined;
}

function requestHeaders(req: IncomingMessage): ProviderContext['headers'] {
  return Object.fromEntries(Object.entries(req.headers));
}

function requestedCompanyId(req: IncomingMessage): string {
  const value = req.headers['x-fleetos-company-id'];
  return Array.isArray(value) ? (value[0] ?? '') : (value ?? '');
}

function authorizeTenant(req: IncomingMessage): ReturnType<TenantAuthorizer['authenticate']> {
  const principal = tenantAuthorizer.authenticate(req);
  if (!principal) return null;
  const requested = requestedCompanyId(req);
  if (requested && requested !== principal.companyId) return null;
  return principal;
}

function authorizeFinance(req: IncomingMessage): ReturnType<TenantAuthorizer['authenticate']> {
  const principal = authorizeTenant(req);
  return principal && FINANCE_ROLES.has(principal.role) ? principal : null;
}

async function persistReading(reading: ReturnType<typeof normalizeTelemetry>): Promise<void> {
  store.upsert(reading);
  await historyRepository.append(reading);
}

const server = createServer(async (req, res) => {
  try {
    const method = req.method ?? 'GET';
    const url = new URL(req.url ?? '/', `http://${req.headers.host ?? 'localhost'}`);

    if (method === 'OPTIONS') {
      applyCors(req, res);
      res.statusCode = 204;
      return res.end();
    }

    if (method === 'GET' && url.pathname === '/health') {
      return sendJson(req, res, 200, {
        ok: true,
        service: 'fleetos-telemetry',
        providersConfigured: providerRegistry.list().length,
        tenantReadPrincipalsConfigured: tenantAuthorizer.configuredCount,
        jwtEnabled: tenantAuthorizer.jwtEnabled,
        telemetryHistoryRepository: historyRepository.kind,
        settlementRepository: settlementRepository.kind,
      });
    }

    if (method === 'GET' && url.pathname === '/api/providers') {
      return sendJson(req, res, 200, { providers: providerRegistry.list() });
    }

    if (method === 'POST' && url.pathname === '/api/telemetry/ingest') {
      if (!ingestToken) return sendJson(req, res, 503, { error: 'ingest token is not configured' });
      if (bearerToken(req) !== ingestToken) return sendJson(req, res, 401, { error: 'unauthorized' });
      const raw = await readJson(req);
      const reading = normalizeTelemetry(raw as ProviderTelemetryPayload);
      await persistReading(reading);
      return sendJson(req, res, 202, { accepted: true, reading });
    }

    const providerId = method === 'POST' ? providerIdFromPath(url.pathname) : undefined;
    if (providerId) {
      if (!ingestToken) return sendJson(req, res, 503, { error: 'ingest token is not configured' });
      if (bearerToken(req) !== ingestToken) return sendJson(req, res, 401, { error: 'unauthorized' });

      const adapter = providerRegistry.resolve(providerId);
      if (!adapter) return sendJson(req, res, 404, { error: 'provider adapter is not configured', providerId });

      const raw = await readJson(req);
      const context: ProviderContext = {
        providerId,
        kind: adapter.kind,
        receivedAt: new Date().toISOString(),
        headers: requestHeaders(req),
      };
      const normalized = adapter.toTelemetry(raw, context).map((reading) => normalizeTelemetry(reading));
      for (const reading of normalized) await persistReading(reading);
      return sendJson(req, res, 202, { accepted: true, providerId, count: normalized.length, readings: normalized });
    }

    if (method === 'GET' && url.pathname === '/api/telemetry/live') {
      const principal = authorizeTenant(req);
      if (!principal) return sendJson(req, res, 401, { error: 'unauthorized or tenant scope mismatch' });
      return sendJson(req, res, 200, {
        companyId: principal.companyId,
        vehicles: store.list(principal.companyId),
        generatedAt: new Date().toISOString(),
      });
    }

    if (method === 'GET' && url.pathname.startsWith('/api/telemetry/live/')) {
      const principal = authorizeTenant(req);
      if (!principal) return sendJson(req, res, 401, { error: 'unauthorized or tenant scope mismatch' });
      const vehicleId = decodeURIComponent(url.pathname.slice('/api/telemetry/live/'.length));
      const reading = store.get(principal.companyId, vehicleId);
      return reading
        ? sendJson(req, res, 200, reading)
        : sendJson(req, res, 404, { error: 'no telemetry available for vehicle in this tenant' });
    }

    if (method === 'GET' && url.pathname === '/api/telemetry/history') {
      const principal = authorizeTenant(req);
      if (!principal) return sendJson(req, res, 401, { error: 'unauthorized or tenant scope mismatch' });
      const rows = await historyRepository.history({
        companyId: principal.companyId,
        vehicleId: url.searchParams.get('vehicleId')?.trim() || undefined,
        from: url.searchParams.get('from')?.trim() || undefined,
        to: url.searchParams.get('to')?.trim() || undefined,
        limit: Number(url.searchParams.get('limit') ?? 500),
      });
      return sendJson(req, res, 200, { companyId: principal.companyId, readings: rows, count: rows.length });
    }

    if (method === 'GET' && url.pathname === '/api/finance/settlement-terms') {
      const principal = authorizeFinance(req);
      if (!principal) return sendJson(req, res, 403, { error: 'finance access requires owner, manager or accountant role' });
      const terms = await settlementRepository.list(principal.companyId);
      return sendJson(req, res, 200, { companyId: principal.companyId, terms });
    }

    const settlementVehicleId = settlementVehicleIdFromPath(url.pathname);
    if (settlementVehicleId && (method === 'GET' || method === 'PUT')) {
      const principal = authorizeFinance(req);
      if (!principal) return sendJson(req, res, 403, { error: 'finance access requires owner, manager or accountant role' });

      if (method === 'GET') {
        const terms = await settlementRepository.get(principal.companyId, settlementVehicleId);
        return terms
          ? sendJson(req, res, 200, { terms })
          : sendJson(req, res, 404, { error: 'settlement terms not configured for this vehicle' });
      }

      const raw = await readJson(req);
      const terms = normalizeSettlementTerms(principal.companyId, settlementVehicleId, raw, principal.sub);
      const saved = await settlementRepository.upsert(terms);
      return sendJson(req, res, 200, { terms: saved });
    }

    if (url.pathname.startsWith('/api/trips/') && url.pathname.endsWith('/evidence')) {
      const principal = authorizeTenant(req);
      if (!principal) return sendJson(req, res, 401, { error: 'unauthorized or tenant scope mismatch' });
      const rawTripId = url.pathname.slice('/api/trips/'.length, -'/evidence'.length);
      const tripId = decodeURIComponent(rawTripId).replace(/^\/+|\/+$/g, '');
      if (!tripId) return sendJson(req, res, 400, { error: 'tripId is required' });

      if (method === 'GET') {
        const evidence = await evidenceStore.list(principal.companyId, tripId);
        return sendJson(req, res, 200, { tripId, evidence, count: evidence.length });
      }
      if (method === 'POST') {
        const evidenceType = url.searchParams.get('type')?.trim() || 'other';
        const evidence = await evidenceStore.upload(req, principal, tripId, evidenceType);
        return sendJson(req, res, 201, { accepted: true, evidence });
      }
      return sendJson(req, res, 405, { error: 'method not allowed' });
    }

    return sendJson(req, res, 404, { error: 'not found' });
  } catch (error) {
    const message = error instanceof Error ? error.message : 'unknown error';
    return sendJson(req, res, 400, { error: message });
  }
});

server.listen(port, '0.0.0.0', () => {
  console.log(`FleetOS telemetry server listening on ${port}`);
});
