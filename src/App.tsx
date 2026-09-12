import React, { useState } from 'react';
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

const FleetAppContent: React.FC = () => {
  const [activeTab, setActiveTab] = useState<ActiveTab>('dashboard');
  const { currentUser } = useFleet();

  if (currentUser.role === 'driver') {
    return (
      <div className="min-h-screen bg-slate-50 dark:bg-slate-950 text-slate-900 dark:text-slate-100 flex flex-col font-sans transition-colors">
        <Header />
        <main className="flex-1 p-4 sm:p-6 lg:p-8 overflow-y-auto">
          <DriverPortalView />
        </main>
        <Toasts />
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-slate-50 dark:bg-slate-950 text-slate-900 dark:text-slate-100 flex flex-col font-sans transition-colors">
      <Header />

      <div className="flex-1 flex flex-col md:flex-row max-w-7xl w-full mx-auto">
        <Sidebar activeTab={activeTab} setActiveTab={setActiveTab} />

        <main className="flex-1 p-4 sm:p-6 lg:p-8 min-w-0 overflow-y-auto max-h-[calc(100vh-4rem)]">
          {activeTab === 'dashboard' && <DashboardView onNavigateTab={setActiveTab} />}
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
    <FleetProvider>
      <FleetAppContent />
    </FleetProvider>
  );
};

export default App;
