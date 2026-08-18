class EmployeeEntity {
  final String id;
  final String companyId;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String? departmentId;
  final String? designationId;
  final String status; // active, suspended, terminated
  final String role; // admin, manager, dispatcher, driver, accountant
  final double baseSalary;
  final double allowance;
  final double deductions;
  final DateTime hiredAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  const EmployeeEntity({
    required this.id,
    required this.companyId,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    this.departmentId,
    this.designationId,
    required this.status,
    required this.role,
    required this.baseSalary,
    required this.allowance,
    required this.deductions,
    required this.hiredAt,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  String get fullName => '$firstName $lastName';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'companyId': companyId,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'phone': phone,
      'departmentId': departmentId,
      'designationId': designationId,
      'status': status,
      'role': role,
      'baseSalary': baseSalary,
      'allowance': allowance,
      'deductions': deductions,
      'hiredAt': hiredAt.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'deletedAt': deletedAt?.toIso8601String(),
    };
  }

  factory EmployeeEntity.fromMap(Map<String, dynamic> map) {
    return EmployeeEntity(
      id: map['id'] as String? ?? '',
      companyId: map['companyId'] as String? ?? '',
      firstName: map['firstName'] as String? ?? '',
      lastName: map['lastName'] as String? ?? '',
      email: map['email'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      departmentId: map['departmentId'] as String?,
      designationId: map['designationId'] as String?,
      status: map['status'] as String? ?? 'active',
      role: map['role'] as String? ?? 'driver',
      baseSalary: (map['baseSalary'] as num? ?? 0.0).toDouble(),
      allowance: (map['allowance'] as num? ?? 0.0).toDouble(),
      deductions: (map['deductions'] as num? ?? 0.0).toDouble(),
      hiredAt: map['hiredAt'] != null
          ? DateTime.parse(map['hiredAt'] as String)
          : DateTime.now(),
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'] as String)
          : DateTime.now(),
      deletedAt: map['deletedAt'] != null
          ? DateTime.parse(map['deletedAt'] as String)
          : null,
    );
  }

  EmployeeEntity copyWith({
    String? id,
    String? companyId,
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    String? departmentId,
    String? designationId,
    String? status,
    String? role,
    double? baseSalary,
    double? allowance,
    double? deductions,
    DateTime? hiredAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return EmployeeEntity(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      departmentId: departmentId ?? this.departmentId,
      designationId: designationId ?? this.designationId,
      status: status ?? this.status,
      role: role ?? this.role,
      baseSalary: baseSalary ?? this.baseSalary,
      allowance: allowance ?? this.allowance,
      deductions: deductions ?? this.deductions,
      hiredAt: hiredAt ?? this.hiredAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }
}
