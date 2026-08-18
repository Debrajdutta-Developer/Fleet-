/// Represents a registered Company/Tenant in the multi-tenant FleetOS ERP database.
class CompanyEntity {
  final String id; // Unique companyId
  final String name; // Company Name
  final String ownerName; // Owner Name
  final String ownerUid; // Linked Authenticated User UID as Owner
  final String? gstNumber; // GST Number (optional)
  final String? panNumber; // PAN Number (optional)
  final String phone; // Company Phone
  final String email; // Company Email
  final String address; // Company Address
  final String logoUrl; // Company Brand Logo
  final String defaultCurrency; // Default Currency (e.g., USD, INR)
  final String timeZone; // Preferred Time Zone (e.g., UTC, IST)
  final DateTime createdAt;
  final bool isSetupComplete;

  const CompanyEntity({
    required this.id,
    required this.name,
    required this.ownerName,
    required this.ownerUid,
    this.gstNumber,
    this.panNumber,
    required this.phone,
    required this.email,
    required this.address,
    this.logoUrl = '',
    required this.defaultCurrency,
    required this.timeZone,
    required this.createdAt,
    this.isSetupComplete = false,
  });

  /// Map representations for Firestore operations
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'ownerName': ownerName,
      'ownerUid': ownerUid,
      'gstNumber': gstNumber,
      'panNumber': panNumber,
      'phone': phone,
      'email': email,
      'address': address,
      'logoUrl': logoUrl,
      'defaultCurrency': defaultCurrency,
      'timeZone': timeZone,
      'createdAt': createdAt.toIso8601String(),
      'isSetupComplete': isSetupComplete,
    };
  }

  /// Create company entity from Firestore document map
  factory CompanyEntity.fromMap(Map<String, dynamic> map) {
    return CompanyEntity(
      id: map['id'] as String,
      name: map['name'] as String,
      ownerName: map['ownerName'] as String? ?? '',
      ownerUid: map['ownerUid'] as String? ?? map['adminUid'] as String? ?? '',
      gstNumber: map['gstNumber'] as String?,
      panNumber: map['panNumber'] as String?,
      phone: map['phone'] as String? ?? '',
      email: map['email'] as String? ?? '',
      address: map['address'] as String? ?? '',
      logoUrl: map['logoUrl'] as String? ?? '',
      defaultCurrency: map['defaultCurrency'] as String? ?? 'USD',
      timeZone: map['timeZone'] as String? ?? 'UTC',
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : DateTime.now(),
      isSetupComplete: map['isSetupComplete'] as bool? ?? false,
    );
  }

  /// Implements copyWith for updates
  CompanyEntity copyWith({
    String? id,
    String? name,
    String? ownerName,
    String? ownerUid,
    String? gstNumber,
    String? panNumber,
    String? phone,
    String? email,
    String? address,
    String? logoUrl,
    String? defaultCurrency,
    String? timeZone,
    DateTime? createdAt,
    bool? isSetupComplete,
  }) {
    return CompanyEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      ownerName: ownerName ?? this.ownerName,
      ownerUid: ownerUid ?? this.ownerUid,
      gstNumber: gstNumber ?? this.gstNumber,
      panNumber: panNumber ?? this.panNumber,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      logoUrl: logoUrl ?? this.logoUrl,
      defaultCurrency: defaultCurrency ?? this.defaultCurrency,
      timeZone: timeZone ?? this.timeZone,
      createdAt: createdAt ?? this.createdAt,
      isSetupComplete: isSetupComplete ?? this.isSetupComplete,
    );
  }
}
