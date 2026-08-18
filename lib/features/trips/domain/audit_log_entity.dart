class AuditLogEntity {
  final String id;
  final String companyId;
  final String entityType; // e.g. "trip"
  final String entityId; // e.g. tripId
  final String action; // e.g. "trip_created", "status_changed"
  final String description; // e.g. "Trip scheduled for Vehicle NY-884-AB", etc.
  final String userId;
  final String userName;
  final DateTime timestamp;

  const AuditLogEntity({
    required this.id,
    required this.companyId,
    required this.entityType,
    required this.entityId,
    required this.action,
    required this.description,
    required this.userId,
    required this.userName,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'companyId': companyId,
      'entityType': entityType,
      'entityId': entityId,
      'action': action,
      'description': description,
      'userId': userId,
      'userName': userName,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory AuditLogEntity.fromMap(Map<String, dynamic> map) {
    return AuditLogEntity(
      id: map['id'] as String? ?? '',
      companyId: map['companyId'] as String? ?? '',
      entityType: map['entityType'] as String? ?? '',
      entityId: map['entityId'] as String? ?? '',
      action: map['action'] as String? ?? '',
      description: map['description'] as String? ?? '',
      userId: map['userId'] as String? ?? '',
      userName: map['userName'] as String? ?? '',
      timestamp: map['timestamp'] != null
          ? DateTime.parse(map['timestamp'] as String)
          : DateTime.now(),
    );
  }
}
