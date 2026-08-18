/// Represents an enterprise user inside the FleetOS ERP platform.
class UserEntity {
  final String uid;
  final String email;
  final String displayName;
  final String role;
  final String?
      companyId; // Null indicates user has not completed onboarding/company setup
  final DateTime createdAt;
  final bool isActive;

  const UserEntity({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.role,
    this.companyId,
    required this.createdAt,
    this.isActive = true,
  });

  /// Map representations for Firestore operations
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'role': role,
      'companyId': companyId,
      'createdAt': createdAt.toIso8601String(),
      'isActive': isActive,
    };
  }

  /// Create user entity from Firestore document map
  factory UserEntity.fromMap(Map<String, dynamic> map) {
    return UserEntity(
      uid: map['uid'] as String,
      email: map['email'] as String,
      displayName: map['displayName'] as String,
      role: map['role'] as String,
      companyId: map['companyId'] as String?,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : DateTime.now(),
      isActive: map['isActive'] as bool? ?? true,
    );
  }

  /// Implements copyWith for state changes inside presentation controllers
  UserEntity copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? role,
    String? companyId,
    DateTime? createdAt,
    bool? isActive,
  }) {
    return UserEntity(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      role: role ?? this.role,
      companyId: companyId ?? this.companyId,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
    );
  }
}
