import React, { createContext, useContext, useEffect, useMemo, useState } from 'react';
import { KeyRound, LogIn, ShieldCheck } from 'lucide-react';
import { beginOidcSignIn, oidcConfigured, restoreOidcSession } from './oidcSession';
import { fetchSecurePrincipal, type SecurePrincipal } from './securePrincipal';
import { getFleetAccessToken, clearFleetAccessToken } from './runtimeSession';
import { nativeFleetLogin } from './nativeAuthClient';

type AuthState = 'loading' | 'authenticated' | 'unauthenticated' | 'error';
type AuthMode = 'native' | 'oidc' | 'demo';

const SecurePrincipalContext = createContext<SecurePrincipal | null>(null);

export function useSecurePrincipal(): SecurePrincipal | null {
  return useContext(SecurePrincipalContext);
}

function configuredAuthMode(): AuthMode {
  const configured = (import.meta.env.VITE_FLEETOS_AUTH_MODE as string | undefined)?.trim().toLowerCase();
  if (configured === 'demo') return 'demo';
  if (configured === 'oidc') return 'oidc';
  if (configured === 'native') return 'native';
  return oidcConfigured ? 'oidc' : 'native';
}

export const OidcAuthGate: React.FC<React.PropsWithChildren> = ({ children }) => {
  const mode = useMemo(configuredAuthMode, []);
  const [state, setState] = useState<AuthState>(mode === 'demo' ? 'authenticated' : 'loading');
  const [error, setError] = useState('');
  const [principal, setPrincipal] = useState<SecurePrincipal | null>(null);
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');

  useEffect(() => {
    if (mode === 'demo') return;
    let active = true;
    const controller = new AbortController();

    const restore = async () => {
      if (mode === 'oidc') {
        const user = await restoreOidcSession();
        if (!active) return;
        if (!user) {
          setPrincipal(null);
          setState('unauthenticated');
          return;
        }
      } else if (!getFleetAccessToken()) {
        setPrincipal(null);
        setState('unauthenticated');
        return;
      }

      const verified = await fetchSecurePrincipal(controller.signal);
      if (!active) return;
      setPrincipal(verified);
      setState('authenticated');
    };

    restore().catch((reason: unknown) => {
      if (!active) return;
      if (mode === 'native') clearFleetAccessToken();
      setPrincipal(null);
      setError(reason instanceof Error ? reason.message : 'Sign-in could not be completed');
      setState('unauthenticated');
    });

    return () => {
      active = false;
      controller.abort();
    };
  }, [mode]);

  const submitNativeLogin = async (event: React.FormEvent) => {
    event.preventDefault();
    setError('');
    setState('loading');
    try {
      const session = await nativeFleetLogin(email, password);
      setPrincipal(session.principal);
      setPassword('');
      setState('authenticated');
    } catch (reason) {
      clearFleetAccessToken();
      setPrincipal(null);
      setError(reason instanceof Error ? reason.message : 'Unable to sign in');
      setState('unauthenticated');
    }
  };

  if (state === 'authenticated') {
    return <SecurePrincipalContext.Provider value={principal}>{children}</SecurePrincipalContext.Provider>;
  }

  return (
    <main className="min-h-screen bg-slate-950 px-4 py-10 text-white flex items-center justify-center">
      <section className="w-full max-w-md rounded-3xl border border-slate-800 bg-slate-900/90 p-7 shadow-2xl">
        <div className="flex h-12 w-12 items-center justify-center rounded-2xl bg-teal-500/15 text-teal-300">
          <ShieldCheck className="h-6 w-6" />
        </div>
        <h1 className="mt-5 text-2xl font-bold">FleetOS Secure Sign-In</h1>
        <p className="mt-2 text-sm leading-6 text-slate-400">
          Your company, role and permissions are verified by FleetOS before any fleet, finance or worker data is shown.
        </p>

        {state === 'loading' && <p className="mt-6 text-sm text-slate-300">Checking your secure session…</p>}

        {error && (
          <div className="mt-5 rounded-xl border border-red-900/60 bg-red-950/40 p-3 text-sm text-red-300">
            {error}
          </div>
        )}

        {mode === 'native' && state !== 'loading' && (
          <form className="mt-6 space-y-4" onSubmit={submitNativeLogin}>
            <label className="block">
              <span className="mb-1.5 block text-xs font-bold uppercase tracking-wider text-slate-400">Email</span>
              <input
                type="email"
                autoComplete="username"
                required
                value={email}
                onChange={(event) => setEmail(event.target.value)}
                className="w-full rounded-xl border border-slate-700 bg-slate-950 px-3.5 py-3 text-sm text-white outline-none transition focus:border-teal-500"
                placeholder="owner@company.com"
              />
            </label>
            <label className="block">
              <span className="mb-1.5 block text-xs font-bold uppercase tracking-wider text-slate-400">Password</span>
              <input
                type="password"
                autoComplete="current-password"
                required
                value={password}
                onChange={(event) => setPassword(event.target.value)}
                className="w-full rounded-xl border border-slate-700 bg-slate-950 px-3.5 py-3 text-sm text-white outline-none transition focus:border-teal-500"
                placeholder="Your FleetOS password"
              />
            </label>
            <button
              type="submit"
              className="inline-flex w-full items-center justify-center gap-2 rounded-xl bg-teal-500 px-4 py-3 text-sm font-bold text-slate-950 transition hover:bg-teal-400"
            >
              <KeyRound className="h-4 w-4" />
              Sign in securely
            </button>
          </form>
        )}

        {mode === 'oidc' && state !== 'loading' && (
          <button
            type="button"
            onClick={() => {
              setError('');
              setState('loading');
              beginOidcSignIn().catch((reason: unknown) => {
                setError(reason instanceof Error ? reason.message : 'Unable to start sign-in');
                setState('error');
              });
            }}
            className="mt-6 inline-flex w-full items-center justify-center gap-2 rounded-xl bg-teal-500 px-4 py-3 text-sm font-bold text-slate-950 transition hover:bg-teal-400"
          >
            <LogIn className="h-4 w-4" />
            Sign in to FleetOS
          </button>
        )}
      </section>
    </main>
  );
};
