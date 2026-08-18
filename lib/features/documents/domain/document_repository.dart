import 'document_entity.dart';

abstract class DocumentRepository {
  Stream<List<DocumentEntity>> watchDocuments(String companyId);
  Future<List<DocumentEntity>> getDocuments(String companyId);
  Future<DocumentEntity?> getDocumentById(String companyId, String documentId);
  Future<DocumentEntity> createDocument(
      String companyId, DocumentEntity document);
  Future<void> updateDocument(String companyId, DocumentEntity document);
  Future<void> deleteDocument(
      String companyId, String documentId); // Soft Delete
  Future<void> restoreDocument(String companyId, String documentId); // Restore
  Future<void> renameDocument(
      String companyId, String documentId, String newName); // Rename
  Future<void> replaceDocumentFile(
    String companyId,
    String documentId, {
    required String newDownloadUrl,
    required String newStoragePath,
    required int newSize,
    required String newMimeType,
    required String newOriginalName,
  });
}
