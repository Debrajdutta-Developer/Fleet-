import React, { useState } from 'react';
import { ExternalLink, Landmark, ShieldCheck, ReceiptText, Fuel, X } from 'lucide-react';

const SERVICES = [
  {
    title: 'VAHAN vehicle services',
    description: 'Official vehicle tax, fitness, RC and related services.',
    url: 'https://vahan.parivahan.gov.in/vahanservice/',
    icon: Landmark,
  },
  {
    title: 'eChallan',
    description: 'Check challans and use the official payment/receipt flow.',
    url: 'https://echallan.parivahan.gov.in/',
    icon: ReceiptText,
  },
  {
    title: 'mParivahan',
    description: 'Official vehicle, licence and transport-service information.',
    url: 'https://mparivahan.parivahan.gov.in/',
    icon: ShieldCheck,
  },
  {
    title: 'NETC / FASTag',
    description: 'Official FASTag issuer and NETC information. Recharge is handled by the issuer bank/provider.',
    url: 'https://www.npci.org.in/product/netc/about-netc',
    icon: Fuel,
  },
] as const;

export const GovernmentServicesQuickActions: React.FC = () => {
  const [open, setOpen] = useState(false);

  return (
    <div className="relative">
      <button
        type="button"
        onClick={() => setOpen((value) => !value)}
        className="rounded-lg border border-slate-700 bg-slate-800 px-3 py-2 text-xs font-semibold text-slate-200 hover:bg-slate-700"
        aria-expanded={open}
      >
        Vehicle Services
      </button>
      {open && (
        <div className="absolute right-0 z-50 mt-2 w-[min(92vw,380px)] rounded-2xl border border-slate-700 bg-slate-900 p-4 shadow-2xl">
          <div className="mb-3 flex items-center justify-between">
            <div>
              <h3 className="text-sm font-bold text-white">Official vehicle services</h3>
              <p className="mt-0.5 text-[11px] text-slate-400">FleetOS never fabricates government status or payment results.</p>
            </div>
            <button type="button" onClick={() => setOpen(false)} className="rounded-lg p-1.5 text-slate-400 hover:bg-slate-800 hover:text-white" aria-label="Close">
              <X className="h-4 w-4" />
            </button>
          </div>
          <div className="space-y-2">
            {SERVICES.map(({ title, description, url, icon: Icon }) => (
              <a
                key={url}
                href={url}
                target="_blank"
                rel="noopener noreferrer"
                className="flex items-start gap-3 rounded-xl border border-slate-700 bg-slate-800/70 p-3 transition hover:border-blue-500/60 hover:bg-slate-800"
              >
                <Icon className="mt-0.5 h-4 w-4 shrink-0 text-blue-400" />
                <span className="min-w-0 flex-1">
                  <span className="flex items-center gap-1 text-xs font-semibold text-white">{title}<ExternalLink className="h-3 w-3 text-slate-500" /></span>
                  <span className="mt-0.5 block text-[11px] leading-4 text-slate-400">{description}</span>
                </span>
              </a>
            ))}
          </div>
          <p className="mt-3 text-[10px] leading-4 text-slate-500">Direct API access to Vahan/Sarathi/eChallan/FASTag data is approval-controlled. FleetOS will only use an authorised provider/API when credentials and approval are available.</p>
        </div>
      )}
    </div>
  );
};
