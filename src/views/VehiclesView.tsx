import React, { useState } from 'react';
import { useFleet } from '../context/FleetContext';
import { Vehicle, VehicleStatus, FuelType } from '../types';
import {
  Truck,
  Plus,
  Search,
  Filter,
  Wrench,
  ShieldCheck,
  AlertTriangle,
  Zap,
  Fuel,
  Archive,
  ChevronRight,
  X,
  Gauge,
  Calendar,
  CheckCircle2,
  AlertCircle
} from 'lucide-react';

export const VehiclesView: React.FC = () => {
  const {
    vehicles,
    drivers,
    addVehicle,
    updateVehicleStatus,
    softDeleteVehicle,
    complianceDocs,
    maintenanceTickets,
    fuelLogs,
  } = useFleet();

  const [searchQuery, setSearchQuery] = useState('');
  const [statusFilter, setStatusFilter] = useState<string>('all');
  const [selectedVehicle, setSelectedVehicle] = useState<Vehicle | null>(null);
  const [showAddModal, setShowAddModal] = useState(false);
  const [showStatusModal, setShowStatusModal] = useState<Vehicle | null>(null);

  // Form State for Add Vehicle
  const [newVin, setNewVin] = useState('');
  const [newPlate, setNewPlate] = useState('');
  const [newMake, setNewMake] = useState('Freightliner');
  const [newModel, setNewModel] = useState('Cascadia 126');
  const [newYear, setNewYear] = useState(2024);
  const [newFuelType, setNewFuelType] = useState<FuelType>('diesel');
  const [newPayloadKg, setNewPayloadKg] = useState(22000);
  const [newGvwrLbs, setNewGvwrLbs] = useState(80000);
  const [newCdlRequired, setNewCdlRequired] = useState<'Class A' | 'Class B'>('Class A');
  const [initialOdometer, setInitialOdometer] = useState(150);

  // Status transition form state
  const [targetStatus, setTargetStatus] = useState<VehicleStatus>('active');
  const [statusReason, setStatusReason] = useState('');

  // Filter vehicles (exclude soft-deleted from standard view unless specifically selected)
  const filteredVehicles = vehicles.filter((v) => {
    if (statusFilter === 'archived') {
      if (!v.deletedAt) return false;
    } else {
      if (v.deletedAt) return false;
      if (statusFilter !== 'all' && v.status !== statusFilter) return false;
    }

    if (searchQuery.trim()) {
      const q = searchQuery.toLowerCase();
      return (
        v.licensePlate.toLowerCase().includes(q) ||
        v.vin.toLowerCase().includes(q) ||
        v.make.toLowerCase().includes(q) ||
        v.model.toLowerCase().includes(q)
      );
    }
    return true;
  });

  const handleCreateVehicle = (e: React.FormEvent) => {
    e.preventDefault();
    if (!newVin.trim() || !newPlate.trim()) return;

    const res = addVehicle({
      vin: newVin.trim().toUpperCase(),
      licensePlate: newPlate.trim().toUpperCase(),
      make: newMake,
      model: newModel,
      year: Number(newYear),
      status: 'registration',
      statusTag: 'Pending Safety Inspection',
      fuelType: newFuelType,
      odometer: Number(initialOdometer),
      maxPayloadKg: Number(newPayloadKg),
      gvwrLbs: Number(newGvwrLbs),
      cdlRequired: newCdlRequired,
      lastServiceDate: new Date().toISOString().split('T')[0],
      lastServiceOdometer: Number(initialOdometer),
      engineHours: 10,
      telemetry: {
        latitude: 32.7767,
        longitude: -96.7970,
        speed: 0,
        heading: 0,
        fuelLevelPercent: 100,
        batteryHealthPercent: 100,
        engineTempC: 25,
        updatedAt: new Date().toISOString(),
        locationName: 'Onboarding Staging Depot',
      },
    });

    if (res.success) {
      setShowAddModal(false);
      setNewVin('');
      setNewPlate('');
    }
  };

  const handleUpdateStatus = (e: React.FormEvent) => {
    e.preventDefault();
    if (!showStatusModal) return;

    const res = updateVehicleStatus(showStatusModal.id, targetStatus, statusReason.trim() || undefined);
    if (res.success) {
      setShowStatusModal(null);
      setStatusReason('');
      if (selectedVehicle?.id === showStatusModal.id) {
        setSelectedVehicle({
          ...selectedVehicle,
          status: targetStatus,
          statusTag: statusReason || undefined,
        });
      }
    }
  };

  return (
    <div className="space-y-6 pb-12">
      {/* Header & Actions */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold text-slate-900 dark:text-white font-display">
            Fleet Asset Inventory & Telemetry
          </h1>
          <p className="text-sm text-slate-500 dark:text-slate-400">
            Lifecycle state control, OBD-II telemetry diagnostics, and payload parameters
          </p>
        </div>

        <button
          onClick={() => setShowAddModal(true)}
          className="flex items-center space-x-2 px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-lg text-sm font-semibold shadow-sm transition"
        >
          <Plus className="h-4 w-4" />
          <span>Register Vehicle</span>
        </button>
      </div>

      {/* Search & Filter Bar */}
      <div className="flex flex-col sm:flex-row items-stretch sm:items-center justify-between gap-3 bg-white dark:bg-slate-800/90 border border-slate-200 dark:border-slate-700/80 rounded-xl p-3 shadow-sm">
        <div className="relative flex-1">
          <Search className="absolute left-3 top-2.5 h-4 w-4 text-slate-400" />
          <input
            type="text"
            placeholder="Search by License Plate, VIN, Make, Model..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            className="w-full pl-9 pr-4 py-2 bg-slate-50 dark:bg-slate-900 border border-slate-200 dark:border-slate-700 rounded-lg text-sm text-slate-900 dark:text-white focus:outline-none focus:ring-2 focus:ring-blue-500"
          />
        </div>

        {/* Filter Pills */}
        <div className="flex items-center space-x-1.5 overflow-x-auto pb-1 sm:pb-0">
          {['all', 'active', 'idle', 'maintenance', 'registration', 'archived'].map((st) => (
            <button
              key={st}
              onClick={() => setStatusFilter(st)}
              className={`px-3 py-1.5 rounded-lg text-xs font-semibold uppercase tracking-wider transition capitalize whitespace-nowrap ${
                statusFilter === st
                  ? 'bg-blue-600 text-white'
                  : 'bg-slate-100 dark:bg-slate-700/60 text-slate-600 dark:text-slate-300 hover:bg-slate-200 dark:hover:bg-slate-700'
              }`}
            >
              {st}
            </button>
          ))}
        </div>
      </div>

      {/* Vehicles Grid / Table */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
        {filteredVehicles.map((vehicle) => {
          const assignedDriver = drivers.find((d) => d.id === vehicle.assignedDriverId);
          const vehicleDocs = complianceDocs.filter((d) => d.vehicleId === vehicle.id);
          const hasExpiredDoc = vehicleDocs.some((d) => d.verificationStatus === 'expired');

          // PM Matrix Trigger Check: Trigger every 10,000 km or 180 days
          const kmSinceLastService = vehicle.odometer - vehicle.lastServiceOdometer;
          const isPMOverdue = kmSinceLastService >= 10000;

          return (
            <div
              key={vehicle.id}
              className={`bg-white dark:bg-slate-800/90 border rounded-xl p-5 shadow-sm hover:shadow-md transition flex flex-col justify-between ${
                selectedVehicle?.id === vehicle.id
                  ? 'border-blue-500 ring-2 ring-blue-500/20'
                  : hasExpiredDoc || vehicle.status === 'maintenance'
                  ? 'border-red-300 dark:border-red-900/60'
                  : 'border-slate-200 dark:border-slate-700/80'
              }`}
            >
              <div>
                {/* Card Top: Plate, Status, Quick Menu */}
                <div className="flex items-start justify-between">
                  <div className="flex items-center space-x-3">
                    <div className="p-2.5 rounded-xl bg-slate-100 dark:bg-slate-700/60 text-slate-700 dark:text-slate-200">
                      <Truck className="h-5 w-5" />
                    </div>
                    <div>
                      <h3 className="font-bold text-base text-slate-900 dark:text-white">
                        {vehicle.licensePlate}
                      </h3>
                      <p className="text-xs text-slate-500 dark:text-slate-400">
                        {vehicle.year} {vehicle.make} {vehicle.model}
                      </p>
                    </div>
                  </div>

                  <span
                    className={`text-[10px] font-bold uppercase px-2 py-0.5 rounded-full ${
                      vehicle.status === 'active'
                        ? 'bg-emerald-100 text-emerald-800 dark:bg-emerald-900/40 dark:text-emerald-300'
                        : vehicle.status === 'maintenance'
                        ? 'bg-red-100 text-red-800 dark:bg-red-900/40 dark:text-red-300'
                        : vehicle.status === 'registration'
                        ? 'bg-purple-100 text-purple-800 dark:bg-purple-900/40 dark:text-purple-300'
                        : 'bg-amber-100 text-amber-800 dark:bg-amber-900/40 dark:text-amber-300'
                    }`}
                  >
                    {vehicle.status}
                  </span>
                </div>

                {/* Sub-state tag / warnings */}
                {(vehicle.statusTag || isPMOverdue || hasExpiredDoc) && (
                  <div className="mt-3 p-2 rounded-lg bg-amber-50 dark:bg-amber-950/30 border border-amber-200 dark:border-amber-800/40 text-xs text-amber-800 dark:text-amber-300 flex items-start space-x-1.5">
                    <AlertTriangle className="h-3.5 w-3.5 shrink-0 mt-0.5 text-amber-500" />
                    <span className="truncate">
                      {vehicle.statusTag || (isPMOverdue ? 'PM Service Interval Overdue (>10,000km)' : 'Compliance Action Required')}
                    </span>
                  </div>
                )}

                {/* Specs List */}
                <div className="mt-4 grid grid-cols-2 gap-2 text-xs border-t border-b border-slate-100 dark:border-slate-700/60 py-3">
                  <div>
                    <span className="text-slate-400 block text-[11px]">Fuel / Battery</span>
                    <span className="font-semibold text-slate-700 dark:text-slate-200 flex items-center space-x-1">
                      {vehicle.fuelType === 'electric' ? <Zap className="h-3 w-3 text-emerald-500" /> : <Fuel className="h-3 w-3 text-blue-500" />}
                      <span className="capitalize">{vehicle.fuelType} ({vehicle.telemetry.fuelLevelPercent}%)</span>
                    </span>
                  </div>

                  <div>
                    <span className="text-slate-400 block text-[11px]">Payload Limit</span>
                    <span className="font-semibold text-slate-700 dark:text-slate-200">
                      {vehicle.maxPayloadKg.toLocaleString()} kg (90% safe: {(vehicle.maxPayloadKg * 0.9).toLocaleString()} kg)
                    </span>
                  </div>

                  <div>
                    <span className="text-slate-400 block text-[11px]">Odometer</span>
                    <span className="font-semibold text-slate-700 dark:text-slate-200">
                      {vehicle.odometer.toLocaleString()} km
                    </span>
                  </div>

                  <div>
                    <span className="text-slate-400 block text-[11px]">Assigned Driver</span>
                    <span className="font-semibold text-slate-700 dark:text-slate-200 truncate">
                      {assignedDriver?.fullName || 'Unassigned'}
                    </span>
                  </div>
                </div>

                {/* Live Location / Speed */}
                <div className="mt-3 flex items-center justify-between text-xs text-slate-500 dark:text-slate-400">
                  <span className="truncate max-w-[190px]">
                    📍 {vehicle.telemetry.locationName}
                  </span>
                  <span className="font-bold text-slate-800 dark:text-slate-200">
                    {vehicle.telemetry.speed} mph
                  </span>
                </div>
              </div>

              {/* Card Actions Footer */}
              <div className="mt-4 pt-3 border-t border-slate-100 dark:border-slate-700/60 flex items-center justify-between">
                <button
                  onClick={() => setSelectedVehicle(vehicle)}
                  className="text-xs font-semibold text-blue-600 dark:text-blue-400 hover:underline flex items-center space-x-1"
                >
                  <span>Full Telemetry Diagnostics</span>
                  <ChevronRight className="h-3 w-3" />
                </button>

                <div className="flex items-center space-x-2">
                  <button
                    onClick={() => {
                      setShowStatusModal(vehicle);
                      setTargetStatus(vehicle.status);
                    }}
                    className="px-2.5 py-1 text-xs font-medium bg-slate-100 dark:bg-slate-700 hover:bg-slate-200 dark:hover:bg-slate-600 rounded-md text-slate-700 dark:text-slate-200 transition"
                    title="Change lifecycle state"
                  >
                    State Machine
                  </button>

                  {!vehicle.deletedAt && (
                    <button
                      onClick={() => softDeleteVehicle(vehicle.id)}
                      className="p-1 text-slate-400 hover:text-red-500 rounded transition"
                      title="Archive vehicle (Soft delete)"
                    >
                      <Archive className="h-4 w-4" />
                    </button>
                  )}
                </div>
              </div>
            </div>
          );
        })}
      </div>

      {filteredVehicles.length === 0 && (
        <div className="bg-white dark:bg-slate-800/90 border border-slate-200 dark:border-slate-700 rounded-xl p-12 text-center">
          <Truck className="h-10 w-10 text-slate-400 mx-auto mb-3" />
          <h3 className="text-base font-semibold text-slate-900 dark:text-white">No vehicles found</h3>
          <p className="text-xs text-slate-500 dark:text-slate-400 mt-1">
            Try adjusting your search criteria or register a new fleet asset.
          </p>
        </div>
      )}

      {/* Vehicle Diagnostics & Detail Drawer Modal */}
      {selectedVehicle && (
        <div className="fixed inset-0 z-50 bg-slate-950/60 backdrop-blur-sm flex items-center justify-center p-4">
          <div className="bg-white dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-2xl max-w-2xl w-full max-h-[90vh] overflow-y-auto shadow-2xl p-6">
            <div className="flex items-center justify-between border-b border-slate-200 dark:border-slate-700 pb-4">
              <div className="flex items-center space-x-3">
                <div className="p-3 bg-blue-500/10 text-blue-600 rounded-xl">
                  <Truck className="h-6 w-6" />
                </div>
                <div>
                  <h3 className="text-lg font-bold text-slate-900 dark:text-white font-display">
                    {selectedVehicle.licensePlate} ({selectedVehicle.make} {selectedVehicle.model})
                  </h3>
                  <p className="text-xs text-slate-500 font-mono">VIN: {selectedVehicle.vin}</p>
                </div>
              </div>
              <button
                onClick={() => setSelectedVehicle(null)}
                className="p-1.5 rounded-lg text-slate-400 hover:text-slate-600 dark:hover:text-white"
              >
                <X className="h-5 w-5" />
              </button>
            </div>

            <div className="mt-5 space-y-5 text-sm">
              {/* Telemetry Sensor Live Grid */}
              <div>
                <h4 className="text-xs font-semibold text-slate-400 uppercase tracking-wider mb-2">
                  CAN-Bus OBD-II Live Telemetry Stream
                </h4>
                <div className="grid grid-cols-2 sm:grid-cols-4 gap-3 bg-slate-50 dark:bg-slate-900/60 p-4 rounded-xl border border-slate-200 dark:border-slate-700/60">
                  <div>
                    <span className="text-xs text-slate-500 block">Instant Speed</span>
                    <span className="font-display text-lg font-bold text-teal-600 dark:text-teal-400">
                      {selectedVehicle.telemetry.speed} mph
                    </span>
                  </div>
                  <div>
                    <span className="text-xs text-slate-500 block">Fuel / Battery</span>
                    <span className="font-display text-lg font-bold text-blue-600 dark:text-blue-400">
                      {selectedVehicle.telemetry.fuelLevelPercent}%
                    </span>
                  </div>
                  <div>
                    <span className="text-xs text-slate-500 block">Engine Coolant</span>
                    <span className="font-display text-lg font-bold text-slate-800 dark:text-slate-200">
                      {selectedVehicle.telemetry.engineTempC}°C
                    </span>
                  </div>
                  <div>
                    <span className="text-xs text-slate-500 block">Battery Health</span>
                    <span className="font-display text-lg font-bold text-emerald-600 dark:text-emerald-400">
                      {selectedVehicle.telemetry.batteryHealthPercent}%
                    </span>
                  </div>
                </div>
              </div>

              {/* PM Matrix Triggers Section */}
              <div>
                <h4 className="text-xs font-semibold text-slate-400 uppercase tracking-wider mb-2">
                  Preventative Maintenance (PM) Matrix Status
                </h4>
                <div className="space-y-2 bg-slate-50 dark:bg-slate-900/60 p-4 rounded-xl border border-slate-200 dark:border-slate-700/60">
                  <div className="flex justify-between text-xs">
                    <span>Odometer Interval (10,000 km target)</span>
                    <span className="font-semibold">
                      {selectedVehicle.odometer - selectedVehicle.lastServiceOdometer} km / 10,000 km
                    </span>
                  </div>
                  <div className="w-full bg-slate-200 dark:bg-slate-700 h-2 rounded-full overflow-hidden">
                    <div
                      className={`h-full rounded-full ${
                        selectedVehicle.odometer - selectedVehicle.lastServiceOdometer >= 10000
                          ? 'bg-red-500'
                          : 'bg-blue-600'
                      }`}
                      style={{
                        width: `${Math.min(
                          100,
                          ((selectedVehicle.odometer - selectedVehicle.lastServiceOdometer) / 10000) * 100
                        )}%`,
                      }}
                    />
                  </div>
                  <p className="text-[11px] text-slate-500">
                    Last Serviced on {selectedVehicle.lastServiceDate} at {selectedVehicle.lastServiceOdometer.toLocaleString()} km
                  </p>
                </div>
              </div>

              {/* Asset Technical Specifications */}
              <div className="grid grid-cols-2 gap-4 text-xs">
                <div className="p-3 rounded-lg border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-800">
                  <span className="text-slate-400 block mb-1">CDL Class Required</span>
                  <span className="font-semibold text-slate-900 dark:text-white">
                    {selectedVehicle.cdlRequired} (GVWR {selectedVehicle.gvwrLbs.toLocaleString()} lbs)
                  </span>
                </div>
                <div className="p-3 rounded-lg border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-800">
                  <span className="text-slate-400 block mb-1">Max Payload Capacity</span>
                  <span className="font-semibold text-slate-900 dark:text-white">
                    {selectedVehicle.maxPayloadKg.toLocaleString()} kg
                  </span>
                </div>
              </div>
            </div>

            <div className="mt-6 pt-4 border-t border-slate-200 dark:border-slate-700 flex justify-end">
              <button
                onClick={() => setSelectedVehicle(null)}
                className="px-4 py-2 bg-slate-100 dark:bg-slate-700 text-slate-700 dark:text-slate-200 rounded-lg text-xs font-semibold hover:bg-slate-200"
              >
                Close Window
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Add Vehicle Modal */}
      {showAddModal && (
        <div className="fixed inset-0 z-50 bg-slate-950/60 backdrop-blur-sm flex items-center justify-center p-4">
          <div className="bg-white dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-2xl max-w-lg w-full p-6 shadow-2xl">
            <div className="flex items-center justify-between border-b border-slate-200 dark:border-slate-700 pb-3">
              <h3 className="text-lg font-bold text-slate-900 dark:text-white font-display">
                Onboard New Fleet Asset
              </h3>
              <button onClick={() => setShowAddModal(false)} className="text-slate-400 hover:text-white">
                <X className="h-5 w-5" />
              </button>
            </div>

            <form onSubmit={handleCreateVehicle} className="mt-4 space-y-4 text-sm">
              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block text-xs font-medium text-slate-700 dark:text-slate-300 mb-1">
                    License Plate *
                  </label>
                  <input
                    type="text"
                    required
                    placeholder="e.g. FL-9912-TX"
                    value={newPlate}
                    onChange={(e) => setNewPlate(e.target.value)}
                    className="w-full px-3 py-2 bg-slate-50 dark:bg-slate-900 border border-slate-200 dark:border-slate-700 rounded-lg text-xs font-mono uppercase"
                  />
                </div>

                <div>
                  <label className="block text-xs font-medium text-slate-700 dark:text-slate-300 mb-1">
                    VIN (17 Characters) *
                  </label>
                  <input
                    type="text"
                    required
                    maxLength={17}
                    placeholder="1FUJBBCK4NL89..."
                    value={newVin}
                    onChange={(e) => setNewVin(e.target.value)}
                    className="w-full px-3 py-2 bg-slate-50 dark:bg-slate-900 border border-slate-200 dark:border-slate-700 rounded-lg text-xs font-mono uppercase"
                  />
                </div>
              </div>

              <div className="grid grid-cols-3 gap-3">
                <div>
                  <label className="block text-xs font-medium text-slate-700 dark:text-slate-300 mb-1">
                    Make
                  </label>
                  <input
                    type="text"
                    value={newMake}
                    onChange={(e) => setNewMake(e.target.value)}
                    className="w-full px-3 py-2 bg-slate-50 dark:bg-slate-900 border border-slate-200 dark:border-slate-700 rounded-lg text-xs"
                  />
                </div>

                <div>
                  <label className="block text-xs font-medium text-slate-700 dark:text-slate-300 mb-1">
                    Model
                  </label>
                  <input
                    type="text"
                    value={newModel}
                    onChange={(e) => setNewModel(e.target.value)}
                    className="w-full px-3 py-2 bg-slate-50 dark:bg-slate-900 border border-slate-200 dark:border-slate-700 rounded-lg text-xs"
                  />
                </div>

                <div>
                  <label className="block text-xs font-medium text-slate-700 dark:text-slate-300 mb-1">
                    Year
                  </label>
                  <input
                    type="number"
                    value={newYear}
                    onChange={(e) => setNewYear(Number(e.target.value))}
                    className="w-full px-3 py-2 bg-slate-50 dark:bg-slate-900 border border-slate-200 dark:border-slate-700 rounded-lg text-xs"
                  />
                </div>
              </div>

              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block text-xs font-medium text-slate-700 dark:text-slate-300 mb-1">
                    Powertrain / Fuel Type
                  </label>
                  <select
                    value={newFuelType}
                    onChange={(e) => setNewFuelType(e.target.value as FuelType)}
                    className="w-full px-3 py-2 bg-slate-50 dark:bg-slate-900 border border-slate-200 dark:border-slate-700 rounded-lg text-xs"
                  >
                    <option value="diesel">Diesel (Heavy Duty)</option>
                    <option value="electric">Electric (EV Battery)</option>
                    <option value="unleaded">Unleaded Gasoline</option>
                    <option value="cng">CNG (Natural Gas)</option>
                  </select>
                </div>

                <div>
                  <label className="block text-xs font-medium text-slate-700 dark:text-slate-300 mb-1">
                    CDL Class Enforcement
                  </label>
                  <select
                    value={newCdlRequired}
                    onChange={(e) => setNewCdlRequired(e.target.value as 'Class A' | 'Class B')}
                    className="w-full px-3 py-2 bg-slate-50 dark:bg-slate-900 border border-slate-200 dark:border-slate-700 rounded-lg text-xs"
                  >
                    <option value="Class A">Class A (Tractor-Trailer &gt;26,000 lbs)</option>
                    <option value="Class B">Class B (Straight Truck / Box Truck)</option>
                  </select>
                </div>
              </div>

              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block text-xs font-medium text-slate-700 dark:text-slate-300 mb-1">
                    Max Payload (kg)
                  </label>
                  <input
                    type="number"
                    value={newPayloadKg}
                    onChange={(e) => setNewPayloadKg(Number(e.target.value))}
                    className="w-full px-3 py-2 bg-slate-50 dark:bg-slate-900 border border-slate-200 dark:border-slate-700 rounded-lg text-xs"
                  />
                </div>

                <div>
                  <label className="block text-xs font-medium text-slate-700 dark:text-slate-300 mb-1">
                    Initial Odometer (km)
                  </label>
                  <input
                    type="number"
                    value={initialOdometer}
                    onChange={(e) => setInitialOdometer(Number(e.target.value))}
                    className="w-full px-3 py-2 bg-slate-50 dark:bg-slate-900 border border-slate-200 dark:border-slate-700 rounded-lg text-xs"
                  />
                </div>
              </div>

              <p className="text-[11px] text-slate-400 bg-slate-50 dark:bg-slate-900/60 p-2.5 rounded-lg border border-slate-200 dark:border-slate-700/60">
                * Note: Newly registered vehicles enter the <b>Registration</b> state and require inspection verification before being activated for dispatches.
              </p>

              <div className="flex justify-end space-x-3 pt-3 border-t border-slate-200 dark:border-slate-700">
                <button
                  type="button"
                  onClick={() => setShowAddModal(false)}
                  className="px-4 py-2 text-xs font-medium text-slate-600 dark:text-slate-300 hover:bg-slate-100 rounded-lg"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  className="px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white text-xs font-semibold rounded-lg shadow-sm"
                >
                  Complete Onboarding
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Lifecycle State Machine Transition Modal */}
      {showStatusModal && (
        <div className="fixed inset-0 z-50 bg-slate-950/60 backdrop-blur-sm flex items-center justify-center p-4">
          <div className="bg-white dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-2xl max-w-md w-full p-6 shadow-2xl">
            <div className="flex items-center justify-between border-b border-slate-200 dark:border-slate-700 pb-3">
              <h3 className="text-base font-bold text-slate-900 dark:text-white font-display">
                Vehicle State Machine: {showStatusModal.licensePlate}
              </h3>
              <button onClick={() => setShowStatusModal(null)} className="text-slate-400 hover:text-white">
                <X className="h-5 w-5" />
              </button>
            </div>

            <form onSubmit={handleUpdateStatus} className="mt-4 space-y-4 text-sm">
              <div>
                <label className="block text-xs font-medium text-slate-700 dark:text-slate-300 mb-1">
                  Target State Transition
                </label>
                <select
                  value={targetStatus}
                  onChange={(e) => setTargetStatus(e.target.value as VehicleStatus)}
                  className="w-full px-3 py-2 bg-slate-50 dark:bg-slate-900 border border-slate-200 dark:border-slate-700 rounded-lg text-xs"
                >
                  <option value="active">Active (Operational & Road-Ready)</option>
                  <option value="idle">Idle (Available, No Active Dispatches)</option>
                  <option value="maintenance">Maintenance (Out of Service)</option>
                  <option value="registration">Registration (Onboarding Verification)</option>
                  <option value="sold">Sold (Decommissioned)</option>
                </select>
              </div>

              <div>
                <label className="block text-xs font-medium text-slate-700 dark:text-slate-300 mb-1">
                  State Reason / Tag
                </label>
                <input
                  type="text"
                  placeholder="e.g. Cleared 10,000km PM inspection"
                  value={statusReason}
                  onChange={(e) => setStatusReason(e.target.value)}
                  className="w-full px-3 py-2 bg-slate-50 dark:bg-slate-900 border border-slate-200 dark:border-slate-700 rounded-lg text-xs"
                />
              </div>

              <div className="flex justify-end space-x-3 pt-3 border-t border-slate-200 dark:border-slate-700">
                <button
                  type="button"
                  onClick={() => setShowStatusModal(null)}
                  className="px-4 py-2 text-xs font-medium text-slate-600 dark:text-slate-300"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  className="px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white text-xs font-semibold rounded-lg"
                >
                  Apply Transition
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};
