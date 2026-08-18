import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../../auth/presentation/auth_providers.dart';
import '../../trips/domain/audit_log_entity.dart';
import '../domain/document_entity.dart';
import '../domain/document_repository.dart';
import '../data/document_repository_impl.dart';
import '../domain/storage_service.dart';
import '../data/storage_service_impl.dart';

// --- Cloud Storage Service Provider ---
final cloudStorageServiceProvider = Provider<CloudStorageService>((ref) {
  return FirebaseStorageService();
});

// --- Repository Provider ---
final documentRepositoryProvider = Provider<DocumentRepository>((ref) {
  return DocumentRepositoryImpl();
});

// --- Stream Provider for Documents ---
final documentsStreamProvider =
    StreamProvider.autoDispose<List<DocumentEntity>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user?.companyId == null) return Stream.value([]);
  return ref.watch(documentRepositoryProvider).watchDocuments(user!.companyId!);
});

// --- State Providers for Filtering & Sorting ---
final selectedDocumentCategoryProvider = StateProvider<String>((ref) => 'all');
final selectedDocumentTypeProvider = StateProvider<String>((ref) => 'all');
final documentSearchQueryProvider = StateProvider<String>((ref) => '');
final documentSortOptionProvider = StateProvider<String>((ref) =>
    'date_uploaded_desc'); // name_asc, name_desc, expiry_asc, date_uploaded_desc
final showDeletedDocumentsProvider = StateProvider<bool>((ref) => false);
final selectedEntityFilterProvider = StateProvider<String?>((ref) => null);

// --- Filtered & Sorted Documents Provider ---
final filteredDocumentsProvider =
    Provider.autoDispose<List<DocumentEntity>>((ref) {
  final docsAsync = ref.watch(documentsStreamProvider);
  final category = ref.watch(selectedDocumentCategoryProvider);
  final type = ref.watch(selectedDocumentTypeProvider);
  final query = ref.watch(documentSearchQueryProvider).toLowerCase();
  final sort = ref.watch(documentSortOptionProvider);
  final showDeleted = ref.watch(showDeletedDocumentsProvider);
  final entityId = ref.watch(selectedEntityFilterProvider);

  final list = docsAsync.valueOrNull ?? [];

  var filtered = list.where((doc) {
    // 1. Soft-delete check
    if (showDeleted) {
      if (doc.deletedAt == null) return false; // Show ONLY deleted documents
    } else {
      if (doc.deletedAt != null) return false; // Hide deleted documents
    }

    // 2. Category filter
    if (category != 'all' && doc.category != category) return false;

    // 3. Type filter
    if (type != 'all' && doc.type != type) return false;

    // 4. Entity filter
    if (entityId != null && doc.relatedEntityId != entityId) return false;

    // 5. Search query
    if (query.isNotEmpty) {
      final name = doc.fileName.toLowerCase();
      final orig = doc.originalFileName.toLowerCase();
      final num = doc.documentNumber.toLowerCase();
      final entity = (doc.entityName ?? '').toLowerCase();
      return name.contains(query) ||
          orig.contains(query) ||
          num.contains(query) ||
          entity.contains(query);
    }

    return true;
  }).toList();

  // Sort
  switch (sort) {
    case 'name_asc':
      filtered.sort((a, b) => a.fileName.compareTo(b.fileName));
      break;
    case 'name_desc':
      filtered.sort((a, b) => b.fileName.compareTo(a.fileName));
      break;
    case 'expiry_asc':
      // Put documents with expiry dates first
      filtered.sort((a, b) {
        if (a.expiryDate == null && b.expiryDate == null) return 0;
        if (a.expiryDate == null) return 1;
        if (b.expiryDate == null) return -1;
        return a.expiryDate!.compareTo(b.expiryDate!);
      });
      break;
    case 'date_uploaded_desc':
    default:
      filtered.sort((a, b) => b.uploadDate.compareTo(a.uploadDate));
      break;
  }

  return filtered;
});

