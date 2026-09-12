import test from 'node:test';
import assert from 'node:assert/strict';
import { FleetSyncScheduler } from './fleetSyncScheduler.js';
import type { FleetSyncResult } from './companyOnboarding.js';

function result(source = 'registry-test'): FleetSyncResult {
  return {
    discovered: [], updated: [], unchanged: [], missingFromLatestRegistry: [],
    source, syncedAt: '2026-09-12T03:00:00.000Z',
  };
}

test('runs due companies and records a successful sync', async () => {
  let calls = 0;
  const scheduler = new FleetSyncScheduler({
    async syncOwnedFleet(companyId: string) {
      calls += 1;
      assert.equal(companyId, 'company-a');
      return result();
    },
  }, { baseIntervalMs: 60_000, now: () => new Date('2026-09-12T03:00:00.000Z') });

  const states = await scheduler.runDue([{ companyId: 'company-a', enabled: true }]);
  assert.equal(calls, 1);
  assert.equal(states[0]?.status, 'success');
  assert.equal(states[0]?.consecutiveFailures, 0);
});

test('does not run disabled targets', async () => {
  let calls = 0;
  const scheduler = new FleetSyncScheduler({
    async syncOwnedFleet() { calls += 1; return result(); },
  });
  const states = await scheduler.runDue([{ companyId: 'company-a', enabled: false }]);
  assert.equal(calls, 0);
  assert.deepEqual(states, []);
});

test('backs off after failure without erasing prior success metadata', async () => {
  let shouldFail = false;
  let now = new Date('2026-09-12T03:00:00.000Z');
  const scheduler = new FleetSyncScheduler({
    async syncOwnedFleet() {
      if (shouldFail) throw new Error('authority unavailable');
      return result();
    },
  }, { baseIntervalMs: 60_000, maxBackoffMs: 600_000, now: () => now });

  const first = await scheduler.runCompany('company-a');
  assert.equal(first.status, 'success');
  shouldFail = true;
  now = new Date('2026-09-12T03:01:00.000Z');
  const failed = await scheduler.runCompany('company-a');
  assert.equal(failed.status, 'failed');
  assert.equal(failed.consecutiveFailures, 1);
  assert.equal(failed.lastSuccessAt, '2026-09-12T03:00:00.000Z');
  assert.match(failed.lastError ?? '', /authority unavailable/);
});
