import React, { useState } from 'react';
import { useFleet } from '../context/FleetContext';
import { Driver, DriverStatus } from '../types';
import {
  Users,
  Plus,
  Search,
  ShieldCheck,
  ShieldAlert,
  Truck,
  Phone,
  Mail,
  Calendar,
  AlertTriangle,
  Award,
  Clock,
  X,
  CheckCircle2
} from 'lucide-react';

export const DriversView: React.FC = () => {
  const { drivers, vehicles, addDriver, assignDriverToVehicle } = useFleet();

  const [searchQuery, setSearchQuery] = useState('');
  const [cdlFilter, setCdlFilter] = useState<string>('all');
  const [showAddModal, setShowAddModal] = useState(false);
  const [assignModalDriver, setAssignModalDriver] = useState<Driver | null>(null);
  const [targetVehicleId, setTargetVehicleId] = useState<string>('');

  // Add Driver Form state
  const [fullName, setFullName] = useState('');
  const [phone, setPhone] = useState('+1 (555) ');
  const [email, setEmail] = useState('');
  const [licenseNumber, setLicenseNumber] = useState('');
  const [cdlClass, setCdlClass] = useState<'Class A' | 'Class B'>('Class A');
  const [licenseExpiry, setLicenseExpiry] = useState('2028-06-30');
  const [safetyScore, setSafetyScore] = useState(95);

  const filteredDrivers = drivers.filter((driver) => {
    if (cdlFilter !== 'all' && driver.cdlClass !== cdlFilter) return false;
    if (searchQuery.trim()) {
      const q = searchQuery.toLowerCase();
      return (
        driver.fullName.toLowerCase().includes(q) ||
        driver.licenseNumber.toLowerCase().includes(q) ||
        driver.email.toLowerCase().includes(q)
      );
    }
    return true;
  });

  const handleCreateDriver = (e: React.FormEvent) => {
    e.preventDefault();
    if (!fullName.trim() || !licenseNumber.trim()) return;

    const res = addDriver({
      fullName,
      phone,
      email: email || `${fullName.toLowerCase().replace(/\s+/g, '.')}@apexlogistics.com`,
      licenseNumber,
      cdlClass,
      licenseExpiry,
      status: 'available',
      safetyScore: Number(safetyScore),
      totalTripsCompleted: 0,
      hoursDrivenThisWeek: 0,
      infractions: {
        hardBrakingCount: 0,
        speedingCount: 0,
        rapidAccelCount: 0,
      },
    });

    if (res.success) {
      setShowAddModal(false);
      setFullName('');
      setLicenseNumber('');
    }
  };

  const handleAssignVehicle = (e: React.FormEvent) => {
    e.preventDefault();
    if (!assignModalDriver) return;

    const res = assignDriverToVehicle(assignModalDriver.id, targetVehicleId || null);
    if (res.success) {
      setAssignModalDriver(null);
      setTargetVehicleId('');
    }
  };

  return (
    <div className="space-y-6 pb-12">
      {/* Header & Add Driver */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold text-slate-900 dark:text-white font-display">
            Driver Roster & Safety Telemetry
          </h1>
          <p className="text-sm text-slate-500 dark:text-slate-400">
            Hours of Service (HOS), CDL compliance tracking, and telemetry safety scoring
          </p>
        </div>

        <button
          onClick={() => setShowAddModal(true)}
          className="flex items-center space-x-2 px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-lg text-sm font-semibold shadow-sm transition"
        >
          <Plus className="h-4 w-4" />
          <span>Enroll New Driver</span>
        </button>
      </div>

      {/* Filter and Search */}
      <div className="flex flex-col sm:flex-row items-stretch sm:items-center justify-between gap-3 bg-white dark:bg-slate-800/90 border border-slate-200 dark:border-slate-700/80 rounded-xl p-3 shadow-sm">
        <div className="relative flex-1">
          <Search className="absolute left-3 top-2.5 h-4 w-4 text-slate-400" />
          <input
            type="text"
            placeholder="Search drivers by name, license number, email..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            className="w-full pl-9 pr-4 py-2 bg-slate-50 dark:bg-slate-900 border border-slate-200 dark:border-slate-700 rounded-lg text-sm text-slate-900 dark:text-white focus:outline-none focus:ring-2 focus:ring-blue-500"
          />
        </div>

        <div className="flex items-center space-x-1.5 overflow-x-auto pb-1 sm:pb-0">
          {['all', 'Class A', 'Class B'].map((cdl) => (
            <button
              key={cdl}
              onClick={() => setCdlFilter(cdl)}
              className={`px-3 py-1.5 rounded-lg text-xs font-semibold uppercase tracking-wider transition ${
                cdlFilter === cdl
                  ? 'bg-blue-600 text-white'
                  : 'bg-slate-100 dark:bg-slate-700/60 text-slate-600 dark:text-slate-300 hover:bg-slate-200'
              }`}
            >
              {cdl === 'all' ? 'All Classes' : cdl}
            </button>
          ))}
        </div>
      </div>

      {/* Driver Cards Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
        {filteredDrivers.map((driver) => {
          const assignedVehicle = vehicles.find((v) => v.id === driver.assignedVehicleId);
          const isScoreLow = driver.safetyScore < 70;
          const expiryDate = new Date(driver.licenseExpiry);
          const isExpiringSoon = (expiryDate.getTime() - Date.now()) / (1000 * 3600 * 24) < 45;

          return (
            <div
              key={driver.id}
              className={`bg-white dark:bg-slate-800/90 border rounded-xl p-5 shadow-sm flex flex-col justify-between ${
                isScoreLow
                  ? 'border-red-300 dark:border-red-900/60'
                  : 'border-slate-200 dark:border-slate-700/80'
              }`}
            >
              <div>
                {/* Header: Name, Status */}
                <div className="flex items-start justify-between">
                  <div className="flex items-center space-x-3">
                    <div className="h-10 w-10 rounded-full bg-blue-100 dark:bg-blue-900/40 text-blue-700 dark:text-blue-300 font-bold flex items-center justify-center text-sm">
                      {driver.fullName
                        .split(' ')
                        .map((n) => n[0])
                        .join('')}
                    </div>
                    <div>
                      <h3 className="font-bold text-base text-slate-900 dark:text-white">
                        {driver.fullName}
                      </h3>
                      <span className="text-xs text-slate-500 font-mono">
                        {driver.cdlClass} • {driver.licenseNumber}
                      </span>
                    </div>
                  </div>

                  <span
                    className={`text-[10px] font-bold uppercase px-2 py-0.5 rounded-full ${
                      driver.status === 'on_duty'
                        ? 'bg-emerald-100 text-emerald-800 dark:bg-emerald-900/40 dark:text-emerald-300'
                        : driver.status === 'suspended'
                        ? 'bg-red-100 text-red-800 dark:bg-red-900/40 dark:text-red-300'
                        : 'bg-slate-100 text-slate-800 dark:bg-slate-700 dark:text-slate-300'
                    }`}
                  >
                    {driver.status.replace('_', ' ')}
                  </span>
                </div>

                {/* Safety Score Meter */}
                <div className="mt-4 p-3 rounded-lg bg-slate-50 dark:bg-slate-900/60 border border-slate-200 dark:border-slate-700/60">
                  <div className="flex items-center justify-between text-xs mb-1.5">
                    <span className="font-medium text-slate-600 dark:text-slate-300 flex items-center space-x-1">
                      <Award className="h-3.5 w-3.5 text-blue-500" />
                      <span>Telemetry Safety Score</span>
                    </span>
                    <span
                      className={`font-bold ${
                        driver.safetyScore >= 90
                          ? 'text-emerald-600 dark:text-emerald-400'
                          : driver.safetyScore >= 70
                          ? 'text-blue-600 dark:text-blue-400'
                          : 'text-red-600 dark:text-red-400'
                      }`}
                    >
                      {driver.safetyScore} / 100
                    </span>
                  </div>

                  <div className="w-full bg-slate-200 dark:bg-slate-700 h-2 rounded-full overflow-hidden">
                    <div
                      className={`h-full rounded-full transition-all ${
                        driver.safetyScore >= 90
                          ? 'bg-emerald-500'
                          : driver.safetyScore >= 70
                          ? 'bg-blue-600'
                          : 'bg-red-500'
                      }`}
                      style={{ width: `${driver.safetyScore}%` }}
                    />
                  </div>

                  {isScoreLow && (
                    <p className="text-[10px] text-red-500 font-semibold mt-1 flex items-center space-x-1">
                      <AlertTriangle className="h-3 w-3" />
                      <span>Safety score &lt;70% blocks Class A heavy assignments</span>
                    </p>
                  )}
                </div>

                {/* Telemetry Infractions Tracker */}
                <div className="mt-3 grid grid-cols-3 gap-1.5 text-center text-xs">
                  <div className="bg-slate-50 dark:bg-slate-900/40 p-2 rounded-lg border border-slate-200 dark:border-slate-700/40">
                    <span className="text-[10px] text-slate-400 block">Hard Brakes</span>
                    <span className="font-bold text-slate-800 dark:text-slate-200">
                      {driver.infractions.hardBrakingCount}
                    </span>
                  </div>
                  <div className="bg-slate-50 dark:bg-slate-900/40 p-2 rounded-lg border border-slate-200 dark:border-slate-700/40">
                    <span className="text-[10px] text-slate-400 block">Speeding</span>
                    <span className="font-bold text-slate-800 dark:text-slate-200">
                      {driver.infractions.speedingCount}
                    </span>
                  </div>
                  <div className="bg-slate-50 dark:bg-slate-900/40 p-2 rounded-lg border border-slate-200 dark:border-slate-700/40">
                    <span className="text-[10px] text-slate-400 block">Rapid Accel</span>
                    <span className="font-bold text-slate-800 dark:text-slate-200">
                      {driver.infractions.rapidAccelCount}
                    </span>
                  </div>
                </div>

                {/* Assignment & Hours info */}
                <div className="mt-3 space-y-1 text-xs text-slate-500">
                  <p className="flex items-center justify-between">
                    <span>Assigned Vehicle:</span>
                    <span className="font-semibold text-slate-800 dark:text-slate-200">
                      {assignedVehicle ? `${assignedVehicle.licensePlate} (${assignedVehicle.make})` : 'None'}
                    </span>
                  </p>
                  <p className="flex items-center justify-between">
                    <span>HOS Driven (This Week):</span>
                    <span className="font-semibold text-slate-800 dark:text-slate-200">
                      {driver.hoursDrivenThisWeek} hrs (Limit: 60h)
                    </span>
                  </p>
                  <p className="flex items-center justify-between">
                    <span>License Expiry:</span>
                    <span className={`font-semibold ${isExpiringSoon ? 'text-amber-500' : 'text-slate-800 dark:text-slate-200'}`}>
                      {driver.licenseExpiry}
                    </span>
                  </p>
                </div>
              </div>

              {/* Card Action */}
              <div className="mt-4 pt-3 border-t border-slate-100 dark:border-slate-700/60 flex items-center justify-between">
                <span className="text-[11px] text-slate-400">
                  {driver.totalTripsCompleted} trips logged
                </span>

                <button
                  onClick={() => {
                    setAssignModalDriver(driver);
                    setTargetVehicleId(driver.assignedVehicleId || '');
                  }}
                  className="px-3 py-1.5 bg-blue-50 dark:bg-blue-900/30 hover:bg-blue-100 text-blue-600 dark:text-blue-300 rounded-lg text-xs font-semibold transition"
                >
                  {driver.assignedVehicleId ? 'Change Vehicle' : 'Assign Vehicle'}
                </button>
              </div>
            </div>
          );
        })}
      </div>

      {/* Assign Vehicle Modal */}
      {assignModalDriver && (
        <div className="fixed inset-0 z-50 bg-slate-950/60 backdrop-blur-sm flex items-center justify-center p-4">
          <div className="bg-white dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-2xl max-w-md w-full p-6 shadow-2xl">
            <div className="flex items-center justify-between border-b border-slate-200 dark:border-slate-700 pb-3">
              <h3 className="text-base font-bold text-slate-900 dark:text-white font-display">
                Vehicle Assignment: {assignModalDriver.fullName}
              </h3>
              <button onClick={() => setAssignModalDriver(null)} className="text-slate-400 hover:text-white">
                <X className="h-5 w-5" />
              </button>
            </div>

            <form onSubmit={handleAssignVehicle} className="mt-4 space-y-4 text-sm">
              <div>
                <label className="block text-xs font-medium text-slate-700 dark:text-slate-300 mb-1">
                  Select Fleet Vehicle
                </label>
                <select
                  value={targetVehicleId}
                  onChange={(e) => setTargetVehicleId(e.target.value)}
                  className="w-full px-3 py-2 bg-slate-50 dark:bg-slate-900 border border-slate-200 dark:border-slate-700 rounded-lg text-xs"
                >
                  <option value="">-- No Vehicle (Unassign / Available) --</option>
                  {vehicles
                    .filter((v) => !v.deletedAt)
                    .map((v) => (
                      <option key={v.id} value={v.id}>
                        {v.licensePlate} ({v.make} {v.model}) [{v.status.toUpperCase()}] - {v.cdlRequired}
                      </option>
                    ))}
                </select>
              </div>

              <div className="p-3 bg-slate-50 dark:bg-slate-900/60 rounded-xl border border-slate-200 dark:border-slate-700 text-xs text-slate-500 space-y-1">
                <p>• Driver CDL Class: <b>{assignModalDriver.cdlClass}</b></p>
                <p>• Telemetry Safety Rating: <b>{assignModalDriver.safetyScore}%</b> (min 70% for Class A)</p>
              </div>

              <div className="flex justify-end space-x-3 pt-3 border-t border-slate-200 dark:border-slate-700">
                <button
                  type="button"
                  onClick={() => setAssignModalDriver(null)}
                  className="px-4 py-2 text-xs font-medium text-slate-600 dark:text-slate-300"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  className="px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white text-xs font-semibold rounded-lg shadow-sm"
                >
                  Save Assignment
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Add Driver Modal */}
      {showAddModal && (
        <div className="fixed inset-0 z-50 bg-slate-950/60 backdrop-blur-sm flex items-center justify-center p-4">
          <div className="bg-white dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-2xl max-w-lg w-full p-6 shadow-2xl">
            <div className="flex items-center justify-between border-b border-slate-200 dark:border-slate-700 pb-3">
              <h3 className="text-lg font-bold text-slate-900 dark:text-white font-display">
                Enroll New Certified Driver
              </h3>
              <button onClick={() => setShowAddModal(false)} className="text-slate-400 hover:text-white">
                <X className="h-5 w-5" />
              </button>
            </div>

            <form onSubmit={handleCreateDriver} className="mt-4 space-y-4 text-sm">
              <div>
                <label className="block text-xs font-medium text-slate-700 dark:text-slate-300 mb-1">
                  Full Legal Name *
                </label>
                <input
                  type="text"
                  required
                  placeholder="e.g. Marcus Alexander"
                  value={fullName}
                  onChange={(e) => setFullName(e.target.value)}
                  className="w-full px-3 py-2 bg-slate-50 dark:bg-slate-900 border border-slate-200 dark:border-slate-700 rounded-lg text-xs"
                />
              </div>

              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block text-xs font-medium text-slate-700 dark:text-slate-300 mb-1">
                    Phone Number
                  </label>
                  <input
                    type="text"
                    value={phone}
                    onChange={(e) => setPhone(e.target.value)}
                    className="w-full px-3 py-2 bg-slate-50 dark:bg-slate-900 border border-slate-200 dark:border-slate-700 rounded-lg text-xs"
                  />
                </div>

                <div>
                  <label className="block text-xs font-medium text-slate-700 dark:text-slate-300 mb-1">
                    Email Address
                  </label>
                  <input
                    type="email"
                    placeholder="driver@apexlogistics.com"
                    value={email}
                    onChange={(e) => setEmail(e.target.value)}
                    className="w-full px-3 py-2 bg-slate-50 dark:bg-slate-900 border border-slate-200 dark:border-slate-700 rounded-lg text-xs"
                  />
                </div>
              </div>

              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block text-xs font-medium text-slate-700 dark:text-slate-300 mb-1">
                    CDL Class
                  </label>
                  <select
                    value={cdlClass}
                    onChange={(e) => setCdlClass(e.target.value as 'Class A' | 'Class B')}
                    className="w-full px-3 py-2 bg-slate-50 dark:bg-slate-900 border border-slate-200 dark:border-slate-700 rounded-lg text-xs"
                  >
                    <option value="Class A">Class A (Tractor-Trailers &gt;26,000 lbs)</option>
                    <option value="Class B">Class B (Straight Trucks &lt;26,000 lbs)</option>
                  </select>
                </div>

                <div>
                  <label className="block text-xs font-medium text-slate-700 dark:text-slate-300 mb-1">
                    CDL License Number *
                  </label>
                  <input
                    type="text"
                    required
                    placeholder="TX-CDLA-9920148"
                    value={licenseNumber}
                    onChange={(e) => setLicenseNumber(e.target.value)}
                    className="w-full px-3 py-2 bg-slate-50 dark:bg-slate-900 border border-slate-200 dark:border-slate-700 rounded-lg text-xs font-mono uppercase"
                  />
                </div>
              </div>

              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block text-xs font-medium text-slate-700 dark:text-slate-300 mb-1">
                    License Expiration Date
                  </label>
                  <input
                    type="date"
                    value={licenseExpiry}
                    onChange={(e) => setLicenseExpiry(e.target.value)}
                    className="w-full px-3 py-2 bg-slate-50 dark:bg-slate-900 border border-slate-200 dark:border-slate-700 rounded-lg text-xs"
                  />
                </div>

                <div>
                  <label className="block text-xs font-medium text-slate-700 dark:text-slate-300 mb-1">
                    Initial Safety Score (0-100)
                  </label>
                  <input
                    type="number"
                    min={0}
                    max={100}
                    value={safetyScore}
                    onChange={(e) => setSafetyScore(Number(e.target.value))}
                    className="w-full px-3 py-2 bg-slate-50 dark:bg-slate-900 border border-slate-200 dark:border-slate-700 rounded-lg text-xs"
                  />
                </div>
              </div>

              <div className="flex justify-end space-x-3 pt-3 border-t border-slate-200 dark:border-slate-700">
                <button
                  type="button"
                  onClick={() => setShowAddModal(false)}
                  className="px-4 py-2 text-xs font-medium text-slate-600 dark:text-slate-300"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  className="px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white text-xs font-semibold rounded-lg shadow-sm"
                >
                  Enroll Driver
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};
