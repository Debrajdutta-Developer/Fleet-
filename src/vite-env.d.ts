/// <reference types="vite/client" />

interface ImportMetaEnv {
  readonly VITE_TELEMETRY_API_URL?: string;
  readonly VITE_ENABLE_DEMO_TELEMETRY?: string;
}

interface ImportMeta {
  readonly env: ImportMetaEnv;
}
