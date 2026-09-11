import { createServer, type IncomingMessage, type ServerResponse } from 'node:http';
import { normalizeTelemetry, TelemetryStore, type ProviderTelemetryPayload } from './telemetry.js';

const port = Number(process.env.PORT ?? 8787);
const ingestToken = process.env.FLEETOS_INGEST_TOKEN ?? '';
const allowedOrigin = process.env.FLEETOS_WEB_ORIGIN?.trim() ?? '';
const store = new TelemetryStore();

function applyCors(req: IncomingMessage, res: ServerResponse): void {
  const origin = req.headers.origin;
  if (!origin || !allowedOrigin || origin !== allowedOrigin) return;

  res.setHeader('access-control-allow-origin', origin);
  res.setHeader('vary', 'Origin');
  res.setHeader('access-control-allow-methods', 'GET,POST,OPTIONS');
  res.setHeader('access-control-allow-headers', 'Authorization,Content-Type,Accept');
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
      return sendJson(req, res, 200, { ok: true, service: 'fleetos-telemetry' });
    }

    if (method === 'POST' && url.pathname === '/api/telemetry/ingest') {
      if (!ingestToken) return sendJson(req, res, 503, { error: 'ingest token is not configured' });
      if (bearerToken(req) !== ingestToken) return sendJson(req, res, 401, { error: 'unauthorized' });

      const raw = await readJson(req);
      const reading = normalizeTelemetry(raw as ProviderTelemetryPayload);
      store.upsert(reading);
      return sendJson(req, res, 202, { accepted: true, reading });
    }

    if (method === 'GET' && url.pathname === '/api/telemetry/live') {
      return sendJson(req, res, 200, { vehicles: store.list(), generatedAt: new Date().toISOString() });
    }

    if (method === 'GET' && url.pathname.startsWith('/api/telemetry/live/')) {
      const vehicleId = decodeURIComponent(url.pathname.slice('/api/telemetry/live/'.length));
      const reading = store.get(vehicleId);
      return reading
        ? sendJson(req, res, 200, reading)
        : sendJson(req, res, 404, { error: 'no telemetry available for vehicle' });
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
