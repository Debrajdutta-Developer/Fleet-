import { GenericJsonTelemetryAdapter, type GenericJsonProviderConfig } from './genericJsonAdapter.js';
import type { ProviderRegistry } from './registry.js';

export function registerConfiguredProviders(registry: ProviderRegistry): void {
  const raw = process.env.FLEETOS_PROVIDER_MAPPINGS_JSON?.trim();
  if (!raw) return;

  const parsed = JSON.parse(raw) as unknown;
  if (!Array.isArray(parsed)) {
    throw new Error('FLEETOS_PROVIDER_MAPPINGS_JSON must be a JSON array');
  }

  for (const entry of parsed) {
    if (!entry || typeof entry !== 'object') {
      throw new Error('each provider mapping must be an object');
    }
    const config = entry as GenericJsonProviderConfig;
    if (!config.providerId || !config.map) {
      throw new Error('provider mapping requires providerId and map');
    }
    registry.register(new GenericJsonTelemetryAdapter(config));
  }
}
