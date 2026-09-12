import type { ProviderContext } from './types.js';
import { GenericJsonTelemetryAdapter, type GenericJsonProviderConfig } from './genericJsonAdapter.js';
import { normalizeTelemetry, type NormalizedTelemetry } from '../telemetry.js';

export interface HttpPollingProviderConfig extends GenericJsonProviderConfig {
  endpoint: string;
  method?: 'GET' | 'POST';
  headers?: Record<string, string>;
  body?: unknown;
  timeoutMs?: number;
}

function assertSafeEndpoint(endpoint: string): URL {
  const url = new URL(endpoint);
  if (url.protocol !== 'https:' && !(url.protocol === 'http:' && ['localhost', '127.0.0.1'].includes(url.hostname))) {
    throw new Error('provider endpoint must use HTTPS (HTTP is allowed only for localhost development)');
  }
  return url;
}

export async function pollHttpProvider(
  config: HttpPollingProviderConfig,
  now = new Date(),
): Promise<NormalizedTelemetry[]> {
  const endpoint = assertSafeEndpoint(config.endpoint);
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), config.timeoutMs ?? 10_000);

  try {
    const response = await fetch(endpoint, {
      method: config.method ?? 'GET',
      headers: {
        accept: 'application/json',
        ...(config.body !== undefined ? { 'content-type': 'application/json' } : {}),
        ...(config.headers ?? {}),
      },
      body: config.body === undefined ? undefined : JSON.stringify(config.body),
      signal: controller.signal,
    });

    if (!response.ok) {
      throw new Error(`provider ${config.providerId} returned HTTP ${response.status}`);
    }

    const payload: unknown = await response.json();
    const context: ProviderContext = {
      providerId: config.providerId,
      kind: config.kind ?? 'gps',
      receivedAt: now.toISOString(),
      headers: {},
    };
    const adapter = new GenericJsonTelemetryAdapter(config);
    return adapter.toTelemetry(payload, context).map((reading) => normalizeTelemetry(reading, now));
  } finally {
    clearTimeout(timeout);
  }
}
