import React, { useState } from 'react';
import { Vehicle } from '../../types';
import { Truck, Navigation, BatteryCharging, Fuel, ShieldAlert, Sparkles, MapPin } from 'lucide-react';

interface TelemetryMapProps {
  vehicles: Vehicle[];
  onSelectVehicle?: (vehicle: Vehicle) => void;
  selectedVehicleId?: string;
}

export const TelemetryMap: React.FC<TelemetryMapProps> = ({
  vehicles,
  onSelectVehicle,
  selectedVehicleId,
}) => {
  const [activeVehicle, setActiveVehicle] = useState<Vehicle | null>(() => {
    return vehicles.find((v) => v.id === selectedVehicleId) || vehicles[0] || null;
  });

  // Calculate normalized positions for the map viewport (US Geographic Bounds approximation: Lat 25-50, Lng -125 to -70)
  const getMapCoordinates = (lat: number, lng: number) => {
    const minLat = 25.0;
    const maxLat = 50.0;
    const minLng = -125.0;
    const maxLng = -70.0;

    const y = ((maxLat - lat) / (maxLat - minLat)) * 80 + 10;
    const x = ((lng - minLng) / (maxLng - minLng)) * 80 + 10;

    return {
      top: `${Math.max(8, Math.min(90, y))}%`,
      left: `${Math.max(8, Math.min(92, x))}%`,
    };
  };

  const handleMarkerClick = (vehicle: Vehicle) => {
    setActiveVehicle(vehicle);
    if (onSelectVehicle) onSelectVehicle(vehicle);
  };

  return (
    <div className="relative w-full h-80 sm:h-96 rounded-2xl bg-slate-950 border border-slate-800 overflow-hidden shadow-inner flex flex-col justify-between">
      {/* Map Grid Vector Background */}
      <div className="absolute inset-0 opacity-20 pointer-events-none">
        <svg className="w-full h-full" xmlns="http://www.w3.org/2000/svg">
          <defs>
            <pattern id="grid-pattern" width="40" height="40" patternUnits="userSpaceOnUse">
              <path d="M 40 0 L 0 0 0 40" fill="none" stroke="#38bdf8" strokeWidth="0.75" />
            </pattern>
            <radialGradient id="radar-glow" cx="50%" cy="50%" r="50%">
              <stop offset="0%" stopColor="#0284c7" stopOpacity="0.3" />
              <stop offset="100%" stopColor="#0f172a" stopOpacity="0" />
            </radialGradient>
          </defs>
          <rect width="100%" height="100%" fill="url(#grid-pattern)" />
          <circle cx="50%" cy="50%" r="45%" fill="url(#radar-glow)" />
        </svg>
      </div>

      {/* Map Top Bar overlay */}
      <div className="relative z-10 p-3 bg-slate-900/80 backdrop-blur-md border-b border-slate-800 flex items-center justify-between">
        <div className="flex items-center space-x-2">
          <div className="h-2 w-2 rounded-full bg-emerald-400 animate-pulse" />
          <span className="text-xs font-semibold text-slate-200 uppercase tracking-wider">
            Live Telemetry Satellite Matrix (CAN-Bus GPS Feed)
          </span>
        </div>
        <div className="flex items-center space-x-3 text-xs text-slate-400">
          <span className="flex items-center space-x-1">
            <span className="h-2 w-2 rounded-full bg-blue-500 inline-block" />
            <span>Active En-Route</span>
          </span>
          <span className="flex items-center space-x-1">
            <span className="h-2 w-2 rounded-full bg-amber-500 inline-block" />
            <span>Idle / Depot</span>
          </span>
          <span className="flex items-center space-x-1">
            <span className="h-2 w-2 rounded-full bg-red-500 inline-block" />
            <span>Maintenance</span>
          </span>
        </div>
      </div>

      {/* Interactive Vehicle Beacons / Markers */}
      <div className="relative flex-1 w-full h-full overflow-hidden">
        {vehicles
          .filter((v) => !v.deletedAt)
          .map((v) => {
            const pos = getMapCoordinates(v.telemetry.latitude, v.telemetry.longitude);
            const isSelected = (activeVehicle?.id || selectedVehicleId) === v.id;
            let statusColor = 'bg-blue-500 shadow-blue-500/50';
            if (v.status === 'idle') statusColor = 'bg-amber-500 shadow-amber-500/50';
            if (v.status === 'maintenance') statusColor = 'bg-red-500 shadow-red-500/50';
            if (v.status === 'registration') statusColor = 'bg-purple-500 shadow-purple-500/50';

            return (
              <div
                key={v.id}
                style={{ top: pos.top, left: pos.left }}
                onClick={() => handleMarkerClick(v)}
                className="absolute -translate-x-1/2 -translate-y-1/2 cursor-pointer group z-20"
              >
                {/* Ping wave for active vehicles */}
                {v.status === 'active' && (
                  <span className="absolute -inset-1 rounded-full bg-blue-400 animate-ping opacity-60 pointer-events-none" />
                )}

                <div
                  className={`relative flex items-center justify-center h-7 w-7 rounded-full text-white shadow-lg transition-transform transform group-hover:scale-125 ${statusColor} ${
                    isSelected ? 'ring-4 ring-white scale-110' : ''
                  }`}
                >
                  <Truck className="h-3.5 w-3.5" />
                </div>

                {/* Tooltip on hover */}
                <div className="absolute bottom-full left-1/2 -translate-x-1/2 mb-2 hidden group-hover:flex flex-col items-center pointer-events-none z-30">
                  <div className="px-2.5 py-1.5 bg-slate-900 text-white rounded-lg shadow-xl text-[11px] whitespace-nowrap border border-slate-700">
                    <p className="font-bold text-blue-300">{v.licensePlate}</p>
                    <p className="text-slate-300 text-[10px]">
                      {v.telemetry.speed} mph • {v.telemetry.locationName}
                    </p>
                  </div>
                  <div className="w-2 h-2 bg-slate-900 rotate-45 -mt-1 border-r border-b border-slate-700" />
                </div>
              </div>
            );
          })}
      </div>

      {/* Selected Vehicle Telemetry HUD Drawer (Bottom) */}
      {activeVehicle && (
        <div className="relative z-10 p-3 bg-slate-900/95 backdrop-blur-md border-t border-slate-800 text-white flex flex-wrap items-center justify-between gap-3">
          <div className="flex items-center space-x-3">
            <div className="p-2 rounded-lg bg-blue-600/20 border border-blue-500/30 text-blue-400">
              <Navigation className="h-4 w-4" />
            </div>
            <div>
              <div className="flex items-center space-x-2">
                <span className="font-bold text-sm text-white">{activeVehicle.licensePlate}</span>
                <span className="text-xs text-slate-400 font-medium">
                  ({activeVehicle.make} {activeVehicle.model})
                </span>
                <span
                  className={`text-[10px] px-2 py-0.5 rounded-full font-bold uppercase ${
                    activeVehicle.status === 'active'
                      ? 'bg-emerald-500/20 text-emerald-300 border border-emerald-500/30'
                      : activeVehicle.status === 'maintenance'
                      ? 'bg-red-500/20 text-red-300 border border-red-500/30'
                      : 'bg-amber-500/20 text-amber-300 border border-amber-500/30'
                  }`}
                >
                  {activeVehicle.status}
                </span>
              </div>
              <p className="text-xs text-slate-400 flex items-center space-x-1 mt-0.5">
                <MapPin className="h-3 w-3 text-slate-500" />
                <span>{activeVehicle.telemetry.locationName}</span>
              </p>
            </div>
          </div>

          <div className="flex items-center space-x-4 text-xs">
            <div className="text-right">
              <span className="text-[10px] text-slate-400 block uppercase">Speed</span>
              <span className="font-display font-bold text-sm text-teal-400">
                {activeVehicle.telemetry.speed} mph
              </span>
            </div>

            <div className="text-right">
              <span className="text-[10px] text-slate-400 block uppercase">
                {activeVehicle.fuelType === 'electric' ? 'Battery SoC' : 'Fuel Level'}
              </span>
              <span className="font-display font-bold text-sm text-blue-400">
                {activeVehicle.telemetry.fuelLevelPercent}%
              </span>
            </div>

            <div className="text-right">
              <span className="text-[10px] text-slate-400 block uppercase">Engine Temp</span>
              <span className="font-display font-bold text-sm text-slate-200">
                {activeVehicle.telemetry.engineTempC}°C
              </span>
            </div>

            <div className="text-right">
              <span className="text-[10px] text-slate-400 block uppercase">Odometer</span>
              <span className="font-display font-bold text-sm text-slate-200">
                {activeVehicle.odometer.toLocaleString()} km
              </span>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};
