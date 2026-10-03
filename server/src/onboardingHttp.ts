import type { IncomingMessage, ServerResponse } from 'node:http';
import type { TenantAuthorizer } from './tenantAuth.js';
import { authorizeTenantRequest } from './httpAuthorization.js';
import type { OnboardingService } from './onboarding.js';

async function readJson(req: IncomingMessage): Promise<unknown> {
  const chunks: Buffer[] = [];
  let total = 0;
  for await (const chunk of req) {
    const buffer = Buffer.isBuffer(chunk) ? chunk : Buffer.from(chunk);
    total += buffer.length;
    if (total > 256 * 1024) throw new Error('payload too large');
    chunks.push(buffer);
  }
  return chunks.length ? JSON.parse(Buffer.concat(chunks).toString('utf8')) : null;
}

function send(req: IncomingMessage, res: ServerResponse, status: number, body: unknown): true {
  const allowedOrigin = process.env.FLEETOS_WEB_ORIGIN?.trim() ?? '';
  const origin = req.headers.origin;
  if (origin && allowedOrigin && origin === allowedOrigin) {
    res.setHeader('access-control-allow-origin', origin);
    res.setHeader('vary', 'Origin');
  }
  res.statusCode = status;
  res.setHeader('content-type', 'application/json; charset=utf-8');
  res.end(JSON.stringify(body));
  return true;
}

function adminToken(req: IncomingMessage): string {
  const value = req.headers['x-fleetos-platform-admin-token'];
  return Array.isArray(value) ? value[0] ?? '' : value ?? '';
}

export async function handleOnboardingRequest(
  req: IncomingMessage,
  res: ServerResponse,
  service: OnboardingService,
  authorizer: TenantAuthorizer,
  pathname: string,
  method: string,
): Promise<boolean> {
  try {
    if (method === 'POST' && pathname === '/api/onboarding/companies') {
      const application = await service.submitCompany(await readJson(req));
      send(req, res, 201, { application });
      return true;
    }
    if (method === 'POST' && pathname === '/api/onboarding/drivers') {
      const driver = await service.registerDriver(await readJson(req));
      send(req, res, 201, { driver });
      return true;
    }
    if (method === 'POST' && pathname === '/api/onboarding/activate-owner') {
      const account = await service.activateOwner(await readJson(req));
      send(req, res, 201, { account });
      return true;
    }
    if (method === 'POST' && pathname === '/api/onboarding/link-driver') {
      const authorization = await authorizeTenantRequest(req, authorizer);
      if (!authorization.ok) { send(req, res, authorization.status, { error: authorization.error }); return true; }
      const driver = await service.linkDriver(await readJson(req), authorization.principal);
      send(req, res, 200, { driver });
      return true;
    }
    if (method === 'GET' && pathname === '/api/platform/applications') {
      const applications = await service.listApplications(adminToken(req));
      send(req, res, 200, { applications });
      return true;
    }
    const match = pathname.match(/^\/api\/platform\/applications\/([^/]+)\/approve$/);
    if (method === 'POST' && match) {
      const approval = await service.approveApplication(decodeURIComponent(match[1]), adminToken(req));
      send(req, res, 200, {
        approval,
        delivery: {
          status: 'manual_pending_email_provider',
          note: 'Send the activation link/token through an approved email provider; FleetOS never emails plaintext passwords.',
        },
      });
      return true;
    }
    return false;
  } catch (error) {
    const message = error instanceof Error ? error.message : 'onboarding request failed';
    const status = message.includes('authorization required') ? 403 : message.includes('not found') ? 404 : 400;
    send(req, res, status, { error: message });
    return true;
  }
}
