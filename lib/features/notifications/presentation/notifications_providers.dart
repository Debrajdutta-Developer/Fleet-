import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../../auth/presentation/auth_providers.dart';
import '../../trips/domain/audit_log_entity.dart';
import '../domain/notification_entity.dart';
import '../domain/notification_preferences_entity.dart';
import '../domain/notification_repository.dart';
import '../data/notification_repository_impl.dart';

// Import target repositories for alerts integration
import '../../vehicles/presentation/vehicle_providers.dart';
import '../../drivers/presentation/driver_providers.dart';
import '../../inventory/presentation/inventory_providers.dart';
import '../../billing/presentation/billing_providers.dart';
import '../../trips/presentation/trip_providers.dart';

// Static validation helpers for mocked fields
class VehicleFastagValidator {
  static final Map<String, double> _balances = {};
  static double getFastagBalance(String vehicleId) =>
      _balances[vehicleId] ?? 100.0;
  static void setFastagBalance(String vehicleId, double balance) =>
      _balances[vehicleId] = balance;
  static void clear() => _balances.clear();
}

class DriverMedicalCertificateValidator {
  static final Map<String, DateTime> _expiries = {};
  static DateTime getMedicalCertificateExpiry(String driverId) =>
      _expiries[driverId] ?? DateTime.now().add(const Duration(days: 365));
  static void setMedicalCertificateExpiry(String driverId, DateTime expiry) =>
      _expiries[driverId] = expiry;
  static void clear() => _expiries.clear();
}

class UnpaidBill {
  final String id;
  final String vendorName;
  final double amount;
  final DateTime dueDate;
  final String description;

  const UnpaidBill({
    required this.id,
    required this.vendorName,
    required this.amount,
    required this.dueDate,
    required this.description,
  });
}

class UnpaidBillsValidator {
  static final Map<String, List<UnpaidBill>> _bills = {};
  static List<UnpaidBill> getUnpaidBills(String companyId) =>
      _bills[companyId] ?? [];
  static void setUnpaidBills(String companyId, List<UnpaidBill> bills) =>
      _bills[companyId] = bills;
  static void clear() => _bills.clear();
}

// Providers
final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepositoryImpl();
});

final notificationPreferencesStreamProvider =
    StreamProvider.autoDispose<NotificationPreferencesEntity>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user?.companyId == null) {
    return Stream.value(NotificationPreferencesEntity(
      companyId: '',
      enabledCategories: const [],
      quietHoursEnabled: false,
      quietHoursStart: '22:00',
      quietHoursEnd: '06:00',
      minPriorityFilter: 'low',
    ));
  }
  return ref
      .watch(notificationRepositoryProvider)
      .watchPreferences(user!.companyId!);
});

final notificationsStreamProvider =
    StreamProvider.autoDispose<List<NotificationEntity>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user?.companyId == null) return Stream.value([]);

  final notificationsStream = ref
      .watch(notificationRepositoryProvider)
      .watchNotifications(user!.companyId!);
  final prefsAsync = ref.watch(notificationPreferencesStreamProvider);

  return notificationsStream.map((list) {
    final prefs = prefsAsync.valueOrNull;
    if (prefs == null) return list;

    // Filter list based on preferences
    return list.where((n) {
      // 1. Enable/Disable categories
      if (!prefs.enabledCategories.contains(n.category)) return false;

      // 2. Priority filters
      final priorityValues = {'low': 0, 'medium': 1, 'high': 2, 'critical': 3};
      final nVal = priorityValues[n.priority] ?? 0;
      final pVal = priorityValues[prefs.minPriorityFilter] ?? 0;
      if (nVal < pVal) return false;

      // 3. Quiet hours check
      if (prefs.quietHoursEnabled && n.priority != 'critical') {
        final now = DateTime.now();
        final nowStr =
            '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
        final start = prefs.quietHoursStart;
        final end = prefs.quietHoursEnd;

        bool inQuietHours = false;
        if (start.compareTo(end) <= 0) {
          inQuietHours =
              nowStr.compareTo(start) >= 0 && nowStr.compareTo(end) <= 0;
        } else {
          inQuietHours =
              nowStr.compareTo(start) >= 0 || nowStr.compareTo(end) <= 0;
        }

        if (inQuietHours) return false;
      }

      return true;
    }).toList();
  });
});

