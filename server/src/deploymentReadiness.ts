export interface ReadinessCheck {
  key: string;
  ok: boolean;
  requiredForProduction: boolean;
  detail: string;
}

export interface DeploymentReadiness {
  readyForProduction: boolean;
  checks: ReadinessCheck[];
}

function present(name: string): boolean {
  return Boolean(process.env[name]?.trim());
}

export function getDeploymentReadiness(): DeploymentReadiness {
  const oidc = present('FLEETOS_OIDC_JWKS_URL') && present('FLEETOS_OIDC_ISSUER') && present('FLEETOS_OIDC_AUDIENCE');
  const postgres = present('DATABASE_URL');
  const s3 = present('FLEETOS_EVIDENCE_S3_BUCKET') && present('FLEETOS_EVIDENCE_S3_REGION');
  const providerMappings = present('FLEETOS_PROVIDER_MAPPINGS_JSON');
  const webOrigin = present('FLEETOS_WEB_ORIGIN');
  const ingestToken = present('FLEETOS_INGEST_TOKEN');

  const checks: ReadinessCheck[] = [
    {
      key: 'oidc', ok: oidc, requiredForProduction: true,
      detail: oidc ? 'External OIDC/JWKS verification configured.' : 'Configure FLEETOS_OIDC_JWKS_URL, FLEETOS_OIDC_ISSUER and FLEETOS_OIDC_AUDIENCE.',
    },
    {
      key: 'postgres', ok: postgres, requiredForProduction: true,
      detail: postgres ? 'PostgreSQL persistence configured.' : 'DATABASE_URL is missing; only development fallbacks are available.',
    },
    {
      key: 'evidence_object_storage', ok: s3, requiredForProduction: true,
      detail: s3 ? 'S3-compatible evidence storage configured.' : 'Configure durable S3/R2/MinIO bucket and region.',
    },
    {
      key: 'web_origin', ok: webOrigin, requiredForProduction: true,
      detail: webOrigin ? 'Exact frontend origin configured.' : 'FLEETOS_WEB_ORIGIN is missing.',
    },
    {
      key: 'telemetry_ingest_secret', ok: ingestToken, requiredForProduction: true,
      detail: ingestToken ? 'Telemetry ingest authentication configured.' : 'FLEETOS_INGEST_TOKEN is missing.',
    },
    {
      key: 'telemetry_provider_mapping', ok: providerMappings, requiredForProduction: false,
      detail: providerMappings ? 'At least one telemetry/provider mapping is configured.' : 'No real telemetry provider configured yet.',
    },
  ];

  return {
    readyForProduction: checks.filter((check) => check.requiredForProduction).every((check) => check.ok),
    checks,
  };
}
