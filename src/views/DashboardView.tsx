import React, { useMemo } from 'react';
import {
  AlertTriangle,
  ArrowUpRight,
  BadgeIndianRupee,
  CheckCircle2,
  CircleGauge,
  Clock3,
  CreditCard,
  Fuel,
  Gauge,
  IndianRupee,
  ReceiptIndianRupee,
  Route,
  ShieldCheck,
  Truck,
  Users,
  Wrench,
} from 'lucide-react';
import {
  Area,
  AreaChart,
  Bar,
  BarChart,
  CartesianGrid,
  Cell,
  Pie,
  PieChart,
  ResponsiveContainer,
  Tooltip,
  XAxis,
  YAxis,
} from 'recharts';
import { TelemetryMap } from '../components/common/TelemetryMap';
import { useFleet } from '../context/FleetContext';
import {
  buildDailyOperationsSeries,
  getComplianceSnapshot,
  getFinancialSnapshot,
  getFleetStatusSeries,
  getFuelEfficiency,
} from '../analytics/fleetAnalytics';

interface DashboardViewProps {
  onNavigateTab: (tab: any) => void;
}

const fleetStatusColors = ['#2563eb', '#0f766e', '#f59e0b', '#8b5cf6', '#64748b', '#94a3b8'];
const complianceColors = ['#10b981', '#f59e0b', '#ef4444', '#8b5cf6'];

function compactNumber(value: number): string {
  return new Intl.NumberFormat('en-IN', { notation: 'compact', maximumFractionDigits: 1 }).format(value);
}

function formatCurrency(value: number, currency: string): string {
  try {
    return new Intl.NumberFormat('en-IN', {
      style: 'currency',
      currency: currency || 'INR',
      maximumFractionDigits: 0,
    }).format(value);
  } catch {
    return `₹${Math.round(value).toLocaleString('en-IN')}`;
  }
}

function MetricCard({
  label,
  value,
  helper,
  icon,
  tone = 'blue',
  onClick,
}: {
  label: string;
  value: string;
  helper: string;
  icon: React.ReactNode;
  tone?: 'blue' | 'emerald' | 'amber' | 'violet' | 'rose';
  onClick?: () => void;
}) {
  const toneClass = {
    blue: 'bg-blue-500/10 text-blue-600 dark:text-blue-400 ring-blue-500/15',
    emerald: 'bg-emerald-500/10 text-emerald-600 dark:text-emerald-400 ring-emerald-500/15',
    amber: 'bg-amber-500/10 text-amber-600 dark:text-amber-400 ring-amber-500/15',
    violet: 'bg-violet-500/10 text-violet-600 dark:text-violet-400 ring-violet-500/15',
    rose: 'bg-rose-500/10 text-rose-600 dark:text-rose-400 ring-rose-500/15',
  }[tone];

  return (
    <button
      type="button"
      onClick={onClick}
      className="group min-w-0 rounded-2xl border border-slate-200/80 bg-white p-4 text-left shadow-sm transition hover:-translate-y-0.5 hover:border-slate-300 hover:shadow-md dark:border-slate-800 dark:bg-slate-900 dark:hover:border-slate-700"
    >
      <div className="flex items-start justify-between gap-3">
        <span className="text-[11px] font-bold uppercase tracking-[0.14em] text-slate-500 dark:text-slate-400">{label}</span>
        <span className={`flex h-9 w-9 shrink-0 items-center justify-center rounded-xl ring-1 ${toneClass}`}>{icon}</span>
      </div>
      <div className="mt-4 truncate font-display text-2xl font-bold tracking-tight text-slate-950 dark:text-white">{value}</div>
      <div className="mt-1 flex items-center justify-between gap-2">
        <p className="truncate text-xs text-slate-500 dark:text-slate-400">{helper}</p>
        {onClick && <ArrowUpRight className="h-3.5 w-3.5 shrink-0 text-slate-300 transition group-hover:text-blue-500" />}
      </div>
    </button>
  );
}

