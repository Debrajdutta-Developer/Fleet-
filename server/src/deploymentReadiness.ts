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
  const nativeAuth = postgres && present('FLEETOS_JWT_SECRET');
  const identity = oidc || nativeAuth;
  const s3 = present('FLEETOS_EVIDENCE_S3_BUCKET') && present('FLEETOS_EVIDENCE_S3_REGION');
  const supabaseStorage = present('FLEETOS_EVIDENCE_SUPABASE_URL')
    && present('FLEETOS_EVIDENCE_SUPABASE_BUCKET')
    && present('FLEETOS_EVIDENCE_SUPABASE_SERVICE_ROLE_KEY');
  const durableEvidenceStorage = s3 || supabaseStorage;
  const providerMappings = present('FLEETOS_PROVIDER_MAPPINGS_JSON');
  const webOrigin = present('FLEETOS_WEB_ORIGIN');
  const ingestToken = present('FLEETOS_INGEST_TOKEN');

  const checks: ReadinessCheck[] = [
    {
      key: 'identity', ok: identity, requiredForProduction: true,
      detail: oidc
        ? 'External OIDC/JWKS verification configured.'
        : nativeAuth
          ? 'FleetOS native PostgreSQL/JWT authentication configured.'
          : 'Configure external OIDC or native auth with DATABASE_URL and FLEETOS_JWT_SECRET.',
    },
    {
      key: 'postgres', ok: postgres, requiredForProduction: true,
      detail: postgres ? 'PostgreSQL persistence configured.' : 'DATABASE_URL is missing; only development fallbacks are available.',
    },
    {
      key: 'evidence_object_storage', ok: durableEvidenceStorage, requiredForProduction: true,
      detail: supabaseStorage
        ? 'Supabase Storage evidence backend configured.'
        : s3
          ? 'S3-compatible evidence storage configured.'
          : 'Configure durable Supabase Storage or S3/R2/MinIO evidence storage.',
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
