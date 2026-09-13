import { createServer, type IncomingMessage, type ServerResponse } from 'node:http';
import { normalizeTelemetry, TelemetryStore, type ProviderTelemetryPayload } from './telemetry.js';
import { createTelemetryRepository } from './telemetryRepository.js';
import { registerConfiguredProviders } from './providers/config.js';
import { ProviderRegistry } from './providers/registry.js';
import type { ProviderContext } from './providers/types.js';
import { TenantAuthorizer, type TenantRole } from './tenantAuth.js';
import { authorizeRoleRequest, authorizeTenantRequest } from './httpAuthorization.js';
import { EvidenceStore } from './evidence.js';
import { createSettlementRepository, normalizeSettlementTerms } from './settlementRepository.js';
import { createTripAccessRepository, normalizeTripAssignment } from './tripAccessRepository.js';
import { getDeploymentReadiness } from './deploymentReadiness.js';
import { NativeAuthService } from './nativeAuth.js';

const port = Number(process.env.PORT ?? 8787);
const ingestToken = process.env.FLEETOS_INGEST_TOKEN ?? '';
const allowedOrigin = process.env.FLEETOS_WEB_ORIGIN?.trim() ?? '';
const store = new TelemetryStore();
const historyRepository = createTelemetryRepository();
const settlementRepository = createSettlementRepository();
const tripAccessRepository = createTripAccessRepository();
const providerRegistry = new ProviderRegistry();
const tenantAuthorizer = new TenantAuthorizer();
const evidenceStore = new EvidenceStore();
const nativeAuth = new NativeAuthService();
registerConfiguredProviders(providerRegistry);

const FINANCE_ROLES = new Set<TenantRole>(['owner', 'manager', 'accountant']);
const ASSIGNMENT_ROLES = new Set<TenantRole>(['owner', 'manager', 'dispatcher']);
const RESTRICTED_WORKER_ROLES = new Set<TenantRole>(['driver', 'khalashi']);

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

function tripIdFromAssignmentPath(pathname: string): string | undefined {
  const prefix = '/api/trips/';
  const suffix = '/assignment';
  if (!pathname.startsWith(prefix) || !pathname.endsWith(suffix)) return undefined;
  const encoded = pathname.slice(prefix.length, -suffix.length).replace(/^\/+|\/+$/g, '');
  if (!encoded || encoded.includes('/')) return undefined;
  return decodeURIComponent(encoded).trim() || undefined;
}

function requestHeaders(req: IncomingMessage): ProviderContext['headers'] {
  return Object.fromEntries(Object.entries(req.headers));
}