// Search & filter providers
final notificationSearchQueryProvider = StateProvider<String>((ref) => '');
final notificationCategoryFilterProvider =
    StateProvider<String>((ref) => 'all');
final notificationPriorityFilterProvider =
    StateProvider<String>((ref) => 'all');

final filteredNotificationsProvider =
    Provider.autoDispose<List<NotificationEntity>>((ref) {
  final notificationsAsync = ref.watch(notificationsStreamProvider);
  final query = ref.watch(notificationSearchQueryProvider).toLowerCase();
  final category = ref.watch(notificationCategoryFilterProvider);
  final priority = ref.watch(notificationPriorityFilterProvider);

  final list = notificationsAsync.valueOrNull ?? [];

  return list.where((n) {
    if (category != 'all' && n.category != category) return false;
    if (priority != 'all' && n.priority != priority) return false;
    if (query.isNotEmpty) {
      final title = n.title.toLowerCase();
      final msg = n.message.toLowerCase();
      return title.contains(query) || msg.contains(query);
    }
    return true;
  }).toList();
});

class NotificationFormState {
  final bool isLoading;
  final String? errorMessage;
  final bool isCompleted;

  const NotificationFormState({
    this.isLoading = false,
    this.errorMessage,
    this.isCompleted = false,
  });

  NotificationFormState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool? isCompleted,
  }) {
    return NotificationFormState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}

class NotificationFormController extends StateNotifier<NotificationFormState> {
  final NotificationRepository _repo;
  final Ref _ref;

  NotificationFormController({
    required NotificationRepository repo,
    required Ref ref,
  })  : _repo = repo,
        _ref = ref,
        super(const NotificationFormState());

  Future<void> markAsRead(NotificationEntity n) async {
    state = const NotificationFormState(isLoading: true);
    try {
      final user = _ref.read(currentUserProvider);
      if (user?.companyId == null) throw Exception('No authenticated company.');

      final updated = n.copyWith(
        isRead: true,
        readAt: DateTime.now(),
      );

      await _repo.updateNotification(user!.companyId!, updated);
      await _writeAuditLog(
        action: 'notification_read',
        description:
            'Notification "${n.title}" marked as read by ${user.displayName}',
        entityId: n.id,
      );
      state = const NotificationFormState(isCompleted: true);
    } catch (e) {
      state = NotificationFormState(errorMessage: e.toString());
    }
  }

  Future<void> dismissNotification(String id, String title) async {
    state = const NotificationFormState(isLoading: true);
    try {
      final user = _ref.read(currentUserProvider);
      if (user?.companyId == null) throw Exception('No authenticated company.');

      await _repo.deleteNotification(user!.companyId!, id);
      await _writeAuditLog(
        action: 'notification_dismissed',
        description: 'Notification "$title" dismissed by ${user.displayName}',
        entityId: id,
      );
      state = const NotificationFormState(isCompleted: true);
    } catch (e) {
      state = NotificationFormState(errorMessage: e.toString());
    }
  }

  Future<void> markAllNotificationsAsRead() async {
    state = const NotificationFormState(isLoading: true);
    try {
      final user = _ref.read(currentUserProvider);
      if (user?.companyId == null) throw Exception('No authenticated company.');

      await _repo.markAllAsRead(user!.companyId!);
      await _writeAuditLog(
        action: 'notification_read_all',
        description: 'All notifications marked as read by ${user.displayName}',
        entityId: 'all',
      );
      state = const NotificationFormState(isCompleted: true);
    } catch (e) {
      state = NotificationFormState(errorMessage: e.toString());
    }
  }

