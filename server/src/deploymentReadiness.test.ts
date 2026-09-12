import test from 'node:test';
import assert from 'node:assert/strict';
import { getDeploymentReadiness } from './deploymentReadiness.js';

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

test('production readiness requires OIDC, Postgres, S3, exact origin and ingest auth', () => {
  withEnv({
    FLEETOS_OIDC_JWKS_URL: 'https://id.example/jwks.json',
    FLEETOS_OIDC_ISSUER: 'https://id.example/',
    FLEETOS_OIDC_AUDIENCE: 'fleetos',
    DATABASE_URL: 'postgresql://example',
    FLEETOS_EVIDENCE_S3_BUCKET: 'fleetos-evidence',
    FLEETOS_EVIDENCE_S3_REGION: 'ap-south-1',
    FLEETOS_WEB_ORIGIN: 'https://fleet.example',
    FLEETOS_INGEST_TOKEN: 'secret',
    FLEETOS_PROVIDER_MAPPINGS_JSON: undefined,
  }, () => {
    const report = getDeploymentReadiness();
    assert.equal(report.readyForProduction, true);
    assert.equal(report.checks.find((c) => c.key === 'telemetry_provider_mapping')?.requiredForProduction, false);
  });
});

test('production readiness fails closed when durable or identity config is missing', () => {
  withEnv({
    FLEETOS_OIDC_JWKS_URL: undefined,
    FLEETOS_OIDC_ISSUER: undefined,
    FLEETOS_OIDC_AUDIENCE: undefined,
    DATABASE_URL: undefined,
    FLEETOS_EVIDENCE_S3_BUCKET: undefined,
    FLEETOS_EVIDENCE_S3_REGION: undefined,
    FLEETOS_WEB_ORIGIN: undefined,
    FLEETOS_INGEST_TOKEN: undefined,
  }, () => {
    const report = getDeploymentReadiness();
    assert.equal(report.readyForProduction, false);
    assert.ok(report.checks.filter((c) => c.requiredForProduction).some((c) => !c.ok));
  });
});
