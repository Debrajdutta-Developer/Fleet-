const ACCESS_TOKEN_KEY = 'fleetos_access_token';

export function getFleetAccessToken(): string | null {
  if (typeof window === 'undefined') return null;
  const token = window.sessionStorage.getItem(ACCESS_TOKEN_KEY)?.trim() ?? '';
  return token || null;
}

export function setFleetAccessToken(token: string): void {
  if (typeof window === 'undefined') return;
  const normalized = token.trim();
  if (!normalized) throw new Error('access token cannot be empty');
  window.sessionStorage.setItem(ACCESS_TOKEN_KEY, normalized);
}

export function clearFleetAccessToken(): void {
  if (typeof window === 'undefined') return;
  window.sessionStorage.removeItem(ACCESS_TOKEN_KEY);
}
