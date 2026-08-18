import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:collection/collection.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../vehicles/presentation/vehicle_providers.dart';
import '../../drivers/presentation/driver_providers.dart';
import '../../trips/presentation/trip_providers.dart';
import '../../trips/domain/audit_log_entity.dart';
import '../../customers/presentation/customer_providers.dart';
import '../../customers/domain/customer_entity.dart';
import '../../fleet_ops/presentation/fleet_ops_providers.dart';
import '../../inventory/presentation/inventory_providers.dart';
import '../../billing/presentation/billing_providers.dart';
import '../../finance/presentation/finance_providers.dart';
import '../domain/report_entity.dart';
import '../domain/report_repository.dart';
import '../data/report_repository_impl.dart';

// --- Repository Provider ---
final reportRepositoryProvider = Provider<ReportRepository>((ref) {
  return ReportRepositoryImpl();
});

// --- Stream Provider for Saved Reports ---
final savedReportsProvider =
    StreamProvider.autoDispose<List<ReportEntity>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user?.companyId == null) return Stream.value([]);
  return ref.watch(reportRepositoryProvider).watchReports(user!.companyId!);
});

// --- State Providers for Filtering and View Configuration ---
final selectedReportTypeProvider =
    StateProvider<String>((ref) => 'financial_revenue');
final reportTimeframeProvider = StateProvider<String>((ref) => 'monthly');

class ReportFilters {
  final String? vehicleId;
  final String? driverId;
  final String? customerId;
  final String? routeId;
  final String? invoiceStatus;
  final String? paymentStatus;
  final DateTimeRange? dateRange;

  const ReportFilters({
    this.vehicleId,
    this.driverId,
    this.customerId,
    this.routeId,
    this.invoiceStatus,
    this.paymentStatus,
    this.dateRange,
  });

  ReportFilters copyWith({
    String? vehicleId,
    String? driverId,
    String? customerId,
    String? routeId,
    String? invoiceStatus,
    String? paymentStatus,
    DateTimeRange? dateRange,
    bool clearVehicle = false,
    bool clearDriver = false,
    bool clearCustomer = false,
    bool clearRoute = false,
    bool clearInvoiceStatus = false,
    bool clearPaymentStatus = false,
    bool clearDateRange = false,
  }) {
    return ReportFilters(
      vehicleId: clearVehicle ? null : (vehicleId ?? this.vehicleId),
      driverId: clearDriver ? null : (driverId ?? this.driverId),
      customerId: clearCustomer ? null : (customerId ?? this.customerId),
      routeId: clearRoute ? null : (routeId ?? this.routeId),
      invoiceStatus:
          clearInvoiceStatus ? null : (invoiceStatus ?? this.invoiceStatus),
      paymentStatus:
          clearPaymentStatus ? null : (paymentStatus ?? this.paymentStatus),
      dateRange: clearDateRange ? null : (dateRange ?? this.dateRange),
    );
  }
}

final reportFiltersProvider =
    StateNotifierProvider<ReportFiltersNotifier, ReportFilters>((ref) {
  return ReportFiltersNotifier();
});

class ReportFiltersNotifier extends StateNotifier<ReportFilters> {
  ReportFiltersNotifier() : super(const ReportFilters());

  void setVehicleId(String? id) =>
      state = state.copyWith(vehicleId: id, clearVehicle: id == null);
  void setDriverId(String? id) =>
      state = state.copyWith(driverId: id, clearDriver: id == null);
  void setCustomerId(String? id) =>
      state = state.copyWith(customerId: id, clearCustomer: id == null);
  void setRouteId(String? id) =>
      state = state.copyWith(routeId: id, clearRoute: id == null);
  void setInvoiceStatus(String? status) => state =
      state.copyWith(invoiceStatus: status, clearInvoiceStatus: status == null);
  void setPaymentStatus(String? status) => state =
      state.copyWith(paymentStatus: status, clearPaymentStatus: status == null);
  void setDateRange(DateTimeRange? range) =>
      state = state.copyWith(dateRange: range, clearDateRange: range == null);
  void reset() => state = const ReportFilters();
}

// --- Chart Data Point Model ---
class ChartDataPoint {
  final String label;
  final double value;
  final String? group;

  const ChartDataPoint({required this.label, required this.value, this.group});

  Map<String, dynamic> toMap() {
    return {
      'label': label,
      'value': value,
      'group': group,
    };
  }

  factory ChartDataPoint.fromMap(Map<String, dynamic> map) {
    return ChartDataPoint(
      label: map['label'] as String? ?? '',
      value: (map['value'] as num? ?? 0.0).toDouble(),
      group: map['group'] as String?,
    );
  }
}

// --- Aggregate Data Model ---
class ReportData {
  final Map<String, dynamic> kpis;
  final List<Map<String, dynamic>> rows;
  final List<ChartDataPoint> chartData;

  const ReportData({
    required this.kpis,
    required this.rows,
    required this.chartData,
  });
}

