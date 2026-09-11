import React, { useMemo, useState } from 'react';
import { Activity, Fuel, Gauge, MapPin, Navigation, Radio, Scale, Truck } from 'lucide-react';
import { Vehicle } from '../../types';
import { useLiveTelemetry } from '../../live/useLiveTelemetry';
import type { LiveTelemetryReading } from '../../live/telemetryClient';

interface TelemetryMapProps {
  vehicles: Vehicle[];
  onSelectVehicle?: (vehicle: Vehicle) => void;
  selectedVehicleId?: string;
}

function freshnessBadge(reading: LiveTelemetryReading): string {
  switch (reading.freshness) {
    case 'live':
      return 'bg-emerald-500/15 text-emerald-300 border-emerald-500/30';
    case 'recent':
      return 'bg-blue-500/15 text-blue-300 border-blue-500/30';
    case 'stale':
      return 'bg-amber-500/15 text-amber-300 border-amber-500/30';
    default:
      return 'bg-slate-500/15 text-slate-300 border-slate-500/30';
  }
}

function motionLabel(reading: LiveTelemetryReading): string {
  if (reading.motionState === 'moving') return 'Moving';
  if (reading.motionState === 'idling') return 'Idling';
  if (reading.motionState === 'stopped') return 'Stopped';
  return 'Offline';
}

