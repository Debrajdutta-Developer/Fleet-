import 'dart:typed_data';

abstract class CloudStorageService {
  Future<String> uploadFile({
    required String companyId,
    required String path,
    required Uint8List fileBytes,
    required String fileName,
    required String mimeType,
  });

  Future<void> deleteFile({
    required String companyId,
    required String path,
  });

  Future<Uint8List> downloadFile({
    required String companyId,
    required String path,
  });
}
