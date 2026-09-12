import React, { useState } from 'react';
import { useFleet } from '../context/FleetContext';
import { UserRole } from '../types';
import {
  Truck,
  Building2,
  ShieldCheck,
  Bell,
  Pause,
  RotateCcw,
  ChevronDown,
  AlertTriangle,
  LogOut,
} from 'lucide-react';
import { oidcConfigured, signOutOidc } from '../auth/oidcSession';

export const Header: React.FC = () => {
  const {
    currentCompany,
    setCurrentCompany,
    companies,
    currentUser,
    setCurrentUserRole,
    isLiveSimulating,
    setIsLiveSimulating,
    resetDemoData,
    complianceDocs,
    vehicles,
  } = useFleet();

  const [showCompanyMenu, setShowCompanyMenu] = useState(false);
  const [showRoleMenu, setShowRoleMenu] = useState(false);
  const [showAlertsDropdown, setShowAlertsDropdown] = useState(false);

  const expiredDocsCount = complianceDocs.filter((d) => d.verificationStatus === 'expired').length;
  const maintenanceVehiclesCount = vehicles.filter((v) => v.status === 'maintenance').length;
  const totalAlerts = expiredDocsCount + maintenanceVehiclesCount;

  const roles: { key: UserRole; label: string }[] = [
    { key: 'super_admin', label: 'Super Admin (Full Access)' },
    { key: 'company_admin', label: 'Company Admin' },
    { key: 'fleet_manager', label: 'Fleet Operations Manager' },
    { key: 'dispatcher', label: 'Trip Dispatcher' },
    { key: 'driver', label: 'Driver Console' },
  ];

  return (
    <header className="sticky top-0 z-30 border-b border-slate-800 bg-slate-900 text-white shadow-md">
      <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
        <div className="flex h-16 items-center justify-between gap-3">
          <div className="flex min-w-0 items-center space-x-3">
            <div className="flex h-10 w-10 shrink-0 items-center justify-center rounded-lg bg-blue-600 shadow-lg shadow-blue-500/20">
              <Truck className="h-6 w-6" />
            </div>
            <div className="min-w-0">
              <div className="flex items-center space-x-2">
                <span className="font-display text-xl font-extrabold tracking-tight">
                  Fleet<span className="text-blue-400">OS</span>
                </span>
                <span className="hidden rounded-full border border-blue-500/30 bg-blue-500/20 px-2 py-0.5 text-[10px] font-bold uppercase tracking-wider text-blue-300 sm:inline">
                  ERP Core
                </span>
              </div>
              <p className="hidden truncate text-xs text-slate-400 md:block">
                India-first transport operations & telemetry
              </p>
            </div>
          </div>

          <div className="flex items-center gap-2 sm:gap-3">
            {!oidcConfigured && (
              <button
                onClick={() => setIsLiveSimulating(!isLiveSimulating)}
                className={`hidden items-center gap-1.5 rounded-lg border px-2.5 py-1.5 text-xs font-medium transition-colors md:flex ${
                  isLiveSimulating
                    ? 'border-teal-500/30 bg-teal-500/10 text-teal-300'
                    : 'border-slate-700 bg-slate-800 text-slate-400'
                }`}
                title="Demo telemetry simulation"
              >
                {isLiveSimulating ? <span className="h-2 w-2 rounded-full bg-teal-500" /> : <Pause className="h-3.5 w-3.5" />}
                <span>{isLiveSimulating ? 'Demo stream' : 'Demo paused'}</span>
              </button>
            )}

            {oidcConfigured ? (
              <div className="hidden items-center gap-2 rounded-lg border border-slate-700 bg-slate-800/80 px-3 py-1.5 text-xs text-slate-200 sm:flex">
                <Building2 className="h-3.5 w-3.5 text-blue-400" />
                <span className="max-w-[160px] truncate">{currentCompany.name}</span>
                <span className="text-slate-500">•</span>
                <ShieldCheck className="h-3.5 w-3.5 text-teal-400" />
                <span className="capitalize">{currentUser.role.replace('_', ' ')}</span>
              </div>
            ) : (
              <>
                <div className="relative">
                  <button
                    onClick={() => {
                      setShowCompanyMenu(!showCompanyMenu);
                      setShowRoleMenu(false);
                      setShowAlertsDropdown(false);
                    }}
                    className="flex items-center gap-2 rounded-lg border border-slate-700 bg-slate-800/80 px-3 py-1.5 text-xs font-medium text-slate-200 transition hover:bg-slate-800"
                  >
                    <Building2 className="h-3.5 w-3.5 text-blue-400" />
                    <span className="max-w-[120px] truncate">{currentCompany.name}</span>
                    <ChevronDown className="h-3 w-3 text-slate-400" />
                  </button>
                  {showCompanyMenu && (
                    <div className="absolute right-0 z-50 mt-2 w-64 rounded-xl border border-slate-700 bg-slate-800 py-2 shadow-2xl">
                      <div className="border-b border-slate-700 px-3 py-1.5 text-[11px] font-semibold uppercase tracking-wider text-slate-400">Demo tenant</div>
                      {companies.map((company) => (
                        <button
                          key={company.id}
                          onClick={() => {
                            setCurrentCompany(company);
                            setShowCompanyMenu(false);
                          }}
                          className={`w-full px-3 py-2 text-left text-xs hover:bg-slate-700/60 ${currentCompany.id === company.id ? 'bg-blue-600/20 text-blue-300' : 'text-slate-300'}`}
                        >
                          <p className="font-medium text-white">{company.name}</p>
                          <p className="text-[10px] text-slate-400">{company.industry}</p>
                        </button>
                      ))}
                    </div>
                  )}
                </div>

                <div className="relative hidden sm:block">
                  <button
                    onClick={() => {
                      setShowRoleMenu(!showRoleMenu);
                      setShowCompanyMenu(false);
                      setShowAlertsDropdown(false);
                    }}
                    className="flex items-center gap-1.5 rounded-lg border border-slate-700 bg-slate-800/80 px-3 py-1.5 text-xs font-medium text-slate-200 hover:bg-slate-800"
                  >
                    <ShieldCheck className="h-3.5 w-3.5 text-teal-400" />
                    <span className="capitalize">{currentUser.role.replace('_', ' ')}</span>
                    <ChevronDown className="h-3 w-3 text-slate-400" />
                  </button>
                  {showRoleMenu && (
                    <div className="absolute right-0 z-50 mt-2 w-56 rounded-xl border border-slate-700 bg-slate-800 py-2 shadow-2xl">
                      <div className="border-b border-slate-700 px-3 py-1.5 text-[11px] font-semibold uppercase tracking-wider text-slate-400">Demo persona</div>
                      {roles.map((role) => (
                        <button
                          key={role.key}
                          onClick={() => {
                            setCurrentUserRole(role.key);
                            setShowRoleMenu(false);
                          }}
                          className={`w-full px-3 py-2 text-left text-xs hover:bg-slate-700/60 ${currentUser.role === role.key ? 'bg-teal-600/20 text-teal-300' : 'text-slate-300'}`}
                        >
                          {role.label}
                        </button>
                      ))}
                    </div>
                  )}
                </div>
              </>
            )}

            <div className="relative">
              <button
                onClick={() => {
                  setShowAlertsDropdown(!showAlertsDropdown);
                  setShowCompanyMenu(false);
                  setShowRoleMenu(false);
                }}
                className="relative rounded-lg p-2 text-slate-400 transition hover:bg-slate-800 hover:text-white"
                title="Fleet alerts"
              >
                <Bell className="h-5 w-5" />
                {totalAlerts > 0 && (
                  <span className="absolute right-1 top-1 flex h-4 w-4 items-center justify-center rounded-full bg-red-500 text-[10px] font-bold text-white ring-2 ring-slate-900">{totalAlerts}</span>
                )}
              </button>
              {showAlertsDropdown && (
                <div className="absolute right-0 z-50 mt-2 w-80 rounded-xl border border-slate-700 bg-slate-800 p-3 shadow-2xl">
                  <div className="flex items-center justify-between border-b border-slate-700 pb-2">
                    <span className="text-xs font-semibold uppercase tracking-wider">Fleet alerts</span>
                    <span className="text-[10px] text-slate-400">{totalAlerts} active</span>
                  </div>
                  <div className="mt-2 space-y-2">
                    {expiredDocsCount > 0 && (
                      <div className="flex gap-2 rounded-lg border border-red-500/20 bg-red-500/10 p-2.5 text-xs text-red-300">
                        <AlertTriangle className="mt-0.5 h-4 w-4 shrink-0" />
                        <div><p className="font-semibold text-red-200">Compliance expired</p><p className="text-[11px]">{expiredDocsCount} document(s) need attention.</p></div>
                      </div>
                    )}
                    {maintenanceVehiclesCount > 0 && (
                      <div className="flex gap-2 rounded-lg border border-amber-500/20 bg-amber-500/10 p-2.5 text-xs text-amber-300">
                        <AlertTriangle className="mt-0.5 h-4 w-4 shrink-0" />
                        <div><p className="font-semibold text-amber-200">Vehicles in maintenance</p><p className="text-[11px]">{maintenanceVehiclesCount} unit(s) out of service.</p></div>
                      </div>
                    )}
                    {totalAlerts === 0 && <div className="py-4 text-center text-xs text-slate-400">No critical warnings.</div>}
                  </div>
                </div>
              )}
            </div>

            {oidcConfigured ? (
              <button
                onClick={() => void signOutOidc()}
                className="rounded-lg p-2 text-slate-400 transition hover:bg-slate-800 hover:text-red-300"
                title="Sign out"
              >
                <LogOut className="h-4 w-4" />
              </button>
            ) : (
              <button
                onClick={resetDemoData}
                className="rounded-lg p-2 text-slate-400 transition hover:bg-slate-800 hover:text-amber-400"
                title="Reset demo data"
              >
                <RotateCcw className="h-4 w-4" />
              </button>
            )}
          </div>
        </div>
      </div>
    </header>
  );
};
