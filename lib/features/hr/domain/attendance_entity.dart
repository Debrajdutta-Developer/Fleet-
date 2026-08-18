class AttendanceEntity {
  final String id;
  final String companyId;
  final String employeeId;
  final DateTime date; // YYYY-MM-DD
  final DateTime? checkIn;
  final DateTime? checkOut;
  final int? durationMinutes;
  final String status; // present, absent, late, leave
  final DateTime createdAt;
  final DateTime updatedAt;

  const AttendanceEntity({
    required this.id,
    required this.companyId,
    required this.employeeId,
    required this.date,
    this.checkIn,
    this.checkOut,
    this.durationMinutes,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'companyId': companyId,
      'employeeId': employeeId,
      'date': date.toIso8601String(),
      'checkIn': checkIn?.toIso8601String(),
      'checkOut': checkOut?.toIso8601String(),
      'durationMinutes': durationMinutes,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory AttendanceEntity.fromMap(Map<String, dynamic> map) {
    return AttendanceEntity(
      id: map['id'] as String? ?? '',
      companyId: map['companyId'] as String? ?? '',
      employeeId: map['employeeId'] as String? ?? '',
      date: map['date'] != null
          ? DateTime.parse(map['date'] as String)
          : DateTime.now(),
      checkIn: map['checkIn'] != null
          ? DateTime.parse(map['checkIn'] as String)
          : null,
      checkOut: map['checkOut'] != null
          ? DateTime.parse(map['checkOut'] as String)
          : null,
      durationMinutes: map['durationMinutes'] as int?,
      status: map['status'] as String? ?? 'absent',
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'] as String)
          : DateTime.now(),
    );
  }

  AttendanceEntity copyWith({
    String? id,
    String? companyId,
    String? employeeId,
    DateTime? date,
    DateTime? checkIn,
    DateTime? checkOut,
    int? durationMinutes,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AttendanceEntity(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      employeeId: employeeId ?? this.employeeId,
      date: date ?? this.date,
      checkIn: checkIn ?? this.checkIn,
      checkOut: checkOut ?? this.checkOut,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
