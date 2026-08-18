import React, { useState } from 'react';
import { useFleet } from '../context/FleetContext';
import { UserRole } from '../types';
import {
  Truck,
  Building2,
  ShieldCheck,
  Bell,
  Play,
  Pause,
  RotateCcw,
  UserCircle,
  ChevronDown,
  Sparkles,
  AlertTriangle
} from 'lucide-react';

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

  // Compute urgent alerts count
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
    <header className="sticky top-0 z-30 bg-slate-900 border-b border-slate-800 text-white shadow-md">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="flex items-center justify-between h-16">
          {/* Brand Logo & Tag */}
          <div className="flex items-center space-x-3">
            <div className="h-10 w-10 rounded-lg bg-blue-600 flex items-center justify-center shadow-lg shadow-blue-500/20 text-white font-bold text-xl">
              <Truck className="h-6 w-6" />
            </div>
            <div>
              <div className="flex items-center space-x-2">
                <span className="font-display font-extrabold text-xl tracking-tight text-white">
                  Fleet<span className="text-blue-400">OS</span>
                </span>
                <span className="px-2 py-0.5 text-[10px] uppercase font-bold tracking-wider bg-blue-500/20 text-blue-300 border border-blue-500/30 rounded-full">
                  ERP Core
                </span>
              </div>
              <p className="text-xs text-slate-400 font-normal hidden sm:block">
                Enterprise Logistics & Multi-Tenant Telemetry
              </p>
            </div>
          </div>

          {/* Center / Right controls */}
          <div className="flex items-center space-x-2 sm:space-x-4">
            {/* Live Telemetry Simulator Toggle */}
            <button
              onClick={() => setIsLiveSimulating(!isLiveSimulating)}
              className={`flex items-center space-x-1.5 px-2.5 py-1.5 rounded-lg text-xs font-medium border transition-colors ${
                isLiveSimulating
                  ? 'bg-teal-500/10 text-teal-300 border-teal-500/30 hover:bg-teal-500/20'
                  : 'bg-slate-800 text-slate-400 border-slate-700 hover:bg-slate-700'
              }`}
              title="Toggle live telemetry coordinate drift simulation"
            >
              {isLiveSimulating ? (
                <>
                  <span className="relative flex h-2 w-2">
                    <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-teal-400 opacity-75"></span>
                    <span className="relative inline-flex rounded-full h-2 w-2 bg-teal-500"></span>
                  </span>
                  <span className="hidden md:inline">Live Stream Active</span>
                </>
              ) : (
                <>
                  <Pause className="h-3.5 w-3.5" />
                  <span className="hidden md:inline">Stream Paused</span>
                </>
              )}
            </button>

            {/* Tenant Selector Dropdown */}
            <div className="relative">
              <button
                onClick={() => {
                  setShowCompanyMenu(!showCompanyMenu);
                  setShowRoleMenu(false);
                  setShowAlertsDropdown(false);
                }}
                className="flex items-center space-x-2 px-3 py-1.5 bg-slate-800/80 hover:bg-slate-800 text-slate-200 border border-slate-700 rounded-lg text-xs font-medium transition"
              >
                <Building2 className="h-3.5 w-3.5 text-blue-400" />
                <span className="max-w-[120px] sm:max-w-[160px] truncate font-medium">
                  {currentCompany.name}
                </span>
                <ChevronDown className="h-3 w-3 text-slate-400" />
              </button>

              {showCompanyMenu && (
                <div className="absolute right-0 mt-2 w-64 bg-slate-800 border border-slate-700 rounded-xl shadow-2xl py-2 z-50">
                  <div className="px-3 py-1.5 text-[11px] font-semibold text-slate-400 uppercase tracking-wider border-b border-slate-700">
                    Switch Corporate Tenant
                  </div>
                  {companies.map((comp) => (
                    <button
                      key={comp.id}
                      onClick={() => {
                        setCurrentCompany(comp);
                        setShowCompanyMenu(false);
                      }}
                      className={`w-full text-left px-3 py-2 text-xs flex items-center justify-between hover:bg-slate-700/60 transition ${
                        currentCompany.id === comp.id ? 'bg-blue-600/20 text-blue-300 font-semibold' : 'text-slate-300'
                      }`}
                    >
                      <div className="truncate">
                        <p className="font-medium text-white">{comp.name}</p>
                        <p className="text-[10px] text-slate-400">{comp.industry}</p>
                      </div>
                      <span className="text-[10px] px-1.5 py-0.5 rounded bg-slate-700 text-slate-300 capitalize">
                        {comp.subscriptionTier}
                      </span>
                    </button>
                  ))}
                </div>
              )}
            </div>

            {/* Role Switcher Dropdown */}
            <div className="relative">
              <button
                onClick={() => {
                  setShowRoleMenu(!showRoleMenu);
                  setShowCompanyMenu(false);
                  setShowAlertsDropdown(false);
                }}
                className="flex items-center space-x-1.5 px-3 py-1.5 bg-slate-800/80 hover:bg-slate-800 text-slate-200 border border-slate-700 rounded-lg text-xs font-medium transition"
              >
                <ShieldCheck className="h-3.5 w-3.5 text-teal-400" />
                <span className="hidden sm:inline capitalize">
                  {currentUser.role.replace('_', ' ')}
                </span>
                <ChevronDown className="h-3 w-3 text-slate-400" />
              </button>

              {showRoleMenu && (
                <div className="absolute right-0 mt-2 w-56 bg-slate-800 border border-slate-700 rounded-xl shadow-2xl py-2 z-50">
                  <div className="px-3 py-1.5 text-[11px] font-semibold text-slate-400 uppercase tracking-wider border-b border-slate-700">
                    Switch Active Persona Role
                  </div>
                  {roles.map((r) => (
                    <button
                      key={r.key}
                      onClick={() => {
                        setCurrentUserRole(r.key);
                        setShowRoleMenu(false);
                      }}
                      className={`w-full text-left px-3 py-2 text-xs hover:bg-slate-700/60 transition ${
                        currentUser.role === r.key ? 'bg-teal-600/20 text-teal-300 font-semibold' : 'text-slate-300'
                      }`}
                    >
                      {r.label}
                    </button>
                  ))}
                </div>
              )}
            </div>

            {/* Notifications Bell */}
            <div className="relative">
              <button
                onClick={() => {
                  setShowAlertsDropdown(!showAlertsDropdown);
                  setShowCompanyMenu(false);
                  setShowRoleMenu(false);
                }}
                className="relative p-2 text-slate-400 hover:text-white rounded-lg hover:bg-slate-800 transition"
                title="System Notifications & Expiries"
              >
                <Bell className="h-5 w-5" />
                {totalAlerts > 0 && (
                  <span className="absolute top-1 right-1 h-4 w-4 rounded-full bg-red-500 text-[10px] font-bold flex items-center justify-center text-white ring-2 ring-slate-900">
                    {totalAlerts}
                  </span>
                )}
              </button>

              {showAlertsDropdown && (
                <div className="absolute right-0 mt-2 w-80 bg-slate-800 border border-slate-700 rounded-xl shadow-2xl p-3 z-50">
                  <div className="flex items-center justify-between pb-2 border-b border-slate-700">
                    <span className="text-xs font-semibold text-white uppercase tracking-wider">
                      Fleet Alerts & Warnings
                    </span>
                    <span className="text-[10px] text-slate-400">{totalAlerts} active</span>
                  </div>
                  <div className="mt-2 space-y-2 max-h-60 overflow-y-auto">
                    {expiredDocsCount > 0 && (
                      <div className="p-2.5 rounded-lg bg-red-500/10 border border-red-500/20 text-xs text-red-300 flex items-start space-x-2">
                        <AlertTriangle className="h-4 w-4 shrink-0 text-red-400 mt-0.5" />
                        <div>
                          <p className="font-semibold text-red-200">Compliance Document Expired</p>
                          <p className="text-[11px] text-red-300/80">
                            {expiredDocsCount} vehicle document(s) expired. Compliance lockout triggered.
                          </p>
                        </div>
                      </div>
                    )}
                    {maintenanceVehiclesCount > 0 && (
                      <div className="p-2.5 rounded-lg bg-amber-500/10 border border-amber-500/20 text-xs text-amber-300 flex items-start space-x-2">
                        <AlertTriangle className="h-4 w-4 shrink-0 text-amber-400 mt-0.5" />
                        <div>
                          <p className="font-semibold text-amber-200">Vehicles in Maintenance</p>
                          <p className="text-[11px] text-amber-300/80">
                            {maintenanceVehiclesCount} unit(s) currently out of service.
                          </p>
                        </div>
                      </div>
                    )}
                    {totalAlerts === 0 && (
                      <div className="py-4 text-center text-xs text-slate-400">
                        No critical warnings. All systems operational.
                      </div>
                    )}
                  </div>
                </div>
              )}
            </div>

            {/* Reset baseline button */}
            <button
              onClick={resetDemoData}
              className="p-2 text-slate-400 hover:text-amber-400 rounded-lg hover:bg-slate-800 transition"
              title="Reset sample enterprise data"
            >
              <RotateCcw className="h-4 w-4" />
            </button>
          </div>
        </div>
      </div>
    </header>
  );
};
