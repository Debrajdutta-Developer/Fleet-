import React, { useState } from 'react';
import { useFleet } from '../context/FleetContext';
import { Trip, TripStatus, Checkpoint } from '../types';
import {
  Route,
  Plus,
  Search,
  CheckCircle2,
  Clock,
  AlertTriangle,
  Play,
  Check,
  Truck,
  User,
  MapPin,
  X,
  Scale,
  ShieldCheck,
  DollarSign
} from 'lucide-react';

export const TripsView: React.FC = () => {
  const {
    trips,
    vehicles,
    drivers,
    createTrip,
    updateTripStatus,
    advanceCheckpoint,
    createMaintenanceTicket,
    currentCompany,
  } = useFleet();

  const [statusFilter, setStatusFilter] = useState<string>('all');
  const [searchQuery, setSearchQuery] = useState('');
  const [showNewTripModal, setShowNewTripModal] = useState(false);
  const [selectedTrip, setSelectedTrip] = useState<Trip | null>(null);

  // New Trip Form State
  const [customerName, setCustomerName] = useState('Titan Global Logistics');
  const [cargoDesc, setCargoDesc] = useState('Industrial Machine Parts');
  const [cargoWeightKg, setCargoWeightKg] = useState(15000);
  const [hazardClass, setHazardClass] = useState('');
  const [selectedVehicleId, setSelectedVehicleId] = useState(vehicles[0]?.id || '');
  const [selectedDriverId, setSelectedDriverId] = useState(drivers[0]?.id || '');
  const [startLocation, setStartLocation] = useState('Chicago IL Hub');
  const [endLocation, setEndLocation] = useState('Detroit MI Automotive Complex');
  const [distanceKm, setDistanceKm] = useState(460);
  const [freightRevenue, setFreightRevenue] = useState(2400);
  const [tollFees, setTollFees] = useState(38);

  const filteredTrips = trips.filter((trip) => {
    if (statusFilter !== 'all' && trip.status !== statusFilter) return false;
    if (searchQuery.trim()) {
      const q = searchQuery.toLowerCase();
      return (
        trip.tripNumber.toLowerCase().includes(q) ||
        trip.customerName.toLowerCase().includes(q) ||
        trip.route.startLocationName.toLowerCase().includes(q) ||
        trip.route.endLocationName.toLowerCase().includes(q)
      );
    }
    return true;
  });

  // Selected vehicle for new trip validation preview
  const candidateVehicle = vehicles.find((v) => v.id === selectedVehicleId);
  const candidateDriver = drivers.find((d) => d.id === selectedDriverId);

  // Real-time validation checks
  const isPayloadSafe = candidateVehicle ? cargoWeightKg <= candidateVehicle.maxPayloadKg * 0.9 : true;
  const isDriverSafetyPassed = candidateDriver && candidateVehicle?.cdlRequired === 'Class A' ? candidateDriver.safetyScore >= 70 : true;
  const isVehicleActive = candidateVehicle ? candidateVehicle.status === 'active' || candidateVehicle.status === 'idle' : false;

  const handleCreateTrip = (e: React.FormEvent) => {
    e.preventDefault();
    if (!candidateVehicle || !candidateDriver) return;

    const res = createTrip({
      status: 'assigned',
      driverId: candidateDriver.id,
      vehicleId: candidateVehicle.id,
      customerName,
      cargo: {
        description: cargoDesc,
        weightKg: Number(cargoWeightKg),
        hazardClass: hazardClass.trim() || undefined,
      },
      route: {
        startLocationName: startLocation,
        endLocationName: endLocation,
        distanceKm: Number(distanceKm),
        estimatedDurationSec: Math.round((distanceKm / 75) * 3600),
      },
      checkpoints: [
        {
          id: `chk-${Date.now()}-1`,
          locationName: startLocation,
          address: `${startLocation} Gate Bay 1`,
          latitude: 41.8781,
          longitude: -87.6298,
          status: 'passed',
          passedAt: new Date().toISOString(),
          scheduledArrival: new Date().toISOString(),
        },
        {
          id: `chk-${Date.now()}-2`,
          locationName: 'Interstate Weigh Station Checkpoint',
          address: 'I-94 Corridor Milepost 78',
          latitude: 42.0,
          longitude: -85.5,
          status: 'pending',
          scheduledArrival: new Date(Date.now() + 2 * 3600 * 1000).toISOString(),
        },
        {
          id: `chk-${Date.now()}-3`,
          locationName: endLocation,
          address: `${endLocation} Dock 4`,
          latitude: 42.3314,
          longitude: -83.0458,
          status: 'pending',
          scheduledArrival: new Date(Date.now() + 5 * 3600 * 1000).toISOString(),
        },
      ],
      scheduledDeparture: new Date().toISOString(),
      tollFeesEstimated: Number(tollFees),
      freightRevenue: Number(freightRevenue),
    });

    if (res.success) {
      setShowNewTripModal(false);
    }
  };

  const handleReportBreakdown = (trip: Trip) => {
    createMaintenanceTicket({
      vehicleId: trip.vehicleId,
      type: 'breakdown',
      priority: 'critical',
      status: 'in_progress',
      issueDescription: `SOS Breakdown reported during trip ${trip.tripNumber} en-route to ${trip.route.endLocationName}. Cargo transshipment required.`,
      reportedBy: `Driver SOS (Trip ${trip.tripNumber})`,
      estimatedCost: 850.00,
      serviceOdometer: 142000,
    });
    updateTripStatus(trip.id, 'cancelled');
  };

  return (
    <div className="space-y-6 pb-12">
      {/* Header & New Dispatch Button */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold text-slate-900 dark:text-white font-display">
            Trip Dispatch & Freight Routing
          </h1>
          <p className="text-sm text-slate-500 dark:text-slate-400">
            Automated compliance gates, milestone checkpoints, and manifest billing
          </p>
        </div>

        <button
          onClick={() => setShowNewTripModal(true)}
          className="flex items-center space-x-2 px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-lg text-sm font-semibold shadow-sm transition"
        >
          <Plus className="h-4 w-4" />
          <span>Dispatch New Manifest</span>
        </button>
      </div>

      {/* Filter and Search */}
      <div className="flex flex-col sm:flex-row items-stretch sm:items-center justify-between gap-3 bg-white dark:bg-slate-800/90 border border-slate-200 dark:border-slate-700/80 rounded-xl p-3 shadow-sm">
        <div className="relative flex-1">
          <Search className="absolute left-3 top-2.5 h-4 w-4 text-slate-400" />
          <input
            type="text"
            placeholder="Search manifests by Trip Number, Customer, City..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            className="w-full pl-9 pr-4 py-2 bg-slate-50 dark:bg-slate-900 border border-slate-200 dark:border-slate-700 rounded-lg text-sm text-slate-900 dark:text-white focus:outline-none focus:ring-2 focus:ring-blue-500"
          />
        </div>

        <div className="flex items-center space-x-1.5 overflow-x-auto pb-1 sm:pb-0">
          {['all', 'in_transit', 'assigned', 'planned', 'completed', 'cancelled'].map((st) => (
            <button
              key={st}
              onClick={() => setStatusFilter(st)}
              className={`px-3 py-1.5 rounded-lg text-xs font-semibold uppercase tracking-wider transition capitalize whitespace-nowrap ${
                statusFilter === st
                  ? 'bg-blue-600 text-white'
                  : 'bg-slate-100 dark:bg-slate-700/60 text-slate-600 dark:text-slate-300 hover:bg-slate-200'
              }`}
            >
              {st.replace('_', ' ')}
            </button>
          ))}
        </div>
      </div>

      {/* Trips Manifest Cards */}
      <div className="space-y-4">
        {filteredTrips.map((trip) => {
          const vehicle = vehicles.find((v) => v.id === trip.vehicleId);
          const driver = drivers.find((d) => d.id === trip.driverId);
          const passedCount = trip.checkpoints.filter((c) => c.status === 'passed').length;
          const nextCheckpoint = trip.checkpoints.find((c) => c.status === 'pending');

          return (
            <div
              key={trip.id}
              className="bg-white dark:bg-slate-800/90 border border-slate-200 dark:border-slate-700/80 rounded-xl p-5 shadow-sm space-y-4"
            >
              {/* Trip Header: Number, Customer, Status, Actions */}
              <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3 border-b border-slate-100 dark:border-slate-700/60 pb-3">
                <div className="flex items-center space-x-3">
                  <div className="p-2.5 rounded-xl bg-blue-50 dark:bg-blue-900/30 text-blue-600 dark:text-blue-400">
                    <Route className="h-5 w-5" />
                  </div>
                  <div>
                    <div className="flex items-center space-x-2">
                      <span className="font-mono font-bold text-sm text-blue-600 dark:text-blue-400">
                        {trip.tripNumber}
                      </span>
                      <span className="font-bold text-base text-slate-900 dark:text-white">
                        {trip.customerName}
                      </span>
                    </div>
                    <p className="text-xs text-slate-500">
                      Cargo: <span className="font-medium text-slate-700 dark:text-slate-300">{trip.cargo.description}</span> ({trip.cargo.weightKg.toLocaleString()} kg)
                      {trip.cargo.hazardClass && (
                        <span className="ml-2 px-1.5 py-0.5 rounded bg-red-100 text-red-800 dark:bg-red-900/40 dark:text-red-300 text-[10px] font-bold">
                          {trip.cargo.hazardClass}
                        </span>
                      )}
                    </p>
                  </div>
                </div>

                <div className="flex items-center space-x-2">
                  <span
                    className={`text-xs font-bold uppercase px-3 py-1 rounded-full ${
                      trip.status === 'in_transit'
                        ? 'bg-emerald-100 text-emerald-800 dark:bg-emerald-900/40 dark:text-emerald-300'
                        : trip.status === 'completed'
                        ? 'bg-slate-100 text-slate-800 dark:bg-slate-700 dark:text-slate-300'
                        : trip.status === 'cancelled'
                        ? 'bg-red-100 text-red-800 dark:bg-red-900/40 dark:text-red-300'
                        : 'bg-blue-100 text-blue-800 dark:bg-blue-900/40 dark:text-blue-300'
                    }`}
                  >
                    {trip.status.replace('_', ' ')}
                  </span>

                  {/* Status Actions */}
                  {trip.status === 'assigned' && (
                    <button
                      onClick={() => updateTripStatus(trip.id, 'in_transit')}
                      className="px-3 py-1.5 bg-emerald-600 hover:bg-emerald-700 text-white rounded-lg text-xs font-semibold flex items-center space-x-1"
                    >
                      <Play className="h-3 w-3" />
                      <span>Start Trip</span>
                    </button>
                  )}

                  {trip.status === 'in_transit' && (
                    <>
                      {nextCheckpoint && (
                        <button
                          onClick={() => advanceCheckpoint(trip.id, nextCheckpoint.id)}
                          className="px-3 py-1.5 bg-blue-600 hover:bg-blue-700 text-white rounded-lg text-xs font-semibold flex items-center space-x-1"
                        >
                          <Check className="h-3 w-3" />
                          <span>Pass Checkpoint</span>
                        </button>
                      )}

                      <button
                        onClick={() => updateTripStatus(trip.id, 'completed')}
                        className="px-3 py-1.5 bg-slate-800 dark:bg-slate-700 hover:bg-slate-700 text-white rounded-lg text-xs font-semibold"
                      >
                        Complete Delivery
                      </button>

                      <button
                        onClick={() => handleReportBreakdown(trip)}
                        className="px-2.5 py-1.5 bg-red-100 hover:bg-red-200 text-red-700 dark:bg-red-900/40 dark:text-red-300 rounded-lg text-xs font-semibold"
                        title="SOS Breakdown"
                      >
                        SOS Breakdown
                      </button>
                    </>
                  )}
                </div>
              </div>

              {/* Route & Assignment Info Grid */}
              <div className="grid grid-cols-1 sm:grid-cols-4 gap-3 text-xs bg-slate-50 dark:bg-slate-900/50 p-3 rounded-lg border border-slate-200 dark:border-slate-700/60">
                <div>
                  <span className="text-slate-400 block">Assigned Vehicle</span>
                  <span className="font-semibold text-slate-800 dark:text-slate-200 flex items-center space-x-1 mt-0.5">
                    <Truck className="h-3.5 w-3.5 text-blue-500" />
                    <span>{vehicle?.licensePlate || 'N/A'} ({vehicle?.make})</span>
                  </span>
                </div>

                <div>
                  <span className="text-slate-400 block">Lead Driver</span>
                  <span className="font-semibold text-slate-800 dark:text-slate-200 flex items-center space-x-1 mt-0.5">
                    <User className="h-3.5 w-3.5 text-teal-500" />
                    <span>{driver?.fullName || 'N/A'} (Score: {driver?.safetyScore}%)</span>
                  </span>
                </div>

                <div>
                  <span className="text-slate-400 block">Distance & Toll</span>
                  <span className="font-semibold text-slate-800 dark:text-slate-200 mt-0.5 block">
                    {trip.route.distanceKm} km • Toll Est: ${trip.tollFeesEstimated.toFixed(2)}
                  </span>
                </div>

                <div>
                  <span className="text-slate-400 block">Freight Billing Revenue</span>
                  <span className="font-bold text-emerald-600 dark:text-emerald-400 text-sm mt-0.5 block">
                    ${trip.freightRevenue.toLocaleString()}
                  </span>
                </div>
              </div>

              {/* Checkpoints Stepper */}
              <div>
                <div className="flex items-center justify-between text-xs font-semibold text-slate-500 mb-2">
                  <span>Milestone Waypoints & Checkpoints ({passedCount}/{trip.checkpoints.length} Cleared)</span>
                  <span>Departure: {new Date(trip.scheduledDeparture).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}</span>
                </div>

                <div className="grid grid-cols-1 md:grid-cols-3 lg:grid-cols-4 gap-2">
                  {trip.checkpoints.map((cp, idx) => {
                    const isPassed = cp.status === 'passed';
                    return (
                      <div
                        key={cp.id}
                        className={`p-2.5 rounded-lg border text-xs flex items-start space-x-2 transition ${
                          isPassed
                            ? 'bg-emerald-50 dark:bg-emerald-950/30 border-emerald-300 dark:border-emerald-800/60'
                            : 'bg-white dark:bg-slate-800 border-slate-200 dark:border-slate-700'
                        }`}
                      >
                        <div
                          className={`h-5 w-5 rounded-full flex items-center justify-center text-[10px] font-bold shrink-0 mt-0.5 ${
                            isPassed
                              ? 'bg-emerald-600 text-white'
                              : 'bg-slate-200 dark:bg-slate-700 text-slate-600 dark:text-slate-300'
                          }`}
                        >
                          {isPassed ? <Check className="h-3 w-3" /> : idx + 1}
                        </div>
                        <div className="min-w-0 flex-1">
                          <p className="font-semibold text-slate-900 dark:text-white truncate">
                            {cp.locationName}
                          </p>
                          <p className="text-[10px] text-slate-500 truncate">{cp.address}</p>
                          <span
                            className={`text-[9px] uppercase font-bold mt-1 inline-block ${
                              isPassed ? 'text-emerald-700 dark:text-emerald-300' : 'text-slate-400'
                            }`}
                          >
                            {isPassed ? `Passed: ${new Date(cp.passedAt!).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}` : 'Pending'}
                          </span>
                        </div>
                      </div>
                    );
                  })}
                </div>
              </div>
            </div>
          );
        })}
      </div>

      {/* New Trip Modal */}
      {showNewTripModal && (
        <div className="fixed inset-0 z-50 bg-slate-950/60 backdrop-blur-sm flex items-center justify-center p-4">
          <div className="bg-white dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-2xl max-w-xl w-full p-6 shadow-2xl max-h-[90vh] overflow-y-auto">
            <div className="flex items-center justify-between border-b border-slate-200 dark:border-slate-700 pb-3">
              <h3 className="text-lg font-bold text-slate-900 dark:text-white font-display">
                Dispatch New Logistics Manifest
              </h3>
              <button onClick={() => setShowNewTripModal(false)} className="text-slate-400 hover:text-white">
                <X className="h-5 w-5" />
              </button>
            </div>

            <form onSubmit={handleCreateTrip} className="mt-4 space-y-4 text-sm">
              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block text-xs font-medium text-slate-700 dark:text-slate-300 mb-1">
                    Customer / Shipper Name *
                  </label>
                  <input
                    type="text"
                    required
                    value={customerName}
                    onChange={(e) => setCustomerName(e.target.value)}
                    className="w-full px-3 py-2 bg-slate-50 dark:bg-slate-900 border border-slate-200 dark:border-slate-700 rounded-lg text-xs"
                  />
                </div>

                <div>
                  <label className="block text-xs font-medium text-slate-700 dark:text-slate-300 mb-1">
                    Cargo Description *
                  </label>
                  <input
                    type="text"
                    required
                    value={cargoDesc}
                    onChange={(e) => setCargoDesc(e.target.value)}
                    className="w-full px-3 py-2 bg-slate-50 dark:bg-slate-900 border border-slate-200 dark:border-slate-700 rounded-lg text-xs"
                  />
                </div>
              </div>

              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block text-xs font-medium text-slate-700 dark:text-slate-300 mb-1">
                    Cargo Weight (kg) *
                  </label>
                  <input
                    type="number"
                    required
                    value={cargoWeightKg}
                    onChange={(e) => setCargoWeightKg(Number(e.target.value))}
                    className="w-full px-3 py-2 bg-slate-50 dark:bg-slate-900 border border-slate-200 dark:border-slate-700 rounded-lg text-xs"
                  />
                </div>

                <div>
                  <label className="block text-xs font-medium text-slate-700 dark:text-slate-300 mb-1">
                    Hazard Classification (Optional)
                  </label>
                  <input
                    type="text"
                    placeholder="e.g. Class 9 / None"
                    value={hazardClass}
                    onChange={(e) => setHazardClass(e.target.value)}
                    className="w-full px-3 py-2 bg-slate-50 dark:bg-slate-900 border border-slate-200 dark:border-slate-700 rounded-lg text-xs"
                  />
                </div>
              </div>

              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block text-xs font-medium text-slate-700 dark:text-slate-300 mb-1">
                    Assign Vehicle *
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

                <div>
                  <label className="block text-xs font-medium text-slate-700 dark:text-slate-300 mb-1">
                    Assign Certified Driver *
                  </label>
                  <select
                    value={selectedDriverId}
                    onChange={(e) => setSelectedDriverId(e.target.value)}
                    className="w-full px-3 py-2 bg-slate-50 dark:bg-slate-900 border border-slate-200 dark:border-slate-700 rounded-lg text-xs"
                  >
                    {drivers.map((d) => (
                      <option key={d.id} value={d.id}>
                        {d.fullName} ({d.cdlClass}, Safety: {d.safetyScore}%) [{d.status}]
                      </option>
                    ))}
                  </select>
                </div>
              </div>

              {/* Automated Business Rules Validation Feedback Box */}
              <div className="p-3.5 rounded-xl bg-slate-50 dark:bg-slate-900/80 border border-slate-200 dark:border-slate-700 space-y-2 text-xs">
                <h5 className="font-semibold text-slate-800 dark:text-slate-200 uppercase tracking-wider text-[11px]">
                  Automated Dispatch Gate Validations:
                </h5>

                <div className="flex items-center space-x-2">
                  {isVehicleActive ? (
                    <CheckCircle2 className="h-4 w-4 text-emerald-500" />
                  ) : (
                    <AlertTriangle className="h-4 w-4 text-red-500" />
                  )}
                  <span className={isVehicleActive ? 'text-slate-600 dark:text-slate-300' : 'text-red-500 font-semibold'}>
                    Vehicle State Gate: {candidateVehicle?.licensePlate} ({candidateVehicle?.status})
                  </span>
                </div>

                <div className="flex items-center space-x-2">
                  {isPayloadSafe ? (
                    <CheckCircle2 className="h-4 w-4 text-emerald-500" />
                  ) : (
                    <AlertTriangle className="h-4 w-4 text-red-500" />
                  )}
                  <span className={isPayloadSafe ? 'text-slate-600 dark:text-slate-300' : 'text-red-500 font-semibold'}>
                    90% Payload Safety Margin: {cargoWeightKg} kg / {(candidateVehicle ? candidateVehicle.maxPayloadKg * 0.9 : 0).toFixed(0)} kg max allowed
                  </span>
                </div>

                <div className="flex items-center space-x-2">
                  {isDriverSafetyPassed ? (
                    <CheckCircle2 className="h-4 w-4 text-emerald-500" />
                  ) : (
                    <AlertTriangle className="h-4 w-4 text-red-500" />
                  )}
                  <span className={isDriverSafetyPassed ? 'text-slate-600 dark:text-slate-300' : 'text-red-500 font-semibold'}>
                    Driver Safety Score Gate: {candidateDriver?.fullName} ({candidateDriver?.safetyScore}% vs 70% threshold)
                  </span>
                </div>
              </div>

              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block text-xs font-medium text-slate-700 dark:text-slate-300 mb-1">
                    Origin Terminal
                  </label>
                  <input
                    type="text"
                    value={startLocation}
                    onChange={(e) => setStartLocation(e.target.value)}
                    className="w-full px-3 py-2 bg-slate-50 dark:bg-slate-900 border border-slate-200 dark:border-slate-700 rounded-lg text-xs"
                  />
                </div>

                <div>
                  <label className="block text-xs font-medium text-slate-700 dark:text-slate-300 mb-1">
                    Destination Terminal
                  </label>
                  <input
                    type="text"
                    value={endLocation}
                    onChange={(e) => setEndLocation(e.target.value)}
                    className="w-full px-3 py-2 bg-slate-50 dark:bg-slate-900 border border-slate-200 dark:border-slate-700 rounded-lg text-xs"
                  />
                </div>
              </div>

              <div className="grid grid-cols-3 gap-3">
                <div>
                  <label className="block text-xs font-medium text-slate-700 dark:text-slate-300 mb-1">
                    Distance (km)
                  </label>
                  <input
                    type="number"
                    value={distanceKm}
                    onChange={(e) => setDistanceKm(Number(e.target.value))}
                    className="w-full px-3 py-2 bg-slate-50 dark:bg-slate-900 border border-slate-200 dark:border-slate-700 rounded-lg text-xs"
                  />
                </div>

                <div>
                  <label className="block text-xs font-medium text-slate-700 dark:text-slate-300 mb-1">
                    Freight Revenue ($)
                  </label>
                  <input
                    type="number"
                    value={freightRevenue}
                    onChange={(e) => setFreightRevenue(Number(e.target.value))}
                    className="w-full px-3 py-2 bg-slate-50 dark:bg-slate-900 border border-slate-200 dark:border-slate-700 rounded-lg text-xs"
                  />
                </div>

                <div>
                  <label className="block text-xs font-medium text-slate-700 dark:text-slate-300 mb-1">
                    Est. Toll ($)
                  </label>
                  <input
                    type="number"
                    value={tollFees}
                    onChange={(e) => setTollFees(Number(e.target.value))}
                    className="w-full px-3 py-2 bg-slate-50 dark:bg-slate-900 border border-slate-200 dark:border-slate-700 rounded-lg text-xs"
                  />
                </div>
              </div>

              <div className="flex justify-end space-x-3 pt-3 border-t border-slate-200 dark:border-slate-700">
                <button
                  type="button"
                  onClick={() => setShowNewTripModal(false)}
                  className="px-4 py-2 text-xs font-medium text-slate-600 dark:text-slate-300 hover:bg-slate-100 rounded-lg"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  disabled={!isPayloadSafe || !isDriverSafetyPassed || !isVehicleActive}
                  className={`px-4 py-2 text-white text-xs font-semibold rounded-lg shadow-sm ${
                    !isPayloadSafe || !isDriverSafetyPassed || !isVehicleActive
                      ? 'bg-slate-400 cursor-not-allowed'
                      : 'bg-blue-600 hover:bg-blue-700'
                  }`}
                >
                  Approve & Dispatch
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};
