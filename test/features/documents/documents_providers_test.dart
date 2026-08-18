import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fleet_os_erp/features/auth/presentation/auth_providers.dart';
import 'package:fleet_os_erp/features/auth/domain/user_entity.dart';
import 'package:fleet_os_erp/features/documents/domain/document_entity.dart';
import 'package:fleet_os_erp/features/documents/domain/document_repository.dart';
import 'package:fleet_os_erp/features/documents/domain/storage_service.dart';
import 'package:fleet_os_erp/features/documents/presentation/document_providers.dart';

class MockCloudStorageService implements CloudStorageService {
  final Map<String, Uint8List> uploadedFiles = {};

  @override
  Future<String> uploadFile({
    required String companyId,
    required String path,
    required Uint8List fileBytes,
    required String fileName,
    required String mimeType,
  }) async {
    final key = 'companies/$companyId/$path';
    uploadedFiles[key] = fileBytes;
    return 'https://mock-storage.com/$key';
  }

  @override
  Future<void> deleteFile({
    required String companyId,
    required String path,
  }) async {
    final key = 'companies/$companyId/$path';
    uploadedFiles.remove(key);
  }

  @override
  Future<Uint8List> downloadFile({
    required String companyId,
    required String path,
  }) async {
    final key = 'companies/$companyId/$path';
    if (!uploadedFiles.containsKey(key)) {
      throw Exception('File not found in Mock Storage');
    }
    return uploadedFiles[key]!;
  }
}

class MockDocumentRepository implements DocumentRepository {
  final List<DocumentEntity> documents = [];

  @override
  Stream<List<DocumentEntity>> watchDocuments(String companyId) =>
      Stream.value(documents);

  @override
  Future<List<DocumentEntity>> getDocuments(String companyId) async =>
      documents;