  Future<void> savePreferences(NotificationPreferencesEntity prefs) async {
    state = const NotificationFormState(isLoading: true);
    try {
      final user = _ref.read(currentUserProvider);
      if (user?.companyId == null) throw Exception('No authenticated company.');

      await _repo.savePreferences(user!.companyId!, prefs);
      state = const NotificationFormState(isCompleted: true);
    } catch (e) {
      state = NotificationFormState(errorMessage: e.toString());
    }
  }

  Future<void> _writeAuditLog({
    required String action,
    required String description,
    required String entityId,
  }) async {
    try {
      final user = _ref.read(currentUserProvider);
      if (user == null || user.companyId == null) return;
      final companyId = user.companyId!;
      final uid = user.uid;
      final displayName = user.displayName;

      final auditLog = AuditLogEntity(
        id: const Uuid().v4(),
        companyId: companyId,
        entityType: 'notification',
        entityId: entityId,
        action: action,
        description: description,
        userId: uid,
        userName: displayName,
        timestamp: DateTime.now(),
      );

      await FirebaseFirestore.instance
          .collection('companies')
          .doc(companyId)
          .collection('audit_logs')
          .doc(auditLog.id)
          .set(auditLog.toMap());
    } catch (e) {
      debugPrint('Audit log write failed: $e');
    }
  }
}

final notificationFormControllerProvider = StateNotifierProvider.autoDispose<
    NotificationFormController, NotificationFormState>((ref) {
  return NotificationFormController(
    repo: ref.watch(notificationRepositoryProvider),
    ref: ref,
  );
});

// Alert Evaluation State & Controller
class AlertEvaluationState {
  final bool isEvaluating;
  final int alertsCreated;
  final String? errorMessage;
  final DateTime? lastEvaluationTime;

  const AlertEvaluationState({
    this.isEvaluating = false,
    this.alertsCreated = 0,
    this.errorMessage,
    this.lastEvaluationTime,
  });

  AlertEvaluationState copyWith({
    bool? isEvaluating,
    int? alertsCreated,
    String? errorMessage,
    DateTime? lastEvaluationTime,
  }) {
    return AlertEvaluationState(
      isEvaluating: isEvaluating ?? this.isEvaluating,
      alertsCreated: alertsCreated ?? this.alertsCreated,
      errorMessage: errorMessage ?? this.errorMessage,
      lastEvaluationTime: lastEvaluationTime ?? this.lastEvaluationTime,
    );
  }
}

class AlertEvaluationController extends StateNotifier<AlertEvaluationState> {
  final NotificationRepository _repo;
  final Ref _ref;

  AlertEvaluationController({
    required NotificationRepository repo,
    required Ref ref,
  })  : _repo = repo,
        _ref = ref,
        super(const AlertEvaluationState());