function isRestrictedWorker(role: TenantRole): boolean {
  return RESTRICTED_WORKER_ROLES.has(role);
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
        oidcEnabled: tenantAuthorizer.oidcEnabled,
        nativeAuthEnabled: nativeAuth.enabled,
        telemetryHistoryRepository: historyRepository.kind,
        settlementRepository: settlementRepository.kind,
        tripAccessRepository: tripAccessRepository.kind,
        evidenceStorage: evidenceStore.storageKind,
      });
    }

    if (method === 'GET' && url.pathname === '/ready') {
      const readiness = getDeploymentReadiness();
      return sendJson(req, res, readiness.readyForProduction ? 200 : 503, readiness);
    }

    if (method === 'GET' && url.pathname === '/api/providers') {
      return sendJson(req, res, 200, { providers: providerRegistry.list() });
    }

    if (method === 'POST' && url.pathname === '/api/auth/login') {
      try {
        const session = await nativeAuth.login(await readJson(req));
        return sendJson(req, res, 200, session);
      } catch (error) {
        const message = error instanceof Error ? error.message : 'sign-in failed';
        const unavailable = message.includes('not configured');
        return sendJson(req, res, unavailable ? 503 : 401, { error: message });
      }
    }

    if (url.pathname === '/api/auth/users' && (method === 'GET' || method === 'POST')) {
      const authorization = await authorizeTenantRequest(req, tenantAuthorizer);
      if (!authorization.ok) return sendJson(req, res, authorization.status, { error: authorization.error });

      if (method === 'GET') {
        if (authorization.principal.role !== 'owner' && authorization.principal.role !== 'manager') {
          return sendJson(req, res, 403, { error: 'user directory requires owner or manager role' });
        }
        const users = await nativeAuth.listUsers(authorization.principal);
        return sendJson(req, res, 200, { companyId: authorization.principal.companyId, users });
      }

      if (authorization.principal.role !== 'owner') {
        return sendJson(req, res, 403, { error: 'only an owner can create FleetOS users' });
      }
      const user = await nativeAuth.createUser(await readJson(req), authorization.principal);
      return sendJson(req, res, 201, { user });
    }

    if (method === 'GET' && url.pathname === '/api/me') {
      const authorization = await authorizeTenantRequest(req, tenantAuthorizer);
      if (!authorization.ok) return sendJson(req, res, authorization.status, { error: authorization.error });
      const { sub, companyId, role } = authorization.principal;
      return sendJson(req, res, 200, { principal: { sub, companyId, role } });
    }

    if (method === 'GET' && url.pathname === '/api/me/trips') {
      const authorization = await authorizeTenantRequest(req, tenantAuthorizer);
      if (!authorization.ok) return sendJson(req, res, authorization.status, { error: authorization.error });
      const assignments = await tripAccessRepository.listForPrincipal(authorization.principal);
      return sendJson(req, res, 200, {
        companyId: authorization.principal.companyId,
        trips: assignments.map(({ tripId, vehicleId, updatedAt }) => ({ tripId, vehicleId, updatedAt })),
      });
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
      const authorization = await authorizeTenantRequest(req, tenantAuthorizer);
      if (!authorization.ok) return sendJson(req, res, authorization.status, { error: authorization.error });
      let vehicles = store.list(authorization.principal.companyId);
      if (isRestrictedWorker(authorization.principal.role)) {
        const assignments = await tripAccessRepository.listForPrincipal(authorization.principal);
        const allowedVehicleIds = new Set(assignments.map((row) => row.vehicleId).filter((id): id is string => Boolean(id)));
        vehicles = vehicles.filter((reading) => allowedVehicleIds.has(reading.vehicleId));
      }
      return sendJson(req, res, 200, {
        companyId: authorization.principal.companyId,
        vehicles,
        generatedAt: new Date().toISOString(),
      });
    }

    if (method === 'GET' && url.pathname.startsWith('/api/telemetry/live/')) {
      const authorization = await authorizeTenantRequest(req, tenantAuthorizer);
      if (!authorization.ok) return sendJson(req, res, authorization.status, { error: authorization.error });
      const vehicleId = decodeURIComponent(url.pathname.slice('/api/telemetry/live/'.length));
      if (isRestrictedWorker(authorization.principal.role)) {
        const allowed = await tripAccessRepository.canAccessVehicle(authorization.principal, vehicleId);
        if (!allowed) return sendJson(req, res, 404, { error: 'vehicle not found' });
      }
      const reading = store.get(authorization.principal.companyId, vehicleId);
      return reading
        ? sendJson(req, res, 200, reading)
        : sendJson(req, res, 404, { error: 'no telemetry available for vehicle in this tenant' });
    }

    if (method === 'GET' && url.pathname === '/api/telemetry/history') {
      const authorization = await authorizeTenantRequest(req, tenantAuthorizer);
      if (!authorization.ok) return sendJson(req, res, authorization.status, { error: authorization.error });
      const vehicleId = url.searchParams.get('vehicleId')?.trim() || undefined;
      if (isRestrictedWorker(authorization.principal.role)) {
        if (!vehicleId) return sendJson(req, res, 403, { error: 'worker telemetry history requires an assigned vehicle' });
        const allowed = await tripAccessRepository.canAccessVehicle(authorization.principal, vehicleId);
        if (!allowed) return sendJson(req, res, 404, { error: 'vehicle not found' });
      }
      const rows = await historyRepository.history({
        companyId: authorization.principal.companyId,
        vehicleId,
        from: url.searchParams.get('from')?.trim() || undefined,
        to: url.searchParams.get('to')?.trim() || undefined,
        limit: Number(url.searchParams.get('limit') ?? 500),
      });
      return sendJson(req, res, 200, { companyId: authorization.principal.companyId, readings: rows, count: rows.length });
    }

    if (method === 'GET' && url.pathname === '/api/finance/settlement-terms') {
      const authorization = await authorizeRoleRequest(
        req,
        tenantAuthorizer,
        FINANCE_ROLES,
        'finance access requires owner, manager or accountant role',
      );
      if (!authorization.ok) return sendJson(req, res, authorization.status, { error: authorization.error });
      const terms = await settlementRepository.list(authorization.principal.companyId);
      return sendJson(req, res, 200, { companyId: authorization.principal.companyId, terms });
    }

    const settlementVehicleId = settlementVehicleIdFromPath(url.pathname);
    if (settlementVehicleId && (method === 'GET' || method === 'PUT')) {
      const authorization = await authorizeRoleRequest(
        req,
        tenantAuthorizer,
        FINANCE_ROLES,
        'finance access requires owner, manager or accountant role',
      );
      if (!authorization.ok) return sendJson(req, res, authorization.status, { error: authorization.error });

      if (method === 'GET') {
        const terms = await settlementRepository.get(authorization.principal.companyId, settlementVehicleId);
        return terms
          ? sendJson(req, res, 200, { terms })
          : sendJson(req, res, 404, { error: 'settlement terms not configured for this vehicle' });
      }

      const raw = await readJson(req);
      const terms = normalizeSettlementTerms(authorization.principal.companyId, settlementVehicleId, raw, authorization.principal.sub);
      const saved = await settlementRepository.upsert(terms);
      return sendJson(req, res, 200, { terms: saved });
    }

    const assignmentTripId = tripIdFromAssignmentPath(url.pathname);
    if (assignmentTripId && (method === 'GET' || method === 'PUT')) {
      const authorization = await authorizeRoleRequest(
        req,
        tenantAuthorizer,
        ASSIGNMENT_ROLES,
        'trip assignment access requires owner, manager or dispatcher role',
      );
      if (!authorization.ok) return sendJson(req, res, authorization.status, { error: authorization.error });

      if (method === 'GET') {
        const assignment = await tripAccessRepository.get(authorization.principal.companyId, assignmentTripId);
        return assignment
          ? sendJson(req, res, 200, { assignment })
          : sendJson(req, res, 404, { error: 'trip assignment not found' });
      }

      const raw = await readJson(req) as Record<string, unknown> | null;
      const assignment = normalizeTripAssignment(
        authorization.principal.companyId,
        assignmentTripId,
        {
          vehicleId: typeof raw?.vehicleId === 'string' ? raw.vehicleId : undefined,
          driverSubject: typeof raw?.driverSubject === 'string' ? raw.driverSubject : undefined,
          khalashiSubject: typeof raw?.khalashiSubject === 'string' ? raw.khalashiSubject : undefined,
        },
        authorization.principal.sub,
      );
      const saved = await tripAccessRepository.upsert(assignment);
      return sendJson(req, res, 200, { assignment: saved });
    }

    if (url.pathname.startsWith('/api/trips/') && url.pathname.endsWith('/evidence')) {
      const authorization = await authorizeTenantRequest(req, tenantAuthorizer);
      if (!authorization.ok) return sendJson(req, res, authorization.status, { error: authorization.error });
      const rawTripId = url.pathname.slice('/api/trips/'.length, -'/evidence'.length);
      const tripId = decodeURIComponent(rawTripId).replace(/^\/+|\/+$/g, '');
      if (!tripId) return sendJson(req, res, 400, { error: 'tripId is required' });

      const canAccessTrip = await tripAccessRepository.canAccess(authorization.principal, tripId);
      if (!canAccessTrip) {
        return sendJson(req, res, 404, { error: 'trip not found' });
      }

      if (method === 'GET') {
        const evidence = await evidenceStore.list(authorization.principal.companyId, tripId);
        return sendJson(req, res, 200, { tripId, evidence, count: evidence.length });
      }
      if (method === 'POST') {
        const evidenceType = url.searchParams.get('type')?.trim() || 'other';
        const evidence = await evidenceStore.upload(req, authorization.principal, tripId, evidenceType);
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

async function start(): Promise<void> {
  try {
    const created = await nativeAuth.bootstrapFromEnv();
    if (created) console.log('FleetOS native auth bootstrap owner created');
  } catch (error) {
    console.error('FleetOS native auth bootstrap failed:', error);
    process.exitCode = 1;
    return;
  }

  server.listen(port, '0.0.0.0', () => {
    console.log(`FleetOS telemetry server listening on ${port}`);
  });
}

void start();