  @override
  Future<DocumentEntity?> getDocumentById(
      String companyId, String documentId) async {
    try {
      return documents.firstWhere((d) => d.id == documentId);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<DocumentEntity> createDocument(
      String companyId, DocumentEntity document) async {
    final id = document.id.isEmpty ? 'doc_${documents.length}' : document.id;
    final newDoc = document.copyWith(id: id, companyId: companyId);
    final idx = documents.indexWhere((d) => d.id == id);
    if (idx != -1) {
      documents[idx] = newDoc;
    } else {
      documents.add(newDoc);
    }
    return newDoc;
  }

  @override
  Future<void> updateDocument(String companyId, DocumentEntity document) async {
    final idx = documents.indexWhere((d) => d.id == document.id);
    if (idx != -1) {
      documents[idx] = document;
    }
  }

  @override
  Future<void> deleteDocument(String companyId, String documentId) async {
    final idx = documents.indexWhere((d) => d.id == documentId);
    if (idx != -1) {
      documents[idx] = documents[idx].copyWith(deletedAt: DateTime.now());
    }
  }

  @override
  Future<void> restoreDocument(String companyId, String documentId) async {
    final idx = documents.indexWhere((d) => d.id == documentId);
    if (idx != -1) {
      documents[idx] = documents[idx].copyWith(clearDeleted: true);
    }
  }

  @override
  Future<void> renameDocument(
      String companyId, String documentId, String newName) async {
    final idx = documents.indexWhere((d) => d.id == documentId);
    if (idx != -1) {
      documents[idx] = documents[idx].copyWith(fileName: newName);
    }
  }

  @override
  Future<void> replaceDocumentFile(
    String companyId,
    String documentId, {
    required String newDownloadUrl,
    required String newStoragePath,
    required int newSize,
    required String newMimeType,
    required String newOriginalName,
  }) async {
    final idx = documents.indexWhere((d) => d.id == documentId);
    if (idx != -1) {
      documents[idx] = documents[idx].copyWith(
        downloadUrl: newDownloadUrl,
        storagePath: newStoragePath,
        fileSize: newSize,
        mimeType: newMimeType,
        originalFileName: newOriginalName,
        uploadDate: DateTime.now(),
      );
    }
  }
}

void main() {
  group('Document Vault & Cloud Storage Unit Tests', () {
    late ProviderContainer container;
    late MockDocumentRepository docRepo;
    late MockCloudStorageService storageMock;
    late ProviderSubscription formSubscription;
    final now = DateTime.now();

    setUp(() {
      docRepo = MockDocumentRepository();
      storageMock = MockCloudStorageService();
      container = ProviderContainer(
        overrides: [
          currentUserProvider.overrideWith((ref) => UserEntity(
                uid: 'u_1',
                email: 'operator@fleet.com',
                displayName: 'Operator John',
                role: 'admin',
                companyId: 'c_1',
                createdAt: now,
              )),
          documentRepositoryProvider.overrideWithValue(docRepo),
          cloudStorageServiceProvider.overrideWithValue(storageMock),
        ],
      );
      formSubscription =
          container.listen(documentFormControllerProvider, (_, __) {});
    });

    tearDown(() {
      formSubscription.close();
      container.dispose();
    });

    test('Selected category filter defaults to all', () {
      expect(container.read(selectedDocumentCategoryProvider), 'all');
    });

    test('saveDocument uploads file to storage and saves document metadata',
        () async {
      final doc = DocumentEntity(
        id: '',
        companyId: '',
        fileName: 'GST Certificate 2026',
        category: 'company',
        type: 'gst_certificate',
        originalFileName: 'gst.pdf',
        fileSize: 150000,
        mimeType: 'application/pdf',
        storagePath: 'documents/gst.pdf',
        downloadUrl: '',
        uploadDate: now,
        status: 'pending_verification',
        uploadedBy: 'Operator John',
        documentNumber: 'GST-9988-12',
        createdAt: now,
        updatedAt: now,
      );

      final mockBytes = Uint8List.fromList([1, 2, 3]);
      final success = await container
          .read(documentFormControllerProvider.notifier)
          .saveDocument(doc, fileBytes: mockBytes);

      expect(success, true);

      // Verify storage upload
      expect(
          storageMock.uploadedFiles
              .containsKey('companies/c_1/documents/gst.pdf'),
          true);

      // Verify firestore record
      final list = await docRepo.getDocuments('c_1');
      expect(list.length, 1);
      expect(list.first.downloadUrl,
          'https://mock-storage.com/companies/c_1/documents/gst.pdf');
    });

    test(
        'Business Validation: Exceeding maximum file size limit fails validation',
        () async {
      final largeDoc = DocumentEntity(
        id: '',
        companyId: '',
        fileName: 'Huge Invoice',
        category: 'finance',
        type: 'invoice',
        originalFileName: 'invoice_11mb.pdf',
        fileSize: 11 * 1024 * 1024, // 11MB
        mimeType: 'application/pdf',
        storagePath: 'documents/huge.pdf',
        downloadUrl: '',
        uploadDate: now,
        status: 'pending_verification',
        uploadedBy: 'Operator John',
        documentNumber: 'INV-001',
        createdAt: now,
        updatedAt: now,
      );

      final success = await container
          .read(documentFormControllerProvider.notifier)
          .saveDocument(largeDoc);

      expect(success, false);
      expect(container.read(documentFormControllerProvider).errorMessage,
          contains('File size exceeds the 10MB maximum limit'));
    });

    test('Business Validation: Disallowed format fails validation', () async {
      final badDoc = DocumentEntity(
        id: '',
        companyId: '',
        fileName: 'Dangerous Script',
        category: 'company',
        type: 'other',
        originalFileName: 'malware.exe',
        fileSize: 12000,
        mimeType: 'application/octet-stream',
        storagePath: 'documents/malware.exe',
        downloadUrl: '',
        uploadDate: now,
        status: 'pending_verification',
        uploadedBy: 'Operator John',
        documentNumber: 'BAD-01',
        createdAt: now,
        updatedAt: now,
      );

      final success = await container
          .read(documentFormControllerProvider.notifier)
          .saveDocument(badDoc);

      expect(success, false);
      expect(container.read(documentFormControllerProvider).errorMessage,
          contains('Only PDF, JPEG, PNG, DOCX, and XLSX files are permitted'));
    });

    test('Business Validation: Duplicate detection fails validation', () async {
      final doc1 = DocumentEntity(
        id: 'd_1',
        companyId: 'c_1',
        fileName: 'PAN Card',
        category: 'company',
        type: 'pan',
        originalFileName: 'pan.jpg',
        fileSize: 200000,
        mimeType: 'image/jpeg',
        storagePath: 'documents/pan.jpg',
        downloadUrl: 'https://mock-storage/pan.jpg',
        uploadDate: now,
        status: 'verified',
        uploadedBy: 'Operator John',
        documentNumber: 'PAN-123',
        createdAt: now,
        updatedAt: now,
      );

      await docRepo.createDocument('c_1', doc1);

      // Try to save duplicate (same name, category, and size)
      final doc2 = DocumentEntity(
        id: '',
        companyId: '',
        fileName: 'PAN Card',
        category: 'company',
        type: 'pan',
        originalFileName: 'pan_new.jpg',
        fileSize: 200000,
        mimeType: 'image/jpeg',
        storagePath: 'documents/pan_new.jpg',
        downloadUrl: '',
        uploadDate: now,
        status: 'pending_verification',
        uploadedBy: 'Operator John',
        documentNumber: 'PAN-123-NEW',
        createdAt: now,
        updatedAt: now,
      );

      // Force Riverpod to watch and cache documents list
      container.read(documentsStreamProvider);
      await pumpEventQueue();

      final success = await container
          .read(documentFormControllerProvider.notifier)
          .saveDocument(doc2);

      expect(success, false);
      expect(container.read(documentFormControllerProvider).errorMessage,
          contains('A document with this name and file size already exists'));
    });

    test('replaceDocumentFile updates storage files and triggers log events',
        () async {
      final doc = DocumentEntity(
        id: 'target_id_1',
        companyId: 'c_1',
        fileName: 'Freight Contract',
        category: 'customer',
        type: 'contract',
        originalFileName: 'contract_v1.pdf',
        fileSize: 500000,
        mimeType: 'application/pdf',
        storagePath: 'documents/contract_v1.pdf',
        downloadUrl: 'https://mock-storage/contract_v1.pdf',
        uploadDate: now,
        status: 'verified',
        uploadedBy: 'Operator John',
        documentNumber: 'CTR-001',
        createdAt: now,
        updatedAt: now,
      );

      await docRepo.createDocument('c_1', doc);

      final newBytes = Uint8List.fromList([9, 8, 7]);
      final success = await container
          .read(documentFormControllerProvider.notifier)
          .replaceDocumentFile(
            'target_id_1',
            fileBytes: newBytes,
            originalFileName: 'contract_v2.pdf',
            mimeType: 'application/pdf',
            fileSize: 550000,
          );

      expect(success, true);
      final updated = await docRepo.getDocumentById('c_1', 'target_id_1');
      expect(updated!.originalFileName, 'contract_v2.pdf');
      expect(updated.fileSize, 550000);
      expect(updated.downloadUrl, contains('contract_v2.pdf'));
    });

    test('renameDocument changes title', () async {
      final doc = DocumentEntity(
        id: 'target_id_2',
        companyId: 'c_1',
        fileName: 'RC Copy',
        category: 'vehicle',
        type: 'rc',
        originalFileName: 'rc.jpg',
        fileSize: 120000,
        mimeType: 'image/jpeg',
        storagePath: 'documents/rc.jpg',
        downloadUrl: 'https://mock-storage/rc.jpg',
        uploadDate: now,
        status: 'pending_verification',
        uploadedBy: 'Operator John',
        documentNumber: 'RC-99',
        createdAt: now,
        updatedAt: now,
      );

      await docRepo.createDocument('c_1', doc);

      final success = await container
          .read(documentFormControllerProvider.notifier)
          .renameDocument('target_id_2', 'Volvo RC 2026');

      expect(success, true);
      final updated = await docRepo.getDocumentById('c_1', 'target_id_2');
      expect(updated!.fileName, 'Volvo RC 2026');
    });

    test('restoreDocument clears deletedAt and returns to active vault',
        () async {
      final doc = DocumentEntity(
        id: 'deleted_doc_id',
        companyId: 'c_1',
        fileName: 'Tax receipt',
        category: 'finance',
        type: 'road_tax',
        originalFileName: 'tax.pdf',
        fileSize: 85000,
        mimeType: 'application/pdf',
        storagePath: 'documents/tax.pdf',
        downloadUrl: 'https://mock-storage/tax.pdf',
        uploadDate: now,
        status: 'verified',
        uploadedBy: 'Operator John',
        documentNumber: 'TAX-001',
        createdAt: now,
        updatedAt: now,
        deletedAt: now,
      );

      await docRepo.createDocument('c_1', doc);

      final success = await container
          .read(documentFormControllerProvider.notifier)
          .restoreDocument('deleted_doc_id');

      expect(success, true);
      final updated = await docRepo.getDocumentById('c_1', 'deleted_doc_id');
      expect(updated!.deletedAt, isNull);
    });
  });
}
