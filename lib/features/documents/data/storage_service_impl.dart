import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import '../domain/storage_service.dart';

class FirebaseStorageService implements CloudStorageService {
  final FirebaseStorage _storage;

  FirebaseStorageService({FirebaseStorage? storage})
      : _storage = storage ?? FirebaseStorage.instance;

  @override
  Future<String> uploadFile({
    required String companyId,
    required String path,
    required Uint8List fileBytes,
    required String fileName,
    required String mimeType,
  }) async {
    // Structure files inside tenant folders in storage
    final ref = _storage.ref().child('companies/$companyId/$path');
    final metadata = SettableMetadata(
      contentType: mimeType,
      customMetadata: {
        'companyId': companyId,
        'originalName': fileName,
      },
    );

    final uploadTask = ref.putData(fileBytes, metadata);
    final snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }

  @override
  Future<void> deleteFile({
    required String companyId,
    required String path,
  }) async {
    final ref = _storage.ref().child('companies/$companyId/$path');
    await ref.delete();
  }

  @override
  Future<Uint8List> downloadFile({
    required String companyId,
    required String path,
  }) async {
    final ref = _storage.ref().child('companies/$companyId/$path');
    final data = await ref.getData();
    if (data == null) {
      throw Exception('Failed to download file data from Storage.');
    }
    return data;
  }
}
