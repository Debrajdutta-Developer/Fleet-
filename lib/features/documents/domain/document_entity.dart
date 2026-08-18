class DocumentEntity {
  final String id;
  final String companyId;
  final String? relatedEntityId;
  final String? relatedEntityType;
  final String? entityName;
  final String category;
  final String type;
  final String fileName;
  final String originalFileName;
  final int fileSize;
  final String mimeType;
  final String storagePath;
  final String downloadUrl;
  final DateTime uploadDate;
  final DateTime? expiryDate;
  final String uploadedBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final String status;
  final String? notes;
  final String documentNumber;
  final String? verifiedBy;
  final DateTime? verifiedAt;

  const DocumentEntity({
    required this.id,
    required this.companyId,
    this.relatedEntityId,
    this.relatedEntityType,
    this.entityName,
    required this.category,
    required this.type,
    required this.fileName,
    required this.originalFileName,
    required this.fileSize,
    required this.mimeType,
    required this.storagePath,
    required this.downloadUrl,
    required this.uploadDate,
    this.expiryDate,
    required this.uploadedBy,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.status,
    this.notes,
    required this.documentNumber,
    this.verifiedBy,
    this.verifiedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'companyId': companyId,
      'relatedEntityId': relatedEntityId,
      'relatedEntityType': relatedEntityType,
      'entityName': entityName,
      'category': category,
      'type': type,
      'fileName': fileName,
      'originalFileName': originalFileName,
      'fileSize': fileSize,
      'mimeType': mimeType,
      'storagePath': storagePath,
      'downloadUrl': downloadUrl,
      'uploadDate': uploadDate.toIso8601String(),
      'expiryDate': expiryDate?.toIso8601String(),
      'uploadedBy': uploadedBy,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'deletedAt': deletedAt?.toIso8601String(),
      'status': status,
      'notes': notes,
      'documentNumber': documentNumber,
      'verifiedBy': verifiedBy,
      'verifiedAt': verifiedAt?.toIso8601String(),
    };
  }

  factory DocumentEntity.fromMap(Map<String, dynamic> map) {
    return DocumentEntity(
      id: map['id'] as String? ?? '',
      companyId: map['companyId'] as String? ?? '',
      relatedEntityId: map['relatedEntityId'] as String?,
      relatedEntityType: map['relatedEntityType'] as String?,
      entityName: map['entityName'] as String?,
      category: map['category'] as String? ?? 'company',
      type: map['type'] as String? ?? 'other',
      fileName: map['fileName'] as String? ?? '',
      originalFileName: map['originalFileName'] as String? ?? '',
      fileSize: map['fileSize'] as int? ?? 0,
      mimeType: map['mimeType'] as String? ?? '',
      storagePath: map['storagePath'] as String? ?? '',
      downloadUrl: map['downloadUrl'] as String? ?? '',
      uploadDate: map['uploadDate'] != null
          ? DateTime.parse(map['uploadDate'] as String)
          : DateTime.now(),
      expiryDate: map['expiryDate'] != null
          ? DateTime.parse(map['expiryDate'] as String)
          : null,
      uploadedBy: map['uploadedBy'] as String? ?? '',
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'] as String)
          : DateTime.now(),
      deletedAt: map['deletedAt'] != null
          ? DateTime.parse(map['deletedAt'] as String)
          : null,
      status: map['status'] as String? ?? 'pending_verification',
      notes: map['notes'] as String?,
      documentNumber: map['documentNumber'] as String? ?? '',
      verifiedBy: map['verifiedBy'] as String?,
      verifiedAt: map['verifiedAt'] != null
          ? DateTime.parse(map['verifiedAt'] as String)
          : null,
    );
  }

  DocumentEntity copyWith({
    String? id,
    String? companyId,
    String? relatedEntityId,
    String? relatedEntityType,
    String? entityName,
    String? category,
    String? type,
    String? fileName,
    String? originalFileName,
    int? fileSize,
    String? mimeType,
    String? storagePath,
    String? downloadUrl,
    DateTime? uploadDate,
    DateTime? expiryDate,
    String? uploadedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    String? status,
    String? notes,
    String? documentNumber,
    String? verifiedBy,
    DateTime? verifiedAt,
    bool clearExpiry = false,
    bool clearDeleted = false,
  }) {
    return DocumentEntity(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      relatedEntityId: relatedEntityId ?? this.relatedEntityId,
      relatedEntityType: relatedEntityType ?? this.relatedEntityType,
      entityName: entityName ?? this.entityName,
      category: category ?? this.category,
      type: type ?? this.type,
      fileName: fileName ?? this.fileName,
      originalFileName: originalFileName ?? this.originalFileName,
      fileSize: fileSize ?? this.fileSize,
      mimeType: mimeType ?? this.mimeType,
      storagePath: storagePath ?? this.storagePath,
      downloadUrl: downloadUrl ?? this.downloadUrl,
      uploadDate: uploadDate ?? this.uploadDate,
      expiryDate: clearExpiry ? null : (expiryDate ?? this.expiryDate),
      uploadedBy: uploadedBy ?? this.uploadedBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: clearDeleted ? null : (deletedAt ?? this.deletedAt),
      status: status ?? this.status,
      notes: notes ?? this.notes,
      documentNumber: documentNumber ?? this.documentNumber,
      verifiedBy: verifiedBy ?? this.verifiedBy,
      verifiedAt: verifiedAt ?? this.verifiedAt,
    );
  }
}
