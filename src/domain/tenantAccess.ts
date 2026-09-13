import type { UserRole } from '../types';

export type FleetPermission =
  | 'fleet.read'
  | 'fleet.write'
  | 'trip.dispatch'
  | 'driver.manage'
  | 'finance.read'
  | 'finance.write'
  | 'compliance.manage'
  | 'hr.manage'
  | 'audit.read';

export interface TenantPrincipal {
  userId: string;
  companyId: string;
  role: UserRole;
  status: 'active' | 'suspended' | 'pending';
}

export interface TenantResource {
  companyId: string;
}

const ADMIN_PERMISSIONS: readonly FleetPermission[] = [
  'fleet.read',
  'fleet.write',
  'trip.dispatch',
  'driver.manage',
  'finance.read',
  'finance.write',
  'compliance.manage',
  'hr.manage',
  'audit.read',
];

const ROLE_PERMISSIONS: Record<UserRole, readonly FleetPermission[]> = {
  super_admin: ADMIN_PERMISSIONS,
  company_admin: ADMIN_PERMISSIONS,
  owner: ADMIN_PERMISSIONS,
  manager: [
    'fleet.read',
    'fleet.write',
    'trip.dispatch',
    'driver.manage',
    'finance.read',
    'compliance.manage',
    'hr.manage',
    'audit.read',
  ],
  fleet_manager: [
    'fleet.read',
    'fleet.write',
    'trip.dispatch',
    'driver.manage',
    'compliance.manage',
    'audit.read',
  ],
  dispatcher: ['fleet.read', 'trip.dispatch'],
  driver: ['fleet.read'],
  khalashi: ['fleet.read'],
  accountant: ['fleet.read', 'finance.read', 'finance.write'],
  compliance: ['fleet.read', 'compliance.manage', 'audit.read'],
  hr_manager: ['hr.manage'],
};

export function hasPermission(principal: TenantPrincipal, permission: FleetPermission): boolean {
  return principal.status === 'active' && ROLE_PERMISSIONS[principal.role].includes(permission);
}

export function canAccessTenantResource(
  principal: TenantPrincipal,
  resource: TenantResource,
  permission: FleetPermission,
): boolean {
  if (principal.status !== 'active') return false;
  if (principal.companyId !== resource.companyId) return false;
  return hasPermission(principal, permission);
}

export function assertTenantAccess(
  principal: TenantPrincipal,
  resource: TenantResource,
  permission: FleetPermission,
): void {
  if (!canAccessTenantResource(principal, resource, permission)) {
    throw new Error('Tenant access denied');
  }
}

export function permissionsForRole(role: UserRole): readonly FleetPermission[] {
  return ROLE_PERMISSIONS[role];
}
