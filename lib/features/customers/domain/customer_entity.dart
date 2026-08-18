class ContactPerson {
  final String name;
  final String email;
  final String phone;
  final String role;

  const ContactPerson({
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'role': role,
    };
  }

  factory ContactPerson.fromMap(Map<String, dynamic> map) {
    return ContactPerson(
      name: map['name'] as String? ?? '',
      email: map['email'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      role: map['role'] as String? ?? '',
    );
  }
}

class CustomerEntity {
  final String id;
  final String name;
  final String contactName;
  final String email;
  final String phone;
  final String address;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  // Sprint 2.6 additions
  final List<ContactPerson> contacts;
  final double creditLimit;
  final double outstandingBalance;

  const CustomerEntity({
    required this.id,
    required this.name,
    required this.contactName,
    required this.email,
    required this.phone,
    required this.address,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.contacts = const [],
    this.creditLimit = 0.0,
    this.outstandingBalance = 0.0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'contactName': contactName,
      'email': email,
      'phone': phone,
      'address': address,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'deletedAt': deletedAt?.toIso8601String(),
      'contacts': contacts.map((c) => c.toMap()).toList(),
      'creditLimit': creditLimit,
      'outstandingBalance': outstandingBalance,
    };
  }

  factory CustomerEntity.fromMap(Map<String, dynamic> map) {
    final contactsList = map['contacts'] as List<dynamic>? ?? [];
    return CustomerEntity(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      contactName: map['contactName'] as String? ?? '',
      email: map['email'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      address: map['address'] as String? ?? '',
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'] as String)
          : DateTime.now(),
      deletedAt: map['deletedAt'] != null
          ? DateTime.parse(map['deletedAt'] as String)
          : null,
      contacts: contactsList
          .map(
              (c) => ContactPerson.fromMap(Map<String, dynamic>.from(c as Map)))
          .toList(),
      creditLimit: (map['creditLimit'] as num? ?? 0.0).toDouble(),
      outstandingBalance: (map['outstandingBalance'] as num? ?? 0.0).toDouble(),
    );
  }

  CustomerEntity copyWith({
    String? id,
    String? name,
    String? contactName,
    String? email,
    String? phone,
    String? address,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    List<ContactPerson>? contacts,
    double? creditLimit,
    double? outstandingBalance,
  }) {
    return CustomerEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      contactName: contactName ?? this.contactName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      contacts: contacts ?? this.contacts,
      creditLimit: creditLimit ?? this.creditLimit,
      outstandingBalance: outstandingBalance ?? this.outstandingBalance,
    );
  }
}
