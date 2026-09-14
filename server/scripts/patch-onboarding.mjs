import { readFile, writeFile } from 'node:fs/promises';

const path = new URL('../src/index.ts', import.meta.url);
let source = await readFile(path, 'utf8');
if (!source.includes("./onboarding.js")) {
  source = source.replace(
    "import { NativeAuthService } from './nativeAuth.js';",
    "import { NativeAuthService } from './nativeAuth.js';\nimport { OnboardingService } from './onboarding.js';\nimport { handleOnboardingRequest } from './onboardingHttp.js';",
  );
}
if (!source.includes('const onboardingService = new OnboardingService(nativeAuth);')) {
  source = source.replace(
    'const nativeAuth = new NativeAuthService();',
    'const nativeAuth = new NativeAuthService();\nconst onboardingService = new OnboardingService(nativeAuth);',
  );
}
if (!source.includes('handleOnboardingRequest(req, res, onboardingService')) {
  source = source.replace(
    "    if (method === 'GET' && url.pathname === '/api/providers') {",
    "    if (await handleOnboardingRequest(req, res, onboardingService, tenantAuthorizer, url.pathname, method)) return;\n\n    if (method === 'GET' && url.pathname === '/api/providers') {",
  );
}
source = source.replace(
  "res.setHeader('access-control-allow-headers', 'Authorization,Content-Type,Accept,X-FleetOS-Company-Id,X-File-Name');",
  "res.setHeader('access-control-allow-headers', 'Authorization,Content-Type,Accept,X-FleetOS-Company-Id,X-File-Name,X-FleetOS-Platform-Admin-Token');",
);
await writeFile(path, source);
