import React, { useMemo } from 'react';
import {
  AlertTriangle,
  CheckCircle2,
  Fuel,
  Gauge,
  IndianRupee,
  MapPin,
  Navigation,
  PackageOpen,
  Route,
  Truck,
} from 'lucide-react';
import { useFleet } from '../context/FleetContext';
import { DriverEvidencePanel } from '../components/driver/DriverEvidencePanel';

const card = 'rounded-2xl border border-slate-200 bg-white p-4 shadow-sm dark:border-slate-800 dark:bg-slate-900';

export const DriverPortalView: React.FC = () => {
  const { currentUser, drivers, vehicles, trips, currentCompany } = useFleet();

  const driver = useMemo(
    () => drivers.find((item) => item.email.toLowerCase() === currentUser.email.toLowerCase()),
    [drivers, currentUser.email],
  );

  const vehicle = driver?.assignedVehicleId
    ? vehicles.find((item) => item.id === driver.assignedVehicleId)
    : undefined;

  const trip = driver
    ? trips.find(
        (item) => item.driverId === driver.id && ['assigned', 'in_transit'].includes(item.status),
      )
    : undefined;

  const money = (value: number) =>
    new Intl.NumberFormat('en-IN', {
      style: 'currency',
      currency: currentCompany.currency || 'INR',
      maximumFractionDigits: 0,
    }).format(value);

  if (!driver) {
    return (
      <div className="mx-auto max-w-2xl pt-10">
        <div className={`${card} text-center`}>
          <AlertTriangle className="mx-auto mb-3 h-9 w-9 text-amber-500" />
          <h1 className="text-xl font-bold">Driver profile not linked</h1>
          <p className="mt-2 text-sm text-slate-500">
            This login is in Driver mode, but no driver record matches the signed-in email. A fleet manager must link the employee/driver profile first.
          </p>
        </div>
      </div>
    );
  }

  const passed = trip?.checkpoints.filter((checkpoint) => checkpoint.status === 'passed').length ?? 0;
  const total = trip?.checkpoints.length ?? 0;
  const progress = total > 0 ? Math.round((passed / total) * 100) : 0;

  return (
    <div className="mx-auto max-w-5xl space-y-5">
      <section className="overflow-hidden rounded-3xl bg-slate-950 p-6 text-white shadow-xl">
        <div className="flex flex-col gap-5 sm:flex-row sm:items-end sm:justify-between">
          <div>
            <p className="text-xs font-semibold uppercase tracking-[0.22em] text-emerald-300">Driver workspace</p>
            <h1 className="mt-2 text-3xl font-black tracking-tight">{driver.fullName}</h1>
            <p className="mt-1 text-sm text-slate-300">{driver.licenseNumber} · Safety score {driver.safetyScore}%</p>
          </div>
          <div className="rounded-2xl bg-white/10 px-4 py-3 backdrop-blur">
            <p className="text-xs text-slate-300">Duty status</p>
            <p className="mt-1 text-lg font-bold capitalize">{driver.status.replace('_', ' ')}</p>
          </div>
        </div>
      </section>

      <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
        <div className={card}>
          <Truck className="h-5 w-5 text-indigo-500" />
          <p className="mt-3 text-xs font-semibold uppercase tracking-wide text-slate-500">Assigned truck</p>
          <p className="mt-1 text-lg font-bold">{vehicle?.licensePlate ?? 'Not assigned'}</p>
          <p className="text-xs text-slate-500">{vehicle ? `${vehicle.make} ${vehicle.model}` : 'Contact dispatcher'}</p>
        </div>
        <div className={card}>
          <Gauge className="h-5 w-5 text-cyan-500" />
          <p className="mt-3 text-xs font-semibold uppercase tracking-wide text-slate-500">Odometer</p>
          <p className="mt-1 text-lg font-bold">{vehicle ? `${vehicle.odometer.toLocaleString('en-IN')} km` : '—'}</p>
          <p className="text-xs text-slate-500">Recorded vehicle value</p>
        </div>
        <div className={card}>
          <Fuel className="h-5 w-5 text-emerald-500" />
          <p className="mt-3 text-xs font-semibold uppercase tracking-wide text-slate-500">Fuel reading</p>
          <p className="mt-1 text-lg font-bold">{vehicle ? `${vehicle.telemetry.fuelLevelPercent}%` : '—'}</p>
          <p className="text-xs text-slate-500">Demo/local record; live feed shown only when provider-backed</p>
        </div>
        <div className={card}>
          <PackageOpen className="h-5 w-5 text-amber-500" />
          <p className="mt-3 text-xs font-semibold uppercase tracking-wide text-slate-500">Current load</p>
          <p className="mt-1 text-lg font-bold">{trip ? `${(trip.cargo.weightKg / 1000).toFixed(1)} t` : '—'}</p>
          <p className="text-xs text-slate-500">{trip?.cargo.description ?? 'No active manifest'}</p>
        </div>
      </div>

      <section className={card}>
        <div className="flex items-start justify-between gap-4">
          <div>
            <p className="text-xs font-semibold uppercase tracking-[0.18em] text-slate-500">Active trip</p>
            <h2 className="mt-1 text-xl font-extrabold">{trip?.tripNumber ?? 'No active trip assigned'}</h2>
          </div>
          {trip && (
            <span className="rounded-full bg-emerald-50 px-3 py-1 text-xs font-bold uppercase text-emerald-700 dark:bg-emerald-950 dark:text-emerald-300">
              {trip.status.replace('_', ' ')}
            </span>
          )}
        </div>

        {trip ? (
          <div className="mt-5 space-y-5">
            <div className="grid gap-3 md:grid-cols-2">
              <div className="rounded-2xl bg-slate-50 p-4 dark:bg-slate-950">
                <div className="flex gap-3">
                  <MapPin className="mt-0.5 h-5 w-5 text-indigo-500" />
                  <div>
                    <p className="text-xs text-slate-500">Pickup</p>
                    <p className="font-bold">{trip.route.startLocationName}</p>
                  </div>
                </div>
              </div>
              <div className="rounded-2xl bg-slate-50 p-4 dark:bg-slate-950">
                <div className="flex gap-3">
                  <Navigation className="mt-0.5 h-5 w-5 text-emerald-500" />
                  <div>
                    <p className="text-xs text-slate-500">Destination</p>
                    <p className="font-bold">{trip.route.endLocationName}</p>
                  </div>
                </div>
              </div>
            </div>

            <div>
              <div className="mb-2 flex items-center justify-between text-xs font-semibold text-slate-500">
                <span>Checkpoint progress</span>
                <span>{passed}/{total} · {progress}%</span>
              </div>
              <div className="h-2 overflow-hidden rounded-full bg-slate-100 dark:bg-slate-800">
                <div className="h-full rounded-full bg-emerald-500 transition-all" style={{ width: `${progress}%` }} />
              </div>
            </div>

            <div className="grid gap-3 sm:grid-cols-3">
              <div className="rounded-xl border border-slate-200 p-3 dark:border-slate-800">
                <Route className="h-4 w-4 text-slate-500" />
                <p className="mt-2 text-xs text-slate-500">Distance</p>
                <p className="font-bold">{trip.route.distanceKm} km</p>
              </div>
              <div className="rounded-xl border border-slate-200 p-3 dark:border-slate-800">
                <IndianRupee className="h-4 w-4 text-slate-500" />
                <p className="mt-2 text-xs text-slate-500">Estimated toll</p>
                <p className="font-bold">{money(trip.tollFeesEstimated)}</p>
              </div>
              <div className="rounded-xl border border-slate-200 p-3 dark:border-slate-800">
                <CheckCircle2 className="h-4 w-4 text-slate-500" />
                <p className="mt-2 text-xs text-slate-500">Customer</p>
                <p className="truncate font-bold">{trip.customerName}</p>
              </div>
            </div>
          </div>
        ) : (
          <p className="mt-4 text-sm text-slate-500">When dispatch assigns a trip, route, load and checkpoint progress will appear here.</p>
        )}
      </section>
      {trip && <DriverEvidencePanel companyId={currentCompany.id} tripId={trip.id} />}
    </div>
  );
};
