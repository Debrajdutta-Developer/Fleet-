import test from 'node:test';
import assert from 'node:assert/strict';
import { InMemoryTelemetryRepository, normalizeTelemetryHistoryQuery } from './telemetryRepository.js';
import type { NormalizedTelemetry } from './telemetry.js';

function reading(companyId: string, vehicleId: string, recordedAt: string): NormalizedTelemetry {
  return {
    companyId,
    provider: 'test-provider',
    deviceId: `${vehicleId}-device`,
    vehicleId,
    recordedAt,
    receivedAt: recordedAt,
    speedKph: 20,
    motionState: 'moving',
    freshness: 'live',
  };
}

test('history is tenant isolated and ordered newest first', async () => {
  const repo = new InMemoryTelemetryRepository();
  await repo.append(reading('comp-a', 'veh-1', '2026-09-12T01:00:00Z'));
  await repo.append(reading('comp-b', 'veh-1', '2026-09-12T01:10:00Z'));
  await repo.append(reading('comp-a', 'veh-2', '2026-09-12T01:20:00Z'));

  const rows = await repo.history({ companyId: 'comp-a' });
  assert.equal(rows.length, 2);
  assert.equal(rows[0].vehicleId, 'veh-2');
  assert.equal(rows[1].vehicleId, 'veh-1');
  assert.ok(rows.every((row) => row.companyId === 'comp-a'));
});

test('history supports vehicle, time range and limit filters', async () => {
  const repo = new InMemoryTelemetryRepository();
  await repo.append(reading('comp-a', 'veh-1', '2026-09-12T01:00:00Z'));
  await repo.append(reading('comp-a', 'veh-1', '2026-09-12T01:10:00Z'));
  await repo.append(reading('comp-a', 'veh-1', '2026-09-12T01:20:00Z'));
  await repo.append(reading('comp-a', 'veh-2', '2026-09-12T01:30:00Z'));

  const rows = await repo.history({
    companyId: 'comp-a',
    vehicleId: 'veh-1',
    from: '2026-09-12T01:05:00Z',
    to: '2026-09-12T01:25:00Z',
    limit: 1,
  });

  assert.equal(rows.length, 1);
  assert.equal(rows[0].vehicleId, 'veh-1');
  assert.equal(rows[0].recordedAt, '2026-09-12T01:20:00Z');
});

test('history query rejects invalid timestamps and non-finite limits', () => {
  assert.throws(() => normalizeTelemetryHistoryQuery({ companyId: 'comp-a', from: 'not-a-date' }), /from must be a valid timestamp/);
  assert.throws(() => normalizeTelemetryHistoryQuery({ companyId: 'comp-a', limit: Number.NaN }), /limit must be a finite number/);
  assert.throws(() => normalizeTelemetryHistoryQuery({ companyId: 'comp-a', from: '2026-09-12T02:00:00Z', to: '2026-09-12T01:00:00Z' }), /from must not be after to/);
});

test('history query clamps finite limits to safe bounds', () => {
  assert.equal(normalizeTelemetryHistoryQuery({ companyId: 'comp-a', limit: 999999 }).limit, 5000);
  assert.equal(normalizeTelemetryHistoryQuery({ companyId: 'comp-a', limit: 0 }).limit, 1);
});
