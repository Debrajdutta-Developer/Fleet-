class DesignationEntity {
  final String id;
  final String companyId;
  final String title;
  final String description;
  final String departmentId; // References Department ID
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  const DesignationEntity({
    required this.id,
    required this.companyId,
    required this.title,
    required this.description,
    required this.departmentId,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'companyId': companyId,
      'title': title,
      'description': description,
      'departmentId': departmentId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'deletedAt': deletedAt?.toIso8601String(),
    };
  }

  factory DesignationEntity.fromMap(Map<String, dynamic> map) {
    return DesignationEntity(
      id: map['id'] as String? ?? '',
      companyId: map['companyId'] as String? ?? '',
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      departmentId: map['departmentId'] as String? ?? '',
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

  DesignationEntity copyWith({
    String? id,
    String? companyId,
    String? title,
    String? description,
    String? departmentId,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return DesignationEntity(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      title: title ?? this.title,
      description: description ?? this.description,
      departmentId: departmentId ?? this.departmentId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }
}
