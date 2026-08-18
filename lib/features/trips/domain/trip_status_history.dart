class TripStatusHistory {
  final String status;
  final DateTime changedAt;
  final String changedBy;
  final String? notes;

  const TripStatusHistory({
    required this.status,
    required this.changedAt,
    required this.changedBy,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'status': status,
      'changedAt': changedAt.toIso8601String(),
      'changedBy': changedBy,
      'notes': notes,
    };
  }

  factory TripStatusHistory.fromMap(Map<String, dynamic> map) {
    return TripStatusHistory(
      status: map['status'] as String? ?? 'scheduled',
      changedAt: map['changedAt'] != null
          ? DateTime.parse(map['changedAt'] as String)
          : DateTime.now(),
      changedBy: map['changedBy'] as String? ?? 'System',
      notes: map['notes'] as String?,
    );
  }
}