// --- UI Form State with Upload Progress Simulation ---
class DocumentFormState {
  final bool isLoading;
  final double uploadProgress; // From 0.0 to 1.0
  final String? errorMessage;
  final bool isCompleted;

  const DocumentFormState({
    this.isLoading = false,
    this.uploadProgress = 0.0,
    this.errorMessage,
    this.isCompleted = false,
  });

  DocumentFormState copyWith({
    bool? isLoading,
    double? uploadProgress,
    String? errorMessage,
    bool? isCompleted,
  }) {
    return DocumentFormState(
      isLoading: isLoading ?? this.isLoading,
      uploadProgress: uploadProgress ?? this.uploadProgress,
      errorMessage: errorMessage ?? this.errorMessage,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}

class DocumentFormController extends StateNotifier<DocumentFormState> {
  final DocumentRepository _repo;
  final CloudStorageService _storage;
  final Ref _ref;

  DocumentFormController({
    required DocumentRepository repo,
    required CloudStorageService storage,
    required Ref ref,
  })  : _repo = repo,
        _storage = storage,
        _ref = ref,
        super(const DocumentFormState());

  // Business Rule Validations
  void validateDocument(DocumentEntity doc, List<DocumentEntity> existingList) {
    // 1. Required Metadata Validation
    if (doc.fileName.trim().isEmpty) {
      throw Exception('Validation Error: Document Name cannot be empty.');
    }
    if (doc.documentNumber.trim().isEmpty) {
      throw Exception(
          'Validation Error: Reference number / ID cannot be empty.');
    }
    if (doc.storagePath.trim().isEmpty) {
      throw Exception('Validation Error: Storage Path is required.');
    }

    // 2. Maximum File Size Validation (10MB limit)
    const maxBytes = 10 * 1024 * 1024;
    if (doc.fileSize > maxBytes) {
      throw Exception(
          'Validation Error: File size exceeds the 10MB maximum limit.');
    }

    // 3. Allowed File Types Validation
    final allowedMimeTypes = [
      'application/pdf',
      'image/jpeg',
      'image/png',
      'application/vnd.openxmlformats-officedocument.wordprocessingml.document', // DOCX
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet', // XLSX
    ];
    if (!allowedMimeTypes.contains(doc.mimeType) && doc.mimeType.isNotEmpty) {
      throw Exception(
          'Validation Error: Only PDF, JPEG, PNG, DOCX, and XLSX files are permitted.');
    }

    // 4. Duplicate Detection (check by fileName, category, and size)
    final isDuplicate = existingList.any((e) =>
        e.id != doc.id &&
        e.deletedAt == null &&
        e.fileName.toLowerCase() == doc.fileName.toLowerCase() &&
        e.category == doc.category &&
        e.fileSize == doc.fileSize);

    if (isDuplicate) {
      throw Exception(
          'Validation Error: A document with this name and file size already exists.');
    }
  }

  Future<bool> saveDocument(DocumentEntity doc, {Uint8List? fileBytes}) async {
    state = const DocumentFormState(isLoading: true, uploadProgress: 0.0);
    try {
      final user = _ref.read(currentUserProvider);
      if (user?.companyId == null)
        throw Exception('No company session context.');
      final companyId = user!.companyId!;

      final existingDocs = await _repo.getDocuments(companyId);

      // Perform local business rule validations
      validateDocument(doc, existingDocs);

      var finalUrl = doc.downloadUrl;

      // Simulate Upload Progress if fileBytes are provided
      if (fileBytes != null) {
        for (var progress = 0.1; progress <= 0.9; progress += 0.2) {
          await Future<void>.delayed(const Duration(milliseconds: 150));
          state = state.copyWith(uploadProgress: progress);
        }

        // Trigger abstract storage service upload
        finalUrl = await _storage.uploadFile(
          companyId: companyId,
          path: doc.storagePath,
          fileBytes: fileBytes,
          fileName: doc.originalFileName,
          mimeType: doc.mimeType,
        );

        state = state.copyWith(uploadProgress: 1.0);
      }

      final isEdit = doc.id.isNotEmpty;
      final savedDoc = await _repo.createDocument(
        companyId,
        doc.copyWith(
          downloadUrl: finalUrl,
          uploadedBy: user.displayName,
          uploadDate: DateTime.now(),
        ),
      );

      // Write Audit Log
      await _writeAuditLog(
        action: isEdit ? 'document_updated' : 'document_uploaded',
        description:
            'Document "${savedDoc.fileName}" (${savedDoc.mimeType}) ${isEdit ? "updated" : "uploaded"} by ${user.displayName}',
        entityId: savedDoc.id,
      );

      state = const DocumentFormState(isCompleted: true);
      return true;
    } catch (e) {
      state = DocumentFormState(
          errorMessage: e.toString().replaceAll('Exception: ', ''));
      return false;
    }
  }

  Future<bool> replaceDocumentFile(
    String docId, {
    required Uint8List fileBytes,
    required String originalFileName,
    required String mimeType,
    required int fileSize,
  }) async {
    state = const DocumentFormState(isLoading: true, uploadProgress: 0.0);
    try {
      final user = _ref.read(currentUserProvider);
      if (user?.companyId == null)
        throw Exception('No company session context.');

      final doc = await _repo.getDocumentById(user!.companyId!, docId);
      if (doc == null) throw Exception('Document not found.');

      // Check max size validation
      const maxBytes = 10 * 1024 * 1024;
      if (fileSize > maxBytes) {
        throw Exception(
            'Validation Error: File size exceeds the 10MB maximum limit.');
      }

      // Simulate Upload Progress
      for (var progress = 0.1; progress <= 0.9; progress += 0.2) {
        await Future<void>.delayed(const Duration(milliseconds: 150));
        state = state.copyWith(uploadProgress: progress);
      }

      // Upload replacement file
      final storagePath =
          'replaced_${DateTime.now().millisecondsSinceEpoch}_$originalFileName';
      final newUrl = await _storage.uploadFile(
        companyId: user.companyId!,
        path: storagePath,
        fileBytes: fileBytes,
        fileName: originalFileName,
        mimeType: mimeType,
      );

      state = state.copyWith(uploadProgress: 1.0);

      await _repo.replaceDocumentFile(
        user.companyId!,
        docId,
        newDownloadUrl: newUrl,
        newStoragePath: storagePath,
        newSize: fileSize,
        newMimeType: mimeType,
        newOriginalName: originalFileName,
      );

      // Write Audit Log
      await _writeAuditLog(
        action: 'document_replaced',
        description:
            'File replaced on Document "${doc.fileName}" with "$originalFileName" by ${user.displayName}',
        entityId: docId,
      );

      state = const DocumentFormState(isCompleted: true);
      return true;
    } catch (e) {
      state = DocumentFormState(
          errorMessage: e.toString().replaceAll('Exception: ', ''));
      return false;
    }
  }

  Future<bool> renameDocument(String docId, String newName) async {
    state = const DocumentFormState(isLoading: true);
    try {
      final user = _ref.read(currentUserProvider);
      if (user?.companyId == null)
        throw Exception('No company session context.');

      if (newName.trim().isEmpty)
        throw Exception('New document name cannot be empty.');

      final doc = await _repo.getDocumentById(user!.companyId!, docId);
      if (doc == null) throw Exception('Document not found.');

      await _repo.renameDocument(user.companyId!, docId, newName);

      // Write Audit Log
      await _writeAuditLog(
        action: 'document_updated',
        description:
            'Document "${doc.fileName}" renamed to "$newName" by ${user.displayName}',
        entityId: docId,
      );

      state = const DocumentFormState(isCompleted: true);
      return true;
    } catch (e) {
      state = DocumentFormState(
          errorMessage: e.toString().replaceAll('Exception: ', ''));
      return false;
    }
  }

  Future<bool> verifyDocument(String docId, String status, String? note) async {
    state = const DocumentFormState(isLoading: true);
    try {
      final user = _ref.read(currentUserProvider);
      if (user?.companyId == null)
        throw Exception('No company session context.');

      final doc = await _repo.getDocumentById(user!.companyId!, docId);
      if (doc == null) throw Exception('Document not found.');

      final updatedDoc = doc.copyWith(
        status: status,
        notes: note,
        verifiedBy: user.displayName,
        verifiedAt: DateTime.now(),
      );

      await _repo.updateDocument(user.companyId!, updatedDoc);

      // Write Audit Log
      await _writeAuditLog(
        action: 'document_verified',
        description:
            'Document "${doc.fileName}" marked as $status by ${user.displayName}',
        entityId: docId,
      );

      state = const DocumentFormState(isCompleted: true);
      return true;
    } catch (e) {
      state = DocumentFormState(errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> deleteDocument(String docId) async {
    state = const DocumentFormState(isLoading: true);
    try {
      final user = _ref.read(currentUserProvider);
      if (user?.companyId == null)
        throw Exception('No company session context.');

      final doc = await _repo.getDocumentById(user!.companyId!, docId);
      if (doc == null) throw Exception('Document not found.');

      await _repo.deleteDocument(user.companyId!, docId);

      // Write Audit Log
      await _writeAuditLog(
        action: 'document_deleted',
        description:
            'Document "${doc.fileName}" soft-deleted by ${user.displayName}',
        entityId: docId,
      );

      state = const DocumentFormState(isCompleted: true);
      return true;
    } catch (e) {
      state = DocumentFormState(errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> restoreDocument(String docId) async {
    state = const DocumentFormState(isLoading: true);
    try {
      final user = _ref.read(currentUserProvider);
      if (user?.companyId == null)
        throw Exception('No company session context.');

      final doc = await _repo.getDocumentById(user!.companyId!, docId);
      if (doc == null) throw Exception('Document not found.');

      await _repo.restoreDocument(user.companyId!, docId);

      // Write Audit Log
      await _writeAuditLog(
        action: 'document_restored',
        description:
            'Document "${doc.fileName}" restored to vault by ${user.displayName}',
        entityId: docId,
      );

      state = const DocumentFormState(isCompleted: true);
      return true;
    } catch (e) {
      state = DocumentFormState(errorMessage: e.toString());
      return false;
    }
  }

  Future<void> simulateDownload(String docId) async {
    try {
      final user = _ref.read(currentUserProvider);
      if (user?.companyId == null) return;

      final doc = await _repo.getDocumentById(user!.companyId!, docId);
      if (doc == null) return;

      // Write Audit Log
      await _writeAuditLog(
        action: 'document_downloaded',
        description:
            'Document file "${doc.fileName}" downloaded by ${user.displayName}',
        entityId: docId,
      );
    } catch (_) {}
  }

  Future<void> _writeAuditLog({
    required String action,
    required String description,
    required String entityId,
  }) async {
    try {
      final user = _ref.read(currentUserProvider);
      if (user?.companyId == null) return;
      final companyId = user!.companyId!;

      final auditLog = AuditLogEntity(
        id: const Uuid().v4(),
        companyId: companyId,
        entityType: 'document',
        entityId: entityId,
        action: action,
        description: description,
        userId: user.uid,
        userName: user.displayName,
        timestamp: DateTime.now(),
      );

      await FirebaseFirestore.instance
          .collection('companies')
          .doc(user.companyId)
          .collection('audit_logs')
          .doc(auditLog.id)
          .set(auditLog.toMap());
    } catch (e) {
      // Gracefully handle Firestore failures in tests/offline environments
      debugPrint('Audit log write failed: $e');
    }
  }
}

final documentFormControllerProvider = StateNotifierProvider.autoDispose<
    DocumentFormController, DocumentFormState>((ref) {
  return DocumentFormController(
    repo: ref.watch(documentRepositoryProvider),
    storage: ref.watch(cloudStorageServiceProvider),
    ref: ref,
  );
});
