import test from 'node:test';
import assert from 'node:assert/strict';
import { createHmac } from 'node:crypto';
import type { IncomingMessage } from 'node:http';
import { TenantAuthorizer } from './tenantAuth.js';

function base64Url(input: string | Buffer): string {
  const buffer = Buffer.isBuffer(input) ? input : Buffer.from(input);
  return buffer.toString('base64').replace(/=/g, '').replace(/\+/g, '-').replace(/\//g, '_');
}

function signJwt(secret: string, claims: Record<string, unknown>): string {
  const header = base64Url(JSON.stringify({ alg: 'HS256', typ: 'JWT' }));
  const payload = base64Url(JSON.stringify(claims));
  const signature = base64Url(createHmac('sha256', secret).update(`${header}.${payload}`).digest());
  return `${header}.${payload}.${signature}`;
}

function requestWithToken(token: string): IncomingMessage {
  return { headers: { authorization: `Bearer ${token}` } } as IncomingMessage;
}

function withEnv(values: Record<string, string | undefined>, fn: () => void): void {
  const previous = new Map<string, string | undefined>();
  for (const [key, value] of Object.entries(values)) {
    previous.set(key, process.env[key]);
    if (value === undefined) delete process.env[key];
    else process.env[key] = value;
  }
  try {
    fn();
  } finally {
    for (const [key, value] of previous) {
      if (value === undefined) delete process.env[key];
      else process.env[key] = value;
    }
  }
}

test('accepts a valid signed tenant JWT', () => {
  withEnv({
    FLEETOS_JWT_SECRET: 'test-secret',
    FLEETOS_JWT_ISSUER: 'fleetos-test',
    FLEETOS_JWT_AUDIENCE: 'fleetos-web',
    FLEETOS_ALLOW_DEV_TOKENS: undefined,
  }, () => {
    const auth = new TenantAuthorizer();
    const token = signJwt('test-secret', {
      sub: 'user-1',
      companyId: 'comp-101',
      role: 'manager',
      iss: 'fleetos-test',
      aud: 'fleetos-web',
      exp: 2_000_000_000,
    });
    assert.deepEqual(auth.authenticate(requestWithToken(token), new Date('2030-01-01T00:00:00Z')), {
      sub: 'user-1',
      companyId: 'comp-101',
      role: 'manager',
    });
  });
});

test('rejects expired and wrongly signed JWTs', () => {
  withEnv({ FLEETOS_JWT_SECRET: 'right-secret', FLEETOS_ALLOW_DEV_TOKENS: undefined }, () => {
    const auth = new TenantAuthorizer();
    const expired = signJwt('right-secret', {
      sub: 'user-1', companyId: 'comp-101', role: 'owner', exp: 1_700_000_000,
    });
    const wrongSignature = signJwt('wrong-secret', {
      sub: 'user-1', companyId: 'comp-101', role: 'owner', exp: 2_000_000_000,
    });
    const now = new Date('2030-01-01T00:00:00Z');
    assert.equal(auth.authenticate(requestWithToken(expired), now), null);
    assert.equal(auth.authenticate(requestWithToken(wrongSignature), now), null);
  });
});

test('dev tokens are disabled unless explicitly enabled', () => {
  const raw = JSON.stringify([{ token: 'dev-token', companyId: 'comp-101', role: 'dispatcher' }]);
  withEnv({ FLEETOS_JWT_SECRET: undefined, FLEETOS_ALLOW_DEV_TOKENS: undefined }, () => {
    const auth = new TenantAuthorizer(raw);
    assert.equal(auth.authenticate(requestWithToken('dev-token')), null);
  });

  withEnv({ FLEETOS_JWT_SECRET: undefined, FLEETOS_ALLOW_DEV_TOKENS: 'true' }, () => {
    const auth = new TenantAuthorizer(raw);
    assert.deepEqual(auth.authenticate(requestWithToken('dev-token')), {
      sub: 'dev:comp-101', companyId: 'comp-101', role: 'dispatcher',
    });
  });
});
