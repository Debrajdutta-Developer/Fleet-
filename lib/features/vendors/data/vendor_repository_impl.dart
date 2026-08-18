import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/errors/failure.dart';
import '../domain/vendor_entity.dart';
import '../domain/vendor_repository.dart';

class VendorRepositoryImpl implements VendorRepository {
  final FirebaseFirestore _firestore;
  final Uuid _uuid;

  VendorRepositoryImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _uuid = const Uuid();

  @override
  Stream<List<VendorEntity>> watchVendors(String companyId) {
    return _firestore
        .collection('companies')
        .doc(companyId)
        .collection('vendors')
        .where('deletedAt', isNull: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => VendorEntity.fromMap(doc.data()))
          .toList();
    });
  }

  @override
  Future<List<VendorEntity>> getVendors(String companyId) async {
    try {
      final snapshot = await _firestore
          .collection('companies')
          .doc(companyId)
          .collection('vendors')
          .where('deletedAt', isNull: true)
          .get();

      return snapshot.docs
          .map((doc) => VendorEntity.fromMap(doc.data()))
          .toList();
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  @override
  Future<VendorEntity?> getVendorById(String companyId, String vendorId) async {
    try {
      final doc = await _firestore
          .collection('companies')
          .doc(companyId)
          .collection('vendors')
          .doc(vendorId)
          .get();

      if (!doc.exists) return null;
      final data = doc.data();
      if (data == null || data['deletedAt'] != null) return null;
      return VendorEntity.fromMap(data);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  @override
  Future<VendorEntity> createVendor(
      String companyId, VendorEntity vendor) async {
    try {
      final id = vendor.id.isEmpty ? _uuid.v4() : vendor.id;
      final newVendor = vendor.copyWith(
        id: id,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection('companies')
          .doc(companyId)
          .collection('vendors')
          .doc(id)
          .set(newVendor.toMap());

      return newVendor;
    } on FirebaseException catch (e) {
      throw ServerFailure.fromFirebaseException(e.code, e.message);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  @override
  Future<void> updateVendor(String companyId, VendorEntity vendor) async {
    try {
      final updatedVendor = vendor.copyWith(updatedAt: DateTime.now());
      await _firestore
          .collection('companies')
          .doc(companyId)
          .collection('vendors')
          .doc(vendor.id)
          .update(updatedVendor.toMap());
    } on FirebaseException catch (e) {
      throw ServerFailure.fromFirebaseException(e.code, e.message);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  @override
  Future<void> deleteVendor(String companyId, String vendorId) async {
    try {
      await _firestore
          .collection('companies')
          .doc(companyId)
          .collection('vendors')
          .doc(vendorId)
          .update({
        'deletedAt': DateTime.now().toIso8601String(),
      });
    } on FirebaseException catch (e) {
      throw ServerFailure.fromFirebaseException(e.code, e.message);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }
}
