import test from 'node:test';
import assert from 'node:assert/strict';
import { GenericJsonTelemetryAdapter } from './genericJsonAdapter.js';

const context = {
  providerId: 'vendor-x',
  kind: 'gps' as const,
  receivedAt: '2026-09-12T01:30:00.000Z',
  headers: {},
};

const baseConfig = {
  providerId: 'vendor-x',
  companyId: 'comp-india-001',
};

test('maps nested provider fields, binds tenant and converts units', () => {
  const adapter = new GenericJsonTelemetryAdapter({
    ...baseConfig,
    kind: 'gps',
    map: {
      deviceId: 'device.imei', vehicleId: 'vehicle.number', recordedAt: 'gps.time',
      latitude: 'gps.lat', longitude: 'gps.lng',
      speedKph: { path: 'gps.speedMph', multiply: 1.609344 },
      odometerKm: { path: 'vehicle.odometerMetres', multiply: 0.001 },
      fuelLevelPercent: 'fuel.percent', ignitionOn: 'engine.ignition',
      grossWeightKg: { path: 'load.grossTonnes', multiply: 1000 },
      tareWeightKg: { path: 'load.tareTonnes', multiply: 1000 },
    },
  });

  const [reading] = adapter.toTelemetry({
    device: { imei: '123456789012345' },
    vehicle: { number: 'WB12AB1234', odometerMetres: 123456000 },
    gps: { time: '2026-09-12T01:29:55.000Z', lat: 22.5726, lng: 88.3639, speedMph: 40 },
    fuel: { percent: 62.5 }, engine: { ignition: 'on' },
    load: { grossTonnes: 46.2, tareTonnes: 15.1 },
  }, context);

  assert.equal(reading.companyId, 'comp-india-001');
  assert.equal(reading.provider, 'vendor-x');
  assert.equal(reading.vehicleId, 'WB12AB1234');
  assert.ok(Math.abs((reading.speedKph ?? 0) - 64.37376) < 0.00001);
  assert.equal(reading.odometerKm, 123456);
  assert.equal(reading.grossWeightKg, 46200);
  assert.equal(reading.tareWeightKg, 15100);
});

test('does not invent optional telemetry values when provider omits them', () => {
  const adapter = new GenericJsonTelemetryAdapter({
    ...baseConfig,
    map: { deviceId: 'imei', vehicleId: 'vehicle', recordedAt: 'time' },
  });
  const [reading] = adapter.toTelemetry({ imei: 'imei-1', vehicle: 'WB01AA0001', time: '2026-09-12T01:29:55.000Z' }, context);
  assert.equal(reading.latitude, undefined);
  assert.equal(reading.fuelLevelPercent, undefined);
  assert.equal(reading.netLoadKg, undefined);
});

test('fails closed when identity or timestamp fields are missing', () => {
  const adapter = new GenericJsonTelemetryAdapter({
    ...baseConfig,
    map: { deviceId: 'imei', vehicleId: 'vehicle', recordedAt: 'time' },
  });
  assert.throws(() => adapter.toTelemetry({ imei: 'imei-1' }, context), /missing deviceId, vehicleId, or recordedAt/);
});

test('fails closed when provider is not bound to a tenant', () => {
  assert.throws(() => new GenericJsonTelemetryAdapter({
    providerId: 'vendor-x', companyId: '',
    map: { deviceId: 'imei', vehicleId: 'vehicle', recordedAt: 'time' },
  }), /companyId/);
});
