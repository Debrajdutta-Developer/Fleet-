class ShiftEntity {
  final String id;
  final String companyId;
  final String name;
  final String startTime; // "HH:MM"
  final String endTime; // "HH:MM"
  final DateTime createdAt;
  final DateTime updatedAt;

  const ShiftEntity({
    required this.id,
    required this.companyId,
    required this.name,
    required this.startTime,
    required this.endTime,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'companyId': companyId,
      'name': name,
      'startTime': startTime,
      'endTime': endTime,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory ShiftEntity.fromMap(Map<String, dynamic> map) {
    return ShiftEntity(
      id: map['id'] as String? ?? '',
      companyId: map['companyId'] as String? ?? '',
      name: map['name'] as String? ?? '',
      startTime: map['startTime'] as String? ?? '09:00',
      endTime: map['endTime'] as String? ?? '17:00',
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'] as String)
          : DateTime.now(),
    );
  }

  ShiftEntity copyWith({
    String? id,
    String? companyId,
    String? name,
    String? startTime,
    String? endTime,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ShiftEntity(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      name: name ?? this.name,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
