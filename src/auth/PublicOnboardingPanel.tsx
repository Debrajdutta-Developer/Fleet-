import React, { useState } from 'react';
import { Building2, IdCard, UserRoundPlus } from 'lucide-react';
import { registerDriverProfile, submitCompanyApplication } from './onboardingClient';

type Mode = 'none' | 'company' | 'driver';

export const PublicOnboardingPanel: React.FC = () => {
  const [mode, setMode] = useState<Mode>('none');
  const [message, setMessage] = useState('');
  const [error, setError] = useState('');
  const [busy, setBusy] = useState(false);

  const companySubmit = async (event: React.FormEvent<HTMLFormElement>) => {
    event.preventDefault(); setBusy(true); setError(''); setMessage('');
    const data = new FormData(event.currentTarget);
    try {
      const result = await submitCompanyApplication({
        legalName: String(data.get('legalName') || ''), tradeName: String(data.get('tradeName') || ''),
        ownerName: String(data.get('ownerName') || ''), ownerEmail: String(data.get('ownerEmail') || ''), ownerPhone: String(data.get('ownerPhone') || ''),
        gstin: String(data.get('gstin') || ''), pan: String(data.get('pan') || ''), address: String(data.get('address') || ''), state: String(data.get('state') || ''),
        fleetSize: Number(data.get('fleetSize') || 0), transportType: String(data.get('transportType') || 'general_logistics'),
        vehicleRegistrations: String(data.get('vehicles') || '').split(/[\s,]+/).map(v => v.trim()).filter(Boolean),
      });
      setMessage(`Application submitted. Reference: ${result.application?.id || result.id || 'created'}`);
      event.currentTarget.reset();
    } catch (reason) { setError(reason instanceof Error ? reason.message : 'Unable to submit company application'); }
    finally { setBusy(false); }
  };

  const driverSubmit = async (event: React.FormEvent<HTMLFormElement>) => {
    event.preventDefault(); setBusy(true); setError(''); setMessage('');
    const data = new FormData(event.currentTarget);
    try {
      await registerDriverProfile({
        fullName: String(data.get('fullName') || ''), email: String(data.get('email') || ''), phone: String(data.get('phone') || ''),
        password: String(data.get('password') || ''), drivingLicenceNumber: String(data.get('dl') || ''), aadhaarLast4: String(data.get('aadhaarLast4') || ''),
      });
      setMessage('Driver account created. You can sign in now; a company can link this profile after matching your details.');
      event.currentTarget.reset();
    } catch (reason) { setError(reason instanceof Error ? reason.message : 'Unable to create driver profile'); }
    finally { setBusy(false); }
  };

  if (mode === 'none') return (
    <div className="mt-6 grid grid-cols-1 gap-3 sm:grid-cols-2">
      <button type="button" onClick={() => setMode('company')} className="rounded-xl border border-slate-700 bg-slate-950 p-4 text-left hover:border-teal-500">
        <Building2 className="h-5 w-5 text-teal-300" /><div className="mt-2 font-semibold">Register a company</div><div className="mt-1 text-xs text-slate-400">Apply for a FleetOS company workspace.</div>
      </button>
      <button type="button" onClick={() => setMode('driver')} className="rounded-xl border border-slate-700 bg-slate-950 p-4 text-left hover:border-teal-500">
        <UserRoundPlus className="h-5 w-5 text-teal-300" /><div className="mt-2 font-semibold">Create driver account</div><div className="mt-1 text-xs text-slate-400">Keep a driver profile ready before joining a fleet.</div>
      </button>
    </div>
  );

  const inputClass = 'w-full rounded-xl border border-slate-700 bg-slate-950 px-3 py-2.5 text-sm text-white outline-none focus:border-teal-500';
  return <div className="mt-6 rounded-2xl border border-slate-800 bg-slate-950/70 p-4">
    <button type="button" onClick={() => { setMode('none'); setError(''); setMessage(''); }} className="text-xs font-semibold text-teal-300">← Back to sign in</button>
    <h2 className="mt-3 flex items-center gap-2 text-lg font-bold">{mode === 'company' ? <Building2 className="h-5 w-5" /> : <IdCard className="h-5 w-5" />}{mode === 'company' ? 'Company registration' : 'Driver registration'}</h2>
    {error && <div className="mt-3 rounded-lg bg-red-950/50 p-3 text-xs text-red-300">{error}</div>}
    {message && <div className="mt-3 rounded-lg bg-emerald-950/50 p-3 text-xs text-emerald-300">{message}</div>}
    {mode === 'company' ? (
      <form onSubmit={companySubmit} className="mt-4 grid gap-3">
        <input className={inputClass} name="legalName" required placeholder="Legal company name" />
        <input className={inputClass} name="tradeName" placeholder="Trade name (optional)" />
        <input className={inputClass} name="ownerName" required placeholder="Owner / authorised person" />
        <input className={inputClass} name="ownerEmail" type="email" required placeholder="Owner email" />
        <input className={inputClass} name="ownerPhone" required placeholder="Owner phone" />
        <div className="grid grid-cols-2 gap-3"><input className={inputClass} name="gstin" placeholder="GSTIN (optional)" /><input className={inputClass} name="pan" placeholder="PAN (optional)" /></div>
        <input className={inputClass} name="address" required placeholder="Registered address" />
        <input className={inputClass} name="state" required placeholder="State" />
        <div className="grid grid-cols-2 gap-3"><input className={inputClass} name="fleetSize" type="number" min="0" placeholder="Fleet size" /><select className={inputClass} name="transportType"><option value="coal">Coal transport</option><option value="bulk_goods">Bulk goods</option><option value="general_logistics">General logistics</option><option value="contract_logistics">Contract logistics</option></select></div>
        <textarea className={inputClass} name="vehicles" rows={3} placeholder="Vehicle registrations, comma or space separated" />
        <p className="text-[11px] leading-4 text-slate-500">Vehicle auto-discovery will run only when an authorised VAHAN/API provider is configured. FleetOS will not scrape private government portals.</p>
        <button disabled={busy} className="rounded-xl bg-teal-500 px-4 py-3 text-sm font-bold text-slate-950 disabled:opacity-50">{busy ? 'Submitting…' : 'Submit for approval'}</button>
      </form>
    ) : (
      <form onSubmit={driverSubmit} className="mt-4 grid gap-3">
        <input className={inputClass} name="fullName" required placeholder="Full name" />
        <input className={inputClass} name="email" type="email" required placeholder="Email" />
        <input className={inputClass} name="phone" required placeholder="Phone" />
        <input className={inputClass} name="dl" required placeholder="Driving licence number" />
        <input className={inputClass} name="aadhaarLast4" inputMode="numeric" maxLength={4} required placeholder="Aadhaar last 4 digits" />
        <input className={inputClass} name="password" type="password" minLength={10} required placeholder="Password (10+ characters)" />
        <p className="text-[11px] leading-4 text-slate-500">FleetOS stores only a one-way hash of the Aadhaar last four digits for profile matching; the full Aadhaar number is not requested here.</p>
        <button disabled={busy} className="rounded-xl bg-teal-500 px-4 py-3 text-sm font-bold text-slate-950 disabled:opacity-50">{busy ? 'Creating…' : 'Create driver account'}</button>
      </form>
    )}
  </div>;
};