// --- Main Aggregation Provider ---
final reportDataProvider = Provider.autoDispose<AsyncValue<ReportData>>((ref) {
  // Listen to UI state
  final type = ref.watch(selectedReportTypeProvider);
  final timeframe = ref.watch(reportTimeframeProvider);
  final filters = ref.watch(reportFiltersProvider);

  // Watch operational data streams
  final vehiclesAsync = ref.watch(vehiclesStreamProvider);
  final driversAsync = ref.watch(driversStreamProvider);
  final tripsAsync = ref.watch(tripsStreamProvider);
  final invoicesAsync = ref.watch(billingInvoicesProvider);
  final paymentsAsync = ref.watch(billingPaymentsProvider);
  final txsAsync = ref.watch(financeTransactionsStreamProvider);
  final partsAsync = ref.watch(partsStreamProvider);
  final fuelsAsync = ref.watch(fuelLogsStreamProvider);
  final maintsAsync = ref.watch(maintenanceLogsStreamProvider);
  final customersAsync = ref.watch(customersStreamProvider);
  final contractsAsync = ref.watch(contractsStreamProvider);

  if (vehiclesAsync.isLoading ||
      driversAsync.isLoading ||
      tripsAsync.isLoading ||
      invoicesAsync.isLoading ||
      paymentsAsync.isLoading ||
      txsAsync.isLoading ||
      partsAsync.isLoading ||
      fuelsAsync.isLoading ||
      maintsAsync.isLoading ||
      customersAsync.isLoading ||
      contractsAsync.isLoading) {
    return const AsyncValue.loading();
  }

  final vehicles = vehiclesAsync.valueOrNull ?? [];
  final drivers = driversAsync.valueOrNull ?? [];
  final trips = tripsAsync.valueOrNull ?? [];
  final invoices = invoicesAsync.valueOrNull ?? [];
  final payments = paymentsAsync.valueOrNull ?? [];
  final txs = txsAsync.valueOrNull ?? [];
  final parts = partsAsync.valueOrNull ?? [];
  final fuels = fuelsAsync.valueOrNull ?? [];
  final maints = maintsAsync.valueOrNull ?? [];
  final customers = customersAsync.valueOrNull ?? [];
  final contracts = contractsAsync.valueOrNull ?? [];

  // Helper date filters
  bool inDateRange(DateTime date) {
    if (filters.dateRange == null) return true;
    return date.isAfter(
            filters.dateRange!.start.subtract(const Duration(seconds: 1))) &&
        date.isBefore(filters.dateRange!.end.add(const Duration(days: 1)));
  }

  String formatDateKey(DateTime date) {
    if (timeframe == 'daily') {
      return DateFormat('yyyy-MM-dd').format(date);
    } else if (timeframe == 'weekly') {
      final weekOfYear =
          ((date.difference(DateTime(date.year, 1, 1)).inDays) / 7).ceil();
      return '${date.year}-W$weekOfYear';
    } else if (timeframe == 'monthly') {
      return DateFormat('yyyy-MM').format(date);
    } else if (timeframe == 'quarterly') {
      final quarter = ((date.month - 1) / 3).floor() + 1;
      return '${date.year}-Q$quarter';
    } else if (timeframe == 'yearly') {
      return '${date.year}';
    }
    return DateFormat('yyyy-MM-dd').format(date);
  }

  try {
    Map<String, dynamic> kpis = {};
    List<Map<String, dynamic>> rows = [];
    List<ChartDataPoint> chartData = [];

    switch (type) {
      case 'financial_revenue':
        final filteredInvoices = invoices.where((i) {
          if (!inDateRange(i.issueDate)) return false;
          if (filters.customerId != null && i.customerId != filters.customerId)
            return false;
          if (filters.invoiceStatus != null &&
              i.status != filters.invoiceStatus) return false;
          return true;
        }).toList();

        final totalInvoiced =
            filteredInvoices.fold<double>(0.0, (acc, i) => acc + i.grandTotal);
        final totalCollected =
            filteredInvoices.fold<double>(0.0, (acc, i) => acc + i.amountPaid);
        final totalOutstanding = filteredInvoices.fold<double>(
            0.0, (acc, i) => acc + i.outstandingAmount);
        final rate = totalInvoiced > 0.0
            ? (totalCollected / totalInvoiced) * 100.0
            : 100.0;

        kpis = {
          'Total Invoiced': '\$${totalInvoiced.toStringAsFixed(2)}',
          'Total Collected': '\$${totalCollected.toStringAsFixed(2)}',
          'Outstanding Receivables': '\$${totalOutstanding.toStringAsFixed(2)}',
          'Collection Rate': '${rate.toStringAsFixed(1)}%',
        };

        // Group by Timeframe for Chart
        final grouped = <String, double>{};
        for (final inv in filteredInvoices) {
          final key = formatDateKey(inv.issueDate);
          grouped[key] = (grouped[key] ?? 0.0) + inv.grandTotal;
        }

        grouped.forEach((key, val) {
          chartData.add(ChartDataPoint(label: key, value: val));
        });
        chartData.sort((a, b) => a.label.compareTo(b.label));

        rows = filteredInvoices
            .map((i) => {
                  'Invoice ID': i.id,
                  'Invoice Number': i.invoiceNumber,
                  'Customer': i.customerName,
                  'Freight Charge': '\$${i.freightCharge.toStringAsFixed(2)}',
                  'Grand Total': '\$${i.grandTotal.toStringAsFixed(2)}',
                  'Amount Paid': '\$${i.amountPaid.toStringAsFixed(2)}',
                  'Outstanding': '\$${i.outstandingAmount.toStringAsFixed(2)}',
                  'Status': i.status,
                  'Issue Date': DateFormat('yyyy-MM-dd').format(i.issueDate),
                })
            .toList();
        break;

      case 'financial_expense':
        final filteredTxs = txs.where((t) {
          if (t.type != 'expense') return false;
          if (!inDateRange(t.transactionDate)) return false;
          if (filters.vehicleId != null && t.vehicleId != filters.vehicleId)
            return false;
          if (filters.driverId != null && t.tripId != null) {
            // Find driver in trip
            final trip = trips.firstWhereOrNull((tr) => tr.id == t.tripId);
            if (trip != null && trip.driverId != filters.driverId) return false;
          }
          return true;
        }).toList();

        final totalExp =
            filteredTxs.fold<double>(0.0, (acc, t) => acc + t.amount);
        final fuelExp = filteredTxs
            .where((t) => t.category == 'diesel')
            .fold<double>(0.0, (acc, t) => acc + t.amount);
        final maintExp = filteredTxs
            .where((t) => t.category == 'repair' || t.category == 'tyre')
            .fold<double>(0.0, (acc, t) => acc + t.amount);
        final salaryExp = filteredTxs
            .where((t) =>
                t.category == 'driver_salary' || t.category == 'advance_salary')
            .fold<double>(0.0, (acc, t) => acc + t.amount);

        kpis = {
          'Total Expenses': '\$${totalExp.toStringAsFixed(2)}',
          'Fuel Expenses': '\$${fuelExp.toStringAsFixed(2)}',
          'Maintenance Expenses': '\$${maintExp.toStringAsFixed(2)}',
          'Salary & Advances': '\$${salaryExp.toStringAsFixed(2)}',
        };

        final grouped = <String, double>{};
        for (final tx in filteredTxs) {
          final key = formatDateKey(tx.transactionDate);
          grouped[key] = (grouped[key] ?? 0.0) + tx.amount;
        }

        grouped.forEach((key, val) {
          chartData.add(ChartDataPoint(label: key, value: val));
        });
        chartData.sort((a, b) => a.label.compareTo(b.label));

        rows = filteredTxs
            .map((t) => {
                  'Transaction ID': t.id,
                  'Category': t.category,
                  'Amount': '\$${t.amount.toStringAsFixed(2)}',
                  'Payment Mode': t.paymentMode,
                  'Vehicle': t.vehicleLicensePlate ?? 'N/A',
                  'Trip': t.tripNumber ?? 'N/A',
                  'Date': DateFormat('yyyy-MM-dd').format(t.transactionDate),
                  'Notes': t.notes ?? '',
                })
            .toList();
        break;

      case 'financial_profit_loss':
        // Sum total income vs expense
        final filteredIncomes = txs
            .where((t) => t.type == 'income' && inDateRange(t.transactionDate))
            .toList();
        final filteredExpenses = txs
            .where((t) => t.type == 'expense' && inDateRange(t.transactionDate))
            .toList();

        // Plus invoices grandTotal as alternative/operational income
        final invoiceRevenue = invoices
            .where((i) =>
                i.status != 'draft' &&
                i.status != 'cancelled' &&
                inDateRange(i.issueDate))
            .fold<double>(0.0, (acc, i) => acc + i.grandTotal);
        final financeIncome =
            filteredIncomes.fold<double>(0.0, (acc, t) => acc + t.amount);
        final totalIncome =
            financeIncome > 0.0 ? financeIncome : invoiceRevenue;

        final totalExpense =
            filteredExpenses.fold<double>(0.0, (acc, t) => acc + t.amount);
        final netProfit = totalIncome - totalExpense;
        final margin =
            totalIncome > 0.0 ? (netProfit / totalIncome) * 100 : 0.0;

        kpis = {
          'Total Income': '\$${totalIncome.toStringAsFixed(2)}',
          'Total Expense': '\$${totalExpense.toStringAsFixed(2)}',
          'Net Profit': '\$${netProfit.toStringAsFixed(2)}',
          'Profit Margin': '${margin.toStringAsFixed(1)}%',
        };

        // Group P&L by Timeframe
        final groupedIncome = <String, double>{};
        final groupedExpense = <String, double>{};

        if (financeIncome > 0.0) {
          for (final t in filteredIncomes) {
            final key = formatDateKey(t.transactionDate);
            groupedIncome[key] = (groupedIncome[key] ?? 0.0) + t.amount;
          }
        } else {
          for (final i in invoices.where((i) =>
              i.status != 'draft' &&
              i.status != 'cancelled' &&
              inDateRange(i.issueDate))) {
            final key = formatDateKey(i.issueDate);
            groupedIncome[key] = (groupedIncome[key] ?? 0.0) + i.grandTotal;
          }
        }

        for (final t in filteredExpenses) {
          final key = formatDateKey(t.transactionDate);
          groupedExpense[key] = (groupedExpense[key] ?? 0.0) + t.amount;
        }

        final allKeys = {...groupedIncome.keys, ...groupedExpense.keys}.toList()
          ..sort();
        for (final key in allKeys) {
          chartData.add(ChartDataPoint(
              label: key, value: groupedIncome[key] ?? 0.0, group: 'Income'));
          chartData.add(ChartDataPoint(
              label: key, value: groupedExpense[key] ?? 0.0, group: 'Expense'));
        }

        rows = [
          {
            'Account': 'Gross Invoiced Revenue',
            'Total Amount': '\$${invoiceRevenue.toStringAsFixed(2)}',
            'Details': 'Accumulated accounts receivable'
          },
          {
            'Account': 'Direct Finance Income',
            'Total Amount': '\$${financeIncome.toStringAsFixed(2)}',
            'Details': 'Cash/UPI/Bank direct receipts'
          },
          {
            'Account': 'Operating Expenses',
            'Total Amount': '\$${totalExpense.toStringAsFixed(2)}',
            'Details': 'Salaries, fuel, tolls, parts, repairs'
          },
          {
            'Account': 'Net Operational Profit',
            'Total Amount': '\$${netProfit.toStringAsFixed(2)}',
            'Details': 'Income minus direct expenses'
          },
        ];
        break;

      case 'financial_cash_flow':
        // Cash Flow tracks direct cash/bank transaction records (payments received vs expense transactions)
        final filteredPayments = payments
            .where((p) => p.status == 'completed' && inDateRange(p.paymentDate))
            .toList();
        final filteredExpenses = txs
            .where((t) => t.type == 'expense' && inDateRange(t.transactionDate))
            .toList();

        final inflows =
            filteredPayments.fold<double>(0.0, (acc, p) => acc + p.amount);
        final outflows =
            filteredExpenses.fold<double>(0.0, (acc, t) => acc + t.amount);
        final netCash = inflows - outflows;

        kpis = {
          'Total Inflow': '\$${inflows.toStringAsFixed(2)}',
          'Total Outflow': '\$${outflows.toStringAsFixed(2)}',
          'Net Cash Flow': '\$${netCash.toStringAsFixed(2)}',
          'Cash Flow Health': netCash >= 0.0 ? 'Positive' : 'Negative Alert',
        };

        // Group by Timeframe
        final groupedIn = <String, double>{};
        final groupedOut = <String, double>{};

        for (final p in filteredPayments) {
          final key = formatDateKey(p.paymentDate);
          groupedIn[key] = (groupedIn[key] ?? 0.0) + p.amount;
        }

        for (final t in filteredExpenses) {
          final key = formatDateKey(t.transactionDate);
          groupedOut[key] = (groupedOut[key] ?? 0.0) + t.amount;
        }

        final allKeys = {...groupedIn.keys, ...groupedOut.keys}.toList()
          ..sort();
        for (final key in allKeys) {
          chartData.add(ChartDataPoint(
              label: key, value: groupedIn[key] ?? 0.0, group: 'Inflow'));
          chartData.add(ChartDataPoint(
              label: key, value: groupedOut[key] ?? 0.0, group: 'Outflow'));
        }

        rows = filteredPayments
            .map((p) => {
                  'Date': DateFormat('yyyy-MM-dd').format(p.paymentDate),
                  'Type': 'Inflow',
                  'Source': 'Invoice ${p.invoiceId}',
                  'Reference': p.referenceNumber ?? 'N/A',
                  'Amount': '+\$${p.amount.toStringAsFixed(2)}',
                })
            .toList()
          ..addAll(filteredExpenses
              .map((t) => {
                    'Date': DateFormat('yyyy-MM-dd').format(t.transactionDate),
                    'Type': 'Outflow',
                    'Source': 'Expense (${t.category})',
                    'Reference': t.referenceNumber ?? 'N/A',
                    'Amount': '-\$${t.amount.toStringAsFixed(2)}',
                  })
              .toList());

        rows.sort(
            (a, b) => (b['Date'] as String).compareTo(a['Date'] as String));
        break;

      case 'financial_outstanding_receivables':
        final activeInvoices = invoices
            .where((i) => i.status == 'sent' || i.status == 'overdue')
            .toList();
        final totalOut = activeInvoices.fold<double>(
            0.0, (acc, i) => acc + i.outstandingAmount);

        final now = DateTime.now();
        final aging30 = activeInvoices
            .where((i) => now.difference(i.issueDate).inDays <= 30)
            .fold<double>(0.0, (acc, i) => acc + i.outstandingAmount);
        final aging60 = activeInvoices
            .where((i) =>
                now.difference(i.issueDate).inDays > 30 &&
                now.difference(i.issueDate).inDays <= 60)
            .fold<double>(0.0, (acc, i) => acc + i.outstandingAmount);
        final aging90 = activeInvoices
            .where((i) => now.difference(i.issueDate).inDays > 60)
            .fold<double>(0.0, (acc, i) => acc + i.outstandingAmount);

        kpis = {
          'Total Outstanding': '\$${totalOut.toStringAsFixed(2)}',
          '0 - 30 Days Aging': '\$${aging30.toStringAsFixed(2)}',
          '31 - 60 Days Aging': '\$${aging60.toStringAsFixed(2)}',
          '60+ Days Aging': '\$${aging90.toStringAsFixed(2)}',
        };

        chartData = [
          ChartDataPoint(label: '0-30 Days', value: aging30),
          ChartDataPoint(label: '31-60 Days', value: aging60),
          ChartDataPoint(label: '60+ Days', value: aging90),
        ];

        rows = activeInvoices
            .map((i) => {
                  'Invoice Number': i.invoiceNumber,
                  'Customer Name': i.customerName,
                  'Due Date': DateFormat('yyyy-MM-dd').format(i.dueDate),
                  'Aging (Days)': now.difference(i.issueDate).inDays.toString(),
                  'Invoiced Amount': '\$${i.grandTotal.toStringAsFixed(2)}',
                  'Outstanding Amount':
                      '\$${i.outstandingAmount.toStringAsFixed(2)}',
                  'Status': i.status,
                })
            .toList();
        break;

      case 'financial_customer_ledger':
        final custId = filters.customerId;
        if (custId == null) {
          kpis = {'Ledger': 'Please select a Customer'};
          rows = [];
          break;
        }

        final customer = customers.firstWhereOrNull((c) => c.id == custId) ??
            CustomerEntity(
                id: custId,
                name: 'Unknown Customer',
                contactName: '',
                email: '',
                phone: '',
                address: '',
                createdAt: DateTime.now(),
                updatedAt: DateTime.now());
        final custInvoices = invoices
            .where((i) => i.customerId == custId && inDateRange(i.issueDate))
            .toList();
        final totalInv =
            custInvoices.fold<double>(0.0, (acc, i) => acc + i.grandTotal);
        final totalPaid =
            custInvoices.fold<double>(0.0, (acc, i) => acc + i.amountPaid);
        final currentBal = totalInv - totalPaid;

        kpis = {
          'Customer Name': customer.name,
          'Total Invoiced': '\$${totalInv.toStringAsFixed(2)}',
          'Total Payments': '\$${totalPaid.toStringAsFixed(2)}',
          'Current Balance': '\$${currentBal.toStringAsFixed(2)}',
        };

        final grouped = <String, double>{};
        for (final inv in custInvoices) {
          final key = formatDateKey(inv.issueDate);
          grouped[key] = (grouped[key] ?? 0.0) + inv.grandTotal;
        }
        grouped.forEach((key, val) {
          chartData.add(ChartDataPoint(label: key, value: val));
        });
        chartData.sort((a, b) => a.label.compareTo(b.label));

        rows = custInvoices
            .map((i) => {
                  'Date': DateFormat('yyyy-MM-dd').format(i.issueDate),
                  'Document ID': i.id,
                  'Invoice/Ref': i.invoiceNumber,
                  'Invoiced Total': '\$${i.grandTotal.toStringAsFixed(2)}',
                  'Amount Settled': '\$${i.amountPaid.toStringAsFixed(2)}',
                  'Balance Remaining':
                      '\$${i.outstandingAmount.toStringAsFixed(2)}',
                  'Status': i.status,
                })
            .toList();
        rows.sort(
            (a, b) => (b['Date'] as String).compareTo(a['Date'] as String));
        break;

      case 'financial_driver_expense':
        final filteredTxs = txs.where((t) {
          if (t.category != 'driver_salary' && t.category != 'advance_salary')
            return false;
          if (!inDateRange(t.transactionDate)) return false;
          if (filters.driverId != null) {
            // Check if transaction has tripId, matching driverId
            final trip = trips.firstWhereOrNull((tr) => tr.id == t.tripId);
            if (trip != null && trip.driverId != filters.driverId) return false;
          }
          return true;
        }).toList();

        final totalSalaries = filteredTxs
            .where((t) => t.category == 'driver_salary')
            .fold<double>(0.0, (acc, t) => acc + t.amount);
        final totalAdvances = filteredTxs
            .where((t) => t.category == 'advance_salary')
            .fold<double>(0.0, (acc, t) => acc + t.amount);
        final totalCombined = totalSalaries + totalAdvances;

        kpis = {
          'Total Expense': '\$${totalCombined.toStringAsFixed(2)}',
          'Salary Disbursed': '\$${totalSalaries.toStringAsFixed(2)}',
          'Salary Advances': '\$${totalAdvances.toStringAsFixed(2)}',
        };

        // Group by Timeframe
        final grouped = <String, double>{};
        for (final t in filteredTxs) {
          final key = formatDateKey(t.transactionDate);
          grouped[key] = (grouped[key] ?? 0.0) + t.amount;
        }
        grouped.forEach((key, val) {
          chartData.add(ChartDataPoint(label: key, value: val));
        });
        chartData.sort((a, b) => a.label.compareTo(b.label));

        rows = filteredTxs
            .map((t) => {
                  'Date': DateFormat('yyyy-MM-dd').format(t.transactionDate),
                  'Category': t.category,
                  'Amount': '\$${t.amount.toStringAsFixed(2)}',
                  'Payment Mode': t.paymentMode,
                  'Trip ID/Number': t.tripNumber ?? 'N/A',
                  'Reference': t.referenceNumber ?? 'N/A',
                })
            .toList();
        break;

      case 'financial_vehicle_expense':
        final filteredTxs = txs.where((t) {
          if (t.vehicleId == null) return false;
          if (!inDateRange(t.transactionDate)) return false;
          if (filters.vehicleId != null && t.vehicleId != filters.vehicleId)
            return false;
          return true;
        }).toList();

        final totalFuel = filteredTxs
            .where((t) => t.category == 'diesel')
            .fold<double>(0.0, (acc, t) => acc + t.amount);
        final totalMaint = filteredTxs
            .where((t) => t.category == 'repair' || t.category == 'tyre')
            .fold<double>(0.0, (acc, t) => acc + t.amount);
        final totalMisc = filteredTxs
            .where((t) =>
                t.category == 'toll' ||
                t.category == 'insurance' ||
                t.category == 'miscellaneous')
            .fold<double>(0.0, (acc, t) => acc + t.amount);
        final totalCombined = totalFuel + totalMaint + totalMisc;

        kpis = {
          'Total Vehicle Expense': '\$${totalCombined.toStringAsFixed(2)}',
          'Fuel/Diesel Cost': '\$${totalFuel.toStringAsFixed(2)}',
          'Repairs & Maintenance': '\$${totalMaint.toStringAsFixed(2)}',
          'Tolls, Insurance & Misc': '\$${totalMisc.toStringAsFixed(2)}',
        };

        // Group by Timeframe
        final grouped = <String, double>{};
        for (final t in filteredTxs) {
          final key = formatDateKey(t.transactionDate);
          grouped[key] = (grouped[key] ?? 0.0) + t.amount;
        }
        grouped.forEach((key, val) {
          chartData.add(ChartDataPoint(label: key, value: val));
        });
        chartData.sort((a, b) => a.label.compareTo(b.label));

        rows = filteredTxs
            .map((t) => {
                  'Date': DateFormat('yyyy-MM-dd').format(t.transactionDate),
                  'Vehicle License': t.vehicleLicensePlate ?? 'N/A',
                  'Category': t.category,
                  'Amount': '\$${t.amount.toStringAsFixed(2)}',
                  'Payment Mode': t.paymentMode,
                  'Reference': t.referenceNumber ?? 'N/A',
                })
            .toList();
        break;

      case 'fleet_vehicle_utilization':
        final activeTrips = trips.where((t) {
          if (!inDateRange(t.createdAt)) return false;
          if (filters.vehicleId != null && t.vehicleId != filters.vehicleId)
            return false;
          return t.status == 'completed' || t.status == 'in_transit';
        }).toList();

        final totalVehicles = vehicles.length;
        final totalTrips = activeTrips.length;

        // Approximate utilization rate based on trip count per vehicle
        final avgTripsPerVehicle =
            totalVehicles > 0 ? totalTrips / totalVehicles : 0.0;
        final utilPercent = totalVehicles > 0
            ? (activeTrips.map((t) => t.vehicleId).toSet().length /
                    totalVehicles) *
                100
            : 0.0;

        kpis = {
          'Fleet Size': totalVehicles.toString(),
          'Utilized Vehicles':
              activeTrips.map((t) => t.vehicleId).toSet().length.toString(),
          'Utilization Rate': '${utilPercent.toStringAsFixed(1)}%',
          'Avg Trips per Vehicle': avgTripsPerVehicle.toStringAsFixed(1),
        };

        // Group by vehicle
        final grouped = <String, int>{};
        for (final t in activeTrips) {
          final v = vehicles.firstWhereOrNull((veh) => veh.id == t.vehicleId);
          final label = v != null ? v.licensePlate : t.vehicleId;
          grouped[label] = (grouped[label] ?? 0) + 1;
        }
        grouped.forEach((label, val) {
          chartData.add(ChartDataPoint(label: label, value: val.toDouble()));
        });

        rows = vehicles.map((v) {
          final vTrips = activeTrips.where((t) => t.vehicleId == v.id).length;
          return {
            'Vehicle ID': v.id,
            'License Plate': v.licensePlate,
            'Make & Model': '${v.make} ${v.model}',
            'Year': v.year.toString(),
            'Trip Count': vTrips.toString(),
            'Status': v.status,
            'Capacity': '${v.odometer} km',
          };
        }).toList();
        break;

      case 'fleet_trip_summary':
        final filteredTrips = trips.where((t) {
          if (!inDateRange(t.createdAt)) return false;
          if (filters.driverId != null && t.driverId != filters.driverId)
            return false;
          if (filters.vehicleId != null && t.vehicleId != filters.vehicleId)
            return false;
          return true;
        }).toList();

        final totalTrips = filteredTrips.length;
        final completed =
            filteredTrips.where((t) => t.status == 'completed').length;
        final inTransit =
            filteredTrips.where((t) => t.status == 'in_transit').length;
        final cancelled =
            filteredTrips.where((t) => t.status == 'cancelled').length;

        kpis = {
          'Total Trips': totalTrips.toString(),
          'Completed Trips': completed.toString(),
          'Active Trips': inTransit.toString(),
          'Cancelled Trips': cancelled.toString(),
        };

        final grouped = <String, double>{};
        for (final t in filteredTrips) {
          final key = formatDateKey(t.createdAt);
          grouped[key] = (grouped[key] ?? 0.0) + 1;
        }
        grouped.forEach((key, val) {
          chartData.add(ChartDataPoint(label: key, value: val));
        });
        chartData.sort((a, b) => a.label.compareTo(b.label));

        rows = filteredTrips
            .map((t) => {
                  'Trip ID': t.id,
                  'Trip Number': t.id,
                  'Driver': drivers
                          .firstWhereOrNull((d) => d.id == t.driverId)
                          ?.fullName ??
                      'Unknown',
                  'Vehicle': vehicles
                          .firstWhereOrNull((v) => v.id == t.vehicleId)
                          ?.licensePlate ??
                      'Unknown',
                  'Cargo Description': t.cargoType,
                  'Route Start': t.pickupLocation,
                  'Route End': t.deliveryLocation,
                  'Status': t.status,
                })
            .toList();
        break;

      case 'fleet_availability':
        final totalVehicles = vehicles.length;
        final available = vehicles
            .where((v) => v.status == 'active' || v.status == 'idle')
            .length;
        final maintenance =
            vehicles.where((v) => v.status == 'maintenance').length;
        final decommissioned = vehicles
            .where((v) => v.status == 'decommissioned' || v.status == 'sold')
            .length;
        final rate =
            totalVehicles > 0 ? (available / totalVehicles) * 100 : 100.0;

        kpis = {
          'Total Fleet Size': totalVehicles.toString(),
          'Available Vehicles': available.toString(),
          'In Maintenance': maintenance.toString(),
          'Availability Rate': '${rate.toStringAsFixed(1)}%',
        };

        chartData = [
          ChartDataPoint(label: 'Available', value: available.toDouble()),
          ChartDataPoint(label: 'Maintenance', value: maintenance.toDouble()),
          ChartDataPoint(
              label: 'Decommissioned', value: decommissioned.toDouble()),
        ];

        rows = vehicles
            .map((v) => {
                  'License Plate': v.licensePlate,
                  'Make': v.make,
                  'Model': v.model,
                  'Year': v.year.toString(),
                  'Status': v.status,
                  'Fuel Type': v.fuelType,
                  'Current Odometer': '${v.odometer} km',
                })
            .toList();
        break;

      case 'fleet_driver_utilization':
        final activeTrips = trips
            .where((t) => t.status == 'completed' || t.status == 'in_transit')
            .toList();
        final totalDrivers = drivers.length;
        final activeDrivers = activeTrips.map((t) => t.driverId).toSet().length;
        final utilPercent =
            totalDrivers > 0 ? (activeDrivers / totalDrivers) * 100 : 0.0;

        kpis = {
          'Total Drivers': totalDrivers.toString(),
          'Active Drivers': activeDrivers.toString(),
          'Driver Utilization': '${utilPercent.toStringAsFixed(1)}%',
          'Idle Drivers': (totalDrivers - activeDrivers).toString(),
        };

        // Group by driver
        final grouped = <String, int>{};
        for (final t in activeTrips) {
          final d = drivers.firstWhereOrNull((drv) => drv.id == t.driverId);
          final label = d != null ? d.fullName : t.driverId;
          grouped[label] = (grouped[label] ?? 0) + 1;
        }
        grouped.forEach((label, val) {
          chartData.add(ChartDataPoint(label: label, value: val.toDouble()));
        });

        rows = drivers.map((d) {
          final count = activeTrips.where((t) => t.driverId == d.id).length;
          return {
            'Driver Name': d.fullName,
            'Phone': d.phone,
            'License Expiry': d.licenseExpiry.toString().split(' ')[0],
            'Status': d.status,
            'Safety Score': '${d.safetyScore}%',
            'Trip Count': count.toString(),
          };
        }).toList();
        break;

      case 'fleet_driver_performance':
        final avgSafety = drivers.isEmpty
            ? 0.0
            : drivers.fold<double>(0.0, (acc, d) => acc + d.safetyScore) /
                drivers.length;
        final highSafety = drivers.isEmpty
            ? 0
            : drivers.map((d) => d.safetyScore).reduce((a, b) => a > b ? a : b);
        final lowSafety = drivers.isEmpty
            ? 0
            : drivers.map((d) => d.safetyScore).reduce((a, b) => a < b ? a : b);

        kpis = {
          'Average Safety Score': '${avgSafety.toStringAsFixed(1)}%',
          'Highest Safety Score': '$highSafety%',
          'Lowest Safety Score': '$lowSafety%',
          'Driver Count': drivers.length.toString(),
        };

        // Group into buckets for chart
        final buckets = {'<70%': 0, '70-80%': 0, '81-90%': 0, '91-100%': 0};
        for (final d in drivers) {
          if (d.safetyScore < 70) {
            buckets['<70%'] = buckets['<70%']! + 1;
          } else if (d.safetyScore <= 80) {
            buckets['70-80%'] = buckets['70-80%']! + 1;
          } else if (d.safetyScore <= 90) {
            buckets['81-90%'] = buckets['81-90%']! + 1;
          } else {
            buckets['91-100%'] = buckets['91-100%']! + 1;
          }
        }
        buckets.forEach((label, val) {
          chartData.add(ChartDataPoint(label: label, value: val.toDouble()));
        });

        rows = drivers
            .map((d) => {
                  'Driver Name': d.fullName,
                  'License Number': d.licenseNumber,
                  'Safety Rating': '${d.safetyScore}%',
                  'Performance Class': d.safetyScore >= 90
                      ? 'Excellent'
                      : d.safetyScore >= 75
                          ? 'Good'
                          : 'Needs Review',
                  'Current Status': d.status,
                })
            .toList();
        break;

      case 'fleet_fuel_consumption':
        final filteredFuels = fuels.where((f) {
          if (!inDateRange(f.date)) return false;
          if (filters.vehicleId != null && f.vehicleId != filters.vehicleId)
            return false;
          if (filters.driverId != null && f.driverId != filters.driverId)
            return false;
          return true;
        }).toList();

        final totalLiters =
            filteredFuels.fold<double>(0.0, (acc, f) => acc + f.fuelQty);
        final totalCost =
            filteredFuels.fold<double>(0.0, (acc, f) => acc + f.amount);
        final avgPrice = totalLiters > 0 ? totalCost / totalLiters : 0.0;

        kpis = {
          'Total Liters Refueled': '${totalLiters.toStringAsFixed(1)} L',
          'Total Fuel Spend': '\$${totalCost.toStringAsFixed(2)}',
          'Average Fuel Price': '\$${avgPrice.toStringAsFixed(2)}/L',
          'Refuel Receipts': filteredFuels.length.toString(),
        };

        // Group by Timeframe
        final grouped = <String, double>{};
        for (final f in filteredFuels) {
          final key = formatDateKey(f.date);
          grouped[key] = (grouped[key] ?? 0.0) + f.fuelQty;
        }
        grouped.forEach((key, val) {
          chartData.add(ChartDataPoint(label: key, value: val));
        });
        chartData.sort((a, b) => a.label.compareTo(b.label));

        rows = filteredFuels
            .map((f) => {
                  'Date': DateFormat('yyyy-MM-dd').format(f.date),
                  'Vehicle License': f.vehicleLicensePlate,
                  'Driver': f.driverName,
                  'Fuel Quantity': '${f.fuelQty.toStringAsFixed(1)} L',
                  'Cost': '\$${f.amount.toStringAsFixed(2)}',
                  'Odometer': '${f.odometer} km',
                })
            .toList();
        break;

      case 'fleet_maintenance_cost':
        final filteredMaints = maints.where((m) {
          if (!inDateRange(m.date)) return false;
          if (filters.vehicleId != null && m.vehicleId != filters.vehicleId)
            return false;
          return true;
        }).toList();

        final totalCost =
            filteredMaints.fold<double>(0.0, (acc, m) => acc + m.cost);
        final preventative = filteredMaints
            .where((m) => m.type == 'preventative')
            .fold<double>(0.0, (acc, m) => acc + m.cost);
        final corrective = filteredMaints
            .where((m) => m.type == 'corrective')
            .fold<double>(0.0, (acc, m) => acc + m.cost);
        final avgCost =
            filteredMaints.isEmpty ? 0.0 : totalCost / filteredMaints.length;

        kpis = {
          'Total Maintenance Cost': '\$${totalCost.toStringAsFixed(2)}',
          'Preventative Spend': '\$${preventative.toStringAsFixed(2)}',
          'Corrective Spend': '\$${corrective.toStringAsFixed(2)}',
          'Avg Cost per Service': '\$${avgCost.toStringAsFixed(2)}',
        };

        // Group by Type
        chartData = [
          ChartDataPoint(label: 'Preventative', value: preventative),
          ChartDataPoint(label: 'Corrective', value: corrective),
        ];

        rows = filteredMaints
            .map((m) => {
                  'Date': DateFormat('yyyy-MM-dd').format(m.date),
                  'Vehicle License': m.vehicleLicensePlate,
                  'Type': m.type,
                  'Description': m.description,
                  'Repair Cost': '\$${m.cost.toStringAsFixed(2)}',
                  'Odometer': '${m.odometer} km',
                  'Part Replaced': m.partName ?? 'None',
                })
            .toList();
        break;

      case 'fleet_inventory_usage':
        // Sum inventory transactions or parts consumed in maintenance
        final maintParts = maints
            .where((m) => m.partId != null && inDateRange(m.date))
            .toList();
        final totalPartsUsed =
            maintParts.fold<int>(0, (acc, m) => acc + (m.partQuantity ?? 0));

        final totalValue = maintParts.fold<double>(0.0, (acc, m) {
          final part = parts.firstWhereOrNull((p) => p.id == m.partId);
          final price = part != null ? part.unitCost : 0.0;
          return acc + ((m.partQuantity ?? 0) * price);
        });

        kpis = {
          'Parts Consumed Count': totalPartsUsed.toString(),
          'Total Valuation': '\$${totalValue.toStringAsFixed(2)}',
          'Unique Parts Replaced':
              maintParts.map((m) => m.partId).toSet().length.toString(),
        };

        // Group by part name
        final grouped = <String, int>{};
        for (final m in maintParts) {
          final label = m.partName ?? m.partId!;
          grouped[label] = (grouped[label] ?? 0) + (m.partQuantity ?? 1);
        }
        grouped.forEach((label, val) {
          chartData.add(ChartDataPoint(label: label, value: val.toDouble()));
        });

        rows = maintParts.map((m) {
          final part = parts.firstWhereOrNull((p) => p.id == m.partId);
          final price = part != null ? part.unitCost : 0.0;
          final value = (m.partQuantity ?? 0) * price;
          return {
            'Date': DateFormat('yyyy-MM-dd').format(m.date),
            'Part Name': m.partName ?? 'N/A',
            'Quantity Consumed': (m.partQuantity ?? 0).toString(),
            'Unit Cost': '\$${price.toStringAsFixed(2)}',
            'Total Value': '\$${value.toStringAsFixed(2)}',
            'Assigned Vehicle': m.vehicleLicensePlate,
          };
        }).toList();
        break;

      case 'customer_revenue':
        final filteredInvoices = invoices
            .where((i) =>
                i.status != 'draft' &&
                i.status != 'cancelled' &&
                inDateRange(i.issueDate))
            .toList();

        // Group by customer
        final grouped = <String, double>{};
        for (final inv in filteredInvoices) {
          grouped[inv.customerName] =
              (grouped[inv.customerName] ?? 0.0) + inv.grandTotal;
        }

        grouped.forEach((name, amount) {
          chartData.add(ChartDataPoint(label: name, value: amount));
        });
        chartData
            .sort((a, b) => b.value.compareTo(a.value)); // Top customers first

        final totalRev =
            filteredInvoices.fold<double>(0.0, (acc, i) => acc + i.grandTotal);
        final topCustomerName =
            chartData.isNotEmpty ? chartData.first.label : 'None';
        final topCustomerValue =
            chartData.isNotEmpty ? chartData.first.value : 0.0;

        kpis = {
          'Total Gross Revenue': '\$${totalRev.toStringAsFixed(2)}',
          'Active Customers Count': customers.length.toString(),
          'Top Customer': topCustomerName,
          'Top Billing Value': '\$${topCustomerValue.toStringAsFixed(2)}',
        };

        rows = grouped.entries
            .map((entry) => {
                  'Customer Name': entry.key,
                  'Total Revenue Generated':
                      '\$${entry.value.toStringAsFixed(2)}',
                  'Share Percentage':
                      '${totalRev > 0.0 ? ((entry.value / totalRev) * 100).toStringAsFixed(1) : 0.0}%',
                })
            .toList();
        break;

      case 'customer_outstanding':
        final unpaidInvoices = invoices
            .where((i) =>
                (i.status == 'sent' || i.status == 'overdue') &&
                inDateRange(i.issueDate))
            .toList();

        final grouped = <String, double>{};
        for (final inv in unpaidInvoices) {
          grouped[inv.customerName] =
              (grouped[inv.customerName] ?? 0.0) + inv.outstandingAmount;
        }

        grouped.forEach((name, amount) {
          chartData.add(ChartDataPoint(label: name, value: amount));
        });
        chartData.sort((a, b) => b.value.compareTo(a.value));

        final totalOut = unpaidInvoices.fold<double>(
            0.0, (acc, i) => acc + i.outstandingAmount);
        final worstCustomerName =
            chartData.isNotEmpty ? chartData.first.label : 'None';
        final worstCustomerValue =
            chartData.isNotEmpty ? chartData.first.value : 0.0;

        kpis = {
          'Total Outstanding Receivables': '\$${totalOut.toStringAsFixed(2)}',
          'Defaulting Customer Count': grouped.keys.length.toString(),
          'Highest Debt Customer': worstCustomerName,
          'Highest Debt Balance': '\$${worstCustomerValue.toStringAsFixed(2)}',
        };

        rows = grouped.entries
            .map((entry) => {
                  'Customer Name': entry.key,
                  'Outstanding Receivables':
                      '\$${entry.value.toStringAsFixed(2)}',
                  'Risk Exposure %':
                      '${totalOut > 0.0 ? ((entry.value / totalOut) * 100).toStringAsFixed(1) : 0.0}%',
                })
            .toList();
        break;

      case 'customer_payment_history':
        final filteredPayments = payments
            .where((p) => p.status == 'completed' && inDateRange(p.paymentDate))
            .toList();

        final totalInflows =
            filteredPayments.fold<double>(0.0, (acc, p) => acc + p.amount);
        final avgPayment = filteredPayments.isEmpty
            ? 0.0
            : totalInflows / filteredPayments.length;

        kpis = {
          'Total Direct Payments Received':
              '\$${totalInflows.toStringAsFixed(2)}',
          'Total Payment Transactions': filteredPayments.length.toString(),
          'Avg Payment Amount': '\$${avgPayment.toStringAsFixed(2)}',
        };

        final grouped = <String, double>{};
        for (final p in filteredPayments) {
          final key = formatDateKey(p.paymentDate);
          grouped[key] = (grouped[key] ?? 0.0) + p.amount;
        }
        grouped.forEach((key, val) {
          chartData.add(ChartDataPoint(label: key, value: val));
        });
        chartData.sort((a, b) => a.label.compareTo(b.label));

        rows = filteredPayments
            .map((p) => {
                  'Payment ID': p.id,
                  'Invoice ID': p.invoiceId,
                  'Payment Mode': p.paymentMethod,
                  'Reference #': p.referenceNumber ?? 'N/A',
                  'Settlement Date':
                      DateFormat('yyyy-MM-dd').format(p.paymentDate),
                  'Paid Sum': '\$${p.amount.toStringAsFixed(2)}',
                  'Payment Status': p.status,
                })
            .toList();
        break;

      case 'customer_contract_summary':
        final filteredContracts =
            contracts.where((c) => inDateRange(c.createdAt)).toList();

        final totalContracts = filteredContracts.length;
        final activeContracts =
            filteredContracts.where((c) => c.status == 'active').length;

        kpis = {
          'Total Managed Contracts': totalContracts.toString(),
          'Active Contracts': activeContracts.toString(),
          'Expired/Terminated Contracts':
              (totalContracts - activeContracts).toString(),
        };

        // Group by Customer
        final grouped = <String, int>{};
        for (final c in filteredContracts) {
          final cust =
              customers.firstWhereOrNull((cust) => cust.id == c.customerId);
          final label = cust != null ? cust.name : c.customerId;
          grouped[label] = (grouped[label] ?? 0) + 1;
        }
        grouped.forEach((label, val) {
          chartData.add(ChartDataPoint(label: label, value: val.toDouble()));
        });

        rows = filteredContracts.map((c) {
          final cust =
              customers.firstWhereOrNull((cust) => cust.id == c.customerId);
          return {
            'Contract ID': c.id,
            'Contract Code/Ref': c.contractNumber,
            'Client/Customer': cust?.name ?? 'Unknown',
            'Start Validity': c.startDate.toString().split(' ')[0],
            'End Expiry': c.endDate.toString().split(' ')[0],
            'Freight Billing Details':
                '\$${c.defaultFreightRate.toStringAsFixed(2)} (Default)',
            'Status State': c.status,
          };
        }).toList();
        break;

      default:
        kpis = {'Operational KPI': 'General Report Selected'};
        rows = [];
        break;
    }

    return AsyncValue.data(ReportData(
      kpis: kpis,
      rows: rows,
      chartData: chartData,
    ));
  } catch (e, stackTrace) {
    return AsyncValue.error(e, stackTrace);
  }
});

