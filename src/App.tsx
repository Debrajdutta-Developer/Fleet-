import React, { useEffect, useState } from 'react';
import { FleetProvider, useFleet } from './context/FleetContext';
import { Header } from './components/Header';
import { Sidebar, ActiveTab } from './components/Sidebar';
import { Toasts } from './components/Toasts';
import { DashboardView } from './views/DashboardView';
import { VehiclesView } from './views/VehiclesView';
import { TripsView } from './views/TripsView';
import { DriversView } from './views/DriversView';
import { MaintenanceFuelView } from './views/MaintenanceFuelView';
import { ComplianceVaultView } from './views/ComplianceVaultView';
import { BillingView } from './views/BillingView';
import { AuditLogsView } from './views/AuditLogsView';
import { HRView } from './views/HRView';
import { DriverPortalView } from './views/DriverPortalView';
import { KhalashiPortalView } from './views/KhalashiPortalView';
import { OidcAuthGate } from './auth/OidcAuthGate';
import { canOpenTab, firstAllowedTab, portalForRole } from './auth/roleAccess';

const RestrictedShell: React.FC<{ children: React.ReactNode }> = ({ children }) => (
  <div className="min-h-screen bg-slate-50 dark:bg-slate-950 text-slate-900 dark:text-slate-100 flex flex-col font-sans transition-colors">
    <Header />
    <main className="flex-1 p-4 sm:p-6 lg:p-8 overflow-y-auto">{children}</main>
    <Toasts />
  </div>
);

const FleetAppContent: React.FC = () => {
  const { currentUser } = useFleet();
  const [activeTab, setActiveTab] = useState<ActiveTab>(() => firstAllowedTab(currentUser.role));
  const portal = portalForRole(currentUser.role);

  useEffect(() => {
    if (!canOpenTab(currentUser.role, activeTab)) {
      setActiveTab(firstAllowedTab(currentUser.role));
    }
  }, [activeTab, currentUser.role]);

  if (portal === 'driver') {
    return (
      <RestrictedShell>
        <DriverPortalView />
      </RestrictedShell>
    );
  }

  if (portal === 'khalashi') {
    return (
      <RestrictedShell>
        <KhalashiPortalView />
      </RestrictedShell>
    );
  }

  if (!canOpenTab(currentUser.role, activeTab)) {
    return (
      <RestrictedShell>
        <div className="mx-auto max-w-xl rounded-2xl border border-amber-200 bg-amber-50 p-6 text-amber-900 dark:border-amber-900/60 dark:bg-amber-950/30 dark:text-amber-200">
          This account is not authorized to open that FleetOS section.
        </div>
      </RestrictedShell>
    );
  }

  return (
    <div className="min-h-screen bg-slate-50 dark:bg-slate-950 text-slate-900 dark:text-slate-100 flex flex-col font-sans transition-colors">
      <Header />

      <div className="flex-1 flex flex-col md:flex-row max-w-7xl w-full mx-auto">
        <Sidebar activeTab={activeTab} setActiveTab={(tab) => canOpenTab(currentUser.role, tab) && setActiveTab(tab)} />

        <main className="flex-1 p-4 sm:p-6 lg:p-8 min-w-0 overflow-y-auto max-h-[calc(100vh-4rem)]">
          {activeTab === 'dashboard' && <DashboardView onNavigateTab={(tab) => canOpenTab(currentUser.role, tab) && setActiveTab(tab)} />}
          {activeTab === 'vehicles' && <VehiclesView />}
          {activeTab === 'trips' && <TripsView />}
          {activeTab === 'drivers' && <DriversView />}
          {activeTab === 'hr' && <HRView />}
          {activeTab === 'maintenance' && <MaintenanceFuelView />}
          {activeTab === 'compliance' && <ComplianceVaultView />}
          {activeTab === 'billing' && <BillingView />}
          {activeTab === 'audit' && <AuditLogsView />}
        </main>
      </div>

      <Toasts />
    </div>
  );
};

export const App: React.FC = () => {
  return (
    <OidcAuthGate>
      <FleetProvider>
        <FleetAppContent />
      </FleetProvider>
    </OidcAuthGate>
  );
};

export default App;
