import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../auth/presentation/auth_providers.dart';
import '../../vehicles/presentation/vehicle_providers.dart';
import '../../drivers/presentation/driver_providers.dart';
import '../../customers/presentation/customer_providers.dart';
import '../../vehicles/domain/vehicle_entity.dart';
import '../../drivers/domain/driver_entity.dart';
import '../../customers/domain/customer_entity.dart';
import '../domain/report_entity.dart';
import 'report_providers.dart';
import 'report_export_helper.dart';
import 'widgets/chart_widgets.dart';

class ReportScreen extends ConsumerStatefulWidget {
  const ReportScreen({super.key});

  @override
  ConsumerState<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends ConsumerState<ReportScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _saveTitleController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _saveTitleController.dispose();
    super.dispose();
  }

  // Helper map to translate report types to human-readable names
  String _getReportName(String type) {
    switch (type) {
      case 'financial_revenue':
        return 'Revenue Report';
      case 'financial_expense':
        return 'Expense Report';
      case 'financial_profit_loss':
        return 'Profit & Loss Statement';
      case 'financial_cash_flow':
        return 'Cash Flow Statement';
      case 'financial_outstanding_receivables':
        return 'Outstanding Receivables Aging';
      case 'financial_customer_ledger':
        return 'Customer General Ledger';
      case 'financial_driver_expense':
        return 'Driver Payroll & Expenses';
      case 'financial_vehicle_expense':
        return 'Vehicle Expense Ledger';
      case 'fleet_vehicle_utilization':
        return 'Vehicle Utilization Analytics';
      case 'fleet_trip_summary':
        return 'Logistics Trip Summary';
      case 'fleet_availability':
        return 'Fleet Availability Matrix';
      case 'fleet_driver_utilization':
        return 'Driver Duty & Shifts';
      case 'fleet_driver_performance':
        return 'Driver Safety & Performance';
      case 'fleet_fuel_consumption':
        return 'Fuel Efficiency Analytics';
      case 'fleet_maintenance_cost':
        return 'Maintenance Cost Analytics';
      case 'fleet_inventory_usage':
        return 'Spare Parts Usage Ledger';
      case 'customer_revenue':
        return 'Customer Revenue Summary';
      case 'customer_outstanding':
        return 'Customer Debt Exposure';
      case 'customer_payment_history':
        return 'Customer Settlement Logs';
      case 'customer_contract_summary':
        return 'Freight Contract Summaries';
      default:
        return 'Business Intelligence Report';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final selectedType = ref.watch(selectedReportTypeProvider);
    final timeframe = ref.watch(reportTimeframeProvider);
    final filters = ref.watch(reportFiltersProvider);

    // Watch query streams for filter dropdown values
    final List<VehicleEntity> vehicles =
        ref.watch(vehiclesStreamProvider).valueOrNull ?? <VehicleEntity>[];
    final List<DriverEntity> drivers =
        ref.watch(driversStreamProvider).valueOrNull ?? <DriverEntity>[];
    final List<CustomerEntity> customers =
        ref.watch(customersStreamProvider).valueOrNull ?? <CustomerEntity>[];

    final reportDataAsync = ref.watch(reportDataProvider);
    final savedReports = ref.watch(savedReportsProvider).valueOrNull ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Enterprise BI & Reporting Engine'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.refresh(reportDataProvider),
          ),
        ],
      ),
      body: Row(
        children: [
          // Main content pane
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Page Header
                  Text(
                    _getReportName(selectedType),
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onBackground,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Timeframe: ${timeframe.toUpperCase()} | Filters active: ${filters.dateRange != null ? "Date Range applied" : "None"}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onBackground.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Filter Toolbar Panel
                  _buildFilterToolbar(
                      context, ref, filters, vehicles, drivers, customers),
                  const SizedBox(height: 24),

                  // KPI Dashboard Grid
                  reportDataAsync.when(
                    data: (data) => _buildKpiGrid(context, data.kpis),
                    loading: () => const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                    error: (err, _) => Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('Error loading KPIs: $err'),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Tab Control for Visuals, Data Grid, and Saved Reports
                  Card(
                    child: Column(
                      children: [
                        TabBar(
                          controller: _tabController,
                          labelColor: colorScheme.primary,
                          unselectedLabelColor: colorScheme.onSurfaceVariant,
                          tabs: const [
                            Tab(
                                icon: Icon(Icons.analytics_outlined),
                                text: 'Visual Analytics'),
                            Tab(
                                icon: Icon(Icons.table_view_outlined),
                                text: 'Data Table Grid'),
                            Tab(
                                icon: Icon(Icons.folder_shared_outlined),
                                text: 'Saved Reports'),
                          ],
                        ),
                        SizedBox(
                          height: 480,
                          child: TabBarView(
                            controller: _tabController,
                            children: [
                              // 1. Chart View
                              reportDataAsync.when(
                                data: (data) => Padding(
                                  padding: const EdgeInsets.all(24.0),
                                  child: _buildChart(
                                      selectedType, data.chartData, theme),
                                ),
                                loading: () => const Center(
                                    child: CircularProgressIndicator()),
                                error: (err, _) => Center(
                                    child: Text('Error plotting chart: $err')),
                              ),
                              // 2. Tabular Data View
                              reportDataAsync.when(
                                data: (data) => Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: _buildDataTable(data.rows, theme),
                                ),
                                loading: () => const Center(
                                    child: CircularProgressIndicator()),
                                error: (err, _) =>
                                    Center(child: Text('Error: $err')),
                              ),
                              // 3. Saved Reports View
                              _buildSavedReportsTab(
                                  savedReports, ref, context, theme),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Right Settings sidebar
          Container(
            width: 320,
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(color: colorScheme.outline.withOpacity(0.2)),
              ),
              color: colorScheme.surfaceVariant.withOpacity(0.2),
            ),
            child: _buildSettingsSidebar(context, ref, selectedType, timeframe,
                reportDataAsync, filters),
          ),
        ],
      ),
    );
  }

  // --- FILTER TOOLBAR PANEL ---
  Widget _buildFilterToolbar(
    BuildContext context,
    WidgetRef ref,
    ReportFilters filters,
    List<VehicleEntity> vehicles,
    List<DriverEntity> drivers,
    List<CustomerEntity> customers,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final notifier = ref.read(reportFiltersProvider.notifier);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withOpacity(0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline.withOpacity(0.1)),
      ),
      child: Wrap(
        spacing: 16,
        runSpacing: 16,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          // Date Range picker
          OutlinedButton.icon(
            icon: const Icon(Icons.date_range_outlined),
            label: Text(
              filters.dateRange == null
                  ? 'Filter Date Range'
                  : '${DateFormat('MM/dd/yy').format(filters.dateRange!.start)} - ${DateFormat('MM/dd/yy').format(filters.dateRange!.end)}',
            ),
            onPressed: () async {
              final picked = await showDateRangePicker(
                context: context,
                firstDate: DateTime(2020),
                lastDate: DateTime(2030),
                initialDateRange: filters.dateRange,
              );
              if (picked != null) {
                notifier.setDateRange(picked);
              }
            },
          ),

          // Vehicle dropdown filter
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              hint: const Text('Filter Vehicle'),
              value: filters.vehicleId,
              items: [
                const DropdownMenuItem<String>(
                    value: null, child: Text('All Vehicles')),
                ...vehicles.map((VehicleEntity v) => DropdownMenuItem<String>(
                      value: v.id,
                      child: Text(v.licensePlate),
                    )),
              ],
              onChanged: (id) => notifier.setVehicleId(id),
            ),
          ),

          // Driver dropdown filter
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              hint: const Text('Filter Driver'),
              value: filters.driverId,
              items: [
                const DropdownMenuItem<String>(
                    value: null, child: Text('All Drivers')),
                ...drivers.map((DriverEntity d) => DropdownMenuItem<String>(
                      value: d.id,
                      child: Text(d.fullName),
                    )),
              ],
              onChanged: (id) => notifier.setDriverId(id),
            ),
          ),

          // Customer dropdown filter
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              hint: const Text('Filter Customer'),
              value: filters.customerId,
              items: [
                const DropdownMenuItem<String>(
                    value: null, child: Text('All Customers')),
                ...customers.map((CustomerEntity c) => DropdownMenuItem<String>(
                      value: c.id,
                      child: Text(c.name),
                    )),
              ],
              onChanged: (id) => notifier.setCustomerId(id),
            ),
          ),

          // Reset button
          if (filters.dateRange != null ||
              filters.vehicleId != null ||
              filters.driverId != null ||
              filters.customerId != null)
            TextButton.icon(
              icon: const Icon(Icons.clear_all),
              label: const Text('Clear Filters'),
              onPressed: () => notifier.reset(),
            ),
        ],
      ),
    );
  }

  // --- KPI CARD ROW ---
  Widget _buildKpiGrid(BuildContext context, Map<String, dynamic> kpis) {
    if (kpis.isEmpty) return const SizedBox();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 240,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        mainAxisExtent: 96,
      ),
      itemCount: kpis.length,
      itemBuilder: (context, index) {
        final key = kpis.keys.elementAt(index);
        final val = kpis[key];
        return Card(
          elevation: 0,
          color:
              Theme.of(context).colorScheme.primaryContainer.withOpacity(0.15),
          shape: RoundedRectangleBorder(
            side: BorderSide(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  key,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurfaceVariant
                            .withOpacity(0.8),
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  val.toString(),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- CHART ROUTING SELECTOR ---
  Widget _buildChart(
      String type, List<ChartDataPoint> chartData, ThemeData theme) {
    if (chartData.isEmpty) {
      return const Center(
          child: Text('No visual data points available for this selection.'));
    }

    // Pie chart suited reports
    if (type == 'fleet_availability' || type == 'fleet_maintenance_cost') {
      return CustomPieChart(data: chartData);
    }

    // Bar chart suited reports
    if (type == 'fleet_vehicle_utilization' ||
        type == 'fleet_driver_utilization' ||
        type == 'fleet_driver_performance' ||
        type == 'customer_contract_summary') {
      return CustomBarChart(data: chartData);
    }

    // Area/Line chart suited reports (financial summaries)
    return CustomLineChart(
      data: chartData,
      fillArea: type == 'financial_revenue' ||
          type == 'financial_profit_loss' ||
          type == 'financial_cash_flow',
    );
  }

  // --- DATA GRID TABLE ---
  Widget _buildDataTable(List<Map<String, dynamic>> rows, ThemeData theme) {
    if (rows.isEmpty) {
      return const Center(
          child: Text('No tabular data records matching the filters.'));
    }

    final headers = rows.first.keys.toList();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: DataTable(
          headingRowColor: MaterialStateProperty.all(
              theme.colorScheme.surfaceVariant.withOpacity(0.5)),
          columns: headers
              .map((h) => DataColumn(
                    label: Text(
                      h,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ))
              .toList(),
          rows: rows
              .map((row) => DataRow(
                    cells: headers
                        .map((header) => DataCell(
                              Text(row[header]?.toString() ?? ''),
                            ))
                        .toList(),
                  ))
              .toList(),
        ),
      ),
    );
  }

  // --- SAVED REPORTS ARCHIVE TAB ---
  Widget _buildSavedReportsTab(
    List<ReportEntity> list,
    WidgetRef ref,
    BuildContext context,
    ThemeData theme,
  ) {
    if (list.isEmpty) {
      return const Center(
          child:
              Text('No saved reports archived. Create one from the sidebar.'));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      separatorBuilder: (_, __) => const Divider(),
      itemBuilder: (ctx, idx) {
        final r = list[idx];
        return ListTile(
          leading: const Icon(Icons.article_outlined),
          title: Text(r.title),
          subtitle: Text(
            'Type: ${r.type.replaceAll('_', ' ').toUpperCase()} | By: ${r.generatedBy} | ${DateFormat('yMMMd').format(r.generatedAt)}',
          ),
          trailing: IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: () async {
              final user = ref.read(currentUserProvider);
              if (user?.companyId != null) {
                await ref
                    .read(reportRepositoryProvider)
                    .deleteReport(user!.companyId!, r.id);
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Report deleted successfully.')),
                );
              }
            },
          ),
          onTap: () {
            // Load filters and values back in
            ref.read(selectedReportTypeProvider.notifier).state = r.type;

            // Re-apply filters
            final filterNotifier = ref.read(reportFiltersProvider.notifier);
            filterNotifier.reset();
            if (r.filters['vehicleId'] != null)
              filterNotifier.setVehicleId(r.filters['vehicleId'] as String?);
            if (r.filters['driverId'] != null)
              filterNotifier.setDriverId(r.filters['driverId'] as String?);
            if (r.filters['customerId'] != null)
              filterNotifier.setCustomerId(r.filters['customerId'] as String?);

            _tabController.animateTo(0); // Go to Visual analytics
          },
        );
      },
    );
  }

  // --- SETTINGS SIDEBAR ---
  Widget _buildSettingsSidebar(
    BuildContext context,
    WidgetRef ref,
    String selectedType,
    String timeframe,
    AsyncValue<ReportData> reportDataAsync,
    ReportFilters filters,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final reportSaveState = ref.watch(reportSaveControllerProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'REPORT SETTINGS',
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),

          // 1. Report Selector
          Text('Report Category', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            isExpanded: true,
            value: selectedType,
            decoration: const InputDecoration(border: OutlineInputBorder()),
            items: const [
              DropdownMenuItem(
                  value: 'financial_revenue', child: Text('Revenue report')),
              DropdownMenuItem(
                  value: 'financial_expense', child: Text('Expense report')),
              DropdownMenuItem(
                  value: 'financial_profit_loss',
                  child: Text('Profit & Loss statement')),
              DropdownMenuItem(
                  value: 'financial_cash_flow',
                  child: Text('Cash Flow statement')),
              DropdownMenuItem(
                  value: 'financial_outstanding_receivables',
                  child: Text('Outstanding Aging')),
              DropdownMenuItem(
                  value: 'financial_customer_ledger',
                  child: Text('Customer General Ledger')),
              DropdownMenuItem(
                  value: 'financial_driver_expense',
                  child: Text('Driver Payroll expenses')),
              DropdownMenuItem(
                  value: 'financial_vehicle_expense',
                  child: Text('Vehicle Expense Ledger')),
              DropdownMenuItem(
                  value: 'fleet_vehicle_utilization',
                  child: Text('Vehicle Utilization')),
              DropdownMenuItem(
                  value: 'fleet_trip_summary',
                  child: Text('Trip logistics summary')),
              DropdownMenuItem(
                  value: 'fleet_availability',
                  child: Text('Availability matrix')),
              DropdownMenuItem(
                  value: 'fleet_driver_utilization',
                  child: Text('Driver shift allocation')),
              DropdownMenuItem(
                  value: 'fleet_driver_performance',
                  child: Text('Driver safety index')),
              DropdownMenuItem(
                  value: 'fleet_fuel_consumption',
                  child: Text('Fuel efficiency spend')),
              DropdownMenuItem(
                  value: 'fleet_maintenance_cost',
                  child: Text('Maintenance Cost ledger')),
              DropdownMenuItem(
                  value: 'fleet_inventory_usage',
                  child: Text('Spare Parts consumption')),
              DropdownMenuItem(
                  value: 'customer_revenue',
                  child: Text('Customer Billing summaries')),
              DropdownMenuItem(
                  value: 'customer_outstanding',
                  child: Text('Customer Debt exposure')),
              DropdownMenuItem(
                  value: 'customer_payment_history',
                  child: Text('Customer settlement checks')),
              DropdownMenuItem(
                  value: 'customer_contract_summary',
                  child: Text('Active Contract reviews')),
            ],
            onChanged: (val) {
              if (val != null) {
                ref.read(selectedReportTypeProvider.notifier).state = val;
              }
            },
          ),
          const SizedBox(height: 20),

          // 2. Timeframe Selector
          Text('Aggregation Timeframe', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            isExpanded: true,
            value: timeframe,
            decoration: const InputDecoration(border: OutlineInputBorder()),
            items: const [
              DropdownMenuItem(value: 'daily', child: Text('Daily Partition')),
              DropdownMenuItem(
                  value: 'weekly', child: Text('Weekly Partition')),
              DropdownMenuItem(
                  value: 'monthly', child: Text('Monthly Partition')),
              DropdownMenuItem(
                  value: 'quarterly', child: Text('Quarterly Partition')),
              DropdownMenuItem(
                  value: 'yearly', child: Text('Yearly Partition')),
            ],
            onChanged: (val) {
              if (val != null) {
                ref.read(reportTimeframeProvider.notifier).state = val;
              }
            },
          ),
          const Divider(height: 40),

          // 3. Export Operations
          Text('EXPORT REPORT', style: theme.textTheme.titleSmall),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 44),
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
            ),
            icon: const Icon(Icons.picture_as_pdf_outlined),
            label: const Text('Export to PDF'),
            onPressed: () {
              final data = reportDataAsync.valueOrNull;
              if (data != null) {
                ReportExportHelper.exportReport(
                  ref: ref,
                  context: context,
                  title: _getReportName(selectedType),
                  type: selectedType,
                  format: 'pdf',
                  rows: data.rows,
                );
              }
            },
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 44)),
            icon: const Icon(Icons.table_rows_outlined),
            label: const Text('Export to CSV'),
            onPressed: () {
              final data = reportDataAsync.valueOrNull;
              if (data != null) {
                ReportExportHelper.exportReport(
                  ref: ref,
                  context: context,
                  title: _getReportName(selectedType),
                  type: selectedType,
                  format: 'csv',
                  rows: data.rows,
                );
              }
            },
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 44)),
            icon: const Icon(Icons.grid_on_outlined),
            label: const Text('Export to Excel'),
            onPressed: () {
              final data = reportDataAsync.valueOrNull;
              if (data != null) {
                ReportExportHelper.exportReport(
                  ref: ref,
                  context: context,
                  title: _getReportName(selectedType),
                  type: selectedType,
                  format: 'excel',
                  rows: data.rows,
                );
              }
            },
          ),
          const Divider(height: 40),

          // 4. Save Report Instance
          Text('SAVE REPORT INSTANCE', style: theme.textTheme.titleSmall),
          const SizedBox(height: 12),
          TextField(
            controller: _saveTitleController,
            decoration: const InputDecoration(
              labelText: 'Saved report name',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 44)),
            onPressed: reportSaveState.isLoading
                ? null
                : () async {
                    final title = _saveTitleController.text.trim();
                    if (title.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text(
                                'Please enter a name for the saved report.')),
                      );
                      return;
                    }
                    final data = reportDataAsync.valueOrNull;
                    if (data != null) {
                      await ref
                          .read(reportSaveControllerProvider.notifier)
                          .saveReport(title, selectedType, data, filters);

                      if (!context.mounted) return;
                      _saveTitleController.clear();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content:
                                Text('Successfully archived this report!')),
                      );
                    }
                  },
            child: reportSaveState.isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Save Report Parameters'),
          ),
        ],
      ),
    );
  }
}
