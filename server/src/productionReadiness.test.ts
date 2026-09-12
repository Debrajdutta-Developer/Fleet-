import test from 'node:test';
import assert from 'node:assert/strict';
import { buildProductionReadinessReport } from './productionReadiness.js';

function withEnv(values: Record<string, string | undefined>, fn: () => void): void {
  const previous = new Map<string, string | undefined>();
  for (const [key, value] of Object.entries(values)) {
    previous.set(key, process.env[key]);
    if (value === undefined) delete process.env[key];
    else process.env[key] = value;
  }
  try { fn(); } finally {
    for (const [key, value] of previous) {
      if (value === undefined) delete process.env[key];
      else process.env[key] = value;
    }
  }
}

test('reports ready when durable production dependencies are configured', () => {
  withEnv({
    FLEETOS_JWKS_URL: 'https://id.example/.well-known/jwks.json',
    FLEETOS_JWT_ISSUER: 'https://id.example/',
    FLEETOS_JWT_AUDIENCE: 'fleetos',
    FLEETOS_EVIDENCE_S3_BUCKET: 'fleetos-evidence',
    FLEETOS_EVIDENCE_S3_REGION: 'ap-south-1',
    FLEETOS_INGEST_TOKEN: 'secret',
    FLEETOS_WEB_ORIGIN: 'https://fleet.example',
  }, () => {
    const report = buildProductionReadinessReport({
      telemetryRepositoryKind: 'postgres',
      settlementRepositoryKind: 'postgres',
      evidenceStorageKind: 's3',
      providerCount: 1,
      now: new Date('2026-09-12T00:00:00Z'),
    });
    assert.equal(report.status, 'ready');
    assert.ok(report.checks.every((check) => check.status === 'ready'));
  });
});

test('blocks production when auth or durable persistence is missing', () => {
  withEnv({
    FLEETOS_JWKS_URL: undefined,
    FLEETOS_JWT_ISSUER: undefined,
    FLEETOS_JWT_AUDIENCE: undefined,
    FLEETOS_EVIDENCE_S3_BUCKET: undefined,
    FLEETOS_EVIDENCE_S3_REGION: undefined,
    FLEETOS_INGEST_TOKEN: undefined,
    FLEETOS_WEB_ORIGIN: undefined,
  }, () => {
    const report = buildProductionReadinessReport({
      telemetryRepositoryKind: 'memory',
      settlementRepositoryKind: 'memory',
      evidenceStorageKind: 'local',
      providerCount: 0,
    });
    assert.equal(report.status, 'blocked');
    assert.ok(report.checks.some((check) => check.key === 'identity' && check.status === 'blocked'));
    assert.ok(report.checks.some((check) => check.key === 'telemetry_provider' && check.status === 'degraded'));
  });
});