function SectionCard({
  title,
  subtitle,
  action,
  children,
  className = '',
}: {
  title: string;
  subtitle?: string;
  action?: React.ReactNode;
  children: React.ReactNode;
  className?: string;
}) {
  return (
    <section className={`rounded-2xl border border-slate-200/80 bg-white shadow-sm dark:border-slate-800 dark:bg-slate-900 ${className}`}>
      <div className="flex items-start justify-between gap-4 border-b border-slate-100 px-5 py-4 dark:border-slate-800">
        <div className="min-w-0">
          <h3 className="font-display text-sm font-bold text-slate-900 dark:text-white">{title}</h3>
          {subtitle && <p className="mt-1 text-xs text-slate-500 dark:text-slate-400">{subtitle}</p>}
        </div>
        {action}
      </div>
      {children}
    </section>
  );
}

export const DashboardView: React.FC<DashboardViewProps> = ({ onNavigateTab }) => {
  const {
    vehicles,
    trips,
    drivers,
    complianceDocs,
    currentCompany,
    fuelLogs,
    maintenanceTickets,
    invoices,
  } = useFleet();

  const visibleVehicles = useMemo(() => vehicles.filter((vehicle) => !vehicle.deletedAt), [vehicles]);
  const activeVehicles = visibleVehicles.filter((vehicle) => vehicle.status === 'active');
  const maintenanceVehicles = visibleVehicles.filter((vehicle) => vehicle.status === 'maintenance');
  const inTransitTrips = trips.filter((trip) => trip.status === 'in_transit' && !trip.deletedAt);
  const completedTrips = trips.filter((trip) => trip.status === 'completed' && !trip.deletedAt);
  const onDutyDrivers = drivers.filter((driver) => driver.status === 'on_duty' && !driver.deletedAt);
  const openMaintenance = maintenanceTickets.filter((ticket) => ticket.status !== 'closed');
  const criticalMaintenance = openMaintenance.filter((ticket) => ticket.priority === 'critical' || ticket.priority === 'high');
  const overdueInvoices = invoices.filter((invoice) => invoice.status === 'overdue');

  const fleetUtilizationRate = visibleVehicles.length ? Math.round((activeVehicles.length / visibleVehicles.length) * 100) : 0;
  const cargoInTransitTonnes = inTransitTrips.reduce((sum, trip) => sum + trip.cargo.weightKg / 1000, 0);
  const avgSafetyScore = drivers.length
    ? Math.round(drivers.reduce((sum, driver) => sum + driver.safetyScore, 0) / drivers.length)
    : 0;

  const dailyOperations = useMemo(
    () => buildDailyOperationsSeries(trips, fuelLogs, invoices, 7),
    [trips, fuelLogs, invoices],
  );
  const finance = useMemo(
    () => getFinancialSnapshot(trips, fuelLogs, maintenanceTickets, invoices),
    [trips, fuelLogs, maintenanceTickets, invoices],
  );
  const compliance = useMemo(() => getComplianceSnapshot(complianceDocs), [complianceDocs]);
  const fleetStatus = useMemo(() => getFleetStatusSeries(visibleVehicles), [visibleVehicles]);
  const fuelEfficiency = useMemo(() => getFuelEfficiency(fuelLogs), [fuelLogs]);

  const currency = currentCompany.currency || 'INR';
  const complianceChart = [
    { name: 'Verified', value: compliance.verified },
    { name: 'Pending', value: compliance.pending },
    { name: 'Expired', value: compliance.expired },
    { name: 'Due ≤30d', value: compliance.expiringSoon },
  ];
  const riskCount = compliance.expired + compliance.expiringSoon + criticalMaintenance.length + overdueInvoices.length;
  const totalOperationalDistance = completedTrips.reduce((sum, trip) => sum + (trip.route.distanceKm || 0), 0);

  return (
    <div className="space-y-6 pb-12">
      <div className="overflow-hidden rounded-3xl border border-slate-200/80 bg-gradient-to-br from-slate-950 via-slate-900 to-blue-950 p-6 text-white shadow-xl shadow-slate-200/40 dark:border-slate-800 dark:shadow-none sm:p-7">
        <div className="flex flex-col gap-6 lg:flex-row lg:items-end lg:justify-between">
          <div className="max-w-2xl">
            <div className="mb-3 flex flex-wrap items-center gap-2">
              <span className="rounded-full border border-white/15 bg-white/10 px-2.5 py-1 text-[10px] font-bold uppercase tracking-[0.16em] text-blue-100">FleetOS Command Center</span>
              <span className="flex items-center gap-1.5 rounded-full border border-emerald-400/20 bg-emerald-400/10 px-2.5 py-1 text-[10px] font-semibold text-emerald-200">
                <span className="h-1.5 w-1.5 rounded-full bg-emerald-300" /> Operations online
              </span>
            </div>
            <h1 className="font-display text-2xl font-bold tracking-tight sm:text-3xl">{currentCompany.name}</h1>
            <p className="mt-2 max-w-xl text-sm leading-6 text-slate-300">One owner view for fleet movement, coal/load operations, finance, FASTag readiness, maintenance and compliance.</p>
          </div>
          <div className="flex flex-wrap gap-2">
            <button type="button" onClick={() => onNavigateTab('vehicles')} className="rounded-xl border border-white/15 bg-white/10 px-4 py-2.5 text-sm font-semibold text-white backdrop-blur transition hover:bg-white/15">Fleet registry</button>
            <button type="button" onClick={() => onNavigateTab('trips')} className="flex items-center gap-2 rounded-xl bg-blue-500 px-4 py-2.5 text-sm font-semibold text-white shadow-lg shadow-blue-950/30 transition hover:bg-blue-400"><Route className="h-4 w-4" /> Dispatch trip</button>
          </div>
        </div>
        <div className="mt-7 grid grid-cols-2 gap-3 border-t border-white/10 pt-5 sm:grid-cols-4">
          <div><p className="text-[10px] font-semibold uppercase tracking-wider text-slate-400">Fleet size</p><p className="mt-1 text-lg font-bold">{visibleVehicles.length}</p></div>
          <div><p className="text-[10px] font-semibold uppercase tracking-wider text-slate-400">Trips completed</p><p className="mt-1 text-lg font-bold">{completedTrips.length}</p></div>
          <div><p className="text-[10px] font-semibold uppercase tracking-wider text-slate-400">Distance recorded</p><p className="mt-1 text-lg font-bold">{compactNumber(totalOperationalDistance)} km</p></div>
          <div><p className="text-[10px] font-semibold uppercase tracking-wider text-slate-400">Attention items</p><p className={`mt-1 text-lg font-bold ${riskCount > 0 ? 'text-amber-300' : 'text-emerald-300'}`}>{riskCount}</p></div>
        </div>
      </div>

      {riskCount > 0 && (
        <div className="flex flex-col gap-3 rounded-2xl border border-amber-200 bg-amber-50 p-4 dark:border-amber-900/60 dark:bg-amber-950/30 sm:flex-row sm:items-center sm:justify-between">
          <div className="flex items-start gap-3">
            <span className="mt-0.5 flex h-9 w-9 shrink-0 items-center justify-center rounded-xl bg-amber-500/10 text-amber-600 dark:text-amber-400"><AlertTriangle className="h-4 w-4" /></span>
            <div>
              <p className="text-sm font-bold text-amber-950 dark:text-amber-100">Owner attention required</p>
              <p className="mt-0.5 text-xs leading-5 text-amber-800 dark:text-amber-300">{compliance.expired} expired docs · {compliance.expiringSoon} expiring within 30 days · {criticalMaintenance.length} high-priority maintenance · {overdueInvoices.length} overdue invoices</p>
            </div>
          </div>
          <button type="button" onClick={() => onNavigateTab(compliance.expired || compliance.expiringSoon ? 'compliance' : 'maintenance')} className="shrink-0 rounded-xl border border-amber-300 bg-white px-3.5 py-2 text-xs font-bold text-amber-900 transition hover:bg-amber-100 dark:border-amber-800 dark:bg-amber-950 dark:text-amber-200">Review risks</button>
        </div>
      )}

      <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 xl:grid-cols-4">
        <MetricCard label="Fleet utilization" value={`${fleetUtilizationRate}%`} helper={`${activeVehicles.length} active of ${visibleVehicles.length} vehicles`} icon={<Truck className="h-4 w-4" />} tone="blue" onClick={() => onNavigateTab('vehicles')} />
        <MetricCard label="Cargo in transit" value={`${cargoInTransitTonnes.toFixed(1)} t`} helper={`${inTransitTrips.length} active trip${inTransitTrips.length === 1 ? '' : 's'}`} icon={<Route className="h-4 w-4" />} tone="emerald" onClick={() => onNavigateTab('trips')} />
        <MetricCard label="Receivables" value={formatCurrency(finance.outstanding, currency)} helper={`${overdueInvoices.length} overdue invoice${overdueInvoices.length === 1 ? '' : 's'}`} icon={<ReceiptIndianRupee className="h-4 w-4" />} tone={overdueInvoices.length ? 'rose' : 'violet'} onClick={() => onNavigateTab('billing')} />
        <MetricCard label="FASTag pool" value={formatCurrency(currentCompany.fastagBalance, currency)} helper="Available company toll balance" icon={<CreditCard className="h-4 w-4" />} tone="amber" onClick={() => onNavigateTab('billing')} />
      </div>

      <div className="grid grid-cols-1 gap-6 xl:grid-cols-3">
        <SectionCard title="7-day operating pulse" subtitle="Calculated from recorded trips and fuel logs — no invented daily values" className="xl:col-span-2" action={<span className="rounded-lg bg-slate-100 px-2 py-1 text-[10px] font-bold uppercase tracking-wider text-slate-500 dark:bg-slate-800 dark:text-slate-400">Recorded data</span>}>
          <div className="h-72 px-2 pb-3 pt-4 sm:px-4">
            <ResponsiveContainer width="100%" height="100%">
              <AreaChart data={dailyOperations} margin={{ top: 8, right: 12, left: 0, bottom: 0 }}>
                <defs>
                  <linearGradient id="fleetRevenueFill" x1="0" y1="0" x2="0" y2="1"><stop offset="5%" stopColor="#2563eb" stopOpacity={0.3} /><stop offset="95%" stopColor="#2563eb" stopOpacity={0.02} /></linearGradient>
                  <linearGradient id="fleetFuelFill" x1="0" y1="0" x2="0" y2="1"><stop offset="5%" stopColor="#f59e0b" stopOpacity={0.25} /><stop offset="95%" stopColor="#f59e0b" stopOpacity={0.01} /></linearGradient>
                </defs>
                <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="#e2e8f0" opacity={0.55} />
                <XAxis dataKey="day" tick={{ fontSize: 11, fill: '#64748b' }} axisLine={false} tickLine={false} />
                <YAxis tick={{ fontSize: 10, fill: '#94a3b8' }} axisLine={false} tickLine={false} width={52} tickFormatter={compactNumber} />
                <Tooltip formatter={(value: number, name: string) => [name === 'Fuel cost' || name === 'Trip revenue' ? formatCurrency(value, currency) : value, name]} contentStyle={{ borderRadius: 12, border: '1px solid #cbd5e1', fontSize: 12 }} />
                <Area type="monotone" dataKey="revenue" name="Trip revenue" stroke="#2563eb" strokeWidth={2.3} fill="url(#fleetRevenueFill)" />
                <Area type="monotone" dataKey="fuelCost" name="Fuel cost" stroke="#f59e0b" strokeWidth={2} fill="url(#fleetFuelFill)" />
              </AreaChart>
            </ResponsiveContainer>
          </div>
          <div className="grid grid-cols-3 border-t border-slate-100 dark:border-slate-800">
            <div className="px-4 py-3"><p className="text-[10px] uppercase tracking-wider text-slate-400">Fuel economy</p><p className="mt-1 text-sm font-bold text-slate-900 dark:text-white">{fuelEfficiency ? `${fuelEfficiency.toFixed(2)} km/L` : '—'}</p></div>
            <div className="border-x border-slate-100 px-4 py-3 dark:border-slate-800"><p className="text-[10px] uppercase tracking-wider text-slate-400">Fuel spend</p><p className="mt-1 text-sm font-bold text-slate-900 dark:text-white">{formatCurrency(finance.fuelCost, currency)}</p></div>
            <div className="px-4 py-3"><p className="text-[10px] uppercase tracking-wider text-slate-400">Maintenance</p><p className="mt-1 text-sm font-bold text-slate-900 dark:text-white">{formatCurrency(finance.maintenanceCost, currency)}</p></div>
          </div>
        </SectionCard>

        <SectionCard title="Fleet state" subtitle="Current vehicle lifecycle distribution">
          <div className="relative h-56 px-4 pt-3">
            {fleetStatus.length ? (
              <ResponsiveContainer width="100%" height="100%"><PieChart><Pie data={fleetStatus} dataKey="value" nameKey="name" innerRadius={55} outerRadius={78} paddingAngle={4}>{fleetStatus.map((_, index) => <Cell key={index} fill={fleetStatusColors[index % fleetStatusColors.length]} />)}</Pie><Tooltip contentStyle={{ borderRadius: 12, border: '1px solid #cbd5e1', fontSize: 12 }} /></PieChart></ResponsiveContainer>
            ) : <div className="flex h-full items-center justify-center text-sm text-slate-400">No vehicles yet</div>}
            {!!fleetStatus.length && <div className="pointer-events-none absolute inset-0 flex items-center justify-center pt-3"><div className="text-center"><p className="text-2xl font-bold text-slate-900 dark:text-white">{visibleVehicles.length}</p><p className="text-[10px] uppercase tracking-wider text-slate-400">vehicles</p></div></div>}
          </div>
          <div className="grid grid-cols-2 gap-x-3 gap-y-2 px-5 pb-5">
            {fleetStatus.map((entry, index) => <div key={entry.name} className="flex items-center justify-between gap-2 text-xs"><span className="flex min-w-0 items-center gap-2 text-slate-600 dark:text-slate-300"><span className="h-2 w-2 shrink-0 rounded-full" style={{ backgroundColor: fleetStatusColors[index % fleetStatusColors.length] }} /><span className="truncate">{entry.name}</span></span><strong className="text-slate-900 dark:text-white">{entry.value}</strong></div>)}
          </div>
        </SectionCard>
      </div>

      <div className="grid grid-cols-1 gap-6 xl:grid-cols-3">
        <SectionCard title="Authoritative live telemetry" subtitle="Provider/device readings only; missing sensors stay blank instead of being guessed" className="xl:col-span-2" action={<button type="button" onClick={() => onNavigateTab('vehicles')} className="text-xs font-bold text-blue-600 hover:text-blue-700 dark:text-blue-400">All vehicles →</button>}>
          <div className="p-3 sm:p-4"><TelemetryMap vehicles={visibleVehicles} onSelectVehicle={() => {}} /></div>
        </SectionCard>
        <SectionCard title="Compliance health" subtitle="Document status and the next 30-day risk window">
          <div className="h-56 px-3 pt-4">
            <ResponsiveContainer width="100%" height="100%"><BarChart data={complianceChart} layout="vertical" margin={{ top: 0, right: 16, left: 4, bottom: 0 }}><CartesianGrid strokeDasharray="3 3" horizontal={false} stroke="#e2e8f0" opacity={0.5} /><XAxis type="number" allowDecimals={false} axisLine={false} tickLine={false} tick={{ fontSize: 10, fill: '#94a3b8' }} /><YAxis type="category" dataKey="name" width={66} axisLine={false} tickLine={false} tick={{ fontSize: 10, fill: '#64748b' }} /><Tooltip contentStyle={{ borderRadius: 12, border: '1px solid #cbd5e1', fontSize: 12 }} /><Bar dataKey="value" name="Documents" radius={[0, 6, 6, 0]}>{complianceChart.map((_, index) => <Cell key={index} fill={complianceColors[index % complianceColors.length]} />)}</Bar></BarChart></ResponsiveContainer>
          </div>
          <button type="button" onClick={() => onNavigateTab('compliance')} className="mx-5 mb-5 flex w-[calc(100%-2.5rem)] items-center justify-between rounded-xl bg-slate-50 px-3 py-2.5 text-xs font-semibold text-slate-700 transition hover:bg-slate-100 dark:bg-slate-800 dark:text-slate-200 dark:hover:bg-slate-700"><span>Open compliance vault</span><ArrowUpRight className="h-3.5 w-3.5" /></button>
        </SectionCard>
      </div>

      <div className="grid grid-cols-1 gap-6 xl:grid-cols-3">
        <SectionCard title="Financial cockpit" subtitle="Billed, collected and operating-cost visibility" className="xl:col-span-2">
          <div className="grid grid-cols-2 gap-px bg-slate-100 dark:bg-slate-800 sm:grid-cols-4">
            {[
              { label: 'Billed', value: finance.billed, icon: <BadgeIndianRupee className="h-4 w-4" /> },
              { label: 'Collected', value: finance.paid, icon: <CheckCircle2 className="h-4 w-4" /> },
              { label: 'Outstanding', value: finance.outstanding, icon: <Clock3 className="h-4 w-4" /> },
              { label: 'Overdue', value: finance.overdue, icon: <AlertTriangle className="h-4 w-4" /> },
            ].map((item) => <div key={item.label} className="bg-white p-4 dark:bg-slate-900"><div className="flex items-center gap-2 text-slate-400">{item.icon}<span className="text-[10px] font-bold uppercase tracking-wider">{item.label}</span></div><p className="mt-2 truncate text-base font-bold text-slate-900 dark:text-white">{formatCurrency(item.value, currency)}</p></div>)}
          </div>
          <div className="grid grid-cols-1 gap-3 p-5 sm:grid-cols-3">
            <div className="rounded-xl border border-slate-200 p-3 dark:border-slate-800"><p className="flex items-center gap-2 text-xs font-semibold text-slate-500"><Fuel className="h-3.5 w-3.5" /> Fuel cost</p><p className="mt-2 font-bold text-slate-900 dark:text-white">{formatCurrency(finance.fuelCost, currency)}</p></div>
            <div className="rounded-xl border border-slate-200 p-3 dark:border-slate-800"><p className="flex items-center gap-2 text-xs font-semibold text-slate-500"><Wrench className="h-3.5 w-3.5" /> Maintenance cost</p><p className="mt-2 font-bold text-slate-900 dark:text-white">{formatCurrency(finance.maintenanceCost, currency)}</p></div>
            <div className="rounded-xl border border-slate-200 p-3 dark:border-slate-800"><p className="flex items-center gap-2 text-xs font-semibold text-slate-500"><IndianRupee className="h-3.5 w-3.5" /> Operating contribution*</p><p className={`mt-2 font-bold ${finance.operatingContribution >= 0 ? 'text-emerald-600' : 'text-rose-600'}`}>{formatCurrency(finance.operatingContribution, currency)}</p></div>
          </div>
          <p className="px-5 pb-4 text-[10px] leading-4 text-slate-400">*Completed-trip revenue less recorded fuel and maintenance only; not accounting profit.</p>
        </SectionCard>

        <SectionCard title="Operations readiness" subtitle="Quick owner-level checks before dispatch">
          <div className="divide-y divide-slate-100 dark:divide-slate-800">
            {[
              { label: 'Drivers on duty', value: `${onDutyDrivers.length}/${drivers.filter((d) => !d.deletedAt).length}`, icon: <Users className="h-4 w-4" />, ok: onDutyDrivers.length > 0 },
              { label: 'Average safety score', value: `${avgSafetyScore}/100`, icon: <ShieldCheck className="h-4 w-4" />, ok: avgSafetyScore >= 70 },
              { label: 'Open maintenance', value: String(openMaintenance.length), icon: <Wrench className="h-4 w-4" />, ok: criticalMaintenance.length === 0 },
              { label: 'Vehicles in maintenance', value: String(maintenanceVehicles.length), icon: <Gauge className="h-4 w-4" />, ok: maintenanceVehicles.length === 0 },
              { label: 'Compliance due/expired', value: String(compliance.expired + compliance.expiringSoon), icon: <CircleGauge className="h-4 w-4" />, ok: compliance.expired + compliance.expiringSoon === 0 },
            ].map((row) => <div key={row.label} className="flex items-center justify-between gap-3 px-5 py-3.5"><div className="flex min-w-0 items-center gap-3"><span className={`flex h-8 w-8 shrink-0 items-center justify-center rounded-lg ${row.ok ? 'bg-emerald-500/10 text-emerald-600' : 'bg-amber-500/10 text-amber-600'}`}>{row.icon}</span><span className="truncate text-xs font-semibold text-slate-600 dark:text-slate-300">{row.label}</span></div><span className="text-sm font-bold text-slate-900 dark:text-white">{row.value}</span></div>)}
          </div>
        </SectionCard>
      </div>
    </div>
  );
};
