import test from 'node:test';
import assert from 'node:assert/strict';
import { createServer } from 'node:http';
import type { AddressInfo } from 'node:net';
import type { IncomingMessage } from 'node:http';
import { exportJWK, generateKeyPair, SignJWT } from 'jose';
import { TenantAuthorizer } from './tenantAuth.js';

function requestWithToken(token: string): IncomingMessage {
  return { headers: { authorization: `Bearer ${token}` } } as IncomingMessage;
}

async function withEnv<T>(values: Record<string, string | undefined>, fn: () => Promise<T>): Promise<T> {
  const previous = new Map<string, string | undefined>();
  for (const [key, value] of Object.entries(values)) {
    previous.set(key, process.env[key]);
    if (value === undefined) delete process.env[key];
    else process.env[key] = value;
  }
  try {
    return await fn();
  } finally {
    for (const [key, value] of previous) {
      if (value === undefined) delete process.env[key];
      else process.env[key] = value;
    }
  }
}

test('verifies an external OIDC JWT through remote JWKS and configurable tenant claims', async () => {
  const { publicKey, privateKey } = await generateKeyPair('RS256');
  const jwk = await exportJWK(publicKey);
  jwk.kid = 'fleetos-test-key';
  jwk.alg = 'RS256';
  jwk.use = 'sig';

  const jwksServer = createServer((_req, res) => {
    res.statusCode = 200;
    res.setHeader('content-type', 'application/json');
    res.end(JSON.stringify({ keys: [jwk] }));
  });
  await new Promise<void>((resolve) => jwksServer.listen(0, '127.0.0.1', resolve));

  try {
    const address = jwksServer.address() as AddressInfo;
    const issuer = 'https://identity.fleetos.test/';
    const audience = 'fleetos-web';
    const token = await new SignJWT({ tenant_id: 'company-a', fleet_role: 'manager' })
      .setProtectedHeader({ alg: 'RS256', kid: jwk.kid })
      .setSubject('user-oidc-1')
      .setIssuer(issuer)
      .setAudience(audience)
      .setIssuedAt()
      .setExpirationTime('10m')
      .sign(privateKey);

    await withEnv({
      FLEETOS_JWT_SECRET: undefined,
      FLEETOS_ALLOW_DEV_TOKENS: undefined,
      FLEETOS_OIDC_JWKS_URL: `http://127.0.0.1:${address.port}/jwks.json`,
      FLEETOS_OIDC_ISSUER: issuer,
      FLEETOS_OIDC_AUDIENCE: audience,
      FLEETOS_OIDC_COMPANY_CLAIM: 'tenant_id',
      FLEETOS_OIDC_ROLE_CLAIM: 'fleet_role',
    }, async () => {
      const auth = new TenantAuthorizer();
      assert.equal(auth.oidcEnabled, true);
      assert.deepEqual(await auth.authenticateAsync(requestWithToken(token)), {
        sub: 'user-oidc-1',
        companyId: 'company-a',
        role: 'manager',
      });
    });
  } finally {
    await new Promise<void>((resolve, reject) => jwksServer.close((error) => error ? reject(error) : resolve()));
  }
});
