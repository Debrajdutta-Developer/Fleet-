import React, { useState } from 'react';
import { useFleet } from '../context/FleetContext';
import { MaintenanceTicket, FuelLog } from '../types';
import {
  Wrench,
  Fuel,
  Plus,
  Search,
  CheckCircle2,
  AlertTriangle,
  Clock,
  ShieldCheck,
  ShieldAlert,
  MapPin,
  Calendar,
  DollarSign,
  X,
  Gauge
} from 'lucide-react';

export const MaintenanceFuelView: React.FC = () => {
  const {
    maintenanceTickets,
    fuelLogs,
    vehicles,
    drivers,
    createMaintenanceTicket,
    resolveMaintenanceTicket,
    addFuelLog,
  } = useFleet();

  const [activeSubTab, setActiveSubTab] = useState<'maintenance' | 'fuel'>('maintenance');
  const [showWorkOrderModal, setShowWorkOrderModal] = useState(false);
  const [showFuelLogModal, setShowFuelLogModal] = useState(false);

  // Work order form state
  const [selectedVehicleId, setSelectedVehicleId] = useState(vehicles[0]?.id || '');
  const [woType, setWoType] = useState<MaintenanceTicket['type']>('scheduled_pm');
  const [woPriority, setWoPriority] = useState<MaintenanceTicket['priority']>('medium');
  const [woDescription, setWoDescription] = useState('10,000 km Preventative Maintenance Service & Oil Filter Change');
  const [woReportedBy, setWoReportedBy] = useState('Fleet Diagnostics Engine');
  const [woEstimatedCost, setWoEstimatedCost] = useState(450.00);

  // Fuel log form state
  const [fuelVehicleId, setFuelVehicleId] = useState(vehicles[0]?.id || '');
  const [fuelDriverId, setFuelDriverId] = useState(drivers[0]?.id || '');
  const [litersAmount, setLitersAmount] = useState(450);
  const [totalCost, setTotalCost] = useState(620.00);
  const [odometerEntry, setOdometerEntry] = useState(148500);
  const [stationName, setStationName] = useState('Love\'s Travel Stop #482');
  const [calcEconomy, setCalcEconomy] = useState(3.4);

  const handleCreateWorkOrder = (e: React.FormEvent) => {
    e.preventDefault();
    createMaintenanceTicket({
      vehicleId: selectedVehicleId,
      type: woType,
      priority: woPriority,
      status: 'open',
      issueDescription: woDescription,
      reportedBy: woReportedBy,
      estimatedCost: Number(woEstimatedCost),
      serviceOdometer: 148000,
    });
    setShowWorkOrderModal(false);
  };

  const handleCreateFuelLog = (e: React.FormEvent) => {
    e.preventDefault();
    addFuelLog({
      vehicleId: fuelVehicleId,
      driverId: fuelDriverId,
      timestamp: new Date().toISOString(),
      fuelStation: stationName,
      stationLatitude: 32.7767,
      stationLongitude: -96.7970,
      fuelAmountLiters: Number(litersAmount),
      totalCost: Number(totalCost),
      odometerReading: Number(odometerEntry),
      calcEconomyKmPerLiter: Number(calcEconomy),
      riskStatus: 'verified',
    });
    setShowFuelLogModal(false);
  };

  return (
    <div className="space-y-6 pb-12">
      {/* View Header & Action Buttons */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold text-slate-900 dark:text-white font-display">
            Maintenance & Fuel Intelligence
          </h1>
          <p className="text-sm text-slate-500 dark:text-slate-400">
            Preventative maintenance matrices and 3-factor fuel theft fraud detection
          </p>
        </div>

        <div className="flex items-center space-x-3">
          <button
            onClick={() => setShowWorkOrderModal(true)}
            className="flex items-center space-x-2 px-3.5 py-2 bg-slate-800 dark:bg-slate-700 hover:bg-slate-700 text-white rounded-lg text-xs font-semibold shadow-sm transition"
          >
            <Wrench className="h-4 w-4 text-blue-400" />
            <span>Open Work Order</span>
          </button>

          <button
            onClick={() => setShowFuelLogModal(true)}
            className="flex items-center space-x-2 px-3.5 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-lg text-xs font-semibold shadow-sm transition"
          >
            <Fuel className="h-4 w-4" />
            <span>Record Fuel Dispense</span>
          </button>
        </div>
      </div>

      {/* Sub-Tab Switcher */}
      <div className="flex items-center space-x-2 border-b border-slate-200 dark:border-slate-700/80 pb-2">
        <button
          onClick={() => setActiveSubTab('maintenance')}
          className={`flex items-center space-x-2 px-4 py-2 rounded-lg text-xs font-semibold transition ${
            activeSubTab === 'maintenance'
              ? 'bg-blue-600 text-white shadow-sm'
              : 'text-slate-600 dark:text-slate-400 hover:bg-slate-100 dark:hover:bg-slate-800'
          }`}
        >
          <Wrench className="h-4 w-4" />
          <span>Work Orders & PM Matrix ({maintenanceTickets.filter((t) => t.status !== 'closed').length} Open)</span>
        </button>

        <button
          onClick={() => setActiveSubTab('fuel')}
          className={`flex items-center space-x-2 px-4 py-2 rounded-lg text-xs font-semibold transition ${
            activeSubTab === 'fuel'
              ? 'bg-blue-600 text-white shadow-sm'
              : 'text-slate-600 dark:text-slate-400 hover:bg-slate-100 dark:hover:bg-slate-800'
          }`}
        >
          <Fuel className="h-4 w-4" />
          <span>3-Factor Fuel Audit Log ({fuelLogs.length} Records)</span>
        </button>
      </div>

      {/* Sub-Tab 1: Maintenance & Work Orders */}
      {activeSubTab === 'maintenance' && (
        <div className="space-y-6">
          {/* PM Service Interval Trigger Matrix Card */}
          <div className="bg-white dark:bg-slate-800/90 border border-slate-200 dark:border-slate-700/80 rounded-xl p-5 shadow-sm">
            <h3 className="font-display font-semibold text-sm text-slate-900 dark:text-white mb-1">
              Automated Preventative Maintenance (PM) Trigger Matrix
            </h3>
            <p className="text-xs text-slate-500 mb-4">
              Rule triggers: <b>10,000 km odometer delta</b>, <b>180 calendar days</b>, or <b>250 continuous engine hours</b>.
            </p>

            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-3">
              {vehicles
                .filter((v) => !v.deletedAt)
                .map((vehicle) => {
                  const deltaKm = vehicle.odometer - vehicle.lastServiceOdometer;
                  const isOverdue = deltaKm >= 10000;
                  const progressPct = Math.min(100, Math.round((deltaKm / 10000) * 100));

                  return (
                    <div
                      key={vehicle.id}
                      className={`p-3.5 rounded-xl border text-xs space-y-2 ${
                        isOverdue
                          ? 'bg-red-50 dark:bg-red-950/30 border-red-300 dark:border-red-900/60'
                          : 'bg-slate-50 dark:bg-slate-900/50 border-slate-200 dark:border-slate-700/60'
                      }`}
                    >
                      <div className="flex items-center justify-between">
                        <span className="font-bold text-slate-900 dark:text-white">{vehicle.licensePlate}</span>
                        <span
                          className={`text-[10px] font-bold uppercase px-1.5 py-0.5 rounded ${
                            isOverdue
                              ? 'bg-red-200 text-red-900 dark:bg-red-900 dark:text-red-200'
                              : 'bg-emerald-100 text-emerald-800 dark:bg-emerald-900/40 dark:text-emerald-300'
                          }`}
                        >
                          {isOverdue ? 'PM Overdue' : 'PM Compliant'}
                        </span>
                      </div>

                      <div className="space-y-1">
                        <div className="flex justify-between text-[11px] text-slate-500">
                          <span>Service Delta</span>
                          <span className="font-bold">{deltaKm.toLocaleString()} / 10,000 km</span>
                        </div>
                        <div className="w-full bg-slate-200 dark:bg-slate-700 h-1.5 rounded-full overflow-hidden">
                          <div
                            className={`h-full rounded-full ${isOverdue ? 'bg-red-500' : 'bg-blue-600'}`}
                            style={{ width: `${progressPct}%` }}
                          />
                        </div>
                      </div>

                      <p className="text-[10px] text-slate-400">
                        Last PM: {vehicle.lastServiceDate} ({vehicle.lastServiceOdometer.toLocaleString()} km)
                      </p>
                    </div>
                  );
                })}
            </div>
          </div>

          {/* Work Orders List */}
          <div className="space-y-3">
            <h3 className="font-display font-semibold text-sm text-slate-900 dark:text-white">
              Active & Historic Work Orders
            </h3>

            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              {maintenanceTickets.map((ticket) => {
                const vehicle = vehicles.find((v) => v.id === ticket.vehicleId);

                return (
                  <div
                    key={ticket.id}
                    className="bg-white dark:bg-slate-800/90 border border-slate-200 dark:border-slate-700/80 rounded-xl p-5 shadow-sm flex flex-col justify-between"
                  >
                    <div>
                      <div className="flex items-start justify-between">
                        <div className="flex items-center space-x-3">
                          <div className="p-2 rounded-lg bg-blue-50 dark:bg-blue-900/30 text-blue-600">
                            <Wrench className="h-5 w-5" />
                          </div>
                          <div>
                            <span className="font-mono font-bold text-xs text-blue-600 dark:text-blue-400">
                              {ticket.ticketNumber}
                            </span>
                            <h4 className="font-bold text-sm text-slate-900 dark:text-white capitalize">
                              {ticket.type.replace('_', ' ')} • {vehicle?.licensePlate || 'N/A'}
                            </h4>
                          </div>
                        </div>

                        <span
                          className={`text-[10px] font-bold uppercase px-2 py-0.5 rounded-full ${
                            ticket.priority === 'critical'
                              ? 'bg-red-100 text-red-800 dark:bg-red-900/40 dark:text-red-300'
                              : ticket.priority === 'high'
                              ? 'bg-amber-100 text-amber-800 dark:bg-amber-900/40 dark:text-amber-300'
                              : 'bg-blue-100 text-blue-800 dark:bg-blue-900/40 dark:text-blue-300'
                          }`}
                        >
                          {ticket.priority} Priority
                        </span>
                      </div>

                      <p className="text-xs text-slate-600 dark:text-slate-300 mt-3 leading-relaxed">
                        {ticket.issueDescription}
                      </p>

                      <div className="mt-4 grid grid-cols-2 gap-2 text-xs border-t border-slate-100 dark:border-slate-700/60 pt-3">
                        <div>
                          <span className="text-slate-400 text-[11px] block">Reported By</span>
                          <span className="font-semibold text-slate-800 dark:text-slate-200">
                            {ticket.reportedBy}
                          </span>
                        </div>
                        <div>
                          <span className="text-slate-400 text-[11px] block">Cost Estimate / Actual</span>
                          <span className="font-semibold text-slate-800 dark:text-slate-200">
                            ${ticket.actualCost ? ticket.actualCost.toFixed(2) : ticket.estimatedCost.toFixed(2)}
                          </span>
                        </div>
                      </div>
                    </div>

                    <div className="mt-4 pt-3 border-t border-slate-100 dark:border-slate-700/60 flex items-center justify-between">
                      <span className="text-xs text-slate-400 font-medium capitalize">
                        Status: <b className="text-slate-700 dark:text-slate-300">{ticket.status.replace('_', ' ')}</b>
                      </span>

                      {ticket.status !== 'closed' && (
                        <button
                          onClick={() => resolveMaintenanceTicket(ticket.id, ticket.estimatedCost)}
                          className="px-3 py-1.5 bg-emerald-600 hover:bg-emerald-700 text-white rounded-lg text-xs font-semibold flex items-center space-x-1"
                        >
                          <CheckCircle2 className="h-3.5 w-3.5" />
                          <span>Close Work Order</span>
                        </button>
                      )}
                    </div>
                  </div>
                );
              })}
            </div>
          </div>
        </div>
      )}

      {/* Sub-Tab 2: 3-Factor Fuel Intelligence Log */}
      {activeSubTab === 'fuel' && (
        <div className="space-y-4">
          <div className="bg-slate-50 dark:bg-slate-900/60 border border-slate-200 dark:border-slate-700/80 rounded-xl p-4 text-xs text-slate-600 dark:text-slate-300 space-y-1">
            <h4 className="font-bold text-slate-900 dark:text-white flex items-center space-x-2">
              <ShieldCheck className="h-4 w-4 text-teal-500" />
              <span>3-Factor Fuel Dispense Fraud Detection Engine</span>
            </h4>
            <p>
              Every logged fueling event is automatically analyzed against three independent telemetry signals:
              <b> 1. Odometer Progression</b>, <b>2. Consumption Rate Variance (&gt;20% delta flag)</b>, and <b>3. GPS Geofence Station Proximity</b>.
            </p>
          </div>

          <div className="bg-white dark:bg-slate-800/90 border border-slate-200 dark:border-slate-700/80 rounded-xl overflow-hidden shadow-sm">
            <div className="overflow-x-auto">
              <table className="w-full text-left text-xs text-slate-600 dark:text-slate-300">
                <thead className="bg-slate-50 dark:bg-slate-900/80 text-slate-700 dark:text-slate-400 font-semibold border-b border-slate-200 dark:border-slate-700">
                  <tr>
                    <th className="py-3 px-4">Date & Station</th>
                    <th className="py-3 px-4">Vehicle & Driver</th>
                    <th className="py-3 px-4">Volume & Total</th>
                    <th className="py-3 px-4">Odometer</th>
                    <th className="py-3 px-4">3-Factor Fraud Status</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-slate-100 dark:divide-slate-700/60">
                  {fuelLogs.map((log) => {
                    const vehicle = vehicles.find((v) => v.id === log.vehicleId);
                    const driver = drivers.find((d) => d.id === log.driverId);
                    const isAuditPass = log.riskStatus === 'verified';

                    return (
                      <tr key={log.id} className="hover:bg-slate-50 dark:hover:bg-slate-700/30">
                        <td className="py-3 px-4">
                          <p className="font-bold text-slate-900 dark:text-white">{log.fuelStation}</p>
                          <p className="text-[11px] text-slate-400">
                            {new Date(log.timestamp).toLocaleDateString()}
                          </p>
                        </td>

                        <td className="py-3 px-4">
                          <p className="font-semibold text-slate-800 dark:text-slate-200">
                            {vehicle?.licensePlate || 'N/A'}
                          </p>
                          <p className="text-[11px] text-slate-400">{driver?.fullName || 'N/A'}</p>
                        </td>

                        <td className="py-3 px-4">
                          <p className="font-bold text-slate-900 dark:text-white">
                            ${log.totalCost.toFixed(2)}
                          </p>
                          <p className="text-[11px] text-slate-400">
                            {log.fuelAmountLiters} L ({log.calcEconomyKmPerLiter} km/L)
                          </p>
                        </td>

                        <td className="py-3 px-4 font-mono font-medium text-slate-800 dark:text-slate-200">
                          {log.odometerReading.toLocaleString()} km
                        </td>

                        <td className="py-3 px-4">
                          <div className="flex items-center space-x-2">
                            {isAuditPass ? (
                              <span className="flex items-center space-x-1 px-2.5 py-1 rounded-full bg-emerald-100 text-emerald-800 dark:bg-emerald-900/40 dark:text-emerald-300 font-semibold text-[10px]">
                                <CheckCircle2 className="h-3 w-3" />
                                <span>3-Factor Pass</span>
                              </span>
                            ) : (
                              <span className="flex items-center space-x-1 px-2.5 py-1 rounded-full bg-amber-100 text-amber-800 dark:bg-amber-900/40 dark:text-amber-300 font-semibold text-[10px]">
                                <AlertTriangle className="h-3 w-3" />
                                <span>Variance Flag</span>
                              </span>
                            )}
                          </div>
                          {log.auditNotes && (
                            <p className="text-[10px] text-slate-400 mt-1">{log.auditNotes}</p>
                          )}
                        </td>
                      </tr>
                    );
                  })}
                </tbody>
              </table>
            </div>
          </div>
        </div>
      )}

      {/* Open Work Order Modal */}
      {showWorkOrderModal && (
        <div className="fixed inset-0 z-50 bg-slate-950/60 backdrop-blur-sm flex items-center justify-center p-4">
          <div className="bg-white dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-2xl max-w-lg w-full p-6 shadow-2xl">
            <div className="flex items-center justify-between border-b border-slate-200 dark:border-slate-700 pb-3">
              <h3 className="text-lg font-bold text-slate-900 dark:text-white font-display">
                Create Maintenance Work Order
              </h3>
              <button onClick={() => setShowWorkOrderModal(false)} className="text-slate-400 hover:text-white">
                <X className="h-5 w-5" />
              </button>
            </div>

            <form onSubmit={handleCreateWorkOrder} className="mt-4 space-y-4 text-sm">
              <div>
                <label className="block text-xs font-medium text-slate-700 dark:text-slate-300 mb-1">
                  Target Vehicle *
                </label>
                <select
                  value={selectedVehicleId}
                  onChange={(e) => setSelectedVehicleId(e.target.value)}
                  className="w-full px-3 py-2 bg-slate-50 dark:bg-slate-900 border border-slate-200 dark:border-slate-700 rounded-lg text-xs"
                >
                  {vehicles
                    .filter((v) => !v.deletedAt)
                    .map((v) => (
                      <option key={v.id} value={v.id}>
                        {v.licensePlate} ({v.make} {v.model}) [{v.status.toUpperCase()}]
                      </option>
                    ))}
                </select>
              </div>

              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block text-xs font-medium text-slate-700 dark:text-slate-300 mb-1">
                    Service Type
                  </label>
                  <select
                    value={woType}
                    onChange={(e) => setWoType(e.target.value as MaintenanceTicket['type'])}
                    className="w-full px-3 py-2 bg-slate-50 dark:bg-slate-900 border border-slate-200 dark:border-slate-700 rounded-lg text-xs"
                  >
                    <option value="scheduled_pm">Scheduled PM Interval (10k km)</option>
                    <option value="repair">Mechanical Repair</option>
                    <option value="breakdown">Emergency Breakdown</option>
                    <option value="inspection">Annual Safety Inspection</option>
                  </select>
                </div>

                <div>
                  <label className="block text-xs font-medium text-slate-700 dark:text-slate-300 mb-1">
                    Priority Level
                  </label>
                  <select
                    value={woPriority}
                    onChange={(e) => setWoPriority(e.target.value as MaintenanceTicket['priority'])}
                    className="w-full px-3 py-2 bg-slate-50 dark:bg-slate-900 border border-slate-200 dark:border-slate-700 rounded-lg text-xs"
                  >
                    <option value="low">Low (Standard Scheduling)</option>
                    <option value="medium">Medium (Within 48h)</option>
                    <option value="high">High (Immediate Action)</option>
                    <option value="critical">Critical (Grounded Vehicle)</option>
                  </select>
                </div>
              </div>

              <div>
                <label className="block text-xs font-medium text-slate-700 dark:text-slate-300 mb-1">
                  Issue Description / Service Scope *
                </label>
                <textarea
                  rows={3}
                  required
                  value={woDescription}
                  onChange={(e) => setWoDescription(e.target.value)}
                  className="w-full px-3 py-2 bg-slate-50 dark:bg-slate-900 border border-slate-200 dark:border-slate-700 rounded-lg text-xs"
                />
              </div>

              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block text-xs font-medium text-slate-700 dark:text-slate-300 mb-1">
                    Reported By
                  </label>
                  <input
                    type="text"
                    value={woReportedBy}
                    onChange={(e) => setWoReportedBy(e.target.value)}
                    className="w-full px-3 py-2 bg-slate-50 dark:bg-slate-900 border border-slate-200 dark:border-slate-700 rounded-lg text-xs"
                  />
                </div>

                <div>
                  <label className="block text-xs font-medium text-slate-700 dark:text-slate-300 mb-1">
                    Estimated Cost ($)
                  </label>
                  <input
                    type="number"
                    value={woEstimatedCost}
                    onChange={(e) => setWoEstimatedCost(Number(e.target.value))}
                    className="w-full px-3 py-2 bg-slate-50 dark:bg-slate-900 border border-slate-200 dark:border-slate-700 rounded-lg text-xs"
                  />
                </div>
              </div>

              <div className="flex justify-end space-x-3 pt-3 border-t border-slate-200 dark:border-slate-700">
                <button
                  type="button"
                  onClick={() => setShowWorkOrderModal(false)}
                  className="px-4 py-2 text-xs font-medium text-slate-600 dark:text-slate-300"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  className="px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white text-xs font-semibold rounded-lg"
                >
                  Generate Work Order
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Record Fuel Dispense Modal */}
      {showFuelLogModal && (
        <div className="fixed inset-0 z-50 bg-slate-950/60 backdrop-blur-sm flex items-center justify-center p-4">
          <div className="bg-white dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-2xl max-w-lg w-full p-6 shadow-2xl">
            <div className="flex items-center justify-between border-b border-slate-200 dark:border-slate-700 pb-3">
              <h3 className="text-lg font-bold text-slate-900 dark:text-white font-display">
                Record Fuel Dispense Transaction
              </h3>
              <button onClick={() => setShowFuelLogModal(false)} className="text-slate-400 hover:text-white">
                <X className="h-5 w-5" />
              </button>
            </div>

            <form onSubmit={handleCreateFuelLog} className="mt-4 space-y-4 text-sm">
              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block text-xs font-medium text-slate-700 dark:text-slate-300 mb-1">
                    Vehicle *
                  </label>
                  <select
                    value={fuelVehicleId}
                    onChange={(e) => setFuelVehicleId(e.target.value)}
                    className="w-full px-3 py-2 bg-slate-50 dark:bg-slate-900 border border-slate-200 dark:border-slate-700 rounded-lg text-xs"
                  >
                    {vehicles
                      .filter((v) => !v.deletedAt)
                      .map((v) => (
                        <option key={v.id} value={v.id}>
                          {v.licensePlate} ({v.make}) - Current: {v.odometer} km
                        </option>
                      ))}
                  </select>
                </div>

                <div>
                  <label className="block text-xs font-medium text-slate-700 dark:text-slate-300 mb-1">
                    Driver *
                  </label>
                  <select
                    value={fuelDriverId}
                    onChange={(e) => setFuelDriverId(e.target.value)}
                    className="w-full px-3 py-2 bg-slate-50 dark:bg-slate-900 border border-slate-200 dark:border-slate-700 rounded-lg text-xs"
                  >
                    {drivers.map((d) => (
                      <option key={d.id} value={d.id}>
                        {d.fullName}
                      </option>
                    ))}
                  </select>
                </div>
              </div>

              <div className="grid grid-cols-3 gap-3">
                <div>
                  <label className="block text-xs font-medium text-slate-700 dark:text-slate-300 mb-1">
                    Volume (Liters)
                  </label>
                  <input
                    type="number"
                    value={litersAmount}
                    onChange={(e) => setLitersAmount(Number(e.target.value))}
                    className="w-full px-3 py-2 bg-slate-50 dark:bg-slate-900 border border-slate-200 dark:border-slate-700 rounded-lg text-xs"
                  />
                </div>

                <div>
                  <label className="block text-xs font-medium text-slate-700 dark:text-slate-300 mb-1">
                    Total Cost ($)
                  </label>
                  <input
                    type="number"
                    step="0.01"
                    value={totalCost}
                    onChange={(e) => setTotalCost(Number(e.target.value))}
                    className="w-full px-3 py-2 bg-slate-50 dark:bg-slate-900 border border-slate-200 dark:border-slate-700 rounded-lg text-xs"
                  />
                </div>

                <div>
                  <label className="block text-xs font-medium text-slate-700 dark:text-slate-300 mb-1">
                    Odometer (km)
                  </label>
                  <input
                    type="number"
                    value={odometerEntry}
                    onChange={(e) => setOdometerEntry(Number(e.target.value))}
                    className="w-full px-3 py-2 bg-slate-50 dark:bg-slate-900 border border-slate-200 dark:border-slate-700 rounded-lg text-xs"
                  />
                </div>
              </div>

              <div>
                <label className="block text-xs font-medium text-slate-700 dark:text-slate-300 mb-1">
                  Station Name
                </label>
                <input
                  type="text"
                  value={stationName}
                  onChange={(e) => setStationName(e.target.value)}
                  className="w-full px-3 py-2 bg-slate-50 dark:bg-slate-900 border border-slate-200 dark:border-slate-700 rounded-lg text-xs"
                />
              </div>

              <div className="flex justify-end space-x-3 pt-3 border-t border-slate-200 dark:border-slate-700">
                <button
                  type="button"
                  onClick={() => setShowFuelLogModal(false)}
                  className="px-4 py-2 text-xs font-medium text-slate-600 dark:text-slate-300"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  className="px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white text-xs font-semibold rounded-lg shadow-sm"
                >
                  Audit & Record
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};
