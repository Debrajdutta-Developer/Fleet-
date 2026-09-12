import type { FleetSyncResult } from './companyOnboarding.js';

export interface FleetSyncTarget {
  companyId: string;
  enabled: boolean;
}

export interface FleetSyncRunner {
  syncOwnedFleet(companyId: string): Promise<FleetSyncResult>;
}

export interface FleetSyncRunState {
  companyId: string;
  status: 'idle' | 'running' | 'success' | 'failed';
  startedAt?: string;
  finishedAt?: string;
  lastSuccessAt?: string;
  consecutiveFailures: number;
  nextEligibleAt?: string;
  lastError?: string;
  lastResult?: {
    discovered: number;
    updated: number;
    unchanged: number;
    missingFromLatestRegistry: number;
    source: string;
    syncedAt: string;
  };
}

export interface FleetSyncSchedulerOptions {
  baseIntervalMs?: number;
  maxBackoffMs?: number;
  now?: () => Date;
}

export class FleetSyncScheduler {
  private readonly states = new Map<string, FleetSyncRunState>();
  private readonly inFlight = new Set<string>();
  private readonly baseIntervalMs: number;
  private readonly maxBackoffMs: number;
  private readonly now: () => Date;

  constructor(private readonly runner: FleetSyncRunner, options: FleetSyncSchedulerOptions = {}) {
    this.baseIntervalMs = Math.max(60_000, options.baseIntervalMs ?? 6 * 60 * 60 * 1000);
    this.maxBackoffMs = Math.max(this.baseIntervalMs, options.maxBackoffMs ?? 24 * 60 * 60 * 1000);
    this.now = options.now ?? (() => new Date());
  }

  getState(companyId: string): FleetSyncRunState {
    return this.states.get(companyId) ?? {
      companyId,
      status: 'idle',
      consecutiveFailures: 0,
    };
  }

  listStates(): FleetSyncRunState[] {
    return [...this.states.values()].map((state) => ({ ...state }));
  }

  async runDue(targets: FleetSyncTarget[]): Promise<FleetSyncRunState[]> {
    const results: FleetSyncRunState[] = [];
    for (const target of targets) {
      if (!target.enabled) continue;
      if (!this.isDue(target.companyId)) continue;
      results.push(await this.runCompany(target.companyId));
    }
    return results;
  }

  async runCompany(companyId: string): Promise<FleetSyncRunState> {
    if (this.inFlight.has(companyId)) return this.getState(companyId);

    const started = this.now();
    this.inFlight.add(companyId);
    const previous = this.getState(companyId);
    this.states.set(companyId, {
      ...previous,
      companyId,
      status: 'running',
      startedAt: started.toISOString(),
      lastError: undefined,
    });

    try {
      const result = await this.runner.syncOwnedFleet(companyId);
      const finished = this.now();
      const state: FleetSyncRunState = {
        companyId,
        status: 'success',
        startedAt: started.toISOString(),
        finishedAt: finished.toISOString(),
        lastSuccessAt: finished.toISOString(),
        consecutiveFailures: 0,
        nextEligibleAt: new Date(finished.getTime() + this.baseIntervalMs).toISOString(),
        lastResult: {
          discovered: result.discovered.length,
          updated: result.updated.length,
          unchanged: result.unchanged.length,
          missingFromLatestRegistry: result.missingFromLatestRegistry.length,
          source: result.source,
          syncedAt: result.syncedAt,
        },
      };
      this.states.set(companyId, state);
      return state;
    } catch (error) {
      const finished = this.now();
      const failures = previous.consecutiveFailures + 1;
      const backoff = Math.min(this.maxBackoffMs, this.baseIntervalMs * 2 ** Math.min(failures - 1, 8));
      const state: FleetSyncRunState = {
        ...previous,
        companyId,
        status: 'failed',
        startedAt: started.toISOString(),
        finishedAt: finished.toISOString(),
        consecutiveFailures: failures,
        nextEligibleAt: new Date(finished.getTime() + backoff).toISOString(),
        lastError: error instanceof Error ? error.message : 'owned-fleet sync failed',
      };
      this.states.set(companyId, state);
      return state;
    } finally {
      this.inFlight.delete(companyId);
    }
  }

  private isDue(companyId: string): boolean {
    if (this.inFlight.has(companyId)) return false;
    const next = this.states.get(companyId)?.nextEligibleAt;
    if (!next) return true;
    return Date.parse(next) <= this.now().getTime();
  }
}
