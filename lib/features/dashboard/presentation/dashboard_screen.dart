import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:collection/collection.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../company_setup/presentation/company_providers.dart';
import '../../company_setup/domain/company_entity.dart';
import 'dashboard_providers.dart';
import '../../reports/presentation/widgets/chart_widgets.dart';
import '../../reports/presentation/report_providers.dart';
import '../../trips/presentation/trip_providers.dart';
import '../../vehicles/presentation/vehicle_providers.dart';
import '../../notifications/presentation/notifications_providers.dart';
import '../../notifications/domain/notification_entity.dart';
import '../../hr/presentation/hr_providers.dart';

/// State notifier for global app theme configuration overrides.
class ThemeController extends StateNotifier<ThemeMode> {
  ThemeController() : super(ThemeMode.system);

  void toggleTheme() {
    state = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
  }
}

/// Global provider for managing Light/Dark theme configuration overrides.
final themeModeProvider = StateNotifierProvider<ThemeController, ThemeMode>((
  ref,
) {
  return ThemeController();
});

/// Enterprise Command Center Dashboard featuring responsive panel shells and layouts.
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  CompanyEntity? _company;
  bool _loadingCompany = true;

  @override
  void initState() {
    super.initState();
    _fetchCompanyDetails();
  }

  Future<void> _fetchCompanyDetails() async {
    final user = ref.read(currentUserProvider);
    if (user?.companyId != null) {
      final repo = ref.read(companyRepositoryProvider);
      final company = await repo.getCompany(user!.companyId!);
      if (mounted) {
        setState(() {
          _company = company;
          _loadingCompany = false;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _loadingCompany = false;
        });
      }
    }
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Session Teardown'),
        content: const Text(
          'Are you sure you want to log out? This will terminate your secure session key.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await ref.read(authControllerProvider.notifier).signOut();
      if (mounted) {
        context.go('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final currentUser = ref.watch(currentUserProvider);
    final themeMode = ref.watch(themeModeProvider);

    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isDesktop = screenWidth > 992;

    final notificationsAsync = ref.watch(notificationsStreamProvider);
    final unreadCount =
        notificationsAsync.valueOrNull?.where((n) => !n.isRead).length ?? 0;

    // Loading details
    final companyName = _loadingCompany
        ? 'Loading company...'
        : (_company?.name ?? 'FleetOS Operator');

    final employees = ref.watch(employeesStreamProvider).valueOrNull ?? [];
    final leaves = ref.watch(leavesStreamProvider).valueOrNull ?? [];
    final todayAttendance =
        ref.watch(attendanceStreamProvider(DateTime.now())).valueOrNull ?? [];

    final totalEmployees = employees.length;
    final activeEmployees = employees.where((e) => e.status == 'active').length;
    final leavesToday = leaves.where((l) {
      final now = DateTime.now();
      return l.status == 'approved' &&
          (l.startDate.isBefore(now) || l.startDate.isAtSameMomentAs(now)) &&
          (l.endDate.isAfter(now) || l.endDate.isAtSameMomentAs(now));
    }).length;

    final todayPresent = todayAttendance
        .where((a) => a.status == 'present' || a.status == 'late')
        .length;
    final attendanceRate =
        totalEmployees > 0 ? (todayPresent / totalEmployees) * 100 : 100.0;

    final statsAsync = ref.watch(dashboardStatsProvider);
    final stats = statsAsync.when(
      data: (data) => [
        _StatCardData(
          title: 'Total Employees',
          value: totalEmployees.toString(),
          subtitle: 'Active roster count',
          icon: Icons.people_outline,
          trend: '$activeEmployees Active',
          isPositive: true,
        ),
        _StatCardData(
          title: 'HR Leaves Today',
          value: leavesToday.toString(),
          subtitle: 'Approved absences',
          icon: Icons.time_to_leave_outlined,
          trend: 'Scheduled leaves',
          isPositive: true,
        ),
        _StatCardData(
          title: 'Today Attendance Rate',
          value: '${attendanceRate.toStringAsFixed(0)}%',
          subtitle: 'Check-in completion',
          icon: Icons.done_all_outlined,
          trend: '$todayPresent Present today',
          isPositive: attendanceRate >= 80.0,
        ),
        _StatCardData(
          title: 'Active Fleet Count',
          value: data.activeFleetCount.toString(),
          subtitle: 'Vehicles online',
          icon: Icons.local_shipping_outlined,
          trend: 'Live monitoring',
          isPositive: true,
        ),
        _StatCardData(
          title: 'Trips Scheduled',
          value: data.tripsScheduled.toString(),
          subtitle: 'Dispatched today',
          icon: Icons.route_outlined,
          trend: 'Active routing',
          isPositive: true,
        ),
        _StatCardData(
          title: 'Critical Diagnostics',
          value: data.criticalDiagnosticsCount.toString().padLeft(2, '0'),
          subtitle: 'Compliance warnings',
          icon: Icons.warning_amber_rounded,
          trend: data.criticalDiagnosticsCount > 0
              ? 'Action needed'
              : 'All compliant',
          isPositive: data.criticalDiagnosticsCount == 0,
        ),
        _StatCardData(
          title: 'Active Cargo Volume',
          value: '${data.averagePayloadCapacity.toStringAsFixed(0)}%',
          subtitle: 'Average payload capacity',
          icon: Icons.inventory_2_outlined,
          trend: 'Capacity load',
          isPositive: true,
        ),
        _StatCardData(
          title: 'Available Drivers',
          value: '${data.availableDriversCount}/${data.totalDriversCount}',
          subtitle: 'Active roster ready',
          icon: Icons.people_outline_rounded,
          trend: 'Roster status',
          isPositive: true,
        ),
        _StatCardData(
          title: 'License Alerts',
          value: data.expiredLicenseDriversCount.toString().padLeft(2, '0'),
          subtitle: 'Expired licenses',
          icon: Icons.badge_outlined,
          trend: data.expiredLicenseDriversCount > 0
              ? 'Action needed'
              : 'All compliant',
          isPositive: data.expiredLicenseDriversCount == 0,
        ),
        _StatCardData(
          title: 'Active Customers',
          value: data.totalCustomersCount.toString(),
          subtitle: 'Corporate accounts',
          icon: Icons.people_rounded,
          trend: 'Billed partners',
          isPositive: true,
        ),
        _StatCardData(
          title: 'Partner Vendors',
          value: data.totalVendorsCount.toString(),
          subtitle: 'Active contractors',
          icon: Icons.business_rounded,
          trend: 'Service directory',
          isPositive: true,
        ),
        _StatCardData(
          title: 'Spare Parts Stock',
          value: data.totalPartsCount.toString(),
          subtitle: 'Different parts listed',
          icon: Icons.build_outlined,
          trend: 'Asset items',
          isPositive: true,
        ),
        _StatCardData(
          title: 'Low Stock Warnings',
          value: data.lowStockPartsCount.toString().padLeft(2, '0'),
          subtitle: 'Requires reorder',
          icon: Icons.production_quantity_limits_rounded,
          trend: data.lowStockPartsCount > 0 ? 'Reorder needed' : 'All stocked',
          isPositive: data.lowStockPartsCount == 0,
        ),
        _StatCardData(
          title: 'Inventory Total Value',
          value: '\$${data.totalStockValue.toStringAsFixed(0)}',
          subtitle: 'Parts stock value',
          icon: Icons.attach_money_rounded,
          trend: 'Asset valuation',
          isPositive: true,
        ),
        _StatCardData(
          title: 'Active Contracts',
          value: data.activeContractsCount.toString(),
          subtitle: 'Service agreements',
          icon: Icons.assignment_rounded,
          trend: 'Pricing active',
          isPositive: true,
        ),
        _StatCardData(
          title: 'Outstanding Invoices',
          value: '\$${data.outstandingInvoicesAmount.toStringAsFixed(0)}',
          subtitle: 'Receivables amount',
          icon: Icons.receipt_rounded,
          trend: 'Total outstanding',
          isPositive: true,
        ),
        _StatCardData(
          title: 'Total Revenue',
          value: '\$${data.totalRevenue.toStringAsFixed(0)}',
          subtitle: 'Gross revenue ever',
          icon: Icons.monetization_on_outlined,
          trend: 'Accumulated',
          isPositive: true,
        ),
        _StatCardData(
          title: 'Revenue Today',
          value: '\$${data.revenueToday.toStringAsFixed(0)}',
          subtitle: 'Issued/paid today',
          icon: Icons.today_outlined,
          trend: 'Daily earnings',
          isPositive: true,
        ),
        _StatCardData(
          title: 'Revenue This Month',
          value: '\$${data.revenueThisMonth.toStringAsFixed(0)}',
          subtitle: 'Issued/paid month',
          icon: Icons.calendar_month_outlined,
          trend: 'Monthly earnings',
          isPositive: true,
        ),
        _StatCardData(
          title: 'Outstanding Amount',
          value: '\$${data.outstandingAmount.toStringAsFixed(0)}',
          subtitle: 'Accounts receivable',
          icon: Icons.pending_actions_outlined,
          trend: 'Unpaid balance',
          isPositive: false,
        ),
        _StatCardData(
          title: 'Overdue Invoices',
          value: data.overdueInvoicesCount.toString(),
          subtitle: 'Overdue items',
          icon: Icons.gpp_maybe_outlined,
          trend:
              data.overdueInvoicesCount > 0 ? 'Urgent attention' : 'No overdue',
          isPositive: data.overdueInvoicesCount == 0,
        ),
        _StatCardData(
          title: 'Paid Invoices',
          value: data.paidInvoicesCount.toString(),
          subtitle: 'Settled invoices',
          icon: Icons.task_alt_outlined,
          trend: 'Completed bills',
          isPositive: true,
        ),
        _StatCardData(
          title: 'Collection Rate',
          value: '${data.collectionRate.toStringAsFixed(1)}%',
          subtitle: 'Payment efficiency',
          icon: Icons.percent_outlined,
          trend: 'Invoiced vs Collected',
          isPositive: data.collectionRate > 85.0,
        ),
      ],
      loading: () => [
        _StatCardData(
            title: 'Active Fleet Count',
            value: '...',
            subtitle: 'Loading...',
            icon: Icons.local_shipping_outlined,
            trend: '...',
            isPositive: true),
        _StatCardData(
            title: 'Trips Scheduled',
            value: '...',
            subtitle: 'Loading...',
            icon: Icons.route_outlined,
            trend: '...',
            isPositive: true),
        _StatCardData(
            title: 'Critical Diagnostics',
            value: '...',
            subtitle: 'Loading...',
            icon: Icons.warning_amber_rounded,
            trend: '...',
            isPositive: false),
        _StatCardData(
            title: 'Active Cargo Volume',
            value: '...',
            subtitle: 'Loading...',
            icon: Icons.inventory_2_outlined,
            trend: '...',
            isPositive: true),
        _StatCardData(
            title: 'Available Drivers',
            value: '...',
            subtitle: 'Loading...',
            icon: Icons.people_outline_rounded,
            trend: '...',
            isPositive: true),
        _StatCardData(
            title: 'License Alerts',
            value: '...',
            subtitle: 'Loading...',
            icon: Icons.badge_outlined,
            trend: '...',
            isPositive: true),
        _StatCardData(
            title: 'Active Customers',
            value: '...',
            subtitle: 'Loading...',
            icon: Icons.people_rounded,
            trend: '...',
            isPositive: true),
        _StatCardData(
            title: 'Partner Vendors',
            value: '...',
            subtitle: 'Loading...',
            icon: Icons.business_rounded,
            trend: '...',
            isPositive: true),
        _StatCardData(
            title: 'Spare Parts Stock',
            value: '...',
            subtitle: 'Loading...',
            icon: Icons.build_outlined,
            trend: '...',
            isPositive: true),
        _StatCardData(
            title: 'Low Stock Warnings',
            value: '...',
            subtitle: 'Loading...',
            icon: Icons.production_quantity_limits_rounded,
            trend: '...',
            isPositive: true),
        _StatCardData(
            title: 'Inventory Total Value',
            value: '...',
            subtitle: 'Loading...',
            icon: Icons.attach_money_rounded,
            trend: '...',
            isPositive: true),
        _StatCardData(
            title: 'Active Contracts',
            value: '...',
            subtitle: 'Loading...',
            icon: Icons.assignment_rounded,
            trend: '...',
            isPositive: true),
        _StatCardData(
            title: 'Outstanding Invoices',
            value: '...',
            subtitle: 'Loading...',
            icon: Icons.receipt_rounded,
            trend: '...',
            isPositive: true),
      ],
      error: (e, _) => [
        _StatCardData(
            title: 'Active Fleet Count',
            value: 'ERR',
            subtitle: 'Error loading',
            icon: Icons.local_shipping_outlined,
            trend: '...',
            isPositive: false),
        _StatCardData(
            title: 'Trips Scheduled',
            value: 'ERR',
            subtitle: 'Error loading',
            icon: Icons.route_outlined,
            trend: '...',
            isPositive: false),
        _StatCardData(
            title: 'Critical Diagnostics',
            value: 'ERR',
            subtitle: 'Error loading',
            icon: Icons.warning_amber_rounded,
            trend: '...',
            isPositive: false),
        _StatCardData(
            title: 'Active Cargo Volume',
            value: 'ERR',
            subtitle: 'Error loading',
            icon: Icons.inventory_2_outlined,
            trend: '...',
            isPositive: false),
        _StatCardData(
            title: 'Available Drivers',
            value: 'ERR',
            subtitle: 'Error loading',
            icon: Icons.people_outline_rounded,
            trend: '...',
            isPositive: false),
        _StatCardData(
            title: 'License Alerts',
            value: 'ERR',
            subtitle: 'Error loading',
            icon: Icons.badge_outlined,
            trend: '...',
            isPositive: false),
        _StatCardData(
            title: 'Active Customers',
            value: 'ERR',
            subtitle: 'Error loading',
            icon: Icons.people_rounded,
            trend: '...',
            isPositive: false),
        _StatCardData(
            title: 'Partner Vendors',
            value: 'ERR',
            subtitle: 'Error loading',
            icon: Icons.business_rounded,
            trend: '...',
            isPositive: false),
        _StatCardData(
            title: 'Spare Parts Stock',
            value: 'ERR',
            subtitle: 'Error loading',
            icon: Icons.build_outlined,
            trend: '...',
            isPositive: false),
        _StatCardData(
            title: 'Low Stock Warnings',
            value: 'ERR',
            subtitle: 'Error loading',
            icon: Icons.production_quantity_limits_rounded,
            trend: '...',
            isPositive: false),
        _StatCardData(
            title: 'Inventory Total Value',
            value: 'ERR',
            subtitle: 'Error loading',
            icon: Icons.attach_money_rounded,
            trend: '...',
            isPositive: false),
        _StatCardData(
            title: 'Active Contracts',
            value: 'ERR',
            subtitle: 'Error loading',
            icon: Icons.assignment_rounded,
            trend: '...',
            isPositive: false),
        _StatCardData(
            title: 'Outstanding Invoices',
            value: 'ERR',
            subtitle: 'Error loading',
            icon: Icons.receipt_rounded,
            trend: '...',
            isPositive: false),
      ],
    );

    final Widget dashboardBody = SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Greeting & Header row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome back, ${currentUser?.displayName ?? "Operator"}',
                    style: theme.textTheme.displayLarge?.copyWith(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Enterprise Tenant: $companyName',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onBackground.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: Icon(
                  themeMode == ThemeMode.dark
                      ? Icons.light_mode
                      : Icons.dark_mode,
                ),
                tooltip: 'Toggle Theme',
                onPressed: () {
                  ref.read(themeModeProvider.notifier).toggleTheme();
                },
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Overview Stats Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: stats.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: isDesktop ? 4 : (screenWidth > 600 ? 2 : 1),
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.6,
            ),
            itemBuilder: (context, index) {
              final stat = stats[index];
              return _StatCard(data: stat);
            },
          ),
          const SizedBox(height: 32),

          // Main Layout Content Section
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    // System Performance Chart card representation
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Fleet Utilization Analytics',
                                  style: theme.textTheme.titleLarge,
                                ),
                                DropdownButton<String>(
                                  value: 'This Week',
                                  underline: const SizedBox(),
                                  items: const [
                                    DropdownMenuItem(
                                      value: 'This Week',
                                      child: Text('This Week'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'Last Month',
                                      child: Text('Last Month'),
                                    ),
                                  ],
                                  onChanged: (_) {},
                                ),
                              ],
                            ),
                            const SizedBox(height: 32),
                            // Real live CustomBarChart from active streams
                            ref.watch(tripsStreamProvider).when(
                                  data: (trips) {
                                    final vehicles = ref
                                            .watch(vehiclesStreamProvider)
                                            .valueOrNull ??
                                        [];
                                    final grouped = <String, int>{};
                                    for (final t in trips) {
                                      final v = vehicles.firstWhereOrNull(
                                          (veh) => veh.id == t.vehicleId);
                                      final label = v != null
                                          ? v.licensePlate
                                          : t.vehicleId;
                                      grouped[label] =
                                          (grouped[label] ?? 0) + 1;
                                    }
                                    final chartData = grouped.entries
                                        .map((e) => ChartDataPoint(
                                            label: e.key,
                                            value: e.value.toDouble()))
                                        .toList();
                                    if (chartData.isEmpty) {
                                      return Container(
                                        height: 240,
                                        decoration: BoxDecoration(
                                          color: colorScheme.primary
                                              .withOpacity(0.04),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          border: Border.all(
                                              color: colorScheme.primary
                                                  .withOpacity(0.08)),
                                        ),
                                        child: const Center(
                                            child: Text(
                                                'No active trip logs to plot')),
                                      );
                                    }
                                    return SizedBox(
                                      height: 240,
                                      child: CustomBarChart(
                                          data: chartData.take(6).toList()),
                                    );
                                  },
                                  loading: () => const SizedBox(
                                    height: 240,
                                    child: Center(
                                        child: CircularProgressIndicator()),
                                  ),
                                  error: (_, __) => const SizedBox(
                                    height: 240,
                                    child: Center(
                                        child: Text('Error loading analytics')),
                                  ),
                                ),
                          ],
                        ),
                      ),
                    ),
                    if (!isDesktop) ...[
                      const SizedBox(height: 16),
                      const _DashboardAlertsWidget(),
                    ],
                  ],
                ),
              ),
              if (isDesktop) ...[
                const SizedBox(width: 16),
                const Expanded(
                  flex: 1,
                  child: _DashboardAlertsWidget(),
                ),
              ],
            ],
          ),
        ],
      ),
    );

    // Sidebar navigation content for desktop
    final Widget sidebar = Container(
      width: 260,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          right: BorderSide(color: theme.dividerColor.withOpacity(0.08)),
        ),
      ),
      child: Column(
        children: [
          // Sidebar header (Brand logo)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.local_shipping_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'FleetOS ERP',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Navigation items list
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 16),
              children: [
                _SidebarNavItem(
                  icon: Icons.dashboard_rounded,
                  label: 'Control Center',
                  isSelected: true,
                  onTap: () {},
                ),
                _SidebarNavItem(
                  icon: Icons.local_shipping_outlined,
                  label: 'Fleet Management',
                  onTap: () => context.push('/vehicles'),
                ),
                _SidebarNavItem(
                  icon: Icons.route_outlined,
                  label: 'Trip Management',
                  onTap: () => context.push('/trips'),
                ),
                _SidebarNavItem(
                  icon: Icons.people_outline_rounded,
                  label: 'Driver Portal',
                  onTap: () => context.push('/drivers'),
                ),
                _SidebarNavItem(
                  icon: Icons.inventory_2_outlined,
                  label: 'Storage & Hubs',
                  onTap: () => context.push('/inventory'),
                ),
                _SidebarNavItem(
                  icon: Icons.business_outlined,
                  label: 'Inventory Suppliers',
                  onTap: () => context.push('/inventory/suppliers'),
                ),
                _SidebarNavItem(
                  icon: Icons.receipt_long_outlined,
                  label: 'Inventory Transactions',
                  onTap: () => context.push('/inventory/transactions'),
                ),
                _SidebarNavItem(
                  icon: Icons.account_balance_outlined,
                  label: 'Finance & Ledger',
                  onTap: () => context.push('/finance'),
                ),
                _SidebarNavItem(
                  icon: Icons.people_rounded,
                  label: 'Customer Accounts',
                  onTap: () => context.push('/customers'),
                ),
                _SidebarNavItem(
                  icon: Icons.assignment_rounded,
                  label: 'Freight Contracts',
                  onTap: () => context.push('/contracts'),
                ),
                _SidebarNavItem(
                  icon: Icons.receipt_rounded,
                  label: 'Customer Invoices',
                  onTap: () => context.push('/invoices'),
                ),
                _SidebarNavItem(
                  icon: Icons.schedule_rounded,
                  label: 'Dispatches & Scheduling',
                  onTap: () => context.push('/dispatches'),
                ),
                _SidebarNavItem(
                  icon: Icons.route_rounded,
                  label: 'Routes Catalog',
                  onTap: () => context.push('/routes'),
                ),
                _SidebarNavItem(
                  icon: Icons.business_rounded,
                  label: 'Vendor Directory',
                  onTap: () => context.push('/vendors'),
                ),
                _SidebarNavItem(
                  icon: Icons.local_gas_station_rounded,
                  label: 'Fuel Registry',
                  onTap: () => context.push('/fuel'),
                ),
                _SidebarNavItem(
                  icon: Icons.build_rounded,
                  label: 'Maintenance Logs',
                  onTap: () => context.push('/maintenance'),
                ),
                _SidebarNavItem(
                  icon: Icons.verified_user_rounded,
                  label: 'Compliance Docs',
                  onTap: () => context.push('/compliance'),
                ),
                _SidebarNavItem(
                  icon: Icons.notifications_rounded,
                  label: 'Notifications',
                  onTap: () => context.push('/notifications'),
                  badge: unreadCount > 0 ? '$unreadCount' : null,
                ),
                _SidebarNavItem(
                  icon: Icons.people_outline_rounded,
                  label: 'HR & Employees',
                  onTap: () => context.push('/hr/employees'),
                ),
                _SidebarNavItem(
                  icon: Icons.settings_outlined,
                  label: 'ERP Settings',
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // User profile drawer link at bottom of sidebar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: colorScheme.primary.withOpacity(0.12),
                  child: Text(
                    (currentUser?.displayName ?? 'O')
                        .substring(0, 1)
                        .toUpperCase(),
                    style: TextStyle(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currentUser?.displayName ?? 'Operator',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        currentUser?.role.toUpperCase() ?? 'ADMIN',
                        maxLines: 1,
                        style: TextStyle(
                          color: colorScheme.onBackground.withOpacity(0.4),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.logout_rounded, size: 20),
                  onPressed: _handleLogout,
                  tooltip: 'Secure Sign Out',
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return Scaffold(
      appBar: !isDesktop
          ? AppBar(
              title: Text(companyName),
              actions: [
                IconButton(
                  icon: Icon(
                    themeMode == ThemeMode.dark
                        ? Icons.light_mode
                        : Icons.dark_mode,
                  ),
                  onPressed: () {
                    ref.read(themeModeProvider.notifier).toggleTheme();
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.logout_rounded),
                  onPressed: _handleLogout,
                ),
              ],
            )
          : null,
      drawer: !isDesktop
          ? Drawer(
              child: Column(
                children: [
                  UserAccountsDrawerHeader(
                    accountName: Text(currentUser?.displayName ?? 'Operator'),
                    accountEmail: Text(currentUser?.email ?? ''),
                    currentAccountPicture: CircleAvatar(
                      backgroundColor: Colors.white,
                      child: Text(
                        (currentUser?.displayName ?? 'O')
                            .substring(0, 1)
                            .toUpperCase(),
                        style: TextStyle(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 24,
                        ),
                      ),
                    ),
                    decoration: BoxDecoration(color: colorScheme.primary),
                  ),
                  ListTile(
                    leading: const Icon(Icons.dashboard_rounded),
                    title: const Text('Control Center'),
                    selected: true,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                  ListTile(
                    leading: const Icon(Icons.local_shipping_outlined),
                    title: const Text('Fleet Management'),
                    onTap: () {
                      Navigator.of(context).pop();
                      context.push('/vehicles');
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.route_outlined),
                    title: const Text('Trip Management'),
                    onTap: () {
                      Navigator.of(context).pop();
                      context.push('/trips');
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.account_balance_outlined),
                    title: const Text('Finance & Ledger'),
                    onTap: () {
                      Navigator.of(context).pop();
                      context.push('/finance');
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.analytics_rounded),
                    title: const Text('Reports & BI'),
                    onTap: () {
                      Navigator.of(context).pop();
                      context.push('/reports');
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.people_outline_rounded),
                    title: const Text('Driver Portal'),
                    onTap: () {
                      Navigator.of(context).pop();
                      context.push('/drivers');
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.people_rounded),
                    title: const Text('Customer Accounts'),
                    onTap: () {
                      Navigator.of(context).pop();
                      context.push('/customers');
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.assignment_rounded),
                    title: const Text('Freight Contracts'),
                    onTap: () {
                      Navigator.of(context).pop();
                      context.push('/contracts');
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.receipt_rounded),
                    title: const Text('Customer Invoices'),
                    onTap: () {
                      Navigator.of(context).pop();
                      context.push('/invoices');
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.schedule_rounded),
                    title: const Text('Dispatches & Scheduling'),
                    onTap: () {
                      Navigator.of(context).pop();
                      context.push('/dispatches');
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.route_rounded),
                    title: const Text('Routes Catalog'),
                    onTap: () {
                      Navigator.of(context).pop();
                      context.push('/routes');
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.business_rounded),
                    title: const Text('Vendor Directory'),
                    onTap: () {
                      Navigator.of(context).pop();
                      context.push('/vendors');
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.local_gas_station_rounded),
                    title: const Text('Fuel Registry'),
                    onTap: () {
                      Navigator.of(context).pop();
                      context.push('/fuel');
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.build_rounded),
                    title: const Text('Maintenance Logs'),
                    onTap: () {
                      Navigator.of(context).pop();
                      context.push('/maintenance');
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.verified_user_rounded),
                    title: const Text('Compliance Docs'),
                    onTap: () {
                      Navigator.of(context).pop();
                      context.push('/compliance');
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.folder_shared_rounded),
                    title: const Text('Document Vault'),
                    onTap: () {
                      Navigator.of(context).pop();
                      context.push('/documents');
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.inventory_2_outlined),
                    title: const Text('Storage & Hubs'),
                    onTap: () {
                      Navigator.of(context).pop();
                      context.push('/inventory');
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.business_outlined),
                    title: const Text('Inventory Suppliers'),
                    onTap: () {
                      Navigator.of(context).pop();
                      context.push('/inventory/suppliers');
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.receipt_long_outlined),
                    title: const Text('Inventory Transactions'),
                    onTap: () {
                      Navigator.of(context).pop();
                      context.push('/inventory/transactions');
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.notifications_rounded),
                    title: const Text('Notifications'),
                    trailing: unreadCount > 0
                        ? Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: colorScheme.error,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '$unreadCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        : null,
                    onTap: () {
                      Navigator.of(context).pop();
                      context.push('/notifications');
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.people_outline_rounded),
                    title: const Text('HR & Employees'),
                    onTap: () {
                      Navigator.of(context).pop();
                      context.push('/hr/employees');
                    },
                  ),
                  const ListTile(
                    leading: Icon(Icons.settings_outlined),
                    title: Text('Settings'),
                  ),
                ],
              ),
            )
          : null,
      body: Row(
        children: [
          if (isDesktop) sidebar,
          Expanded(child: dashboardBody),
        ],
      ),
    );
  }
}

class _StatCardData {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final String trend;
  final bool isPositive;

  const _StatCardData({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.trend,
    required this.isPositive,
  });
}

class _StatCard extends StatelessWidget {
  final _StatCardData data;

  const _StatCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  data.title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface.withOpacity(0.5),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Icon(data.icon, color: colorScheme.primary, size: 20),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.value,
                  style: theme.textTheme.displayLarge?.copyWith(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  data.subtitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 12,
                    color: colorScheme.onSurface.withOpacity(0.4),
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Icon(
                  data.isPositive ? Icons.trending_up : Icons.trending_down,
                  color: data.isPositive ? Colors.green : Colors.red,
                  size: 14,
                ),
                const SizedBox(width: 4),
                Text(
                  data.trend,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: data.isPositive ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SidebarNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback? onTap;
  final String? badge;

  const _SidebarNavItem({
    required this.icon,
    required this.label,
    this.isSelected = false,
    this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected
            ? colorScheme.primary.withOpacity(0.08)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        visualDensity: const VisualDensity(vertical: -2),
        leading: Icon(
          icon,
          color: isSelected
              ? colorScheme.primary
              : colorScheme.onSurface.withOpacity(0.6),
          size: 20,
        ),
        title: Text(
          label,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: isSelected ? colorScheme.primary : colorScheme.onSurface,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 14,
          ),
        ),
        trailing: badge != null
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: colorScheme.error,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  badge!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            : null,
        onTap: onTap,
      ),
    );
  }
}

class _DashboardAlertsWidget extends ConsumerStatefulWidget {
  const _DashboardAlertsWidget();

  @override
  ConsumerState<_DashboardAlertsWidget> createState() =>
      _DashboardAlertsWidgetState();
}

class _DashboardAlertsWidgetState extends ConsumerState<_DashboardAlertsWidget>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final notificationsAsync = ref.watch(notificationsStreamProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Operations Control Center',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.open_in_new_rounded, size: 20),
                  onPressed: () => context.push('/notifications'),
                  tooltip: 'Go to Notification Center',
                ),
              ],
            ),
            const SizedBox(height: 12),
            TabBar(
              controller: _tabController,
              labelColor: theme.colorScheme.primary,
              unselectedLabelColor: Colors.grey,
              isScrollable: true,
              tabs: const [
                Tab(text: 'Critical'),
                Tab(text: 'Today'),
                Tab(text: 'Expiries'),
                Tab(text: 'Pending'),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 350,
              child: notificationsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(child: Text('Error: $err')),
                data: (list) {
                  final now = DateTime.now();

                  // 1. Critical Alerts (critical & high priority)
                  final criticalAlerts = list
                      .where((n) =>
                          n.priority == 'critical' || n.priority == 'high')
                      .toList();

                  // 2. Notifications Today
                  final notificationsToday = list
                      .where((n) =>
                          n.createdAt.year == now.year &&
                          n.createdAt.month == now.month &&
                          n.createdAt.day == now.day)
                      .toList();

                  // 3. Upcoming Expiries
                  final upcomingExpiries = list
                      .where((n) =>
                          n.title.contains('Expiring Soon') ||
                          n.title.contains('Expired'))
                      .toList();

                  // 4. Pending Actions (Unread)
                  final pendingActions = list.where((n) => !n.isRead).toList();

                  Widget buildList(
                      List<NotificationEntity> items, String emptyMessage) {
                    if (items.isEmpty) {
                      return Center(
                        child: Text(
                          emptyMessage,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey.shade500),
                        ),
                      );
                    }
                    return ListView.builder(
                      itemCount: items.length,
                      itemBuilder: (context, idx) {
                        final item = items[idx];
                        Color iconColor = Colors.grey;
                        if (item.priority == 'critical')
                          iconColor = Colors.red;
                        else if (item.priority == 'high')
                          iconColor = Colors.orange;
                        else if (item.priority == 'medium')
                          iconColor = Colors.blue;

                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(
                            item.isRead
                                ? Icons.notifications_none_rounded
                                : Icons.notifications_active_rounded,
                            color: iconColor,
                          ),
                          title: Text(
                            item.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: item.isRead
                                  ? FontWeight.normal
                                  : FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            item.message,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12),
                          ),
                          trailing:
                              const Icon(Icons.chevron_right_rounded, size: 16),
                          onTap: () => context.push(
                              '/notifications/alert-details',
                              extra: item),
                        );
                      },
                    );
                  }

                  return TabBarView(
                    controller: _tabController,
                    children: [
                      buildList(criticalAlerts, 'No critical alerts active.'),
                      buildList(notificationsToday,
                          'No notifications generated today.'),
                      buildList(
                          upcomingExpiries, 'No upcoming expiries found.'),
                      buildList(
                          pendingActions, 'All caught up! No pending actions.'),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
