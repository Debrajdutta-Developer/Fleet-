import React, { useMemo, useState } from 'react';
import { Calculator, IndianRupee, Truck, AlertTriangle } from 'lucide-react';
import { useFleet } from '../../context/FleetContext';
import {
  calculateTripSettlement,
  type CommercialVehicleRelation,
  type SettlementBasis,
  type VehicleSettlementTerms,
} from '../../domain/vehicleSettlement';

interface SavedTerms extends VehicleSettlementTerms {
  updatedAt: string;
}

const STORAGE_KEY = 'fleetos_vehicle_settlement_terms';

function loadTerms(): Record<string, SavedTerms> {
  try {
    return JSON.parse(localStorage.getItem(STORAGE_KEY) ?? '{}') as Record<string, SavedTerms>;
  } catch {
    return {};
  }
}

export const SettlementDesk: React.FC = () => {
  const { vehicles, trips, fuelLogs, maintenanceTickets, currentCompany } = useFleet();
  const [termsByVehicle, setTermsByVehicle] = useState<Record<string, SavedTerms>>(loadTerms);
  const [selectedVehicleId, setSelectedVehicleId] = useState(vehicles.find((v) => !v.deletedAt)?.id ?? '');

  const vehicle = vehicles.find((v) => v.id === selectedVehicleId && !v.deletedAt);
  const saved = selectedVehicleId ? termsByVehicle[selectedVehicleId] : undefined;
  const [relation, setRelation] = useState<CommercialVehicleRelation>(saved?.relation ?? 'owned');
  const [basis, setBasis] = useState<SettlementBasis>(saved?.basis ?? 'per_trip');
  const [rate, setRate] = useState(saved?.rate ?? 0);
  const [ownerName, setOwnerName] = useState(saved?.ownerName ?? '');

  const money = (value: number) => new Intl.NumberFormat('en-IN', {
    style: 'currency',
    currency: currentCompany.currency || 'INR',
    maximumFractionDigits: 0,
  }).format(value);

  const selectVehicle = (id: string) => {
    setSelectedVehicleId(id);
    const next = termsByVehicle[id];
    setRelation(next?.relation ?? 'owned');
    setBasis(next?.basis ?? 'per_trip');
    setRate(next?.rate ?? 0);
    setOwnerName(next?.ownerName ?? '');
  };

  const saveTerms = () => {
    if (!selectedVehicleId) return;
    const next: SavedTerms = {
      vehicleId: selectedVehicleId,
      relation,
      basis,
      rate: Number(rate) || 0,
      ownerName: relation === 'owned' ? undefined : ownerName.trim() || undefined,
      revenueSharePercent: basis === 'revenue_share' ? Number(rate) || 0 : undefined,
      updatedAt: new Date().toISOString(),
    };
    const updated = { ...termsByVehicle, [selectedVehicleId]: next };
    setTermsByVehicle(updated);
    localStorage.setItem(STORAGE_KEY, JSON.stringify(updated));
  };

  const results = useMemo(() => {
    if (!vehicle) return [];
    const terms = termsByVehicle[vehicle.id] ?? {
      vehicleId: vehicle.id,
      relation: 'owned' as const,
      basis: 'per_trip' as const,
      rate: 0,
      updatedAt: new Date(0).toISOString(),
    };

    return trips
      .filter((trip) => trip.vehicleId === vehicle.id && trip.status === 'completed')
      .map((trip) => {
        const tripFuel = fuelLogs
          .filter((log) => log.vehicleId === vehicle.id)
          .reduce((sum, log) => sum + log.totalCost, 0);
        const completedTripsForVehicle = Math.max(1, trips.filter((t) => t.vehicleId === vehicle.id && t.status === 'completed').length);
        const allocatedFuel = tripFuel / completedTripsForVehicle;
        const maintenance = maintenanceTickets
          .filter((ticket) => ticket.vehicleId === vehicle.id)
          .reduce((sum, ticket) => sum + (ticket.actualCost ?? ticket.estimatedCost), 0) / completedTripsForVehicle;

        return calculateTripSettlement(terms, {
          tripId: trip.id,
          vehicleId: trip.vehicleId,
          freightRevenue: trip.freightRevenue,
          distanceKm: trip.route.distanceKm,
          netLoadKg: trip.cargo.weightKg,
          fuelCost: allocatedFuel,
          tollCost: trip.tollFeesEstimated,
          maintenanceAllocated: maintenance,
          loadingCost: 0,
          unloadingCost: 0,
          detentionCost: 0,
          otherTripCost: 0,
        });
      });
  }, [vehicle, termsByVehicle, trips, fuelLogs, maintenanceTickets]);

  const totals = results.reduce((acc, row) => ({
    revenue: acc.revenue + row.grossRevenue,
    ownerPayable: acc.ownerPayable + row.ownerNetPayable,
    contribution: acc.contribution + row.companyOperatingContribution,
  }), { revenue: 0, ownerPayable: 0, contribution: 0 });

  return (
    <section className="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm dark:border-slate-700 dark:bg-slate-800/90">
      <div className="flex flex-col gap-3 lg:flex-row lg:items-center lg:justify-between">
        <div>
          <div className="flex items-center gap-2 text-xs font-bold uppercase tracking-wider text-teal-600 dark:text-teal-400">
            <Calculator className="h-4 w-4" /> Commercial settlement desk
          </div>
          <h3 className="mt-1 text-lg font-bold text-slate-900 dark:text-white">Owned vs hired vehicle profitability</h3>
          <p className="text-xs text-slate-500">Uses recorded trip revenue, fuel, toll and allocated maintenance. Loading, detention and other costs remain zero until recorded.</p>
        </div>
        <select
          value={selectedVehicleId}
          onChange={(e) => selectVehicle(e.target.value)}
          className="rounded-lg border border-slate-200 bg-slate-50 px-3 py-2 text-sm dark:border-slate-700 dark:bg-slate-900"
        >
          {vehicles.filter((v) => !v.deletedAt).map((v) => (
            <option key={v.id} value={v.id}>{v.licensePlate} · {v.make} {v.model}</option>
          ))}
        </select>
      </div>

      {vehicle && (
        <>
          <div className="mt-5 grid gap-3 sm:grid-cols-2 lg:grid-cols-5">
            <label className="text-xs text-slate-500">Relation
              <select value={relation} onChange={(e) => setRelation(e.target.value as CommercialVehicleRelation)} className="mt-1 w-full rounded-lg border border-slate-200 bg-white px-3 py-2 text-sm dark:border-slate-700 dark:bg-slate-900">
                <option value="owned">Owned</option><option value="hired">Hired</option><option value="attached">Attached</option><option value="third_party">Third-party</option>
              </select>
            </label>
            <label className="text-xs text-slate-500">Settlement basis
              <select value={basis} onChange={(e) => setBasis(e.target.value as SettlementBasis)} disabled={relation === 'owned'} className="mt-1 w-full rounded-lg border border-slate-200 bg-white px-3 py-2 text-sm disabled:opacity-50 dark:border-slate-700 dark:bg-slate-900">
                <option value="per_trip">Per trip</option><option value="per_tonne">Per tonne</option><option value="per_km">Per km</option><option value="fixed_daily">Fixed daily</option><option value="revenue_share">Revenue share %</option>
              </select>
            </label>
            <label className="text-xs text-slate-500">{basis === 'revenue_share' ? 'Share %' : 'Rate'}
              <input type="number" min="0" value={rate} onChange={(e) => setRate(Number(e.target.value))} disabled={relation === 'owned'} className="mt-1 w-full rounded-lg border border-slate-200 bg-white px-3 py-2 text-sm disabled:opacity-50 dark:border-slate-700 dark:bg-slate-900" />
            </label>
            <label className="text-xs text-slate-500">Vehicle owner
              <input value={ownerName} onChange={(e) => setOwnerName(e.target.value)} disabled={relation === 'owned'} placeholder={relation === 'owned' ? currentCompany.name : 'Owner / vendor name'} className="mt-1 w-full rounded-lg border border-slate-200 bg-white px-3 py-2 text-sm disabled:opacity-50 dark:border-slate-700 dark:bg-slate-900" />
            </label>
            <div className="flex items-end"><button onClick={saveTerms} className="w-full rounded-lg bg-teal-600 px-4 py-2 text-sm font-semibold text-white hover:bg-teal-700">Save terms</button></div>
          </div>

          <div className="mt-5 grid gap-3 sm:grid-cols-3">
            <Summary label="Completed-trip revenue" value={money(totals.revenue)} icon={IndianRupee} />
            <Summary label="External owner payable" value={money(totals.ownerPayable)} icon={Truck} />
            <Summary label="Operating contribution" value={money(totals.contribution)} icon={Calculator} />
          </div>

          <div className="mt-4 overflow-x-auto rounded-xl border border-slate-200 dark:border-slate-700">
            <table className="w-full min-w-[760px] text-left text-xs">
              <thead className="bg-slate-50 text-slate-500 dark:bg-slate-900"><tr><th className="p-3">Trip</th><th>Revenue</th><th>Operating costs</th><th>Owner payable</th><th>Contribution</th><th>Checks</th></tr></thead>
              <tbody className="divide-y divide-slate-100 dark:divide-slate-700">
                {results.length === 0 ? <tr><td colSpan={6} className="p-5 text-center text-slate-500">No completed trip available for this vehicle.</td></tr> : results.map((row) => (
                  <tr key={row.tripId}><td className="p-3 font-mono">{row.tripId}</td><td>{money(row.grossRevenue)}</td><td>{money(row.operatingCostsBeforeOwnerSettlement)}</td><td>{money(row.ownerNetPayable)}</td><td className={row.companyOperatingContribution < 0 ? 'font-semibold text-red-600' : 'font-semibold text-emerald-600'}>{money(row.companyOperatingContribution)}</td><td>{row.warnings.length ? <span className="inline-flex items-center gap-1 text-amber-600"><AlertTriangle className="h-3 w-3" />{row.warnings.length}</span> : 'OK'}</td></tr>
                ))}
              </tbody>
            </table>
          </div>
        </>
      )}
    </section>
  );
};

const Summary: React.FC<{ label: string; value: string; icon: React.ComponentType<{ className?: string }> }> = ({ label, value, icon: Icon }) => (
  <div className="rounded-xl border border-slate-200 bg-slate-50 p-4 dark:border-slate-700 dark:bg-slate-900/60"><div className="flex items-center gap-2 text-[10px] font-semibold uppercase tracking-wide text-slate-500"><Icon className="h-3.5 w-3.5" />{label}</div><div className="mt-2 text-xl font-bold text-slate-900 dark:text-white">{value}</div></div>
);
