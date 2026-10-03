import React, { useMemo, useState } from 'react';
import { Fuel, Route, ReceiptText, Search, ShieldAlert, Wallet, ExternalLink } from 'lucide-react';
import type { Vehicle } from '../types';

type Geo = { lat: number; lon: number; name: string };
type RouteOption = { distanceKm: number; durationMin: number; geometry?: { coordinates: [number, number][] }; tolls: { name: string; fee?: number }[] };

const geocode = async (query: string): Promise<Geo | null> => {
  const res = await fetch(`https://photon.komoot.io/api/?limit=1&q=${encodeURIComponent(query)}`);
  if (!res.ok) throw new Error(`Geocoder returned ${res.status}`);
  const data = await res.json();
  const feature = data?.features?.[0];
  if (!feature?.geometry?.coordinates) return null;
  const [lon, lat] = feature.geometry.coordinates;
  const p = feature.properties || {};
  const name = [p.name, p.city, p.state, p.country].filter(Boolean).join(', ') || query;
  return { lat, lon, name };
};

const routeOnce = async (from: Geo, to: Geo, alternatives: boolean): Promise<RouteOption[]> => {
  const url = `https://router.project-osrm.org/route/v1/driving/${from.lon},${from.lat};${to.lon},${to.lat}?overview=full&geometries=geojson&steps=true&alternatives=${alternatives ? 'true' : 'false'}`;
  const res = await fetch(url);
  if (!res.ok) throw new Error(`Routing service returned ${res.status}`);
  const data = await res.json();
  return (data.routes || []).map((r: any) => ({
    distanceKm: r.distance / 1000,
    durationMin: r.duration / 60,
    geometry: r.geometry,
    tolls: [],
  }));
};

const findTolls = async (route: RouteOption): Promise<RouteOption> => {
  if (!route.geometry?.coordinates?.length) return route;
  const xs = route.geometry.coordinates.map((c) => c[0]);
  const ys = route.geometry.coordinates.map((c) => c[1]);
  const minLon = Math.min(...xs) - 0.05;
  const maxLon = Math.max(...xs) + 0.05;
  const minLat = Math.min(...ys) - 0.05;
  const maxLat = Math.max(...ys) + 0.05;
  const query = `[out:json][timeout:15];(node[barrier=toll_booth](${minLat},${minLon},${maxLat},${maxLon});way[toll=yes](${minLat},${minLon},${maxLat},${maxLon}););out tags center;`;
  const res = await fetch(`https://overpass-api.de/api/interpreter?data=${encodeURIComponent(query)}`);
  if (!res.ok) return route;
  const data = await res.json();
  const tolls = (data.elements || []).slice(0, 30).map((e: any) => {
    const tags = e.tags || {};
    const name = tags.name || tags.operator || 'Toll location';
    const raw = tags.charge || tags.fee;
    const parsed = typeof raw === 'string' ? Number(raw.replace(/[^0-9.]/g, '')) : undefined;
    return { name, fee: Number.isFinite(parsed) && parsed > 0 ? parsed : undefined };
  });
  const seen = new Set<string>();
  return { ...route, tolls: tolls.filter((t: { name: string }) => !seen.has(t.name) && (seen.add(t.name), true)) };
};

