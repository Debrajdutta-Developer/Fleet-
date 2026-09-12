export type ReadinessStatus = 'ready' | 'degraded' | 'blocked';

export interface ReadinessCheck {
  key: string;
  status: ReadinessStatus;
  message: string;
}

export interface ProductionReadinessReport {
  status: ReadinessStatus;
  checks: ReadinessCheck[];
  generatedAt: string;
}

function envPresent(name: string): boolean {
  return Boolean(process.env[name]?.trim());
}

function oidcConfigured(): boolean {
  return envPresent('FLEETOS_JWKS_URL') && envPresent('FLEETOS_JWT_ISSUER') && envPresent('FLEETOS_JWT_AUDIENCE');
}

function s3Configured(): boolean {
  return envPresent('FLEETOS_EVIDENCE_S3_BUCKET') && envPresent('FLEETOS_EVIDENCE_S3_REGION');
}

function severity(status: ReadinessStatus): number {
  return status === 'blocked' ? 2 : status === 'degraded' ? 1 : 0;
}

export function buildProductionReadinessReport(options: {
  telemetryRepositoryKind: 'memory' | 'jsonl' | 'postgres';
  settlementRepositoryKind: 'memory' | 'postgres';
  evidenceStorageKind: 'local' | 's3';
  providerCount: number;
  now?: Date;
}): ProductionReadinessReport {
  const checks: ReadinessCheck[] = [];

  checks.push(oidcConfigured()
    ? { key: 'identity', status: 'ready', message: 'External OIDC/JWKS verification is configured.' }
    : { key: 'identity', status: 'blocked', message: 'Production OIDC issuer/audience/JWKS configuration is missing.' });

  checks.push(options.telemetryRepositoryKind === 'postgres'
    ? { key: 'telemetry_persistence', status: 'ready', message: 'Telemetry history uses PostgreSQL.' }
    : { key: 'telemetry_persistence', status: 'blocked', message: `Telemetry history is using ${options.telemetryRepositoryKind}; production requires PostgreSQL.` });

  checks.push(options.settlementRepositoryKind === 'postgres'
    ? { key: 'settlement_persistence', status: 'ready', message: 'Settlement terms use PostgreSQL.' }
    : { key: 'settlement_persistence', status: 'blocked', message: 'Settlement terms are not using PostgreSQL.' });

  checks.push(options.evidenceStorageKind === 's3' && s3Configured()
    ? { key: 'evidence_storage', status: 'ready', message: 'Durable S3-compatible evidence storage is configured.' }
    : { key: 'evidence_storage', status: 'blocked', message: 'Evidence storage is not using a configured S3-compatible bucket.' });

  checks.push(options.providerCount > 0
    ? { key: 'telemetry_provider', status: 'ready', message: `${options.providerCount} telemetry provider adapter(s) are configured.` }
    : { key: 'telemetry_provider', status: 'degraded', message: 'No live telemetry provider adapter is configured yet.' });

  checks.push(envPresent('FLEETOS_INGEST_TOKEN')
    ? { key: 'ingest_auth', status: 'ready', message: 'Telemetry ingest authentication secret is configured.' }
    : { key: 'ingest_auth', status: 'blocked', message: 'Telemetry ingest secret is missing.' });

  checks.push(envPresent('FLEETOS_WEB_ORIGIN')
    ? { key: 'cors_origin', status: 'ready', message: 'Exact frontend origin is configured.' }
    : { key: 'cors_origin', status: 'blocked', message: 'Production frontend origin is not configured.' });

  const worst = checks.reduce<ReadinessStatus>((current, check) =>
    severity(check.status) > severity(current) ? check.status : current, 'ready');

  return {
    status: worst,
    checks,
    generatedAt: (options.now ?? new Date()).toISOString(),
  };
}
