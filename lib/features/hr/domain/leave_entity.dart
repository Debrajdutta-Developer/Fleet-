class LeaveEntity {
  final String id;
  final String companyId;
  final String employeeId;
  final String leaveType; // annual, sick, casual, unpaid
  final DateTime startDate;
  final DateTime endDate;
  final String reason;
  final String status; // pending, approved, rejected
  final String? approvedById;
  final DateTime createdAt;
  final DateTime updatedAt;

  const LeaveEntity({
    required this.id,
    required this.companyId,
    required this.employeeId,
    required this.leaveType,
    required this.startDate,
    required this.endDate,
    required this.reason,
    required this.status,
    this.approvedById,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'companyId': companyId,
      'employeeId': employeeId,
      'leaveType': leaveType,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'reason': reason,
      'status': status,
      'approvedById': approvedById,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory LeaveEntity.fromMap(Map<String, dynamic> map) {
    return LeaveEntity(
      id: map['id'] as String? ?? '',
      companyId: map['companyId'] as String? ?? '',
      employeeId: map['employeeId'] as String? ?? '',
      leaveType: map['leaveType'] as String? ?? 'annual',
      startDate: map['startDate'] != null
          ? DateTime.parse(map['startDate'] as String)
          : DateTime.now(),
      endDate: map['endDate'] != null
          ? DateTime.parse(map['endDate'] as String)
          : DateTime.now(),
      reason: map['reason'] as String? ?? '',
      status: map['status'] as String? ?? 'pending',
      approvedById: map['approvedById'] as String?,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'] as String)
          : DateTime.now(),
    );
  }

  LeaveEntity copyWith({
    String? id,
    String? companyId,
    String? employeeId,
    String? leaveType,
    DateTime? startDate,
    DateTime? endDate,
    String? reason,
    String? status,
    String? approvedById,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return LeaveEntity(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      employeeId: employeeId ?? this.employeeId,
      leaveType: leaveType ?? this.leaveType,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      reason: reason ?? this.reason,
      status: status ?? this.status,
      approvedById: approvedById ?? this.approvedById,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
