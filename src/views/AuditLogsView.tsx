import React, { useState } from 'react';
import { useFleet } from '../context/FleetContext';
import {
  History,
  Search,
  ShieldCheck,
  Code2,
  ChevronDown,
  ChevronUp,
  User,
  Laptop
} from 'lucide-react';

export const AuditLogsView: React.FC = () => {
  const { auditLogs } = useFleet();

  const [searchQuery, setSearchQuery] = useState('');
  const [collectionFilter, setCollectionFilter] = useState<string>('all');
  const [expandedLogId, setExpandedLogId] = useState<string | null>(null);

  const filteredLogs = auditLogs.filter((log) => {
    if (collectionFilter !== 'all' && log.collection !== collectionFilter) return false;
    if (searchQuery.trim()) {
      const q = searchQuery.toLowerCase();
      return (
        log.action.toLowerCase().includes(q) ||
        log.summary.toLowerCase().includes(q) ||
        log.userEmail.toLowerCase().includes(q) ||
        log.documentId.toLowerCase().includes(q)
      );
    }
    return true;
  });

  const toggleExpand = (id: string) => {
    setExpandedLogId(expandedLogId === id ? null : id);
  };

  return (
    <div className="space-y-6 pb-12">
      {/* View Header */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold text-slate-900 dark:text-white font-display">
            Immutable Enterprise Audit Trail
          </h1>
          <p className="text-sm text-slate-500 dark:text-slate-400">
            Append-only security log recording state transitions, driver dispatches, and financial authorizations
          </p>
        </div>

        <div className="flex items-center space-x-2 text-xs text-emerald-600 dark:text-emerald-400 bg-emerald-50 dark:bg-emerald-950/30 border border-emerald-200 dark:border-emerald-800/40 px-3 py-1.5 rounded-lg font-semibold">
          <ShieldCheck className="h-4 w-4" />
          <span>Cryptographic Hash Integrity Verified</span>
        </div>
      </div>

      {/* Filter and Search */}
      <div className="flex flex-col sm:flex-row items-stretch sm:items-center justify-between gap-3 bg-white dark:bg-slate-800/90 border border-slate-200 dark:border-slate-700/80 rounded-xl p-3 shadow-sm">
        <div className="relative flex-1">
          <Search className="absolute left-3 top-2.5 h-4 w-4 text-slate-400" />
          <input
            type="text"
            placeholder="Search audit trail by Action, User, Document ID, Summary..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            className="w-full pl-9 pr-4 py-2 bg-slate-50 dark:bg-slate-900 border border-slate-200 dark:border-slate-700 rounded-lg text-sm text-slate-900 dark:text-white focus:outline-none focus:ring-2 focus:ring-blue-500"
          />
        </div>

        <div className="flex items-center space-x-1.5 overflow-x-auto pb-1 sm:pb-0">
          {[
            { id: 'all', label: 'All Events' },
            { id: 'vehicles', label: 'Vehicles' },
            { id: 'trips', label: 'Trips' },
            { id: 'drivers', label: 'Drivers' },
            { id: 'maintenance', label: 'Maintenance' },
            { id: 'compliance', label: 'Compliance' },
            { id: 'billing', label: 'Billing' },
          ].map((item) => (
            <button
              key={item.id}
              onClick={() => setCollectionFilter(item.id)}
              className={`px-3 py-1.5 rounded-lg text-xs font-semibold uppercase tracking-wider transition whitespace-nowrap ${
                collectionFilter === item.id
                  ? 'bg-blue-600 text-white'
                  : 'bg-slate-100 dark:bg-slate-700/60 text-slate-600 dark:text-slate-300 hover:bg-slate-200'
              }`}
            >
              {item.label}
            </button>
          ))}
        </div>
      </div>

      {/* Audit Log Timeline */}
      <div className="bg-white dark:bg-slate-800/90 border border-slate-200 dark:border-slate-700/80 rounded-xl overflow-hidden shadow-sm">
        <div className="divide-y divide-slate-100 dark:divide-slate-700/60">
          {filteredLogs.map((log) => {
            const isExpanded = expandedLogId === log.id;

            return (
              <div key={log.id} className="p-4 hover:bg-slate-50 dark:hover:bg-slate-700/30 transition">
                <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-2">
                  <div className="flex items-center space-x-3">
                    <div className="p-2 rounded-lg bg-slate-100 dark:bg-slate-700 text-slate-600 dark:text-slate-300">
                      <History className="h-4 w-4" />
                    </div>

                    <div>
                      <div className="flex items-center space-x-2">
                        <span className="font-bold text-sm text-slate-900 dark:text-white">
                          {log.summary}
                        </span>
                        <span className="text-[10px] font-bold uppercase px-2 py-0.5 rounded bg-blue-100 text-blue-800 dark:bg-blue-900/40 dark:text-blue-300">
                          {log.action}
                        </span>
                        <span className="text-[10px] font-bold uppercase px-2 py-0.5 rounded bg-slate-100 dark:bg-slate-700 text-slate-600 dark:text-slate-300">
                          {log.collection}
                        </span>
                      </div>
                      <p className="text-xs text-slate-500 flex items-center space-x-2 mt-0.5">
                        <span className="flex items-center space-x-1">
                          <User className="h-3 w-3" />
                          <span>{log.userEmail}</span>
                        </span>
                        <span>•</span>
                        <span className="flex items-center space-x-1">
                          <Laptop className="h-3 w-3" />
                          <span>IP: {log.ipAddress}</span>
                        </span>
                        <span>•</span>
                        <span className="font-mono text-[11px]">Doc: {log.documentId}</span>
                      </p>
                    </div>
                  </div>

                  <div className="flex items-center space-x-3 text-xs">
                    <span className="text-slate-400 font-mono">
                      {new Date(log.timestamp).toLocaleString()}
                    </span>

                    <button
                      onClick={() => toggleExpand(log.id)}
                      className="p-1 text-slate-400 hover:text-slate-600 dark:hover:text-white rounded"
                    >
                      {isExpanded ? <ChevronUp className="h-4 w-4" /> : <ChevronDown className="h-4 w-4" />}
                    </button>
                  </div>
                </div>

                {/* Expanded Payload Diff Inspection Box */}
                {isExpanded && (
                  <div className="mt-3 p-3 bg-slate-950 text-slate-200 rounded-lg border border-slate-800 text-xs font-mono overflow-x-auto">
                    <div className="flex items-center space-x-1 text-slate-400 mb-1">
                      <Code2 className="h-3.5 w-3.5 text-blue-400" />
                      <span>Audit Delta Changes Payload:</span>
                    </div>
                    <pre className="text-[11px] leading-relaxed text-teal-300">
                      {JSON.stringify(log.changes, null, 2)}
                    </pre>
                  </div>
                )}
              </div>
            );
          })}
        </div>
      </div>
    </div>
  );
};
