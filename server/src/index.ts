import { createServer, type IncomingMessage, type ServerResponse } from 'node:http';
import { normalizeTelemetry, TelemetryStore, type ProviderTelemetryPayload } from './telemetry.js';
import { createTelemetryRepository } from './telemetryRepository.js';
import { registerConfiguredProviders } from './providers/config.js';
import { ProviderRegistry } from './providers/registry.js';
import type { ProviderContext } from './providers/types.js';
import { TenantAuthorizer } from './tenantAuth.js';

const port = Number(process.env.PORT ?? 8787);
const ingestToken = process.env.FLEETOS_INGEST_TOKEN ?? '';
const allowedOrigin = process.env.FLEETOS_WEB_ORIGIN?.trim() ?? '';
const store = new TelemetryStore();
const historyRepository = createTelemetryRepository();
const providerRegistry = new ProviderRegistry();
const tenantAuthorizer = new TenantAuthorizer();
registerConfiguredProviders(providerRegistry);

function applyCors(req: IncomingMessage, res: ServerResponse): void {
  const origin = req.headers.origin;
  if (!origin || !allowedOrigin || origin !== allowedOrigin) return;
  res.setHeader('access-control-allow-origin', origin);
  res.setHeader('vary', 'Origin');
  res.setHeader('access-control-allow-methods', 'GET,POST,OPTIONS');
  res.setHeader('access-control-allow-headers', 'Authorization,Content-Type,Accept,X-FleetOS-Company-Id');
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
        durableHistory: Boolean(process.env.FLEETOS_TELEMETRY_HISTORY_FILE?.trim()),
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

    return sendJson(req, res, 404, { error: 'not found' });
  } catch (error) {
    const message = error instanceof Error ? error.message : 'unknown error';
    return sendJson(req, res, 400, { error: message });
  }
});

server.listen(port, '0.0.0.0', () => {
  console.log(`FleetOS telemetry server listening on ${port}`);
});
