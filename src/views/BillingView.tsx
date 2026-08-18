import React, { useState } from 'react';
import { useFleet } from '../context/FleetContext';
import { Invoice } from '../types';
import {
  CreditCard,
  TrendingUp,
  DollarSign,
  Search,
  FileText,
  X,
  ArrowDownRight
} from 'lucide-react';

export const BillingView: React.FC = () => {
  const {
    invoices,
    fuelLogs,
    maintenanceTickets,
    currentCompany,
    markInvoicePaid,
    topUpFastag,
  } = useFleet();

  const [searchQuery, setSearchQuery] = useState('');
  const [selectedInvoice, setSelectedInvoice] = useState<Invoice | null>(null);
  const [showTopUpModal, setShowTopUpModal] = useState(false);
  const [topUpAmount, setTopUpAmount] = useState(500);

  // Calculate high-level financial P&L
  const totalGrossRevenue = invoices.reduce((acc, inv) => acc + inv.totalAmount, 0);
  const totalFuelExpense = fuelLogs.reduce((acc, log) => acc + log.totalCost, 0);
  const totalMaintenanceExpense = maintenanceTickets.reduce((acc, t) => acc + (t.actualCost || t.estimatedCost), 0);
  const netOperatingMargin = totalGrossRevenue - totalFuelExpense - totalMaintenanceExpense;
  const marginPercentage = totalGrossRevenue > 0 ? Math.round((netOperatingMargin / totalGrossRevenue) * 100) : 0;

  const filteredInvoices = invoices.filter((inv) => {
    if (searchQuery.trim()) {
      const q = searchQuery.toLowerCase();
      return (
        inv.invoiceNumber.toLowerCase().includes(q) ||
        inv.customerName.toLowerCase().includes(q)
      );
    }
    return true;
  });

  const handleTopUp = (e: React.FormEvent) => {
    e.preventDefault();
    topUpFastag(Number(topUpAmount));
    setShowTopUpModal(false);
  };

  return (
    <div className="space-y-6 pb-12">
      {/* View Header */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold text-slate-900 dark:text-white font-display">
            Billing & Financial Intelligence
          </h1>
          <p className="text-sm text-slate-500 dark:text-slate-400">
            Freight invoice ledgers, operational P&L margins, and FASTag toll management
          </p>
        </div>

        <button
          onClick={() => setShowTopUpModal(true)}
          className="flex items-center space-x-2 px-4 py-2 bg-teal-600 hover:bg-teal-700 text-white rounded-lg text-sm font-semibold shadow-sm transition"
        >
          <CreditCard className="h-4 w-4" />
          <span>Top-Up FASTag Balance</span>
        </button>
      </div>

      {/* P&L Executive Summary Cards */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        {/* Gross Revenue */}
        <div className="bg-white dark:bg-slate-800/90 border border-slate-200 dark:border-slate-700/80 rounded-xl p-4 shadow-sm">
          <div className="flex items-center justify-between">
            <span className="text-xs font-medium text-slate-500 dark:text-slate-400 uppercase tracking-wider">
              Gross Freight Revenue
            </span>
            <div className="h-8 w-8 rounded-lg bg-blue-50 dark:bg-blue-900/30 text-blue-600 dark:text-blue-400 flex items-center justify-center">
              <DollarSign className="h-4 w-4" />
            </div>
          </div>
          <div className="mt-3 flex items-baseline space-x-2">
            <span className="font-display text-2xl font-bold text-slate-900 dark:text-white">
              ${totalGrossRevenue.toLocaleString(undefined, { minimumFractionDigits: 2 })}
            </span>
          </div>
          <p className="text-xs text-slate-500 dark:text-slate-400 mt-1">
            {invoices.length} freight manifests billed
          </p>
        </div>

        {/* Fuel Expense */}
        <div className="bg-white dark:bg-slate-800/90 border border-slate-200 dark:border-slate-700/80 rounded-xl p-4 shadow-sm">
          <div className="flex items-center justify-between">
            <span className="text-xs font-medium text-slate-500 dark:text-slate-400 uppercase tracking-wider">
              Total Fuel Expense
            </span>
            <div className="h-8 w-8 rounded-lg bg-amber-50 dark:bg-amber-900/30 text-amber-600 dark:text-amber-400 flex items-center justify-center">
              <ArrowDownRight className="h-4 w-4" />
            </div>
          </div>
          <div className="mt-3 flex items-baseline space-x-2">
            <span className="font-display text-2xl font-bold text-slate-900 dark:text-white">
              ${totalFuelExpense.toLocaleString(undefined, { minimumFractionDigits: 2 })}
            </span>
          </div>
          <p className="text-xs text-slate-500 dark:text-slate-400 mt-1">
            {fuelLogs.length} verified station receipts
          </p>
        </div>

        {/* Maintenance Expense */}
        <div className="bg-white dark:bg-slate-800/90 border border-slate-200 dark:border-slate-700/80 rounded-xl p-4 shadow-sm">
          <div className="flex items-center justify-between">
            <span className="text-xs font-medium text-slate-500 dark:text-slate-400 uppercase tracking-wider">
              Fleet Maintenance OPEX
            </span>
            <div className="h-8 w-8 rounded-lg bg-red-50 dark:bg-red-900/30 text-red-600 dark:text-red-400 flex items-center justify-center">
              <ArrowDownRight className="h-4 w-4" />
            </div>
          </div>
          <div className="mt-3 flex items-baseline space-x-2">
            <span className="font-display text-2xl font-bold text-slate-900 dark:text-white">
              ${totalMaintenanceExpense.toLocaleString(undefined, { minimumFractionDigits: 2 })}
            </span>
          </div>
          <p className="text-xs text-slate-500 dark:text-slate-400 mt-1">
            Routine PM & mechanical repairs
          </p>
        </div>

        {/* Net Operating Margin */}
        <div className="bg-white dark:bg-slate-800/90 border border-slate-200 dark:border-slate-700/80 rounded-xl p-4 shadow-sm">
          <div className="flex items-center justify-between">
            <span className="text-xs font-medium text-slate-500 dark:text-slate-400 uppercase tracking-wider">
              Net Operating Margin
            </span>
            <div className="h-8 w-8 rounded-lg bg-emerald-50 dark:bg-emerald-900/30 text-emerald-600 dark:text-emerald-400 flex items-center justify-center">
              <TrendingUp className="h-4 w-4" />
            </div>
          </div>
          <div className="mt-3 flex items-baseline space-x-2">
            <span className="font-display text-2xl font-bold text-emerald-600 dark:text-emerald-400">
              ${netOperatingMargin.toLocaleString(undefined, { minimumFractionDigits: 2 })}
            </span>
            <span className="text-xs font-bold text-emerald-600">({marginPercentage}%)</span>
          </div>
          <p className="text-xs text-slate-500 dark:text-slate-400 mt-1">
            Positive cashflow generated
          </p>
        </div>
      </div>

      {/* FASTag Toll Pool Card */}
      <div className="bg-slate-900 text-white rounded-2xl p-6 border border-slate-800 flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4">
        <div>
          <div className="flex items-center space-x-2 text-teal-400 text-xs font-bold uppercase tracking-wider">
            <CreditCard className="h-4 w-4" />
            <span>FASTag Electronic Toll Pool</span>
          </div>
          <h3 className="text-2xl font-bold font-display mt-1">
            ${currentCompany.fastagBalance.toFixed(2)}{' '}
            <span className="text-xs font-normal text-slate-400">Available across all active RFID transponders</span>
          </h3>
          <p className="text-xs text-slate-400 mt-1">
            Auto-replenishment threshold trigger: <span className="text-amber-400 font-semibold">$300.00</span>
          </p>
        </div>

        <button
          onClick={() => setShowTopUpModal(true)}
          className="px-4 py-2 bg-teal-500 hover:bg-teal-600 text-slate-950 font-bold text-xs rounded-xl shadow-lg transition"
        >
          Instant Top-Up &rarr;
        </button>
      </div>

      {/* Invoices Ledger Table */}
      <div className="bg-white dark:bg-slate-800/90 border border-slate-200 dark:border-slate-700/80 rounded-xl overflow-hidden shadow-sm">
        <div className="p-4 border-b border-slate-200 dark:border-slate-700 flex items-center justify-between">
          <div>
            <h3 className="font-display font-semibold text-sm text-slate-900 dark:text-white">
              Customer Freight Invoices & Ledgers
            </h3>
            <p className="text-xs text-slate-500">
              Tax invoices with automated fuel surcharge calculations
            </p>
          </div>

          <div className="relative w-64">
            <Search className="absolute left-3 top-2.5 h-4 w-4 text-slate-400" />
            <input
              type="text"
              placeholder="Search invoice #, customer..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              className="w-full pl-9 pr-3 py-1.5 bg-slate-50 dark:bg-slate-900 border border-slate-200 dark:border-slate-700 rounded-lg text-xs"
            />
          </div>
        </div>

        <div className="overflow-x-auto">
          <table className="w-full text-left text-xs text-slate-600 dark:text-slate-300">
            <thead className="bg-slate-50 dark:bg-slate-900/80 text-slate-700 dark:text-slate-400 font-semibold border-b border-slate-200 dark:border-slate-700">
              <tr>
                <th className="py-3 px-4">Invoice #</th>
                <th className="py-3 px-4">Customer</th>
                <th className="py-3 px-4">Trip Manifest</th>
                <th className="py-3 px-4">Amount</th>
                <th className="py-3 px-4">Due Date</th>
                <th className="py-3 px-4">Status</th>
                <th className="py-3 px-4 text-right">Action</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100 dark:divide-slate-700/60">
              {filteredInvoices.map((inv) => {
                const isPaid = inv.status === 'paid';
                return (
                  <tr key={inv.id} className="hover:bg-slate-50 dark:hover:bg-slate-700/30">
                    <td className="py-3 px-4 font-mono font-bold text-blue-600 dark:text-blue-400">
                      {inv.invoiceNumber}
                    </td>

                    <td className="py-3 px-4 font-medium text-slate-900 dark:text-white">
                      {inv.customerName}
                    </td>

                    <td className="py-3 px-4 font-mono text-slate-500">
                      {inv.tripId ? `Trip: ${inv.tripId.slice(-6)}` : 'Manual Order'}
                    </td>

                    <td className="py-3 px-4 font-bold text-slate-900 dark:text-white">
                      ${inv.totalAmount.toLocaleString(undefined, { minimumFractionDigits: 2 })}
                    </td>

                    <td className="py-3 px-4 text-slate-500">
                      {inv.dueDate}
                    </td>

                    <td className="py-3 px-4">
                      <span
                        className={`text-[10px] font-bold uppercase px-2 py-0.5 rounded-full ${
                          isPaid
                            ? 'bg-emerald-100 text-emerald-800 dark:bg-emerald-900/40 dark:text-emerald-300'
                            : 'bg-amber-100 text-amber-800 dark:bg-amber-900/40 dark:text-amber-300'
                        }`}
                      >
                        {inv.status}
                      </span>
                    </td>

                    <td className="py-3 px-4 text-right space-x-2">
                      <button
                        onClick={() => setSelectedInvoice(inv)}
                        className="p-1 text-slate-400 hover:text-blue-600 rounded"
                        title="View Manifest & Print"
                      >
                        <FileText className="h-4 w-4 inline" />
                      </button>

                      {!isPaid && (
                        <button
                          onClick={() => markInvoicePaid(inv.id)}
                          className="px-2 py-1 bg-emerald-600 hover:bg-emerald-700 text-white rounded text-[10px] font-semibold"
                        >
                          Mark Paid
                        </button>
                      )}
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>
      </div>

      {/* View Printable Invoice Manifest Modal */}
      {selectedInvoice && (
        <div className="fixed inset-0 z-50 bg-slate-950/60 backdrop-blur-sm flex items-center justify-center p-4">
          <div className="bg-white dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-2xl max-w-xl w-full p-6 shadow-2xl">
            <div className="flex items-center justify-between border-b border-slate-200 dark:border-slate-700 pb-3">
              <div className="flex items-center space-x-2">
                <FileText className="h-5 w-5 text-blue-600" />
                <h3 className="text-base font-bold text-slate-900 dark:text-white font-display">
                  Freight Invoice Manifest: {selectedInvoice.invoiceNumber}
                </h3>
              </div>
              <button onClick={() => setSelectedInvoice(null)} className="text-slate-400 hover:text-white">
                <X className="h-5 w-5" />
              </button>
            </div>

            <div className="mt-4 p-5 bg-slate-50 dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-700 text-xs space-y-4 font-sans">
              <div className="flex justify-between border-b border-slate-200 dark:border-slate-700 pb-3">
                <div>
                  <h4 className="font-bold text-sm text-slate-900 dark:text-white">{currentCompany.name}</h4>
                  <p className="text-slate-500">Logistics & Freight Solutions ERP</p>
                </div>
                <div className="text-right">
                  <span className="font-mono font-bold text-blue-600">{selectedInvoice.invoiceNumber}</span>
                  <p className="text-slate-500">Date: {selectedInvoice.issueDate}</p>
                </div>
              </div>

              <div className="grid grid-cols-2 gap-4">
                <div>
                  <span className="text-slate-400 block text-[10px] uppercase">Billed To:</span>
                  <p className="font-bold text-slate-800 dark:text-slate-200">{selectedInvoice.customerName}</p>
                  <p className="text-slate-500">Corporate Shipper Account</p>
                </div>
                <div>
                  <span className="text-slate-400 block text-[10px] uppercase">Payment Status:</span>
                  <span className="font-bold text-emerald-600 capitalize">{selectedInvoice.status}</span>
                  <p className="text-slate-500">Due: {selectedInvoice.dueDate}</p>
                </div>
              </div>

              {/* Line Items */}
              <div className="border-t border-b border-slate-200 dark:border-slate-700 py-3 space-y-2">
                <div className="flex justify-between font-semibold">
                  <span>Line Item Description</span>
                  <span>Amount ($)</span>
                </div>
                {selectedInvoice.items.map((item, idx) => (
                  <div key={idx} className="flex justify-between text-slate-600 dark:text-slate-400">
                    <span>{item.description} ({item.quantity} unit @ ${item.rate})</span>
                    <span className="font-mono font-semibold">${item.amount.toFixed(2)}</span>
                  </div>
                ))}
              </div>

              <div className="flex justify-between font-bold text-sm text-slate-900 dark:text-white pt-1">
                <span>Total Balance Due:</span>
                <span className="font-mono text-base text-blue-600 dark:text-blue-400">
                  ${selectedInvoice.totalAmount.toFixed(2)}
                </span>
              </div>
            </div>

            <div className="mt-5 flex justify-between items-center">
              <span className="text-[11px] text-slate-400">
                Authorized Electronic Billing Document
              </span>
              <button
                onClick={() => setSelectedInvoice(null)}
                className="px-4 py-2 bg-slate-100 dark:bg-slate-700 text-slate-700 dark:text-slate-200 rounded-lg text-xs font-semibold"
              >
                Close Manifest
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Top-Up FASTag Balance Modal */}
      {showTopUpModal && (
        <div className="fixed inset-0 z-50 bg-slate-950/60 backdrop-blur-sm flex items-center justify-center p-4">
          <div className="bg-white dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-2xl max-w-md w-full p-6 shadow-2xl">
            <div className="flex items-center justify-between border-b border-slate-200 dark:border-slate-700 pb-3">
              <h3 className="text-base font-bold text-slate-900 dark:text-white font-display">
                Replenish FASTag Electronic Toll Pool
              </h3>
              <button onClick={() => setShowTopUpModal(false)} className="text-slate-400 hover:text-white">
                <X className="h-5 w-5" />
              </button>
            </div>

            <form onSubmit={handleTopUp} className="mt-4 space-y-4 text-sm">
              <div>
                <label className="block text-xs font-medium text-slate-700 dark:text-slate-300 mb-1">
                  Top-Up Deposit Amount ($)
                </label>
                <div className="grid grid-cols-3 gap-2 mb-2">
                  {[250, 500, 1000].map((amt) => (
                    <button
                      key={amt}
                      type="button"
                      onClick={() => setTopUpAmount(amt)}
                      className={`py-2 rounded-lg text-xs font-bold border ${
                        topUpAmount === amt
                          ? 'bg-teal-600 text-white border-teal-600'
                          : 'bg-slate-50 dark:bg-slate-900 border-slate-200 dark:border-slate-700'
                      }`}
                    >
                      ${amt}
                    </button>
                  ))}
                </div>
                <input
                  type="number"
                  required
                  min={50}
                  value={topUpAmount}
                  onChange={(e) => setTopUpAmount(Number(e.target.value))}
                  className="w-full px-3 py-2 bg-slate-50 dark:bg-slate-900 border border-slate-200 dark:border-slate-700 rounded-lg text-xs font-bold"
                />
              </div>

              <div className="p-3 bg-slate-50 dark:bg-slate-900/60 rounded-xl border border-slate-200 dark:border-slate-700 text-xs text-slate-500 space-y-1">
                <p>• Current Balance: <b>${currentCompany.fastagBalance.toFixed(2)}</b></p>
                <p>• Balance After Top-up: <b>${(currentCompany.fastagBalance + Number(topUpAmount)).toFixed(2)}</b></p>
              </div>

              <div className="flex justify-end space-x-3 pt-3 border-t border-slate-200 dark:border-slate-700">
                <button
                  type="button"
                  onClick={() => setShowTopUpModal(false)}
                  className="px-4 py-2 text-xs font-medium text-slate-600 dark:text-slate-300"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  className="px-4 py-2 bg-teal-600 hover:bg-teal-700 text-white text-xs font-semibold rounded-lg shadow-sm"
                >
                  Authorize Toll Deposit
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};