export const TripIntelligencePanel: React.FC<{ vehicles: Vehicle[] }> = ({ vehicles }) => {
  const [from, setFrom] = useState('');
  const [to, setTo] = useState('');
  const [vehicleId, setVehicleId] = useState(vehicles[0]?.id || '');
  const [kmPerLitre, setKmPerLitre] = useState('4');
  const [fuelPrice, setFuelPrice] = useState('90');
  const [routes, setRoutes] = useState<RouteOption[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const [upiId, setUpiId] = useState('');
  const [rechargeAmount, setRechargeAmount] = useState('500');

  const vehicle = vehicles.find((v) => v.id === vehicleId);
  const fuelEstimate = useMemo(() => {
    const kmpl = Number(kmPerLitre);
    const price = Number(fuelPrice);
    if (!routes[0] || !(kmpl > 0) || !(price >= 0)) return null;
    const litres = routes[0].distanceKm / kmpl;
    return { litres, cost: litres * price };
  }, [routes, kmPerLitre, fuelPrice]);

  const tollEstimate = useMemo(() => {
    const known = routes[0]?.tolls.filter((t) => typeof t.fee === 'number') || [];
    return known.length ? known.reduce((sum, t) => sum + (t.fee || 0), 0) : null;
  }, [routes]);

  const plan = async () => {
    setError('');
    setLoading(true);
    setRoutes([]);
    try {
      if (!from.trim() || !to.trim()) throw new Error('Enter both origin and destination.');
      const [a, b] = await Promise.all([geocode(from), geocode(to)]);
      if (!a || !b) throw new Error('Could not resolve one of the locations.');
      const rawRoutes = await routeOnce(a, b, true);
      const enriched = await Promise.all(rawRoutes.slice(0, 3).map(findTolls));
      setRoutes(enriched);
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Route planning failed.');
    } finally {
      setLoading(false);
    }
  };

  const openUpi = () => {
    const pa = upiId.trim();
    const amount = Number(rechargeAmount);
    if (!pa || !(amount > 0)) return;
    const url = `upi://pay?pa=${encodeURIComponent(pa)}&pn=${encodeURIComponent('FleetOS FASTag Recharge')}&am=${amount.toFixed(2)}&cu=INR`;
    window.location.href = url;
  };

  return (
    <section className="space-y-4 rounded-2xl border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-800/90 p-5 shadow-sm">
      <div className="flex items-start justify-between gap-3">
        <div>
          <h2 className="text-lg font-bold text-slate-900 dark:text-white flex items-center gap-2"><Route className="h-5 w-5 text-blue-500" />Real Route & Cost Intelligence</h2>
          <p className="text-xs text-slate-500 mt-1">Uses live geocoding/routing data. No fabricated toll, fuel or payment values are written into FleetOS.</p>
        </div>
        <span className="text-[10px] font-bold uppercase tracking-wider px-2 py-1 rounded-full bg-emerald-100 text-emerald-700">Live services</span>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
        <input value={from} onChange={(e) => setFrom(e.target.value)} placeholder="Origin" className="px-3 py-2 rounded-lg border bg-slate-50 dark:bg-slate-900 border-slate-200 dark:border-slate-700 text-sm" />
        <input value={to} onChange={(e) => setTo(e.target.value)} placeholder="Destination" className="px-3 py-2 rounded-lg border bg-slate-50 dark:bg-slate-900 border-slate-200 dark:border-slate-700 text-sm" />
      </div>
      <div className="grid grid-cols-1 sm:grid-cols-4 gap-3">
        <select value={vehicleId} onChange={(e) => setVehicleId(e.target.value)} className="px-3 py-2 rounded-lg border bg-slate-50 dark:bg-slate-900 border-slate-200 dark:border-slate-700 text-sm">
          {vehicles.filter((v) => !v.deletedAt).map((v) => <option key={v.id} value={v.id}>{v.licensePlate} · {v.make} {v.model}</option>)}
        </select>
        <input type="number" min="0.1" step="0.1" value={kmPerLitre} onChange={(e) => setKmPerLitre(e.target.value)} placeholder="km/L" className="px-3 py-2 rounded-lg border bg-slate-50 dark:bg-slate-900 border-slate-200 dark:border-slate-700 text-sm" />
        <input type="number" min="0" step="0.01" value={fuelPrice} onChange={(e) => setFuelPrice(e.target.value)} placeholder="Fuel ₹/L" className="px-3 py-2 rounded-lg border bg-slate-50 dark:bg-slate-900 border-slate-200 dark:border-slate-700 text-sm" />
        <button onClick={plan} disabled={loading} className="px-4 py-2 rounded-lg bg-blue-600 hover:bg-blue-700 disabled:bg-slate-400 text-white text-sm font-semibold flex items-center justify-center gap-2"><Search className="h-4 w-4" />{loading ? 'Planning…' : 'Plan routes'}</button>
      </div>

      {error && <div className="rounded-lg border border-red-200 bg-red-50 text-red-700 px-3 py-2 text-xs">{error}</div>}

      {routes.map((route, i) => (
        <div key={i} className="rounded-xl border border-slate-200 dark:border-slate-700 p-4 space-y-3">
          <div className="flex flex-wrap gap-4 text-sm">
            <strong>Route {i + 1}</strong><span>{route.distanceKm.toFixed(1)} km</span><span>{Math.round(route.durationMin)} min</span>
            <span>{route.tolls.length} mapped toll location{route.tolls.length === 1 ? '' : 's'}</span>
          </div>
          {route.tolls.length > 0 && <div className="space-y-1">{route.tolls.map((t, n) => <div key={n} className="flex justify-between text-xs"><span>{t.name}</span><span>{typeof t.fee === 'number' ? `₹${t.fee.toFixed(2)}` : 'Fee not published'}</span></div>)}</div>}
          <div className="grid grid-cols-1 sm:grid-cols-3 gap-3 text-xs">
            <div className="rounded-lg bg-slate-50 dark:bg-slate-900 p-3"><Fuel className="h-4 w-4 text-amber-500 mb-1" />Fuel: {fuelEstimate ? `${fuelEstimate.litres.toFixed(1)} L` : 'Enter km/L'}</div>
            <div className="rounded-lg bg-slate-50 dark:bg-slate-900 p-3">Fuel cost: {fuelEstimate ? `₹${fuelEstimate.cost.toFixed(0)}` : 'Enter fuel price'}</div>
            <div className="rounded-lg bg-slate-50 dark:bg-slate-900 p-3">Toll total: {tollEstimate !== null ? `₹${tollEstimate.toFixed(2)}` : 'Fee unavailable'}</div>
          </div>
          <a href={`https://www.openstreetmap.org/directions?engine=fossgis_osrm_car&route=${route.geometry?.coordinates?.[0]?.[1]},${route.geometry?.coordinates?.[0]?.[0]};${route.geometry?.coordinates?.at(-1)?.[1]},${route.geometry?.coordinates?.at(-1)?.[0]}`} target="_blank" rel="noreferrer" className="inline-flex items-center gap-1 text-xs font-semibold text-blue-600">Open route on OpenStreetMap <ExternalLink className="h-3 w-3" /></a>
        </div>
      ))}

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
        <div className="rounded-xl border border-amber-200 bg-amber-50 dark:bg-amber-950/20 dark:border-amber-900/50 p-4 space-y-3">
          <div className="flex gap-2"><ShieldAlert className="h-4 w-4 text-amber-600" /><div><strong className="text-sm">FASTag payment</strong><p className="text-xs text-amber-800 dark:text-amber-300 mt-1">FleetOS will never increase the balance just because this button is pressed. A verified issuer transaction is required before any ledger update.</p></div></div>
          <input value={upiId} onChange={(e) => setUpiId(e.target.value)} placeholder="Issuer FASTag UPI ID (from your bank)" className="w-full px-3 py-2 rounded-lg border bg-white dark:bg-slate-900 border-amber-200 dark:border-amber-800 text-sm" />
          <div className="flex gap-2"><input type="number" min="1" value={rechargeAmount} onChange={(e) => setRechargeAmount(e.target.value)} className="w-32 px-3 py-2 rounded-lg border bg-white dark:bg-slate-900 border-amber-200 dark:border-amber-800 text-sm" /><button onClick={openUpi} disabled={!upiId.trim()} className="px-4 py-2 rounded-lg bg-amber-600 disabled:bg-slate-400 text-white text-sm font-semibold flex items-center gap-2"><Wallet className="h-4 w-4" />Open UPI</button></div>
        </div>

        <div className="rounded-xl border border-slate-200 dark:border-slate-700 p-4">
          <div className="flex gap-2 items-center"><ReceiptText className="h-4 w-4 text-blue-500" /><strong className="text-sm">Trip expense invoice</strong></div>
          <p className="text-xs text-slate-500 mt-2">The invoice should be generated from verified trip, fuel, toll and payment records. This panel deliberately does not invent invoice totals.</p>
          <button type="button" onClick={() => window.print()} className="mt-3 px-3 py-2 rounded-lg border border-slate-200 dark:border-slate-700 text-xs font-semibold">Print verified trip report</button>
          {vehicle && <p className="text-[11px] text-slate-500 mt-2">Selected vehicle: {vehicle.licensePlate} · odometer {vehicle.odometer.toLocaleString()} km</p>}
        </div>
      </div>

      <p className="text-[10px] text-slate-400">Map/routing: OpenStreetMap ecosystem via Photon + OSRM. Toll locations come from OpenStreetMap tags; a toll fee is shown only when a published fee/charge tag exists.</p>
    </section>
  );
};
