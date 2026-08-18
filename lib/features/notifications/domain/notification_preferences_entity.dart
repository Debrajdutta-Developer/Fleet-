/// Represents user/company-level preferences for filtering, silencing, or gating notifications.
class NotificationPreferencesEntity {
  final String companyId;
  final List<String>
      enabledCategories; // e.g. ['vehicles', 'drivers', 'inventory']
  final bool quietHoursEnabled;
  final String quietHoursStart; // "HH:MM" e.g. "22:00"
  final String quietHoursEnd; // "HH:MM" e.g. "06:00"
  final String minPriorityFilter; // 'low', 'medium', 'high', 'critical'

  const NotificationPreferencesEntity({
    required this.companyId,
    required this.enabledCategories,
    required this.quietHoursEnabled,
    required this.quietHoursStart,
    required this.quietHoursEnd,
    required this.minPriorityFilter,
  });

  Map<String, dynamic> toMap() {
    return {
      'companyId': companyId,
      'enabledCategories': enabledCategories,
      'quietHoursEnabled': quietHoursEnabled,
      'quietHoursStart': quietHoursStart,
      'quietHoursEnd': quietHoursEnd,
      'minPriorityFilter': minPriorityFilter,
    };
  }

  factory NotificationPreferencesEntity.fromMap(Map<String, dynamic> map) {
    return NotificationPreferencesEntity(
      companyId: map['companyId'] as String? ?? '',
      enabledCategories: List<String>.from(
        (map['enabledCategories'] as Iterable?) ??
            [
              'vehicles',
              'drivers',
              'inventory',
              'trips',
              'billing',
              'finance',
              'general'
            ],
      ),
      quietHoursEnabled: map['quietHoursEnabled'] as bool? ?? false,
      quietHoursStart: map['quietHoursStart'] as String? ?? '22:00',
      quietHoursEnd: map['quietHoursEnd'] as String? ?? '06:00',
      minPriorityFilter: map['minPriorityFilter'] as String? ?? 'low',
    );
  }

  NotificationPreferencesEntity copyWith({
    String? companyId,
    List<String>? enabledCategories,
    bool? quietHoursEnabled,
    String? quietHoursStart,
    String? quietHoursEnd,
    String? minPriorityFilter,
  }) {
    return NotificationPreferencesEntity(
      companyId: companyId ?? this.companyId,
      enabledCategories: enabledCategories ?? this.enabledCategories,
      quietHoursEnabled: quietHoursEnabled ?? this.quietHoursEnabled,
      quietHoursStart: quietHoursStart ?? this.quietHoursStart,
      quietHoursEnd: quietHoursEnd ?? this.quietHoursEnd,
      minPriorityFilter: minPriorityFilter ?? this.minPriorityFilter,
    );
  }
}
