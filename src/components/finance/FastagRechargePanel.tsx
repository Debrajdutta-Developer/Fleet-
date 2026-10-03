import React, { useMemo, useState } from 'react';
import { CreditCard, ExternalLink, ShieldAlert } from 'lucide-react';

const ISSUERS = [
  ['SBI', '@sbi'], ['ICICI', '@icici'], ['AXIS', '@axis'], ['Paytm', '@paytm'],
  ['HDFC', '@hdfcbank'], ['IDFC FIRST', '@idfcnetc'], ['IndusInd', '@indus'],
  ['KVB', '@kvb'], ['Kotak', '@kotak'], ['PNB', '@pnb'], ['Federal', '@fbl'],
  ['Bank of Baroda', '@barodampay'], ['CUB', '@cub'], ['Equitas', '@equitas'],
  ['Airtel Payments Bank', '@mairtel'], ['South Indian Bank', '@sib'],
  ['Union Bank', '@unionbank'], ['AU Small Finance Bank', '@aubank'],
  ['IDBI', '@idbi'], ['Jammu & Kashmir Bank', '@jkb'], ['Bank of Maharashtra', '@mahb'],
] as const;

export const FastagRechargePanel: React.FC = () => {
  const [vehicleNumber, setVehicleNumber] = useState('');
  const [issuer, setIssuer] = useState(ISSUERS[0][0]);
  const [amount, setAmount] = useState('500');
  const [message, setMessage] = useState('');
  const handle = ISSUERS.find(([name]) => name === issuer)?.[1] || '';
  const normalizedVehicle = vehicleNumber.toUpperCase().replace(/[^A-Z0-9]/g, '');
  const fastagUpiId = useMemo(() => normalizedVehicle && handle ? `netc.${normalizedVehicle}${handle}` : '', [normalizedVehicle, handle]);

  const openRecharge = () => {
    setMessage('');
    const value = Number(amount);
    if (!/^[A-Z]{2}[0-9]{1,3}[A-Z]{0,3}[0-9]{1,4}$/.test(normalizedVehicle)) {
      setMessage('Enter the vehicle registration number exactly as shown on the FASTag/RC.');
      return;
    }
    if (!(value > 0)) {
      setMessage('Enter a recharge amount greater than ₹0.');
      return;
    }
    if (!fastagUpiId) {
      setMessage('Select the FASTag issuing bank first.');
      return;
    }
    const upi = `upi://pay?pa=${encodeURIComponent(fastagUpiId)}&pn=${encodeURIComponent(`${issuer} FASTag`) }&am=${value.toFixed(2)}&cu=INR`;
    window.location.href = upi;
  };

  return (
    <div className="bg-slate-900 text-white rounded-2xl p-5 border border-slate-800 space-y-4">
      <div className="flex items-start justify-between gap-3">
        <div>
          <div className="flex items-center gap-2 text-teal-400 text-xs font-bold uppercase tracking-wider">
            <CreditCard className="h-4 w-4" /> FASTag recharge
          </div>
          <h3 className="text-lg font-bold mt-1">Recharge the actual vehicle FASTag</h3>
          <p className="text-xs text-slate-400 mt-1">No FleetOS balance is increased here. Payment must be completed with the selected issuer through UPI.</p>
        </div>
        <ShieldAlert className="h-5 w-5 text-amber-400 shrink-0" />
      </div>

      <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
        <input value={vehicleNumber} onChange={(e) => setVehicleNumber(e.target.value)} placeholder="Vehicle number e.g. WB12AB1234" className="px-3 py-2 rounded-lg bg-slate-800 border border-slate-700 text-sm uppercase" />
        <select value={issuer} onChange={(e) => setIssuer(e.target.value)} className="px-3 py-2 rounded-lg bg-slate-800 border border-slate-700 text-sm">
          {ISSUERS.map(([name]) => <option key={name}>{name}</option>)}
        </select>
        <input type="number" min="1" step="1" value={amount} onChange={(e) => setAmount(e.target.value)} placeholder="Amount ₹" className="px-3 py-2 rounded-lg bg-slate-800 border border-slate-700 text-sm" />
      </div>

      <div className="rounded-lg bg-slate-800/80 border border-slate-700 p-3 text-xs">
        <div className="text-slate-400">Generated NETC UPI ID</div>
        <div className="font-mono font-semibold text-teal-300 break-all mt-1">{fastagUpiId || 'Enter vehicle number'}</div>
      </div>

      {message && <div className="rounded-lg bg-red-950/50 border border-red-900 text-red-300 px-3 py-2 text-xs">{message}</div>}

      <div className="flex flex-wrap items-center gap-3">
        <button type="button" onClick={openRecharge} className="px-4 py-2 rounded-lg bg-teal-500 hover:bg-teal-400 text-slate-950 font-bold text-xs">Open UPI recharge</button>
        <a href="https://www.npci.org.in/product/netc/about-netc" target="_blank" rel="noreferrer" className="inline-flex items-center gap-1 text-xs text-slate-300 hover:text-white">NETC details <ExternalLink className="h-3 w-3" /></a>
      </div>

      <p className="text-[10px] text-slate-500">Issuer-confirmed balance and transaction status will remain unavailable until FleetOS has an authorised issuer/NETC integration. The UI will not invent a balance.</p>
    </div>
  );
};
