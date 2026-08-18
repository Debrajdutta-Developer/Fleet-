import React, { useState } from 'react';
import { useFleet } from '../context/FleetContext';
import { ComplianceDocument } from '../types';
import {
  FileCheck2,
  Plus,
  Search,
  CheckCircle2,
  AlertTriangle,
  Clock,
  ShieldAlert,
  ShieldCheck,
  Calendar,
  Truck,
  UploadCloud,
  X,
  FileText
} from 'lucide-react';

export const ComplianceVaultView: React.FC = () => {
  const { complianceDocs, vehicles, verifyComplianceDoc, addComplianceDoc } = useFleet();

  const [searchQuery, setSearchQuery] = useState('');
  const [docTypeFilter, setDocTypeFilter] = useState<string>('all');
  const [showUploadModal, setShowUploadModal] = useState(false);

  // Upload Form State
  const [selectedVehicleId, setSelectedVehicleId] = useState(vehicles[0]?.id || '');
  const [docType, setDocType] = useState<ComplianceDocument['documentType']>('Insurance');
  const [docNumber, setDocNumber] = useState('POL-2026-99214');
  const [issueDate, setIssueDate] = useState(new Date().toISOString().split('T')[0]);
  const [expiryDate, setExpiryDate] = useState('2027-12-31');

  const filteredDocs = complianceDocs.filter((doc) => {
    if (docTypeFilter !== 'all' && doc.documentType !== docTypeFilter) return false;
    if (searchQuery.trim()) {
      const q = searchQuery.toLowerCase();
      return (
        doc.documentNumber.toLowerCase().includes(q) ||
        doc.documentType.toLowerCase().includes(q)
      );
    }
    return true;
  });

  const handleUploadDoc = (e: React.FormEvent) => {
    e.preventDefault();
    addComplianceDoc({
      vehicleId: selectedVehicleId,
      documentType: docType,
      documentNumber: docNumber,
      issueDate,
      expiryDate,
      verificationStatus: 'verified',
      verifiedBy: 'Safety Officer',
    });
    setShowUploadModal(false);
  };

  return (
    <div className="space-y-6 pb-12">
      {/* View Header */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold text-slate-900 dark:text-white font-display">
            Regulatory Compliance Vault
          </h1>
          <p className="text-sm text-slate-500 dark:text-slate-400">
            Automated statutory expiry verification and dispatch lockout enforcement
          </p>
        </div>

        <button
          onClick={() => setShowUploadModal(true)}
          className="flex items-center space-x-2 px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-lg text-sm font-semibold shadow-sm transition"
        >
          <Plus className="h-4 w-4" />
          <span>Upload Certificate</span>
        </button>
      </div>

      {/* Expiry Alert Summary Cards */}
      <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
        <div className="bg-emerald-50 dark:bg-emerald-950/30 border border-emerald-200 dark:border-emerald-800/40 p-4 rounded-xl flex items-center justify-between">
          <div>
            <span className="text-xs font-semibold text-emerald-800 dark:text-emerald-300 uppercase tracking-wider block">
              Active & Valid
            </span>
            <span className="text-2xl font-bold text-emerald-900 dark:text-emerald-100 font-display">
              {complianceDocs.filter((d) => d.verificationStatus === 'verified').length}
            </span>
            <p className="text-[11px] text-emerald-700/80 dark:text-emerald-300/80 mt-0.5">
              100% road legal compliance
            </p>
          </div>
          <ShieldCheck className="h-8 w-8 text-emerald-500 opacity-80" />
        </div>

        <div className="bg-amber-50 dark:bg-amber-950/30 border border-amber-200 dark:border-amber-800/40 p-4 rounded-xl flex items-center justify-between">
          <div>
            <span className="text-xs font-semibold text-amber-800 dark:text-amber-300 uppercase tracking-wider block">
              Expiring Within 30 Days
            </span>
            <span className="text-2xl font-bold text-amber-900 dark:text-amber-100 font-display">
              {
                complianceDocs.filter((d) => {
                  if (d.verificationStatus === 'expired') return false;
                  const days = (new Date(d.expiryDate).getTime() - Date.now()) / (1000 * 3600 * 24);
                  return days <= 30 && days > 0;
                }).length
              }
            </span>
            <p className="text-[11px] text-amber-700/80 dark:text-amber-300/80 mt-0.5">
              Renewal alerts dispatched
            </p>
          </div>
          <AlertTriangle className="h-8 w-8 text-amber-500 opacity-80" />
        </div>

        <div className="bg-red-50 dark:bg-red-950/30 border border-red-200 dark:border-red-800/40 p-4 rounded-xl flex items-center justify-between">
          <div>
            <span className="text-xs font-semibold text-red-800 dark:text-red-300 uppercase tracking-wider block">
              Expired (Lockout Enforced)
            </span>
            <span className="text-2xl font-bold text-red-900 dark:text-red-100 font-display">
              {complianceDocs.filter((d) => d.verificationStatus === 'expired').length}
            </span>
            <p className="text-[11px] text-red-700/80 dark:text-red-300/80 mt-0.5">
              Automated trip grounding active
            </p>
          </div>
          <ShieldAlert className="h-8 w-8 text-red-500 opacity-80" />
        </div>
      </div>

      {/* Filter and Search */}
      <div className="flex flex-col sm:flex-row items-stretch sm:items-center justify-between gap-3 bg-white dark:bg-slate-800/90 border border-slate-200 dark:border-slate-700/80 rounded-xl p-3 shadow-sm">
        <div className="relative flex-1">
          <Search className="absolute left-3 top-2.5 h-4 w-4 text-slate-400" />
          <input
            type="text"
            placeholder="Search documents by Certificate #, Vehicle..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            className="w-full pl-9 pr-4 py-2 bg-slate-50 dark:bg-slate-900 border border-slate-200 dark:border-slate-700 rounded-lg text-sm text-slate-900 dark:text-white focus:outline-none focus:ring-2 focus:ring-blue-500"
          />
        </div>

        <div className="flex items-center space-x-1.5 overflow-x-auto pb-1 sm:pb-0">
          {[
            { id: 'all', label: 'All Documents' },
            { id: 'RC', label: 'RC' },
            { id: 'Insurance', label: 'Insurance' },
            { id: 'PUC', label: 'PUC' },
            { id: 'Fitness', label: 'Fitness' },
            { id: 'National Permit', label: 'Permit' },
            { id: 'Road Tax', label: 'Road Tax' },
          ].map((item) => (
            <button
              key={item.id}
              onClick={() => setDocTypeFilter(item.id)}
              className={`px-3 py-1.5 rounded-lg text-xs font-semibold uppercase tracking-wider transition whitespace-nowrap ${
                docTypeFilter === item.id
                  ? 'bg-blue-600 text-white'
                  : 'bg-slate-100 dark:bg-slate-700/60 text-slate-600 dark:text-slate-300 hover:bg-slate-200'
              }`}
            >
              {item.label}
            </button>
          ))}
        </div>
      </div>

      {/* Compliance Documents Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
        {filteredDocs.map((doc) => {
          const vehicle = vehicles.find((v) => v.id === doc.vehicleId);
          const daysToExpiry = Math.round(
            (new Date(doc.expiryDate).getTime() - Date.now()) / (1000 * 3600 * 24)
          );
          const isExpired = doc.verificationStatus === 'expired' || daysToExpiry < 0;
          const isExpiringSoon = !isExpired && daysToExpiry <= 30;

          return (
            <div
              key={doc.id}
              className={`bg-white dark:bg-slate-800/90 border rounded-xl p-5 shadow-sm flex flex-col justify-between ${
                isExpired
                  ? 'border-red-300 dark:border-red-900/60'
                  : isExpiringSoon
                  ? 'border-amber-300 dark:border-amber-900/60'
                  : 'border-slate-200 dark:border-slate-700/80'
              }`}
            >
              <div>
                <div className="flex items-start justify-between">
                  <div className="flex items-center space-x-3">
                    <div className="p-2.5 rounded-xl bg-blue-50 dark:bg-blue-900/30 text-blue-600">
                      <FileText className="h-5 w-5" />
                    </div>
                    <div>
                      <h4 className="font-bold text-sm text-slate-900 dark:text-white">
                        {doc.documentType} Certificate
                      </h4>
                      <p className="text-xs text-slate-500 font-mono">
                        {doc.documentNumber}
                      </p>
                    </div>
                  </div>

                  <span
                    className={`text-[10px] font-bold uppercase px-2 py-0.5 rounded-full ${
                      isExpired
                        ? 'bg-red-100 text-red-800 dark:bg-red-900/40 dark:text-red-300'
                        : isExpiringSoon
                        ? 'bg-amber-100 text-amber-800 dark:bg-amber-900/40 dark:text-amber-300'
                        : 'bg-emerald-100 text-emerald-800 dark:bg-emerald-900/40 dark:text-emerald-300'
                    }`}
                  >
                    {isExpired ? 'Expired' : isExpiringSoon ? `${daysToExpiry}d Expiry` : 'Verified'}
                  </span>
                </div>

                <div className="mt-4 space-y-2 text-xs border-t border-b border-slate-100 dark:border-slate-700/60 py-3">
                  <p className="flex justify-between">
                    <span className="text-slate-400">Assigned Vehicle:</span>
                    <span className="font-semibold text-slate-800 dark:text-slate-200">
                      {vehicle ? `${vehicle.licensePlate} (${vehicle.make})` : 'N/A'}
                    </span>
                  </p>
                  <p className="flex justify-between">
                    <span className="text-slate-400">Issued On:</span>
                    <span className="font-semibold text-slate-800 dark:text-slate-200">
                      {doc.issueDate}
                    </span>
                  </p>
                  <p className="flex justify-between">
                    <span className="text-slate-400">Expiry Date:</span>
                    <span
                      className={`font-semibold ${
                        isExpired
                          ? 'text-red-600 dark:text-red-400'
                          : isExpiringSoon
                          ? 'text-amber-600 dark:text-amber-400'
                          : 'text-slate-800 dark:text-slate-200'
                      }`}
                    >
                      {doc.expiryDate}
                    </span>
                  </p>
                  {doc.verifiedBy && (
                    <p className="flex justify-between">
                      <span className="text-slate-400">Verified By:</span>
                      <span className="font-semibold text-slate-800 dark:text-slate-200">
                        {doc.verifiedBy}
                      </span>
                    </p>
                  )}
                </div>
              </div>

              {/* Action Buttons */}
              <div className="mt-4 pt-3 border-t border-slate-100 dark:border-slate-700/60 flex items-center justify-between">
                <span className="text-[11px] text-slate-400">
                  Status: <b className="capitalize text-slate-600 dark:text-slate-300">{doc.verificationStatus}</b>
                </span>

                <div className="flex items-center space-x-2">
                  {doc.verificationStatus !== 'verified' && (
                    <button
                      onClick={() => verifyComplianceDoc(doc.id)}
                      className="px-2.5 py-1 bg-emerald-600 hover:bg-emerald-700 text-white rounded-md text-xs font-semibold flex items-center space-x-1"
                    >
                      <CheckCircle2 className="h-3 w-3" />
                      <span>Approve</span>
                    </button>
                  )}
                </div>
              </div>
            </div>
          );
        })}
      </div>

      {/* Upload Document Modal */}
      {showUploadModal && (
        <div className="fixed inset-0 z-50 bg-slate-950/60 backdrop-blur-sm flex items-center justify-center p-4">
          <div className="bg-white dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-2xl max-w-lg w-full p-6 shadow-2xl">
            <div className="flex items-center justify-between border-b border-slate-200 dark:border-slate-700 pb-3">
              <h3 className="text-lg font-bold text-slate-900 dark:text-white font-display">
                Upload Compliance Document
              </h3>
              <button onClick={() => setShowUploadModal(false)} className="text-slate-400 hover:text-white">
                <X className="h-5 w-5" />
              </button>
            </div>

            <form onSubmit={handleUploadDoc} className="mt-4 space-y-4 text-sm">
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
                        {v.licensePlate} ({v.make} {v.model})
                      </option>
                    ))}
                </select>
              </div>

              <div>
                <label className="block text-xs font-medium text-slate-700 dark:text-slate-300 mb-1">
                  Document Type *
                </label>
                <select
                  value={docType}
                  onChange={(e) => setDocType(e.target.value as ComplianceDocument['documentType'])}
                  className="w-full px-3 py-2 bg-slate-50 dark:bg-slate-900 border border-slate-200 dark:border-slate-700 rounded-lg text-xs"
                >
                  <option value="Insurance">Commercial Freight Insurance</option>
                  <option value="RC">Registration Certificate (RC)</option>
                  <option value="PUC">PUC Emissions Certificate</option>
                  <option value="Fitness">Vehicle Safety Fitness Cert</option>
                  <option value="National Permit">National Freight Permit</option>
                  <option value="Road Tax">Interstate Road Tax Receipt</option>
                </select>
              </div>

              <div>
                <label className="block text-xs font-medium text-slate-700 dark:text-slate-300 mb-1">
                  Document / Policy # *
                </label>
                <input
                  type="text"
                  required
                  value={docNumber}
                  onChange={(e) => setDocNumber(e.target.value)}
                  className="w-full px-3 py-2 bg-slate-50 dark:bg-slate-900 border border-slate-200 dark:border-slate-700 rounded-lg text-xs font-mono"
                />
              </div>

              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block text-xs font-medium text-slate-700 dark:text-slate-300 mb-1">
                    Issue Date *
                  </label>
                  <input
                    type="date"
                    required
                    value={issueDate}
                    onChange={(e) => setIssueDate(e.target.value)}
                    className="w-full px-3 py-2 bg-slate-50 dark:bg-slate-900 border border-slate-200 dark:border-slate-700 rounded-lg text-xs"
                  />
                </div>

                <div>
                  <label className="block text-xs font-medium text-slate-700 dark:text-slate-300 mb-1">
                    Expiry Date *
                  </label>
                  <input
                    type="date"
                    required
                    value={expiryDate}
                    onChange={(e) => setExpiryDate(e.target.value)}
                    className="w-full px-3 py-2 bg-slate-50 dark:bg-slate-900 border border-slate-200 dark:border-slate-700 rounded-lg text-xs"
                  />
                </div>
              </div>

              <div className="flex justify-end space-x-3 pt-3 border-t border-slate-200 dark:border-slate-700">
                <button
                  type="button"
                  onClick={() => setShowUploadModal(false)}
                  className="px-4 py-2 text-xs font-medium text-slate-600 dark:text-slate-300"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  className="px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white text-xs font-semibold rounded-lg shadow-sm"
                >
                  Save & Certify
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};