export const TelemetryMap: React.FC<TelemetryMapProps> = ({
  vehicles,
  onSelectVehicle,
  selectedVehicleId,
}) => {
  const { readings, byVehicleId, loading, error, lastUpdatedAt } = useLiveTelemetry();
  const [activeVehicleId, setActiveVehicleId] = useState<string | null>(selectedVehicleId ?? null);

  const linkedReadings = useMemo(
    () => readings.filter((reading) => vehicles.some((vehicle) => vehicle.id === reading.vehicleId && !vehicle.deletedAt)),
    [readings, vehicles]
  );

  const activeReading = activeVehicleId
    ? byVehicleId.get(activeVehicleId)
    : linkedReadings[0];

  const activeVehicle = activeReading
    ? vehicles.find((vehicle) => vehicle.id === activeReading.vehicleId) ?? null
    : null;

  const handleSelect = (reading: LiveTelemetryReading) => {
    setActiveVehicleId(reading.vehicleId);
    const vehicle = vehicles.find((item) => item.id === reading.vehicleId);
    if (vehicle && onSelectVehicle) onSelectVehicle(vehicle);
  };

  const pointLayout = useMemo(() => {
    const points = linkedReadings.filter(
      (reading) => typeof reading.latitude === 'number' && typeof reading.longitude === 'number'
    );
    if (points.length === 0) return new Map<string, { top: string; left: string }>();

    const lats = points.map((reading) => reading.latitude as number);
    const lngs = points.map((reading) => reading.longitude as number);
    const minLat = Math.min(...lats);
    const maxLat = Math.max(...lats);
    const minLng = Math.min(...lngs);
    const maxLng = Math.max(...lngs);
    const latSpan = Math.max(maxLat - minLat, 0.01);
    const lngSpan = Math.max(maxLng - minLng, 0.01);

    return new Map(
      points.map((reading) => {
        const top = 12 + ((maxLat - (reading.latitude as number)) / latSpan) * 76;
        const left = 10 + (((reading.longitude as number) - minLng) / lngSpan) * 80;
        return [reading.vehicleId, { top: `${top}%`, left: `${left}%` }];
      })
    );
  }, [linkedReadings]);

  return (
    <div className="overflow-hidden rounded-2xl border border-slate-800 bg-slate-950 text-white shadow-inner">
      <div className="flex flex-col gap-3 border-b border-slate-800 bg-slate-900/90 p-3 sm:flex-row sm:items-center sm:justify-between">
        <div className="flex items-center gap-2">
          <Radio className="h-4 w-4 text-emerald-400" />
          <div>
            <p className="text-xs font-semibold uppercase tracking-wider text-slate-200">Authoritative live telemetry</p>
            <p className="text-[11px] text-slate-400">Provider/device readings only. No simulated vehicle movement.</p>
          </div>
        </div>
        <div className="text-[11px] text-slate-400">
          {loading ? 'Connecting…' : error ? `Feed unavailable: ${error}` : `Feed vehicles: ${linkedReadings.length}`}
          {lastUpdatedAt ? ` • refreshed ${new Date(lastUpdatedAt).toLocaleTimeString()}` : ''}
        </div>
      </div>

      {linkedReadings.length === 0 ? (
        <div className="flex min-h-72 flex-col items-center justify-center px-6 py-10 text-center">
          <Radio className="mb-3 h-8 w-8 text-slate-500" />
          <h4 className="text-sm font-semibold text-slate-200">No live vehicle feed connected</h4>
          <p className="mt-1 max-w-lg text-xs leading-5 text-slate-400">
            FleetOS will show vehicle location, speed, ignition, fuel and load only after an authorized GPS/telematics provider sends real readings to the telemetry backend.
          </p>
        </div>
      ) : (
        <>
          <div className="relative h-72 overflow-hidden border-b border-slate-800 bg-slate-950 sm:h-80">
            <div className="absolute inset-0 opacity-20" aria-hidden="true">
              <svg className="h-full w-full" viewBox="0 0 100 100" preserveAspectRatio="none">
                <defs>
                  <pattern id="telemetry-grid" width="8" height="8" patternUnits="userSpaceOnUse">
                    <path d="M 8 0 L 0 0 0 8" fill="none" stroke="currentColor" strokeWidth="0.25" className="text-slate-500" />
                  </pattern>
                </defs>
                <rect width="100" height="100" fill="url(#telemetry-grid)" />
              </svg>
            </div>

            <div className="absolute left-3 top-3 rounded-md border border-slate-700 bg-slate-900/90 px-2 py-1 text-[10px] text-slate-400">
              Coordinate plot • not a road map
            </div>

            {linkedReadings.map((reading) => {
              const position = pointLayout.get(reading.vehicleId);
              if (!position) return null;
              const selected = activeReading?.vehicleId === reading.vehicleId;
              const vehicle = vehicles.find((item) => item.id === reading.vehicleId);
              return (
                <button
                  key={reading.vehicleId}
                  type="button"
                  onClick={() => handleSelect(reading)}
                  style={{ top: position.top, left: position.left }}
                  className={`absolute -translate-x-1/2 -translate-y-1/2 rounded-full border p-2 shadow-lg transition ${
                    selected
                      ? 'border-white bg-emerald-500 text-white ring-4 ring-emerald-500/20'
                      : 'border-slate-600 bg-slate-800 text-slate-100 hover:bg-slate-700'
                  }`}
                  aria-label={`Select ${vehicle?.licensePlate ?? reading.vehicleId}`}
                >
                  <Truck className="h-4 w-4" />
                </button>
              );
            })}
          </div>

          {activeReading && (
            <div className="space-y-4 p-4">
              <div className="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
                <div className="min-w-0">
                  <div className="flex flex-wrap items-center gap-2">
                    <span className="text-sm font-bold">{activeVehicle?.licensePlate ?? activeReading.vehicleId}</span>
                    <span className={`rounded-full border px-2 py-0.5 text-[10px] font-bold uppercase ${freshnessBadge(activeReading)}`}>
                      {activeReading.freshness}
                    </span>
                    <span className="rounded-full border border-slate-700 bg-slate-800 px-2 py-0.5 text-[10px] font-semibold text-slate-300">
                      {motionLabel(activeReading)}
                    </span>
                  </div>
                  <p className="mt-1 text-xs text-slate-400">
                    {activeReading.provider} • device {activeReading.deviceId} • recorded {new Date(activeReading.recordedAt).toLocaleString()}
                  </p>
                </div>
              </div>

              <div className="grid grid-cols-2 gap-3 sm:grid-cols-3 lg:grid-cols-6">
                <Metric icon={Navigation} label="Speed" value={activeReading.speedKph === undefined ? '—' : `${activeReading.speedKph.toFixed(0)} km/h`} />
                <Metric icon={Activity} label="Ignition" value={activeReading.ignitionOn === undefined ? '—' : activeReading.ignitionOn ? 'ON' : 'OFF'} />
                <Metric icon={Fuel} label="Fuel" value={activeReading.fuelLevelPercent === undefined ? '—' : `${activeReading.fuelLevelPercent.toFixed(1)}%`} />
                <Metric icon={Gauge} label="Odometer" value={activeReading.odometerKm === undefined ? '—' : `${activeReading.odometerKm.toLocaleString()} km`} />
                <Metric icon={Scale} label="Net load" value={activeReading.netLoadKg === undefined ? '—' : `${(activeReading.netLoadKg / 1000).toFixed(2)} t`} />
                <Metric icon={MapPin} label="Position" value={activeReading.latitude === undefined || activeReading.longitude === undefined ? '—' : `${activeReading.latitude.toFixed(5)}, ${activeReading.longitude.toFixed(5)}`} />
              </div>

              <div className="grid grid-cols-1 gap-2 text-xs text-slate-400 sm:grid-cols-3">
                <div>Trip fuel used: <span className="font-medium text-slate-200">{activeReading.fuelUsedLitresTrip === undefined ? '—' : `${activeReading.fuelUsedLitresTrip.toFixed(1)} L`}</span></div>
                <div>Gross / tare: <span className="font-medium text-slate-200">{activeReading.grossWeightKg === undefined || activeReading.tareWeightKg === undefined ? '—' : `${(activeReading.grossWeightKg / 1000).toFixed(2)} / ${(activeReading.tareWeightKg / 1000).toFixed(2)} t`}</span></div>
                <div>Evidence: <span className="font-medium text-slate-200">{activeReading.sourceEvidenceId ?? 'provider reading'}</span></div>
              </div>
            </div>
          )}
        </>
      )}
    </div>
  );
};

const Metric: React.FC<{
  icon: React.ComponentType<{ className?: string }>;
  label: string;
  value: string;
}> = ({ icon: Icon, label, value }) => (
  <div className="rounded-xl border border-slate-800 bg-slate-900/70 p-3">
    <div className="flex items-center gap-1.5 text-[10px] uppercase tracking-wide text-slate-500">
      <Icon className="h-3.5 w-3.5" />
      <span>{label}</span>
    </div>
    <div className="mt-1 break-words text-sm font-semibold text-slate-100">{value}</div>
  </div>
);
