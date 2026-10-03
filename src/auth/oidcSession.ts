import { UserManager, WebStorageStateStore, type User } from 'oidc-client-ts';
import { clearFleetAccessToken, setFleetAccessToken } from './runtimeSession';

const authority = (import.meta.env.VITE_OIDC_AUTHORITY ?? '').trim();
const clientId = (import.meta.env.VITE_OIDC_CLIENT_ID ?? '').trim();
const configuredRedirect = (import.meta.env.VITE_OIDC_REDIRECT_URI ?? '').trim();
const configuredPostLogout = (import.meta.env.VITE_OIDC_POST_LOGOUT_REDIRECT_URI ?? '').trim();
const scope = (import.meta.env.VITE_OIDC_SCOPE ?? 'openid profile email').trim();

export const oidcConfigured = Boolean(authority && clientId);

let manager: UserManager | null = null;

function browserOrigin(): string {
  return typeof window === 'undefined' ? '' : window.location.origin;
}

function getManager(): UserManager {
  if (!oidcConfigured) throw new Error('FleetOS OIDC is not configured');
  if (typeof window === 'undefined') throw new Error('OIDC session manager requires a browser');
  if (!manager) {
    manager = new UserManager({
      authority,
      client_id: clientId,
      redirect_uri: configuredRedirect || `${browserOrigin()}/`,
      post_logout_redirect_uri: configuredPostLogout || `${browserOrigin()}/`,
      response_type: 'code',
      scope,
      userStore: new WebStorageStateStore({ store: window.sessionStorage }),
      automaticSilentRenew: false,
      monitorSession: false,
    });
  }
  return manager;
}

function storeFleetToken(user: User): void {
  // FleetOS backend verifies the provider JWT. Prefer the ID token because it
  // carries OIDC identity/custom tenant claims and is normally a signed JWT.
  const token = user.id_token || user.access_token;
  if (!token) throw new Error('Identity provider did not return a usable signed token');
  setFleetAccessToken(token);
}

function looksLikeOidcCallback(): boolean {
  if (typeof window === 'undefined') return false;
  const params = new URLSearchParams(window.location.search);
  return params.has('code') && params.has('state');
}

export async function restoreOidcSession(): Promise<User | null> {
  if (!oidcConfigured) return null;
  const oidc = getManager();

  if (looksLikeOidcCallback()) {
    const user = await oidc.signinRedirectCallback(window.location.href);
    storeFleetToken(user);
    window.history.replaceState({}, document.title, window.location.pathname + window.location.hash);
    return user;
  }

  const user = await oidc.getUser();
  if (!user || user.expired) {
    clearFleetAccessToken();
    return null;
  }
  storeFleetToken(user);
  return user;
}

export async function beginOidcSignIn(): Promise<void> {
  await getManager().signinRedirect();
}

export async function signOutOidc(): Promise<void> {
  clearFleetAccessToken();
  if (!oidcConfigured) return;
  await getManager().signoutRedirect();
}
