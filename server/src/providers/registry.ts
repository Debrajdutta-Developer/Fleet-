import type { ProviderAdapter } from './types.js';

export class ProviderRegistry {
  private readonly adapters: ProviderAdapter[] = [];

  register(adapter: ProviderAdapter): void {
    if (this.adapters.some((existing) => existing.id === adapter.id)) {
      throw new Error(`provider adapter ${adapter.id} is already registered`);
    }
    this.adapters.push(adapter);
  }

  resolve(providerId: string): ProviderAdapter | undefined {
    return this.adapters.find((adapter) => adapter.canHandle(providerId));
  }

  list(): Array<{
    id: string;
    kind: ProviderAdapter['kind'];
    transports: readonly string[];
    authoritative: boolean;
  }> {
    return this.adapters.map((adapter) => ({
      id: adapter.id,
      kind: adapter.kind,
      transports: adapter.transports,
      authoritative: adapter.authoritative,
    }));
  }
}
