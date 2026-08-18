import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/auth_providers.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/company_setup/presentation/company_setup_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/splash/presentation/splash_screen.dart';
import '../../features/vehicles/presentation/vehicle_list_screen.dart';
import '../../features/vehicles/presentation/vehicle_detail_screen.dart';
import '../../features/vehicles/presentation/vehicle_form_screen.dart';
import '../../features/trips/presentation/trip_list_screen.dart';
import '../../features/trips/presentation/trip_detail_screen.dart';
import '../../features/trips/presentation/trip_form_screen.dart';
import '../../features/finance/presentation/finance_list_screen.dart';
import '../../features/finance/presentation/finance_form_screen.dart';
import '../../features/finance/presentation/profit_loss_screen.dart';
import '../../features/drivers/presentation/driver_list_screen.dart';
import '../../features/drivers/presentation/driver_detail_screen.dart';
import '../../features/drivers/presentation/driver_form_screen.dart';
import '../../features/customers/presentation/customer_list_screen.dart';
import '../../features/customers/presentation/customer_form_screen.dart';
import '../../features/vendors/presentation/vendor_list_screen.dart';
import '../../features/vendors/presentation/vendor_form_screen.dart';
import '../../features/fleet_ops/presentation/fuel_list_screen.dart';
import '../../features/fleet_ops/presentation/fuel_form_screen.dart';
import '../../features/fleet_ops/presentation/maintenance_list_screen.dart';
import '../../features/fleet_ops/presentation/maintenance_form_screen.dart';
import '../../features/fleet_ops/presentation/compliance_list_screen.dart';
import '../../features/fleet_ops/presentation/compliance_form_screen.dart';
import '../../features/inventory/presentation/part_list_screen.dart';
import '../../features/inventory/presentation/part_form_screen.dart';
import '../../features/inventory/presentation/supplier_list_screen.dart';
import '../../features/inventory/presentation/supplier_form_screen.dart';
import '../../features/inventory/presentation/transaction_list_screen.dart';
import '../../features/inventory/presentation/transaction_form_screen.dart';
import '../../features/customers/presentation/contract_list_screen.dart';
import '../../features/customers/presentation/contract_form_screen.dart';
import '../../features/customers/presentation/invoice_list_screen.dart';
import '../../features/billing/presentation/invoice_form_screen.dart';
import '../../features/billing/presentation/invoice_detail_screen.dart';
import '../../features/dispatch/presentation/dispatch_list_screen.dart';
import '../../features/dispatch/presentation/dispatch_form_screen.dart';
import '../../features/dispatch/presentation/dispatch_detail_screen.dart';
import '../../features/dispatch/presentation/route_list_screen.dart';
import '../../features/reports/presentation/report_screen.dart';
import '../../features/documents/presentation/document_list_screen.dart';
import '../../features/documents/presentation/document_form_screen.dart';
import '../../features/documents/presentation/document_detail_screen.dart';
import '../../features/notifications/domain/notification_entity.dart';
import '../../features/notifications/presentation/screens/notification_center_screen.dart';
import '../../features/notifications/presentation/screens/alert_details_screen.dart';
import '../../features/notifications/presentation/screens/notification_settings_screen.dart';
import '../../features/hr/presentation/screens/employee_list_screen.dart';
import '../../features/hr/presentation/screens/employee_form_screen.dart';
import '../../features/hr/presentation/screens/employee_profile_screen.dart';
import '../../features/hr/presentation/screens/attendance_screen.dart';
import '../../features/hr/presentation/screens/leave_screen.dart';
import '../../features/hr/presentation/screens/payroll_screen.dart';
import '../../features/hr/presentation/screens/hr_settings_screen.dart';

