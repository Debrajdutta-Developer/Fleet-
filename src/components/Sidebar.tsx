import React from 'react';
import {
  LayoutDashboard,
  Truck,
  Route,
  Users,
  Briefcase,
  Wrench,
  FileCheck2,
  Receipt,
  History,
  CreditCard,
} from 'lucide-react';
import { useFleet } from '../context/FleetContext';
import { allowedTabsForRole } from '../auth/roleAccess';

export type ActiveTab =
  | 'dashboard'
  | 'vehicles'
  | 'trips'
  | 'drivers'
  | 'hr'
  | 'maintenance'
  | 'compliance'
  | 'billing'
  | 'audit';

interface SidebarProps {
  activeTab: ActiveTab;
  setActiveTab: (tab: ActiveTab) => void;
}

export const Sidebar: React.FC<SidebarProps> = ({ activeTab, setActiveTab }) => {
  const { vehicles, trips, drivers, complianceDocs, currentCompany, currentUser, employees, leaveRequests } = useFleet();
  const allowedTabs = allowedTabsForRole(currentUser.role);

  const activeVehiclesCount = vehicles.filter((v) => v.status === 'active' && !v.deletedAt).length;
  const inTransitTripsCount = trips.filter((t) => t.status === 'in_transit').length;
  const pendingLeaves = leaveRequests.filter((l) => l.companyId === currentCompany.id && l.status === 'pending').length;
  const expiringDocsCount = complianceDocs.filter((d) => {
    if (d.verificationStatus === 'expired') return true;
    const expiry = new Date(d.expiryDate).getTime();
    const now = Date.now();
    const days = (expiry - now) / (1000 * 60 * 60 * 24);
    return days <= 15;
  }).length;

  const navItems = [
    { id: 'dashboard' as ActiveTab, label: 'Command Center', icon: LayoutDashboard, badge: null },
    {
      id: 'vehicles' as ActiveTab,
      label: 'Fleet & Telemetry',
      icon: Truck,
      badge: `${activeVehiclesCount} Active`,
      badgeColor: 'bg-blue-100 text-blue-800 dark:bg-blue-900/40 dark:text-blue-300',
    },
    {
      id: 'trips' as ActiveTab,
      label: 'Trip Dispatch',
      icon: Route,
      badge: inTransitTripsCount > 0 ? `${inTransitTripsCount} Live` : null,
      badgeColor: 'bg-emerald-100 text-emerald-800 dark:bg-emerald-900/40 dark:text-emerald-300',
    },
    {
      id: 'drivers' as ActiveTab,
      label: 'Drivers & Safety',
      icon: Users,
      badge: `${drivers.length}`,
      badgeColor: 'bg-slate-100 text-slate-700 dark:bg-slate-800 dark:text-slate-300',
    },
    {
      id: 'hr' as ActiveTab,
      label: 'HR & Workforce',
      icon: Briefcase,
      badge: pendingLeaves > 0 ? `${pendingLeaves} Leave` : `${employees.filter((e) => e.companyId === currentCompany.id && !e.deletedAt).length} Staff`,
      badgeColor: pendingLeaves > 0 ? 'bg-amber-100 text-amber-800 dark:bg-amber-900/40 dark:text-amber-300' : 'bg-purple-100 text-purple-800 dark:bg-purple-900/40 dark:text-purple-300',
    },
    { id: 'maintenance' as ActiveTab, label: 'Maintenance & Fuel', icon: Wrench, badge: null },
    {
      id: 'compliance' as ActiveTab,
      label: 'Compliance Vault',
      icon: FileCheck2,
      badge: expiringDocsCount > 0 ? `${expiringDocsCount} Alert` : null,
      badgeColor: 'bg-amber-100 text-amber-800 dark:bg-amber-900/40 dark:text-amber-300',
    },
    { id: 'billing' as ActiveTab, label: 'Billing & Financials', icon: Receipt, badge: null },
    { id: 'audit' as ActiveTab, label: 'Audit Trail & Logs', icon: History, badge: null },
  ].filter((item) => allowedTabs.has(item.id));

  return (
    <aside className="w-full md:w-64 bg-white dark:bg-slate-900 border-r border-slate-200 dark:border-slate-800 flex flex-col shrink-0">
      <div className="p-3 space-y-1 flex-1 overflow-y-auto">
        <div className="px-3 py-2 text-[11px] font-semibold text-slate-400 dark:text-slate-500 uppercase tracking-wider">
          Operations Platform
        </div>
        {navItems.map((item) => {
          const Icon = item.icon;
          const isActive = activeTab === item.id;
          return (
            <button
              key={item.id}
              onClick={() => setActiveTab(item.id)}
              className={`w-full flex items-center justify-between px-3 py-2.5 rounded-lg text-sm font-medium transition-all ${
                isActive
                  ? 'bg-blue-600 text-white shadow-sm shadow-blue-500/20'
                  : 'text-slate-700 dark:text-slate-300 hover:bg-slate-100 dark:hover:bg-slate-800/80'
              }`}
            >
              <div className="flex items-center space-x-3">
                <Icon className={`h-4 w-4 ${isActive ? 'text-white' : 'text-slate-400'}`} />
                <span className="truncate">{item.label}</span>
              </div>
              {item.badge && (
                <span className={`text-[10px] font-bold px-1.5 py-0.5 rounded-full ${isActive ? 'bg-white/20 text-white' : item.badgeColor}`}>
                  {item.badge}
                </span>
              )}
            </button>
          );
        })}
      </div>

      {allowedTabs.has('billing') && (
        <div className="p-4 m-3 bg-slate-50 dark:bg-slate-800/60 border border-slate-200 dark:border-slate-700/60 rounded-xl">
          <div className="flex items-center justify-between text-xs text-slate-500 dark:text-slate-400 mb-1">
            <span className="flex items-center space-x-1 font-medium">
              <CreditCard className="h-3.5 w-3.5 text-teal-500" />
              <span>FASTag Toll Pool</span>
            </span>
            <span className="font-semibold text-slate-700 dark:text-slate-200">
              {currentCompany.currency || 'INR'} {currentCompany.fastagBalance.toFixed(2)}
            </span>
          </div>
          <div className="w-full bg-slate-200 dark:bg-slate-700 h-1.5 rounded-full overflow-hidden mt-1.5">
            <div
              className={`h-full rounded-full transition-all ${currentCompany.fastagBalance < 500 ? 'bg-amber-500' : 'bg-teal-500'}`}
              style={{ width: `${Math.min(100, (currentCompany.fastagBalance / 5000) * 100)}%` }}
            />
          </div>
          <div className="flex justify-between items-center mt-2 text-[11px]">
            <span className="text-slate-400">Status: Active</span>
            <button onClick={() => setActiveTab('billing')} className="text-blue-600 dark:text-blue-400 hover:underline font-medium">
              Manage Tolls &rarr;
            </button>
          </div>
        </div>
      )}
    </aside>
  );
};
