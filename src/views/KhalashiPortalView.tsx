import React from 'react';
import { ShieldCheck, Truck, ClipboardCheck } from 'lucide-react';

export const KhalashiPortalView: React.FC = () => {
  return (
    <section className="mx-auto max-w-3xl space-y-5">
      <div className="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm dark:border-slate-800 dark:bg-slate-900">
        <div className="flex items-start gap-4">
          <div className="rounded-xl bg-teal-500/10 p-3 text-teal-600 dark:text-teal-300">
            <ShieldCheck className="h-6 w-6" />
          </div>
          <div>
            <h1 className="text-2xl font-bold">Khalashi Portal</h1>
            <p className="mt-2 text-sm leading-6 text-slate-500 dark:text-slate-400">
              This account is intentionally restricted. Only trips assigned to this signed-in khalashi are accessible. Other drivers, khalashis, finance records and staff profiles are blocked by the server even if someone edits a URL manually.
            </p>
          </div>
        </div>
      </div>

      <div className="grid gap-4 sm:grid-cols-2">
        <div className="rounded-2xl border border-slate-200 bg-white p-5 dark:border-slate-800 dark:bg-slate-900">
          <Truck className="h-5 w-5 text-blue-500" />
          <h2 className="mt-3 font-semibold">Assigned vehicle & trip</h2>
          <p className="mt-1 text-sm text-slate-500 dark:text-slate-400">
            Assignment details are loaded only from the authenticated company and signed-in worker identity.
          </p>
        </div>
        <div className="rounded-2xl border border-slate-200 bg-white p-5 dark:border-slate-800 dark:bg-slate-900">
          <ClipboardCheck className="h-5 w-5 text-emerald-500" />
          <h2 className="mt-3 font-semibold">Trip evidence</h2>
          <p className="mt-1 text-sm text-slate-500 dark:text-slate-400">
            POD, weighment and receipt access is permitted only for the trip assigned to this account.
          </p>
        </div>
      </div>
    </section>
  );
};
