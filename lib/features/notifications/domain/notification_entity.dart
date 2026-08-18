/// Represents a system notification or alert generated in the FleetOS ERP platform.
class NotificationEntity {
  final String id;
  final String companyId;
  final String title;
  final String message;
  final String
      category; // 'vehicles', 'drivers', 'inventory', 'trips', 'billing', 'finance', 'general'
  final String priority; // 'low', 'medium', 'high', 'critical'
  final bool isRead;
  final DateTime createdAt;
  final DateTime? readAt;
  final String? actionUrl; // for UI deep-linking
  final String? relatedEntityId; // e.g. vehicleId, driverId
  final String? relatedEntityType; // e.g. 'vehicle', 'driver'
  final String? ruleExecutionId; // tracks the automation rule execution

  const NotificationEntity({
    required this.id,
    required this.companyId,
    required this.title,
    required this.message,
    required this.category,
    required this.priority,
    this.isRead = false,
    required this.createdAt,
    this.readAt,
    this.actionUrl,
    this.relatedEntityId,
    this.relatedEntityType,
    this.ruleExecutionId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'companyId': companyId,
      'title': title,
      'message': message,
      'category': category,
      'priority': priority,
      'isRead': isRead,
      'createdAt': createdAt.toIso8601String(),
      'readAt': readAt?.toIso8601String(),
      'actionUrl': actionUrl,
      'relatedEntityId': relatedEntityId,
      'relatedEntityType': relatedEntityType,
      'ruleExecutionId': ruleExecutionId,
    };
  }

  factory NotificationEntity.fromMap(Map<String, dynamic> map) {
    return NotificationEntity(
      id: map['id'] as String? ?? '',
      companyId: map['companyId'] as String? ?? '',
      title: map['title'] as String? ?? '',
      message: map['message'] as String? ?? '',
      category: map['category'] as String? ?? 'general',
      priority: map['priority'] as String? ?? 'low',
      isRead: map['isRead'] as bool? ?? false,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : DateTime.now(),
      readAt: map['readAt'] != null
          ? DateTime.parse(map['readAt'] as String)
          : null,
      actionUrl: map['actionUrl'] as String?,
      relatedEntityId: map['relatedEntityId'] as String?,
      relatedEntityType: map['relatedEntityType'] as String?,
      ruleExecutionId: map['ruleExecutionId'] as String?,
    );
  }

  NotificationEntity copyWith({
    String? id,
    String? companyId,
    String? title,
    String? message,
    String? category,
    String? priority,
    bool? isRead,
    DateTime? createdAt,
    DateTime? readAt,
    String? actionUrl,
    String? relatedEntityId,
    String? relatedEntityType,
    String? ruleExecutionId,
  }) {
    return NotificationEntity(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      title: title ?? this.title,
      message: message ?? this.message,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      readAt: readAt ?? this.readAt,
      actionUrl: actionUrl ?? this.actionUrl,
      relatedEntityId: relatedEntityId ?? this.relatedEntityId,
      relatedEntityType: relatedEntityType ?? this.relatedEntityType,
      ruleExecutionId: ruleExecutionId ?? this.ruleExecutionId,
    );
  }
}
