import type {
  ComplianceDocument,
  FuelLog,
  Invoice,
  MaintenanceTicket,
  Trip,
  Vehicle,
} from '../types';

const DAY_MS = 86_400_000;

export interface DailyOperationsPoint {
  day: string;
  revenue: number;
  fuelCost: number;
  distanceKm: number;
  cargoTonnes: number;
  trips: number;
}

export interface FinancialSnapshot {
  billed: number;
  paid: number;
  outstanding: number;
  overdue: number;
  fuelCost: number;
  maintenanceCost: number;
  operatingContribution: number;
}

export interface ComplianceSnapshot {
  verified: number;
  pending: number;
  expired: number;
  expiringSoon: number;
}

function validDate(value?: string): Date | undefined {
  if (!value) return undefined;
  const date = new Date(value);
  return Number.isNaN(date.getTime()) ? undefined : date;
}

function startOfUtcDay(date: Date): Date {
  return new Date(Date.UTC(date.getUTCFullYear(), date.getUTCMonth(), date.getUTCDate()));
}

function keyForDate(date: Date): string {
  return startOfUtcDay(date).toISOString().slice(0, 10);
}

function displayDay(date: Date): string {
  return new Intl.DateTimeFormat('en-IN', { day: '2-digit', month: 'short', timeZone: 'UTC' }).format(date);
}

function latestOperationalDate(trips: Trip[], fuelLogs: FuelLog[], invoices: Invoice[]): Date {
  const candidates: Date[] = [];
  trips.forEach((trip) => {
    const date = validDate(trip.completedAt ?? trip.startedAt ?? trip.scheduledDeparture ?? trip.createdAt);
    if (date) candidates.push(date);
  });
  fuelLogs.forEach((log) => {
    const date = validDate(log.timestamp);
    if (date) candidates.push(date);
  });
  invoices.forEach((invoice) => {
    const date = validDate(invoice.issueDate);
    if (date) candidates.push(date);
  });

  if (candidates.length === 0) return new Date();
  return new Date(Math.max(...candidates.map((date) => date.getTime())));
}

export function buildDailyOperationsSeries(
  trips: Trip[],
  fuelLogs: FuelLog[],
  invoices: Invoice[],
  days = 7,
): DailyOperationsPoint[] {
  const end = startOfUtcDay(latestOperationalDate(trips, fuelLogs, invoices));
  const points = Array.from({ length: days }, (_, index) => {
    const date = new Date(end.getTime() - (days - 1 - index) * DAY_MS);
    return {
      key: keyForDate(date),
      point: {
        day: displayDay(date),
        revenue: 0,
        fuelCost: 0,
        distanceKm: 0,
        cargoTonnes: 0,
        trips: 0,
      } satisfies DailyOperationsPoint,
    };
  });

  const byKey = new Map(points.map(({ key, point }) => [key, point]));

  trips.forEach((trip) => {
    const date = validDate(trip.completedAt ?? trip.startedAt ?? trip.scheduledDeparture ?? trip.createdAt);
    if (!date) return;
    const point = byKey.get(keyForDate(date));
    if (!point) return;
    point.revenue += Number(trip.freightRevenue) || 0;
    point.distanceKm += Number(trip.route.distanceKm) || 0;
    point.cargoTonnes += (Number(trip.cargo.weightKg) || 0) / 1000;
    point.trips += 1;
  });

  fuelLogs.forEach((log) => {
    const date = validDate(log.timestamp);
    if (!date) return;
    const point = byKey.get(keyForDate(date));
    if (point) point.fuelCost += Number(log.totalCost) || 0;
  });

  // Invoice totals are deliberately not added to trip revenue here to avoid double counting.
  // Invoice data is represented in the finance snapshot instead.
  return points.map(({ point }) => point);
}

export function getFinancialSnapshot(
  trips: Trip[],
  fuelLogs: FuelLog[],
  maintenanceTickets: MaintenanceTicket[],
  invoices: Invoice[],
): FinancialSnapshot {
  const billed = invoices.reduce((sum, invoice) => sum + (Number(invoice.totalAmount) || 0), 0);
  const paid = invoices
    .filter((invoice) => invoice.status === 'paid')
    .reduce((sum, invoice) => sum + (Number(invoice.totalAmount) || 0), 0);
  const overdue = invoices
    .filter((invoice) => invoice.status === 'overdue')
    .reduce((sum, invoice) => sum + (Number(invoice.totalAmount) || 0), 0);
  const outstanding = Math.max(0, billed - paid);
  const fuelCost = fuelLogs.reduce((sum, log) => sum + (Number(log.totalCost) || 0), 0);
  const maintenanceCost = maintenanceTickets.reduce(
    (sum, ticket) => sum + (Number(ticket.actualCost ?? ticket.estimatedCost) || 0),
    0,
  );
  const completedTripRevenue = trips
    .filter((trip) => trip.status === 'completed')
    .reduce((sum, trip) => sum + (Number(trip.freightRevenue) || 0), 0);

  return {
    billed,
    paid,
    outstanding,
    overdue,
    fuelCost,
    maintenanceCost,
    operatingContribution: completedTripRevenue - fuelCost - maintenanceCost,
  };
}

export function getComplianceSnapshot(
  complianceDocs: ComplianceDocument[],
  now = new Date(),
  soonDays = 30,
): ComplianceSnapshot {
  let verified = 0;
  let pending = 0;
  let expired = 0;
  let expiringSoon = 0;
  const nowMs = now.getTime();
  const soonMs = soonDays * DAY_MS;

  complianceDocs.forEach((doc) => {
    const expiry = validDate(doc.expiryDate);
    const isExpired = doc.verificationStatus === 'expired' || (!!expiry && expiry.getTime() < nowMs);
    if (isExpired) {
      expired += 1;
      return;
    }

    if (doc.verificationStatus === 'pending') pending += 1;
    else verified += 1;

    if (expiry) {
      const remaining = expiry.getTime() - nowMs;
      if (remaining >= 0 && remaining <= soonMs) expiringSoon += 1;
    }
  });

  return { verified, pending, expired, expiringSoon };
}

export function getFleetStatusSeries(vehicles: Vehicle[]) {
  const activeVehicles = vehicles.filter((vehicle) => !vehicle.deletedAt);
  const statuses: Array<Vehicle['status']> = ['active', 'idle', 'maintenance', 'registration', 'sold', 'archived'];
  return statuses
    .map((status) => ({
      name: status.replace('_', ' ').replace(/\b\w/g, (letter) => letter.toUpperCase()),
      value: activeVehicles.filter((vehicle) => vehicle.status === status).length,
    }))
    .filter((entry) => entry.value > 0);
}

export function getFuelEfficiency(fuelLogs: FuelLog[]): number | null {
  const valid = fuelLogs.filter((log) => Number.isFinite(log.calcEconomyKmPerLiter) && log.calcEconomyKmPerLiter > 0);
  if (valid.length === 0) return null;
  return valid.reduce((sum, log) => sum + log.calcEconomyKmPerLiter, 0) / valid.length;
}
