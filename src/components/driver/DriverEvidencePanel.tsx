import React, { useEffect, useState } from 'react';
import { FileCheck2, Loader2, UploadCloud } from 'lucide-react';
import { listTripEvidence, uploadTripEvidence, type EvidenceType, type TripEvidenceRecord } from '../../live/evidenceClient';

interface Props {
  companyId: string;
  tripId: string;
}

export const DriverEvidencePanel: React.FC<Props> = ({ companyId, tripId }) => {
  const [type, setType] = useState<EvidenceType>('pod');
  const [file, setFile] = useState<File | null>(null);
  const [items, setItems] = useState<TripEvidenceRecord[]>([]);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const refresh = async () => {
    try {
      setItems(await listTripEvidence(companyId, tripId));
      setError(null);
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Evidence unavailable');
    }
  };

  useEffect(() => { void refresh(); }, [companyId, tripId]);

  const submit = async () => {
    if (!file) return;
    if (file.size > 10 * 1024 * 1024) {
      setError('Maximum file size is 10 MB.');
      return;
    }
    if (!['image/jpeg', 'image/png', 'image/webp', 'application/pdf'].includes(file.type)) {
      setError('Use JPEG, PNG, WEBP or PDF only.');
      return;
    }
    setBusy(true);
    try {
      await uploadTripEvidence(companyId, tripId, type, file);
      setFile(null);
      await refresh();
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Upload failed');
    } finally {
      setBusy(false);
    }
  };

  return (
    <section className="rounded-2xl border border-slate-200 bg-white p-4 shadow-sm dark:border-slate-800 dark:bg-slate-900">
      <div className="flex items-start gap-3">
        <UploadCloud className="mt-0.5 h-5 w-5 text-indigo-500" />
        <div>
          <h3 className="font-bold text-slate-900 dark:text-white">Trip proof & receipts</h3>
          <p className="text-xs text-slate-500">Upload POD, weighment, fuel, toll or repair evidence. Files are tenant- and trip-scoped.</p>
        </div>
      </div>

      <div className="mt-4 grid gap-3 md:grid-cols-[180px_1fr_auto]">
        <select value={type} onChange={(e) => setType(e.target.value as EvidenceType)} className="rounded-lg border border-slate-200 bg-white px-3 py-2 text-sm dark:border-slate-700 dark:bg-slate-950">
          <option value="pod">Proof of delivery</option>
          <option value="weighment">Weighment slip</option>
          <option value="fuel_receipt">Fuel receipt</option>
          <option value="toll_receipt">Toll receipt</option>
          <option value="repair_receipt">Repair receipt</option>
          <option value="other">Other evidence</option>
        </select>
        <input type="file" accept="image/jpeg,image/png,image/webp,application/pdf" onChange={(e) => setFile(e.target.files?.[0] ?? null)} className="rounded-lg border border-slate-200 bg-slate-50 px-3 py-2 text-sm dark:border-slate-700 dark:bg-slate-950" />
        <button type="button" disabled={!file || busy} onClick={() => void submit()} className="inline-flex items-center justify-center gap-2 rounded-lg bg-indigo-600 px-4 py-2 text-sm font-semibold text-white disabled:opacity-50">
          {busy ? <Loader2 className="h-4 w-4 animate-spin" /> : <UploadCloud className="h-4 w-4" />} Upload
        </button>
      </div>

      {error && <p className="mt-3 text-xs font-medium text-red-600">{error}</p>}

      <div className="mt-4 grid gap-2 sm:grid-cols-2">
        {items.length === 0 ? <p className="text-xs text-slate-500">No evidence uploaded for this trip yet.</p> : items.map((item) => (
          <div key={item.id} className="flex items-center gap-3 rounded-xl border border-slate-200 p-3 dark:border-slate-800">
            <FileCheck2 className="h-4 w-4 text-emerald-500" />
            <div className="min-w-0">
              <p className="truncate text-xs font-semibold text-slate-800 dark:text-slate-100">{item.originalFileName}</p>
              <p className="text-[10px] uppercase tracking-wide text-slate-500">{item.evidenceType.replace('_', ' ')} · {(item.sizeBytes / 1024).toFixed(0)} KB</p>
            </div>
          </div>
        ))}
      </div>
    </section>
  );
};
