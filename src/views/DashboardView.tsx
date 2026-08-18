import React from 'react';
import { useFleet } from '../context/FleetContext';
import { TelemetryMap } from '../components/common/TelemetryMap';
import {
  Truck,
  Route,
  Users,
  AlertTriangle,
  Fuel,
  CreditCard,
  ShieldCheck,
  ArrowUpRight,
  TrendingUp,
  Activity,
  Calendar,
  Briefcase,
  Clock,
  DollarSign
} from 'lucide-react';
import {
  ResponsiveContainer,
  AreaChart,
  Area,
  XAxis,
  YAxis,
  Tooltip,
  PieChart,
  Pie,
  Cell,
  BarChart,
  Bar,
} from 'recharts';

interface DashboardViewProps {
  onNavigateTab: (tab: any) => void;
}

export const DashboardView: React.FC<DashboardViewProps> = ({ onNavigateTab }) => {
  const { vehicles, trips, drivers, complianceDocs, currentCompany, fuelLogs } = useFleet();

  const activeVehicles = vehicles.filter((v) => v.status === 'active' && !v.deletedAt);
  const idleVehicles = vehicles.filter((v) => v.status === 'idle' && !v.deletedAt);
  const maintenanceVehicles = vehicles.filter((v) => v.status === 'maintenance' && !v.deletedAt);
  const registrationVehicles = vehicles.filter((v) => v.status === 'registration' && !v.deletedAt);

  const inTransitTrips = trips.filter((t) => t.status === 'in_transit');
  const onDutyDrivers = drivers.filter((d) => d.status === 'on_duty');

  // Total active cargo payload in transit
  const totalInTransitCargoKg = inTransitTrips.reduce((acc, t) => acc + t.cargo.weightKg, 0);

  // Fleet utilization percentage
  const totalFleetUnits = vehicles.filter((v) => !v.deletedAt).length || 1;
  const fleetUtilizationRate = Math.round((activeVehicles.length / totalFleetUnits) * 100);

  // Average driver safety score
  const avgSafetyScore = Math.round(
    drivers.reduce((acc, d) => acc + d.safetyScore, 0) / (drivers.length || 1)
  );

  // Urgent compliance issues
  const expiredDocs = complianceDocs.filter((d) => d.verificationStatus === 'expired');

  // Chart data: 7-day fuel efficiency & haulage activity
  const activityData = [
    { day: 'Mon', revenue: 4200, fuelBurn: 680, kmDriven: 1420 },
    { day: 'Tue', revenue: 5100, fuelBurn: 790, kmDriven: 1680 },
    { day: 'Wed', revenue: 4900, fuelBurn: 720, kmDriven: 1540 },
    { day: 'Thu', revenue: 6300, fuelBurn: 880, kmDriven: 1920 },
    { day: 'Fri', revenue: 7200, fuelBurn: 990, kmDriven: 2200 },
    { day: 'Sat', revenue: 3800, fuelBurn: 540, kmDriven: 1180 },
    { day: 'Sun (Today)', revenue: 6900, fuelBurn: 810, kmDriven: 1850 },
  ];

  const fleetStatusData = [
    { name: 'Active (En-Route)', value: activeVehicles.length, color: '#3B82F6' },
    { name: 'Idle (Available)', value: idleVehicles.length, color: '#F59E0B' },
    { name: 'Maintenance', value: maintenanceVehicles.length, color: '#EF4444' },
    { name: 'Registration Staging', value: registrationVehicles.length, color: '#A855F7' },
  ];

  return (
    <div className="space-y-6 pb-12">
      {/* Top Welcome & KPI Header */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold text-slate-900 dark:text-white font-display">
            Operational Command Center
          </h1>
          <p className="text-sm text-slate-500 dark:text-slate-400">
            Real-time multi-tenant telemetry for <span className="font-semibold text-slate-800 dark:text-slate-200">{currentCompany.name}</span>
          </p>
        </div>

        <div className="flex items-center space-x-3">
          <button
            onClick={() => onNavigateTab('trips')}
            className="flex items-center space-x-2 px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-lg text-sm font-semibold shadow-sm transition"
          >
            <Route className="h-4 w-4" />
            <span>Dispatch New Trip</span>
          </button>
        </div>
      </div>

      {/* Critical Warnings Banner if any */}
      {(expiredDocs.length > 0 || maintenanceVehicles.length > 0) && (
        <div className="bg-amber-50 dark:bg-amber-950/40 border border-amber-200 dark:border-amber-800/80 rounded-xl p-4 flex items-start justify-between">
          <div className="flex items-start space-x-3">
            <AlertTriangle className="h-5 w-5 text-amber-600 dark:text-amber-400 mt-0.5 shrink-0" />
            <div>
              <h4 className="text-sm font-semibold text-amber-900 dark:text-amber-200">
                Compliance & Fleet Health Attention Required
              </h4>
              <p className="text-xs text-amber-800 dark:text-amber-300/80 mt-0.5">
                {expiredDocs.length} expired compliance document(s) detected. {maintenanceVehicles.length} vehicle(s) under maintenance lock.
              </p>
            </div>
          </div>
          <button
            onClick={() => onNavigateTab('compliance')}
            className="text-xs font-semibold text-amber-900 dark:text-amber-200 bg-amber-200/60 dark:bg-amber-900/60 hover:bg-amber-200 px-3 py-1.5 rounded-lg transition"
          >
            Review Vault &rarr;
          </button>
        </div>
      )}

      {/* Top 4 KPI Stat Cards */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        {/* Fleet Utilization */}
        <div className="bg-white dark:bg-slate-800/90 border border-slate-200 dark:border-slate-700/80 rounded-xl p-4 shadow-sm">
          <div className="flex items-center justify-between">
            <span className="text-xs font-medium text-slate-500 dark:text-slate-400 uppercase tracking-wider">
              Fleet Utilization
            </span>
            <div className="h-8 w-8 rounded-lg bg-blue-50 dark:bg-blue-900/30 text-blue-600 dark:text-blue-400 flex items-center justify-center">
              <Truck className="h-4 w-4" />
            </div>
          </div>
          <div className="mt-3 flex items-baseline space-x-2">
            <span className="font-display text-2xl font-bold text-slate-900 dark:text-white">
              {fleetUtilizationRate}%
            </span>
            <span className="text-xs font-medium text-emerald-600 flex items-center">
              <TrendingUp className="h-3 w-3 mr-0.5" /> +4.2%
            </span>
          </div>
          <p className="text-xs text-slate-500 dark:text-slate-400 mt-1">
            {activeVehicles.length} of {totalFleetUnits} vehicles active on route
          </p>
        </div>

        {/* In-Transit Cargo */}
        <div className="bg-white dark:bg-slate-800/90 border border-slate-200 dark:border-slate-700/80 rounded-xl p-4 shadow-sm">
          <div className="flex items-center justify-between">
            <span className="text-xs font-medium text-slate-500 dark:text-slate-400 uppercase tracking-wider">
              Active In-Transit Cargo
            </span>
            <div className="h-8 w-8 rounded-lg bg-teal-50 dark:bg-teal-900/30 text-teal-600 dark:text-teal-400 flex items-center justify-center">
              <Route className="h-4 w-4" />
            </div>
          </div>
          <div className="mt-3 flex items-baseline space-x-2">
            <span className="font-display text-2xl font-bold text-slate-900 dark:text-white">
              {(totalInTransitCargoKg / 1000).toFixed(1)} MT
            </span>
            <span className="text-xs text-slate-400 font-medium">
              ({inTransitTrips.length} active trips)
            </span>
          </div>
          <p className="text-xs text-slate-500 dark:text-slate-400 mt-1">
            Zero SLA delivery breaches today
          </p>
        </div>

        {/* Driver Safety Score */}
        <div className="bg-white dark:bg-slate-800/90 border border-slate-200 dark:border-slate-700/80 rounded-xl p-4 shadow-sm">
          <div className="flex items-center justify-between">
            <span className="text-xs font-medium text-slate-500 dark:text-slate-400 uppercase tracking-wider">
              Driver Safety Rating
            </span>
            <div className="h-8 w-8 rounded-lg bg-emerald-50 dark:bg-emerald-900/30 text-emerald-600 dark:text-emerald-400 flex items-center justify-center">
              <ShieldCheck className="h-4 w-4" />
            </div>
          </div>
          <div className="mt-3 flex items-baseline space-x-2">
            <span className="font-display text-2xl font-bold text-slate-900 dark:text-white">
              {avgSafetyScore}/100
            </span>
            <span className="text-xs text-emerald-600 font-medium">Good Tier</span>
          </div>
          <p className="text-xs text-slate-500 dark:text-slate-400 mt-1">
            {onDutyDrivers.length} drivers currently on shift
          </p>
        </div>

        {/* FASTag Toll Pool */}
        <div className="bg-white dark:bg-slate-800/90 border border-slate-200 dark:border-slate-700/80 rounded-xl p-4 shadow-sm">
          <div className="flex items-center justify-between">
            <span className="text-xs font-medium text-slate-500 dark:text-slate-400 uppercase tracking-wider">
              FASTag Toll Pool
            </span>
            <div className="h-8 w-8 rounded-lg bg-amber-50 dark:bg-amber-900/30 text-amber-600 dark:text-amber-400 flex items-center justify-center">
              <CreditCard className="h-4 w-4" />
            </div>
          </div>
          <div className="mt-3 flex items-baseline space-x-2">
            <span className="font-display text-2xl font-bold text-slate-900 dark:text-white">
              ${currentCompany.fastagBalance.toFixed(2)}
            </span>
          </div>
          <p className="text-xs text-slate-500 dark:text-slate-400 mt-1">
            Threshold guard: $300 minimum lock
          </p>
        </div>
      </div>

      {/* Live Telemetry Radar Map */}
      <div className="space-y-2">
        <div className="flex items-center justify-between">
          <h3 className="text-base font-semibold text-slate-900 dark:text-white flex items-center space-x-2">
            <Activity className="h-4 w-4 text-blue-500" />
            <span>Interactive Fleet Telemetry Radar</span>
          </h3>
          <button
            onClick={() => onNavigateTab('vehicles')}
            className="text-xs font-medium text-blue-600 dark:text-blue-400 hover:underline"
          >
            View Vehicle List &rarr;
          </button>
        </div>
        <TelemetryMap vehicles={vehicles} onSelectVehicle={(v) => {}} />
      </div>

      {/* Analytics Grid: Revenue / Activity & Fleet Breakdown */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Weekly Haulage & Revenue Activity Area Chart */}
        <div className="lg:col-span-2 bg-white dark:bg-slate-800/90 border border-slate-200 dark:border-slate-700/80 rounded-xl p-5 shadow-sm">
          <div className="flex items-center justify-between mb-4">
            <div>
              <h4 className="font-display font-semibold text-sm text-slate-900 dark:text-white">
                Revenue & Fuel Burn Trends (7-Day)
              </h4>
              <p className="text-xs text-slate-500 dark:text-slate-400">
                Daily freight billings vs operational fuel expenditures
              </p>
            </div>
            <span className="text-xs font-medium px-2 py-1 bg-slate-100 dark:bg-slate-700 rounded text-slate-600 dark:text-slate-300">
              Live Aggregate
            </span>
          </div>

          <div className="h-64 w-full">
            <ResponsiveContainer width="100%" height="100%">
              <AreaChart data={activityData} margin={{ top: 10, right: 10, left: -20, bottom: 0 }}>
                <defs>
                  <linearGradient id="colorRevenue" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="5%" stopColor="#3B82F6" stopOpacity={0.4} />
                    <stop offset="95%" stopColor="#3B82F6" stopOpacity={0.0} />
                  </linearGradient>
                  <linearGradient id="colorFuel" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="5%" stopColor="#F59E0B" stopOpacity={0.4} />
                    <stop offset="95%" stopColor="#F59E0B" stopOpacity={0.0} />
                  </linearGradient>
                </defs>
                <XAxis dataKey="day" tick={{ fontSize: 11, fill: '#94a3b8' }} />
                <YAxis tick={{ fontSize: 11, fill: '#94a3b8' }} />
                <Tooltip
                  contentStyle={{
                    backgroundColor: '#0f172a',
                    borderColor: '#334155',
                    borderRadius: '8px',
                    color: '#fff',
                    fontSize: '12px',
                  }}
                />
                <Area type="monotone" dataKey="revenue" stroke="#3B82F6" strokeWidth={2} fillOpacity={1} fill="url(#colorRevenue)" name="Freight Revenue ($)" />
                <Area type="monotone" dataKey="fuelBurn" stroke="#F59E0B" strokeWidth={2} fillOpacity={1} fill="url(#colorFuel)" name="Fuel Cost ($)" />
              </AreaChart>
            </ResponsiveContainer>
          </div>
        </div>

        {/* Fleet Composition Doughnut */}
        <div className="bg-white dark:bg-slate-800/90 border border-slate-200 dark:border-slate-700/80 rounded-xl p-5 shadow-sm flex flex-col justify-between">
          <div>
            <h4 className="font-display font-semibold text-sm text-slate-900 dark:text-white">
              Fleet Status Distribution
            </h4>
            <p className="text-xs text-slate-500 dark:text-slate-400">
              Breakdown across lifecycle state machine
            </p>
          </div>

          <div className="h-44 w-full my-2">
            <ResponsiveContainer width="100%" height="100%">
              <PieChart>
                <Pie
                  data={fleetStatusData}
                  cx="50%"
                  cy="50%"
                  innerRadius={45}
                  outerRadius={65}
                  paddingAngle={4}
                  dataKey="value"
                >
                  {fleetStatusData.map((entry, index) => (
                    <Cell key={`cell-${index}`} fill={entry.color} />
                  ))}
                </Pie>
                <Tooltip
                  contentStyle={{
                    backgroundColor: '#0f172a',
                    borderColor: '#334155',
                    borderRadius: '8px',
                    color: '#fff',
                    fontSize: '12px',
                  }}
                />
              </PieChart>
            </ResponsiveContainer>
          </div>

          <div className="space-y-1.5 text-xs">
            {fleetStatusData.map((item) => (
              <div key={item.name} className="flex items-center justify-between">
                <span className="flex items-center space-x-2 text-slate-600 dark:text-slate-300">
                  <span className="h-2 w-2 rounded-full" style={{ backgroundColor: item.color }} />
                  <span>{item.name}</span>
                </span>
                <span className="font-bold text-slate-900 dark:text-white">{item.value} units</span>
              </div>
            ))}
          </div>
        </div>
      </div>

      {/* Live Trips & Dispatch Activity Stream */}
      <div className="bg-white dark:bg-slate-800/90 border border-slate-200 dark:border-slate-700/80 rounded-xl p-5 shadow-sm">
        <div className="flex items-center justify-between mb-4">
          <h4 className="font-display font-semibold text-sm text-slate-900 dark:text-white">
            Active Freight Dispatches
          </h4>
          <button
            onClick={() => onNavigateTab('trips')}
            className="text-xs font-medium text-blue-600 dark:text-blue-400 hover:underline"
          >
            All Trips &rarr;
          </button>
        </div>

        <div className="divide-y divide-slate-100 dark:divide-slate-700/60">
          {trips.slice(0, 3).map((trip) => {
            const vehicle = vehicles.find((v) => v.id === trip.vehicleId);
            const driver = drivers.find((d) => d.id === trip.driverId);
            const passedCount = trip.checkpoints.filter((c) => c.status === 'passed').length;
            const progress = Math.round((passedCount / (trip.checkpoints.length || 1)) * 100);

            return (
              <div key={trip.id} className="py-3.5 flex flex-col sm:flex-row sm:items-center justify-between gap-3">
                <div className="space-y-1">
                  <div className="flex items-center space-x-2">
                    <span className="font-mono font-bold text-xs text-blue-600 dark:text-blue-400">
                      {trip.tripNumber}
                    </span>
                    <span className="text-xs font-semibold text-slate-900 dark:text-white">
                      {trip.customerName}
                    </span>
                    <span
                      className={`text-[10px] uppercase font-bold px-2 py-0.5 rounded-full ${
                        trip.status === 'in_transit'
                          ? 'bg-emerald-100 text-emerald-800 dark:bg-emerald-900/40 dark:text-emerald-300'
                          : 'bg-blue-100 text-blue-800 dark:bg-blue-900/40 dark:text-blue-300'
                      }`}
                    >
                      {trip.status.replace('_', ' ')}
                    </span>
                  </div>
                  <p className="text-xs text-slate-500 dark:text-slate-400">
                    Route: <span className="text-slate-700 dark:text-slate-300">{trip.route.startLocationName}</span> &rarr;{' '}
                    <span className="text-slate-700 dark:text-slate-300">{trip.route.endLocationName}</span>
                  </p>
                  <p className="text-[11px] text-slate-400">
                    Vehicle: {vehicle?.licensePlate || 'N/A'} • Driver: {driver?.fullName || 'N/A'} • Cargo: {trip.cargo.weightKg.toLocaleString()} kg
                  </p>
                </div>

                <div className="sm:w-48">
                  <div className="flex justify-between text-[11px] text-slate-500 mb-1">
                    <span>Checkpoints</span>
                    <span className="font-semibold">{passedCount} / {trip.checkpoints.length} ({progress}%)</span>
                  </div>
                  <div className="w-full bg-slate-100 dark:bg-slate-700 h-2 rounded-full overflow-hidden">
                    <div
                      className="bg-blue-600 h-full rounded-full transition-all"
                      style={{ width: `${progress}%` }}
                    />
                  </div>
                </div>
              </div>
            );
          })}
        </div>
      </div>
    </div>
  );
};
