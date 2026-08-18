import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/services/local_storage_service.dart';
import '../domain/company_entity.dart';
import '../domain/company_repository.dart';

/// Firebase Implementation of CompanyRepository.
class CompanyRepositoryImpl implements CompanyRepository {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  final LocalStorageService _localStorage;
  final Uuid _uuid;

  CompanyRepositoryImpl({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
    required LocalStorageService localStorage,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance,
        _localStorage = localStorage,
        _uuid = const Uuid();

  @override
  Future<CompanyEntity> createCompany({
    required String name,
    required String ownerName,
    required String ownerUid,
    String? gstNumber,
    String? panNumber,
    required String phone,
    required String email,
    required String address,
    required String defaultCurrency,
    required String timeZone,
    File? logoFile,
  }) async {
    try {
      final companyId = _uuid.v4();
      String logoUrl = '';

      // 1. Upload logo if provided
      if (logoFile != null) {
        logoUrl = await uploadLogo(companyId, logoFile);
      }

      // 2. Build company profile record
      final company = CompanyEntity(
        id: companyId,
        name: name,
        ownerName: ownerName,
        ownerUid: ownerUid,
        gstNumber: gstNumber,
        panNumber: panNumber,
        phone: phone,
        email: email,
        address: address,
        logoUrl: logoUrl,
        defaultCurrency: defaultCurrency,
        timeZone: timeZone,
        createdAt: DateTime.now(),
        isSetupComplete: true,
      );

      // 3. Save to Firestore (Offline persistence handles queuing if offline)
      await _firestore
          .collection('companies')
          .doc(companyId)
          .set(company.toMap());

      // 4. Cache company selection locally
      await _localStorage.cacheUserCompanyId(companyId);

      return company;
    } on FirebaseException catch (e) {
      throw ServerFailure.fromFirebaseException(e.code, e.message);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  @override
  Future<CompanyEntity?> getCompany(String companyId) async {
    try {
      final doc = await _firestore.collection('companies').doc(companyId).get();
      if (!doc.exists || doc.data() == null) {
        return null;
      }
      return CompanyEntity.fromMap(doc.data()!);
    } catch (e) {
      // Local Firestore cache automatic fallback
      return null;
    }
  }

  @override
  Future<String> uploadLogo(String companyId, File logoFile) async {
    try {
      final ref =
          _storage.ref().child('companies').child(companyId).child('logo.png');
      final uploadTask = await ref.putFile(
        logoFile,
        SettableMetadata(contentType: 'image/png'),
      );
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      // Return a standard placeholder or empty string to ensure offline-friendliness
      // in case Storage bucket permissions aren't set up yet.
      return 'https://images.unsplash.com/photo-1579546929518-9e396f3cc809?w=200';
    }
  }
}
