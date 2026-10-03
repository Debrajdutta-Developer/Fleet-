import React, { useState } from 'react';
import { approvePlatformApplication, listPlatformApplications } from './onboardingClient';

export const PlatformApprovalPanel: React.FC = () => {
  const [token, setToken] = useState('');
  const [apps, setApps] = useState<any[]>([]);
  const [error, setError] = useState('');
  const [result, setResult] = useState<any>(null);
  const load = async () => {
    setError('');
    try { const data = await listPlatformApplications(token); setApps(data.applications || []); }
    catch (e) { setError(e instanceof Error ? e.message : 'Unable to load applications'); }
  };
  const approve = async (id: string) => {
    setError(''); setResult(null);
    try { const data = await approvePlatformApplication(id, token); setResult(data); await load(); }
    catch (e) { setError(e instanceof Error ? e.message : 'Unable to approve application'); }
  };
  return <div className="mt-6 rounded-2xl border border-amber-800/60 bg-amber-950/20 p-4">
    <h2 className="font-bold text-amber-200">Platform approval console</h2>
    <p className="mt-1 text-xs text-slate-400">Temporary admin console protected by the server-side platform admin token.</p>
    <div className="mt-3 flex gap-2"><input value={token} onChange={e => setToken(e.target.value)} type="password" placeholder="Platform admin token" className="min-w-0 flex-1 rounded-xl border border-slate-700 bg-slate-950 px-3 py-2 text-sm"/><button onClick={load} className="rounded-xl bg-amber-400 px-4 py-2 text-sm font-bold text-slate-950">Load</button></div>
    {error && <div className="mt-3 rounded-lg bg-red-950/50 p-3 text-xs text-red-300">{error}</div>}
    {result?.approval && <div className="mt-3 rounded-lg bg-emerald-950/40 p-3 text-xs text-emerald-200"><div>Approved: {result.approval.application?.legalName}</div><div className="mt-1 break-all">Activation token: {result.approval.activationToken}</div><div className="mt-1 text-emerald-300/80">Email delivery is not automatic until an email provider is configured. Send an activation link, never a plaintext password.</div></div>}
    <div className="mt-3 space-y-2">{apps.map(app => <div key={app.id} className="rounded-xl border border-slate-800 bg-slate-950/70 p-3 text-xs"><div className="font-semibold text-white">{app.legalName}</div><div className="mt-1 text-slate-400">{app.ownerName} · {app.ownerEmail} · {app.state} · fleet {app.fleetSize}</div><div className="mt-2 flex items-center justify-between"><span className="uppercase tracking-wider text-slate-500">{app.status}</span>{app.status === 'pending' && <button onClick={() => approve(app.id)} className="rounded-lg bg-emerald-500 px-3 py-1.5 font-bold text-slate-950">Approve</button>}</div></div>)}</div>
  </div>;
};
