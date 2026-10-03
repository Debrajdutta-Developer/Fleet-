import type { UserRole } from '../types';
import type { ActiveTab } from '../components/Sidebar';

export type PortalKind = 'owner' | 'manager' | 'accountant' | 'driver' | 'khalashi' | 'operations';

const NO_TABS = new Set<ActiveTab>();
const OWNER_TABS = new Set<ActiveTab>([
  'dashboard', 'vehicles', 'trips', 'drivers', 'hr', 'maintenance', 'compliance', 'billing', 'audit',
]);
const MANAGER_TABS = new Set<ActiveTab>([
  'dashboard', 'vehicles', 'trips', 'drivers', 'hr', 'maintenance', 'compliance', 'billing',
]);
const ACCOUNTANT_TABS = new Set<ActiveTab>(['dashboard', 'billing']);
const OPERATIONS_TABS = new Set<ActiveTab>([
  'dashboard', 'vehicles', 'trips', 'drivers', 'maintenance', 'compliance',
]);

export function portalForRole(role: UserRole): PortalKind {
  if (role === 'driver') return 'driver';
  if (role === 'khalashi') return 'khalashi';
  if (role === 'accountant') return 'accountant';
  if (role === 'owner' || role === 'company_admin' || role === 'super_admin') return 'owner';
  if (role === 'manager' || role === 'fleet_manager' || role === 'hr_manager') return 'manager';
  return 'operations';
}

export function allowedTabsForRole(role: UserRole): ReadonlySet<ActiveTab> {
  const portal = portalForRole(role);
  if (portal === 'owner') return OWNER_TABS;
  if (portal === 'manager') return MANAGER_TABS;
  if (portal === 'accountant') return ACCOUNTANT_TABS;
  if (portal === 'driver' || portal === 'khalashi') return NO_TABS;
  return OPERATIONS_TABS;
}

export function firstAllowedTab(role: UserRole): ActiveTab {
  return portalForRole(role) === 'accountant' ? 'billing' : 'dashboard';
}

export function canOpenTab(role: UserRole, tab: ActiveTab): boolean {
  return allowedTabsForRole(role).has(tab);
}
