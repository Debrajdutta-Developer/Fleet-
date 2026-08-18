class RouteEntity {
  final String id;
  final String name;
  final String startLocation;
  final String endLocation;
  final double distanceKm;
  final int estimatedDurationMinutes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  const RouteEntity({
    required this.id,
    required this.name,
    required this.startLocation,
    required this.endLocation,
    required this.distanceKm,
    required this.estimatedDurationMinutes,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'startLocation': startLocation,
      'endLocation': endLocation,
      'distanceKm': distanceKm,
      'estimatedDurationMinutes': estimatedDurationMinutes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'deletedAt': deletedAt?.toIso8601String(),
    };
  }

  factory RouteEntity.fromMap(Map<String, dynamic> map) {
    return RouteEntity(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      startLocation: map['startLocation'] as String? ?? '',
      endLocation: map['endLocation'] as String? ?? '',
      distanceKm: (map['distanceKm'] as num? ?? 0.0).toDouble(),
      estimatedDurationMinutes: map['estimatedDurationMinutes'] as int? ?? 0,
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

  RouteEntity copyWith({
    String? id,
    String? name,
    String? startLocation,
    String? endLocation,
    double? distanceKm,
    int? estimatedDurationMinutes,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return RouteEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      startLocation: startLocation ?? this.startLocation,
      endLocation: endLocation ?? this.endLocation,
      distanceKm: distanceKm ?? this.distanceKm,
      estimatedDurationMinutes:
          estimatedDurationMinutes ?? this.estimatedDurationMinutes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }
}
