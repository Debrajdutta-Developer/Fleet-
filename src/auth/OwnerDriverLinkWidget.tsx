import React, { useState } from 'react';
import { UserPlus, X } from 'lucide-react';
import { linkExistingDriver } from './onboardingClient';
import type { SecurePrincipal } from './securePrincipal';

export const OwnerDriverLinkWidget: React.FC<{ principal: SecurePrincipal | null }> = ({ principal }) => {
  const [open, setOpen] = useState(false);
  const [message, setMessage] = useState('');
  const [error, setError] = useState('');
  const [busy, setBusy] = useState(false);
  if (!principal || (principal.role !== 'owner' && principal.role !== 'manager')) return null;

  const submit = async (event: React.FormEvent<HTMLFormElement>) => {
    event.preventDefault(); setBusy(true); setMessage(''); setError('');
    const data = new FormData(event.currentTarget);
    try {
      const result = await linkExistingDriver({
        email: String(data.get('email') || ''),
        drivingLicenceNumber: String(data.get('dl') || ''),
        aadhaarLast4: String(data.get('aadhaarLast4') || ''),
      });
      setMessage(`Driver linked to this company: ${result.driver?.email || 'success'}. They should sign in again to receive the company tenant.`);
      event.currentTarget.reset();
    } catch (reason) { setError(reason instanceof Error ? reason.message : 'Unable to link driver'); }
    finally { setBusy(false); }
  };

  return <>
    <button type="button" onClick={() => setOpen(true)} className="fixed bottom-5 right-5 z-40 inline-flex items-center gap-2 rounded-full bg-slate-950 px-4 py-3 text-xs font-bold text-white shadow-2xl ring-1 ring-slate-700 hover:bg-slate-800">
      <UserPlus className="h-4 w-4" /> Link Driver
    </button>
    {open && <div className="fixed inset-0 z-50 flex items-center justify-center bg-slate-950/70 p-4">
      <div className="w-full max-w-md rounded-2xl border border-slate-700 bg-white p-5 text-slate-900 shadow-2xl dark:bg-slate-900 dark:text-white">
        <div className="flex items-center justify-between"><div><h2 className="text-lg font-bold">Link existing driver</h2><p className="mt-1 text-xs text-slate-500">Match a driver who already created a FleetOS account.</p></div><button onClick={() => setOpen(false)}><X className="h-5 w-5" /></button></div>
        {error && <div className="mt-4 rounded-lg bg-red-50 p-3 text-xs text-red-700 dark:bg-red-950/40 dark:text-red-300">{error}</div>}
        {message && <div className="mt-4 rounded-lg bg-emerald-50 p-3 text-xs text-emerald-700 dark:bg-emerald-950/40 dark:text-emerald-300">{message}</div>}
        <form onSubmit={submit} className="mt-4 grid gap-3">
          <input name="email" type="email" required placeholder="Driver account email" className="rounded-xl border border-slate-300 bg-transparent px-3 py-2.5 text-sm dark:border-slate-700" />
          <input name="dl" required placeholder="Driving licence number" className="rounded-xl border border-slate-300 bg-transparent px-3 py-2.5 text-sm dark:border-slate-700" />
          <input name="aadhaarLast4" inputMode="numeric" maxLength={4} required placeholder="Aadhaar last 4 digits" className="rounded-xl border border-slate-300 bg-transparent px-3 py-2.5 text-sm dark:border-slate-700" />
          <p className="text-[11px] leading-4 text-slate-500">The last four digits are matched using a one-way hash; FleetOS does not request the full Aadhaar number here.</p>
          <button disabled={busy} className="rounded-xl bg-blue-600 px-4 py-3 text-sm font-bold text-white disabled:opacity-50">{busy ? 'Linking…' : 'Verify & link driver'}</button>
        </form>
      </div>
    </div>}
  </>;
};