/// Stream-to-Listenable converter helper class for GoRouter reactive redirects.
class GoRouterRefreshStream extends ChangeNotifier {
  late final StreamSubscription<dynamic> _subscription;

  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.listen((dynamic _) => notifyListeners());
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

/// Provider managing the global application router instance.
final routerProvider = Provider<GoRouter>((ref) {
  // Listen to Auth State changes to trigger router redirects
  final authStateStream = ref.watch(authRepositoryProvider).authStateChanges;

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: GoRouterRefreshStream(authStateStream),
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/company-setup',
        builder: (context, state) => const CompanySetupScreen(),
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: '/vehicles',
        builder: (context, state) => const VehicleListScreen(),
      ),
      GoRoute(
        path: '/vehicles/new',
        builder: (context, state) => const VehicleFormScreen(),
      ),
      GoRoute(
        path: '/vehicles/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return VehicleDetailScreen(vehicleId: id);
        },
      ),
      GoRoute(
        path: '/vehicles/:id/edit',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return VehicleFormScreen(vehicleId: id);
        },
      ),
      GoRoute(
        path: '/trips',
        builder: (context, state) => const TripListScreen(),
      ),
      GoRoute(
        path: '/trips/new',
        builder: (context, state) => const TripFormScreen(),
      ),
      GoRoute(
        path: '/trips/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return TripDetailScreen(tripId: id);
        },
      ),
      GoRoute(
        path: '/trips/:id/edit',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return TripFormScreen(tripId: id);
        },
      ),
      GoRoute(
        path: '/finance',
        builder: (context, state) => const FinanceListScreen(),
      ),
      GoRoute(
        path: '/finance/new',
        builder: (context, state) => const FinanceFormScreen(),
      ),
      GoRoute(
        path: '/finance/reports',
        builder: (context, state) => const ProfitLossScreen(),
      ),
      GoRoute(
        path: '/finance/:id/edit',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return FinanceFormScreen(transactionId: id);
        },
      ),
      GoRoute(
        path: '/drivers',
        builder: (context, state) => const DriverListScreen(),
      ),
      GoRoute(
        path: '/drivers/new',
        builder: (context, state) => const DriverFormScreen(),
      ),
      GoRoute(
        path: '/drivers/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return DriverDetailScreen(driverId: id);
        },
      ),
      GoRoute(
        path: '/drivers/:id/edit',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return DriverFormScreen(driverId: id);
        },
      ),
      GoRoute(
        path: '/customers',
        builder: (context, state) => const CustomerListScreen(),
      ),
      GoRoute(
        path: '/customers/new',
        builder: (context, state) => const CustomerFormScreen(),
      ),
      GoRoute(
        path: '/customers/:id/edit',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return CustomerFormScreen(customerId: id);
        },
      ),
      GoRoute(
        path: '/vendors',
        builder: (context, state) => const VendorListScreen(),
      ),
      GoRoute(
        path: '/vendors/new',
        builder: (context, state) => const VendorFormScreen(),
      ),
      GoRoute(
        path: '/vendors/:id/edit',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return VendorFormScreen(vendorId: id);
        },
      ),
      GoRoute(
        path: '/fuel',
        builder: (context, state) => const FuelListScreen(),
      ),
      GoRoute(
        path: '/fuel/new',
        builder: (context, state) => const FuelFormScreen(),
      ),
      GoRoute(
        path: '/fuel/:id/edit',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return FuelFormScreen(fuelLogId: id);
        },
      ),
      GoRoute(
        path: '/maintenance',
        builder: (context, state) => const MaintenanceListScreen(),
      ),
      GoRoute(
        path: '/maintenance/new',
        builder: (context, state) => const MaintenanceFormScreen(),
      ),
      GoRoute(
        path: '/maintenance/:id/edit',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return MaintenanceFormScreen(maintLogId: id);
        },
      ),
      GoRoute(
        path: '/compliance',
        builder: (context, state) => const ComplianceListScreen(),
      ),
      GoRoute(
        path: '/compliance/new',
        builder: (context, state) => const ComplianceFormScreen(),
      ),
      GoRoute(
        path: '/compliance/:id/edit',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return ComplianceFormScreen(complianceId: id);
        },
      ),
      GoRoute(
        path: '/inventory',
        builder: (context, state) => const PartListScreen(),
      ),
      GoRoute(
        path: '/inventory/new',
        builder: (context, state) => const PartFormScreen(),
      ),
      GoRoute(
        path: '/inventory/:id/edit',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return PartFormScreen(partId: id);
        },
      ),
      GoRoute(
        path: '/inventory/suppliers',
        builder: (context, state) => const SupplierListScreen(),
      ),
      GoRoute(
        path: '/inventory/suppliers/new',
        builder: (context, state) => const SupplierFormScreen(),
      ),
      GoRoute(
        path: '/inventory/suppliers/:id/edit',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return SupplierFormScreen(supplierId: id);
        },
      ),
      GoRoute(
        path: '/inventory/transactions',
        builder: (context, state) => const TransactionListScreen(),
      ),
      GoRoute(
        path: '/inventory/transactions/new',
        builder: (context, state) {
          final partId = state.uri.queryParameters['partId'];
          return TransactionFormScreen(preSelectedPartId: partId);
        },
      ),
      GoRoute(
        path: '/contracts',
        builder: (context, state) => const ContractListScreen(),
      ),
      GoRoute(
        path: '/contracts/new',
        builder: (context, state) => const ContractFormScreen(),
      ),
      GoRoute(
        path: '/contracts/:id/edit',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return ContractFormScreen(contractId: id);
        },
      ),
      GoRoute(
        path: '/invoices',
        builder: (context, state) => const InvoiceListScreen(),
      ),
      GoRoute(
        path: '/invoices/new',
        builder: (context, state) => const InvoiceFormScreen(),
      ),
      GoRoute(
        path: '/invoices/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return InvoiceDetailScreen(invoiceId: id);
        },
      ),
      GoRoute(
        path: '/invoices/:id/edit',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return InvoiceFormScreen(invoiceId: id);
        },
      ),
      GoRoute(
        path: '/reports',
        builder: (context, state) => const ReportScreen(),
      ),
      GoRoute(
        path: '/documents',
        builder: (context, state) => const DocumentListScreen(),
      ),
      GoRoute(
        path: '/documents/new',
        builder: (context, state) => const DocumentFormScreen(),
      ),
      GoRoute(
        path: '/documents/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return DocumentDetailScreen(documentId: id);
        },
      ),
      GoRoute(
        path: '/dispatches',
        builder: (context, state) => const DispatchListScreen(),
      ),
      GoRoute(
        path: '/dispatches/new',
        builder: (context, state) => const DispatchFormScreen(),
      ),
      GoRoute(
        path: '/dispatches/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return DispatchDetailScreen(dispatchId: id);
        },
      ),
      GoRoute(
        path: '/dispatches/:id/edit',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return DispatchFormScreen(dispatchId: id);
        },
      ),
      GoRoute(
        path: '/routes',
        builder: (context, state) => const RouteListScreen(),
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationCenterScreen(),
      ),
      GoRoute(
        path: '/notifications/alert-details',
        builder: (context, state) {
          final n = state.extra as NotificationEntity;
          return AlertDetailsScreen(notification: n);
        },
      ),
      GoRoute(
        path: '/notifications/settings',
        builder: (context, state) => const NotificationSettingsScreen(),
      ),
      GoRoute(
        path: '/hr/employees',
        builder: (context, state) => const EmployeeListScreen(),
      ),
      GoRoute(
        path: '/hr/employees/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return EmployeeProfileScreen(employeeId: id);
        },
      ),
      GoRoute(
        path: '/hr/employees/:id/edit',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return EmployeeFormScreen(employeeId: id);
        },
      ),
      GoRoute(
        path: '/hr/attendance',
        builder: (context, state) => const AttendanceScreen(),
      ),
      GoRoute(
        path: '/hr/leaves',
        builder: (context, state) => const LeaveScreen(),
      ),
      GoRoute(
        path: '/hr/payroll',
        builder: (context, state) => const PayrollScreen(),
      ),
      GoRoute(
        path: '/hr/settings',
        builder: (context, state) => const HrSettingsScreen(),
      ),
    ],
    redirect: (context, state) {
      final user = ref.read(currentUserProvider);
      final isLoggingIn = state.matchedLocation == '/login';
      final isSplashing = state.matchedLocation == '/splash';
      final isOnboarding = state.matchedLocation == '/company-setup';

      // 1. If we are on the splash screen, do not redirect. Let it manage state transitions.
      if (isSplashing) {
        return null;
      }

      // 2. If the user is NOT authenticated, force login screen
      if (user == null) {
        return isLoggingIn ? null : '/login';
      }

      // 3. User authenticated, check company setup onboarding mapping
      final hasCompany = user.companyId != null && user.companyId!.isNotEmpty;

      if (!hasCompany) {
        // Must complete onboarding/setup first
        return isOnboarding ? null : '/company-setup';
      }

      // 4. Authenticated & Onboarded: Redirect away from login / onboarding to dashboard
      if (isLoggingIn || isOnboarding) {
        return '/dashboard';
      }

      // Default: proceed to requested route
      return null;
    },
  );
});
