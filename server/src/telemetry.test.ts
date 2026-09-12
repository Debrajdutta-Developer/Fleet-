import test from 'node:test';
import assert from 'node:assert/strict';
import { normalizeTelemetry, TelemetryStore } from './telemetry.js';

function reading(companyId: string, vehicleId: string, latitude: number) {
  return normalizeTelemetry({
    companyId,
    provider: 'test-provider',
    deviceId: `${companyId}-${vehicleId}`,
    vehicleId,
    recordedAt: '2026-09-12T02:25:00.000Z',
    latitude,
    longitude: 88.3639,
    speedKph: 35,
    ignitionOn: true,
  }, new Date('2026-09-12T02:25:05.000Z'));
}

test('isolates identical vehicle IDs across companies', () => {
  const store = new TelemetryStore();
  store.upsert(reading('company-a', 'WB12AB1234', 22.57));
  store.upsert(reading('company-b', 'WB12AB1234', 23.34));

  assert.equal(store.list('company-a').length, 1);
  assert.equal(store.list('company-b').length, 1);
  assert.equal(store.get('company-a', 'WB12AB1234')?.latitude, 22.57);
  assert.equal(store.get('company-b', 'WB12AB1234')?.latitude, 23.34);
});

test('requires company identity on ingest', () => {
  assert.throws(() => normalizeTelemetry({
    companyId: '', provider: 'x', deviceId: 'd', vehicleId: 'v', recordedAt: '2026-09-12T02:25:00.000Z',
  }), /companyId is required/);
});

test('rejects impossible coordinates instead of clamping them', () => {
  assert.throws(() => normalizeTelemetry({
    companyId: 'company-a', provider: 'x', deviceId: 'd', vehicleId: 'v',
    recordedAt: '2026-09-12T02:25:00.000Z', latitude: 120, longitude: 88,
  }), /latitude is outside valid range/);
});
