class PayrollEntity {
  final String id;
  final String companyId;
  final String employeeId;
  final String employeeName;
  final int month;
  final int year;
  final double baseSalary;
  final double allowances;
  final double deductions;
  final double netSalary;
  final String status; // draft, processed, paid
  final DateTime? paidAt;
  final String? referenceId;
  final DateTime createdAt;
  final DateTime updatedAt;

  const PayrollEntity({
    required this.id,
    required this.companyId,
    required this.employeeId,
    required this.employeeName,
    required this.month,
    required this.year,
    required this.baseSalary,
    required this.allowances,
    required this.deductions,
    required this.netSalary,
    required this.status,
    this.paidAt,
    this.referenceId,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'companyId': companyId,
      'employeeId': employeeId,
      'employeeName': employeeName,
      'month': month,
      'year': year,
      'baseSalary': baseSalary,
      'allowances': allowances,
      'deductions': deductions,
      'netSalary': netSalary,
      'status': status,
      'paidAt': paidAt?.toIso8601String(),
      'referenceId': referenceId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory PayrollEntity.fromMap(Map<String, dynamic> map) {
    return PayrollEntity(
      id: map['id'] as String? ?? '',
      companyId: map['companyId'] as String? ?? '',
      employeeId: map['employeeId'] as String? ?? '',
      employeeName: map['employeeName'] as String? ?? '',
      month: map['month'] as int? ?? 1,
      year: map['year'] as int? ?? 2026,
      baseSalary: (map['baseSalary'] as num? ?? 0.0).toDouble(),
      allowances: (map['allowances'] as num? ?? 0.0).toDouble(),
      deductions: (map['deductions'] as num? ?? 0.0).toDouble(),
      netSalary: (map['netSalary'] as num? ?? 0.0).toDouble(),
      status: map['status'] as String? ?? 'draft',
      paidAt: map['paidAt'] != null
          ? DateTime.parse(map['paidAt'] as String)
          : null,
      referenceId: map['referenceId'] as String?,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'] as String)
          : DateTime.now(),
    );
  }

  PayrollEntity copyWith({
    String? id,
    String? companyId,
    String? employeeId,
    String? employeeName,
    int? month,
    int? year,
    double? baseSalary,
    double? allowances,
    double? deductions,
    double? netSalary,
    String? status,
    DateTime? paidAt,
    String? referenceId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PayrollEntity(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      employeeId: employeeId ?? this.employeeId,
      employeeName: employeeName ?? this.employeeName,
      month: month ?? this.month,
      year: year ?? this.year,
      baseSalary: baseSalary ?? this.baseSalary,
      allowances: allowances ?? this.allowances,
      deductions: deductions ?? this.deductions,
      netSalary: netSalary ?? this.netSalary,
      status: status ?? this.status,
      paidAt: paidAt ?? this.paidAt,
      referenceId: referenceId ?? this.referenceId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