  Future<int> evaluateAllRules() async {
    state = state.copyWith(isEvaluating: true, errorMessage: null);
    int newAlerts = 0;
    final ruleExecId = const Uuid().v4();

    try {
      final user = _ref.read(currentUserProvider);
      if (user?.companyId == null)
        throw Exception('No authenticated company context.');
      final companyId = user!.companyId!;

      // 1. Fetch existing unread notifications to avoid duplicate spamming
      final existingAlerts = await _repo.getNotifications(companyId);
      bool isAlreadyNotified(String category, String entityId, String title) {
        return existingAlerts.any((n) =>
            n.category == category &&
            n.relatedEntityId == entityId &&
            n.title == title &&
            !n.isRead);
      }

      Future<void> triggerAlert({
        required String title,
        required String message,
        required String category,
        required String priority,
        required String relatedId,
        required String relatedType,
        String? actionUrl,
      }) async {
        if (isAlreadyNotified(category, relatedId, title)) return;

        final notification = NotificationEntity(
          id: '',
          companyId: companyId,
          title: title,
          message: message,
          category: category,
          priority: priority,
          createdAt: DateTime.now(),
          relatedEntityId: relatedId,
          relatedEntityType: relatedType,
          actionUrl: actionUrl,
          ruleExecutionId: ruleExecId,
        );

        await _repo.createNotification(companyId, notification);
        newAlerts++;
      }

      final now = DateTime.now();

      // --- Rule 1: Vehicle Expiries (Insurance, PUC, Fitness, Permit) ---
      final vehicles =
          await _ref.read(vehicleRepositoryProvider).getVehicles(companyId);
      for (final v in vehicles) {
        // Insurance Expiry
        final insDiff = v.insuranceExpiry.difference(now).inDays;
        if (insDiff <= 0) {
          await triggerAlert(
            title: 'Insurance Expired: ${v.licensePlate}',
            message:
                'Vehicle insurance expired on ${v.insuranceExpiry.toString().split(' ')[0]}!',
            category: 'vehicles',
            priority: 'critical',
            relatedId: v.id,
            relatedType: 'vehicle',
            actionUrl: '/vehicles/${v.id}',
          );
        } else if (insDiff <= 30) {
          await triggerAlert(
            title: 'Insurance Expiring Soon: ${v.licensePlate}',
            message: 'Vehicle insurance expires in $insDiff days.',
            category: 'vehicles',
            priority: 'high',
            relatedId: v.id,
            relatedType: 'vehicle',
            actionUrl: '/vehicles/${v.id}',
          );
        }

        // PUC Expiry
        final pucDiff = v.pucExpiry.difference(now).inDays;
        if (pucDiff <= 0) {
          await triggerAlert(
            title: 'PUC Expired: ${v.licensePlate}',
            message:
                'PUC certificate expired on ${v.pucExpiry.toString().split(' ')[0]}!',
            category: 'vehicles',
            priority: 'critical',
            relatedId: v.id,
            relatedType: 'vehicle',
            actionUrl: '/vehicles/${v.id}',
          );
        } else if (pucDiff <= 30) {
          await triggerAlert(
            title: 'PUC Expiring Soon: ${v.licensePlate}',
            message: 'PUC certificate expires in $pucDiff days.',
            category: 'vehicles',
            priority: 'medium',
            relatedId: v.id,
            relatedType: 'vehicle',
            actionUrl: '/vehicles/${v.id}',
          );
        }

        // Fitness Expiry
        final fitDiff = v.fitnessExpiry.difference(now).inDays;
        if (fitDiff <= 0) {
          await triggerAlert(
            title: 'Fitness Certificate Expired: ${v.licensePlate}',
            message:
                'Vehicle fitness expired on ${v.fitnessExpiry.toString().split(' ')[0]}!',
            category: 'vehicles',
            priority: 'critical',
            relatedId: v.id,
            relatedType: 'vehicle',
            actionUrl: '/vehicles/${v.id}',
          );
        } else if (fitDiff <= 30) {
          await triggerAlert(
            title: 'Fitness Expiring Soon: ${v.licensePlate}',
            message: 'Fitness certificate expires in $fitDiff days.',
            category: 'vehicles',
            priority: 'high',
            relatedId: v.id,
            relatedType: 'vehicle',
            actionUrl: '/vehicles/${v.id}',
          );
        }

        // Permit Expiry (VehiclePermitValidator)
        final permitExpiry = VehiclePermitValidator.getPermitExpiry(v.id);
        final permitDiff = permitExpiry.difference(now).inDays;
        if (permitDiff <= 0) {
          await triggerAlert(
            title: 'Permit Expired: ${v.licensePlate}',
            message:
                'Vehicle road permit expired on ${permitExpiry.toString().split(' ')[0]}!',
            category: 'vehicles',
            priority: 'critical',
            relatedId: v.id,
            relatedType: 'vehicle',
            actionUrl: '/vehicles/${v.id}',
          );
        } else if (permitDiff <= 30) {
          await triggerAlert(
            title: 'Permit Expiring Soon: ${v.licensePlate}',
            message: 'Vehicle road permit expires in $permitDiff days.',
            category: 'vehicles',
            priority: 'high',
            relatedId: v.id,
            relatedType: 'vehicle',
            actionUrl: '/vehicles/${v.id}',
          );
        }

        // --- Rule 4: Low FASTag Balance ---
        final fastagBalance = VehicleFastagValidator.getFastagBalance(v.id);
        if (fastagBalance < 50.0) {
          await triggerAlert(
            title: 'Low FASTag Balance: ${v.licensePlate}',
            message:
                'FASTag balance is low (\$${fastagBalance.toStringAsFixed(2)}). Please recharge immediately.',
            category: 'vehicles',
            priority: 'medium',
            relatedId: v.id,
            relatedType: 'vehicle',
            actionUrl: '/vehicles/${v.id}',
          );
        }

        // --- Rule 8: Vehicle Maintenance Reminders ---
        if (v.status == 'maintenance') {
          await triggerAlert(
            title: 'Vehicle in Maintenance: ${v.licensePlate}',
            message: 'Vehicle status is marked as maintenance.',
            category: 'vehicles',
            priority: 'medium',
            relatedId: v.id,
            relatedType: 'vehicle',
            actionUrl: '/vehicles/${v.id}',
          );
        } else if (v.lastServiceDate != null) {
          final serviceDiff = now.difference(v.lastServiceDate!).inDays;
          if (serviceDiff >= 180) {
            await triggerAlert(
              title: 'Maintenance Due: ${v.licensePlate}',
              message:
                  'Last serviced $serviceDiff days ago. Routine maintenance is due.',
              category: 'vehicles',
              priority: 'medium',
              relatedId: v.id,
              relatedType: 'vehicle',
              actionUrl: '/vehicles/${v.id}',
            );
          }
        }
      }

      // --- Rule 2: Driver Expiries (License, Medical Certificate) ---
      final drivers =
          await _ref.read(driverRepositoryProvider).getDrivers(companyId);
      for (final d in drivers) {
        // License Expiry
        final licDiff = d.licenseExpiry.difference(now).inDays;
        if (licDiff <= 0) {
          await triggerAlert(
            title: 'License Expired: ${d.fullName}',
            message:
                'Driver license expired on ${d.licenseExpiry.toString().split(' ')[0]}!',
            category: 'drivers',
            priority: 'critical',
            relatedId: d.id,
            relatedType: 'driver',
            actionUrl: '/drivers/${d.id}',
          );
        } else if (licDiff <= 30) {
          await triggerAlert(
            title: 'License Expiring Soon: ${d.fullName}',
            message: 'Driver license expires in $licDiff days.',
            category: 'drivers',
            priority: 'high',
            relatedId: d.id,
            relatedType: 'driver',
            actionUrl: '/drivers/${d.id}',
          );
        }

        // Medical Certificate Expiry
        final medExpiry =
            DriverMedicalCertificateValidator.getMedicalCertificateExpiry(d.id);
        final medDiff = medExpiry.difference(now).inDays;
        if (medDiff <= 0) {
          await triggerAlert(
            title: 'Medical Certificate Expired: ${d.fullName}',
            message:
                'Medical certificate expired on ${medExpiry.toString().split(' ')[0]}!',
            category: 'drivers',
            priority: 'critical',
            relatedId: d.id,
            relatedType: 'driver',
            actionUrl: '/drivers/${d.id}',
          );
        } else if (medDiff <= 30) {
          await triggerAlert(
            title: 'Medical Certificate Expiring Soon: ${d.fullName}',
            message: 'Medical certificate expires in $medDiff days.',
            category: 'drivers',
            priority: 'medium',
            relatedId: d.id,
            relatedType: 'driver',
            actionUrl: '/drivers/${d.id}',
          );
        }
      }

      // --- Rule 3: Low Inventory Alerts ---
      final parts =
          await _ref.read(inventoryRepositoryProvider).getParts(companyId);
      for (final p in parts) {
        if (p.quantity <= p.minStockThreshold) {
          await triggerAlert(
            title: 'Low Stock Alert: ${p.name}',
            message:
                'Inventory stock level is low (${p.quantity} left, minimum threshold is ${p.minStockThreshold}).',
            category: 'inventory',
            priority: 'high',
            relatedId: p.id,
            relatedType: 'part',
            actionUrl: '/inventory',
          );
        }
      }

      // --- Rule 5: Customer Overdue Invoices ---
      final invoices =
          await _ref.read(invoiceRepositoryProvider).getInvoices(companyId);
      for (final inv in invoices) {
        final isOverdue = inv.dueDate.isBefore(now) &&
            inv.outstandingAmount > 0.0 &&
            inv.status != 'paid' &&
            inv.status != 'cancelled';

        if (isOverdue) {
          await triggerAlert(
            title: 'Overdue Invoice: ${inv.invoiceNumber}',
            message:
                'Invoice total \$${inv.grandTotal.toStringAsFixed(2)} is overdue from ${inv.customerName} since ${inv.dueDate.toString().split(' ')[0]}!',
            category: 'billing',
            priority: 'high',
            relatedId: inv.id,
            relatedType: 'invoice',
            actionUrl: '/billing',
          );
        }
      }

      // --- Rule 6: Unpaid Bills ---
      final bills = UnpaidBillsValidator.getUnpaidBills(companyId);
      for (final b in bills) {
        final billDiff = b.dueDate.difference(now).inDays;
        if (billDiff <= 0) {
          await triggerAlert(
            title: 'Overdue Bill: ${b.vendorName}',
            message:
                'Bill of \$${b.amount.toStringAsFixed(2)} for "${b.description}" was due on ${b.dueDate.toString().split(' ')[0]}!',
            category: 'finance',
            priority: 'high',
            relatedId: b.id,
            relatedType: 'bill',
            actionUrl: '/finance',
          );
        } else if (billDiff <= 7) {
          await triggerAlert(
            title: 'Bill Due Soon: ${b.vendorName}',
            message:
                'Bill of \$${b.amount.toStringAsFixed(2)} for "${b.description}" is due in $billDiff days.',
            category: 'finance',
            priority: 'medium',
            relatedId: b.id,
            relatedType: 'bill',
            actionUrl: '/finance',
          );
        }
      }

      // --- Rule 7: Upcoming Trip Reminders ---
      final trips = await _ref.read(tripRepositoryProvider).getTrips(companyId);
      for (final t in trips) {
        if (t.status == 'scheduled') {
          await triggerAlert(
            title: 'Upcoming Trip Scheduled',
            message:
                'Trip from ${t.pickupLocation} to ${t.deliveryLocation} is scheduled with vehicle ${t.vehicleLicensePlate} and driver ${t.driverName}.',
            category: 'trips',
            priority: 'low',
            relatedId: t.id,
            relatedType: 'trip',
            actionUrl: '/trips/${t.id}',
          );
        }
      }

      // Log the execution of rules
      if (newAlerts > 0) {
        await _writeAuditLog(
          action: 'rule_execution_completed',
          description:
              'Daily alerts evaluation executed. $newAlerts new notifications generated.',
          entityId: ruleExecId,
        );
      }

      state = AlertEvaluationState(
        alertsCreated: newAlerts,
        lastEvaluationTime: DateTime.now(),
      );
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    } finally {
      state = state.copyWith(isEvaluating: false);
    }

    return newAlerts;
  }

  Future<void> _writeAuditLog({
    required String action,
    required String description,
    required String entityId,
  }) async {
    try {
      final user = _ref.read(currentUserProvider);
      if (user == null || user.companyId == null) return;
      final companyId = user.companyId!;
      final uid = user.uid;
      final displayName = user.displayName;

      final auditLog = AuditLogEntity(
        id: const Uuid().v4(),
        companyId: companyId,
        entityType: 'automation_rule',
        entityId: entityId,
        action: action,
        description: description,
        userId: uid,
        userName: displayName,
        timestamp: DateTime.now(),
      );

      await FirebaseFirestore.instance
          .collection('companies')
          .doc(companyId)
          .collection('audit_logs')
          .doc(auditLog.id)
          .set(auditLog.toMap());
    } catch (e) {
      debugPrint('Audit log write failed: $e');
    }
  }
}

final alertEvaluationControllerProvider = StateNotifierProvider.autoDispose<
    AlertEvaluationController, AlertEvaluationState>((ref) {
  return AlertEvaluationController(
    repo: ref.watch(notificationRepositoryProvider),
    ref: ref,
  );
});
