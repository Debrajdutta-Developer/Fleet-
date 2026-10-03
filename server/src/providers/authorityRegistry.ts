import type { AuthorityAdapter } from './types.js';

export class AuthorityRegistry {
  private readonly adapters: AuthorityAdapter[] = [];

  register(adapter: AuthorityAdapter): void {
    if (this.adapters.some((existing) => existing.id === adapter.id)) {
      throw new Error(`authority adapter ${adapter.id} is already registered`);
    }
    this.adapters.push(adapter);
  }

  resolve(providerId: string): AuthorityAdapter | undefined {
    return this.adapters.find((adapter) => adapter.canHandle(providerId));
  }

  list(): Array<{ id: string; authoritative: true }> {
    return this.adapters.map((adapter) => ({ id: adapter.id, authoritative: true }));
  }
}