// --- Report Saving Controller ---
class ReportSaveState {
  final bool isLoading;
  final String? errorMessage;
  final bool isCompleted;

  const ReportSaveState({
    this.isLoading = false,
    this.errorMessage,
    this.isCompleted = false,
  });
}

class ReportSaveController extends StateNotifier<ReportSaveState> {
  final ReportRepository _repo;
  final Ref _ref;

  ReportSaveController({
    required ReportRepository repo,
    required Ref ref,
  })  : _repo = repo,
        _ref = ref,
        super(const ReportSaveState());

  Future<void> saveReport(
      String title, String type, ReportData data, ReportFilters filters) async {
    state = const ReportSaveState(isLoading: true);
    try {
      final user = _ref.read(currentUserProvider);
      if (user?.companyId == null) {
        throw Exception('User tenant company context is missing.');
      }

      final report = ReportEntity(
        id: '',
        companyId: user!.companyId!,
        title: title,
        type: type,
        filters: {
          'vehicleId': filters.vehicleId,
          'driverId': filters.driverId,
          'customerId': filters.customerId,
          'routeId': filters.routeId,
          'invoiceStatus': filters.invoiceStatus,
          'paymentStatus': filters.paymentStatus,
          'dateRangeStart': filters.dateRange?.start.toIso8601String(),
          'dateRangeEnd': filters.dateRange?.end.toIso8601String(),
        },
        data: {
          'kpis': data.kpis,
          'rows': data.rows,
          'chartData': data.chartData.map((d) => d.toMap()).toList(),
        },
        generatedAt: DateTime.now(),
        generatedBy: user.displayName,
      );

      await _repo.createReport(user.companyId!, report);

      // Write Audit Log
      final auditLog = AuditLogEntity(
        id: const Uuid().v4(),
        companyId: user.companyId!,
        entityType: 'report',
        entityId: report.id,
        action: 'report_generated',
        description: 'Report "$title" ($type) generated by ${user.displayName}',
        userId: user.uid,
        userName: user.displayName,
        timestamp: DateTime.now(),
      );

      await FirebaseFirestore.instance
          .collection('companies')
          .doc(user.companyId)
          .collection('audit_logs')
          .doc(auditLog.id)
          .set(auditLog.toMap());

      state = const ReportSaveState(isCompleted: true);
    } catch (e) {
      state = ReportSaveState(errorMessage: e.toString());
    }
  }

  Future<void> logReportExport(String title, String type, String format) async {
    try {
      final user = _ref.read(currentUserProvider);
      if (user?.companyId == null) return;

      final auditLog = AuditLogEntity(
        id: const Uuid().v4(),
        companyId: user!.companyId!,
        entityType: 'report',
        entityId: '',
        action: 'report_exported',
        description:
            'Report "$title" ($type) exported to $format by ${user.displayName}',
        userId: user.uid,
        userName: user.displayName,
        timestamp: DateTime.now(),
      );

      await FirebaseFirestore.instance
          .collection('companies')
          .doc(user.companyId)
          .collection('audit_logs')
          .doc(auditLog.id)
          .set(auditLog.toMap());
    } catch (_) {}
  }
}

final reportSaveControllerProvider =
    StateNotifierProvider.autoDispose<ReportSaveController, ReportSaveState>(
        (ref) {
  return ReportSaveController(
    repo: ref.watch(reportRepositoryProvider),
    ref: ref,
  );
});
