const LEGACY_FLEETOS_KEYS = [
  'fleetos_companies',
  'fleetos_current_company',
  'fleetos_current_user',
  'fleetos_vehicles',
  'fleetos_drivers',
  'fleetos_trips',
  'fleetos_fuel_logs',
  'fleetos_maintenance',
  'fleetos_compliance',
  'fleetos_invoices',
  'fleetos_audit_logs',
  'fleetos_departments',
  'fleetos_designations',
  'fleetos_shifts',
  'fleetos_employees',
  'fleetos_attendance',
  'fleetos_leaves',
  'fleetos_payroll',
];

/** Remove browser-local demo/seed state before the production data layer starts. */
export function purgeLegacyDemoState(): void {
  if (typeof window === 'undefined') return;
  for (const key of LEGACY_FLEETOS_KEYS) window.localStorage.removeItem(key);
}
