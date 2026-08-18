class DepartmentEntity {
  final String id;
  final String companyId;
  final String name;
  final String description;
  final String? managerId; // References Employee ID
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  const DepartmentEntity({
    required this.id,
    required this.companyId,
    required this.name,
    required this.description,
    this.managerId,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'companyId': companyId,
      'name': name,
      'description': description,
      'managerId': managerId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'deletedAt': deletedAt?.toIso8601String(),
    };
  }

  factory DepartmentEntity.fromMap(Map<String, dynamic> map) {
    return DepartmentEntity(
      id: map['id'] as String? ?? '',
      companyId: map['companyId'] as String? ?? '',
      name: map['name'] as String? ?? '',
      description: map['description'] as String? ?? '',
      managerId: map['managerId'] as String?,
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

  DepartmentEntity copyWith({
    String? id,
    String? companyId,
    String? name,
    String? description,
    String? managerId,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return DepartmentEntity(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      name: name ?? this.name,
      description: description ?? this.description,
      managerId: managerId ?? this.managerId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }
}
