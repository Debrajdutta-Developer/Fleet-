import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/errors/failure.dart';
import '../domain/driver_entity.dart';
import '../domain/driver_repository.dart';

class DriverRepositoryImpl implements DriverRepository {
  final FirebaseFirestore _firestore;
  final Uuid _uuid;

  DriverRepositoryImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _uuid = const Uuid();

  @override
  Stream<List<DriverEntity>> watchDrivers(String companyId) {
    return _firestore
        .collection('companies')
        .doc(companyId)
        .collection('drivers')
        .where('deletedAt', isNull: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => DriverEntity.fromMap(doc.data()))
          .toList();
    });
  }

  @override
  Future<List<DriverEntity>> getDrivers(String companyId) async {
    try {
      final snapshot = await _firestore
          .collection('companies')
          .doc(companyId)
          .collection('drivers')
          .where('deletedAt', isNull: true)
          .get();

      return snapshot.docs
          .map((doc) => DriverEntity.fromMap(doc.data()))
          .toList();
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  @override
  Future<DriverEntity?> getDriverById(String companyId, String driverId) async {
    try {
      final doc = await _firestore
          .collection('companies')
          .doc(companyId)
          .collection('drivers')
          .doc(driverId)
          .get();

      if (!doc.exists) return null;
      final data = doc.data();
      if (data == null || data['deletedAt'] != null) return null;
      return DriverEntity.fromMap(data);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  @override
  Future<DriverEntity> createDriver(
      String companyId, DriverEntity driver) async {
    try {
      final id = driver.id.isEmpty ? _uuid.v4() : driver.id;
      final newDriver = driver.copyWith(
        id: id,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection('companies')
          .doc(companyId)
          .collection('drivers')
          .doc(id)
          .set(newDriver.toMap());

      return newDriver;
    } on FirebaseException catch (e) {
      throw ServerFailure.fromFirebaseException(e.code, e.message);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  @override
  Future<void> updateDriver(String companyId, DriverEntity driver) async {
    try {
      final updatedDriver = driver.copyWith(updatedAt: DateTime.now());
      await _firestore
          .collection('companies')
          .doc(companyId)
          .collection('drivers')
          .doc(driver.id)
          .update(updatedDriver.toMap());
    } on FirebaseException catch (e) {
      throw ServerFailure.fromFirebaseException(e.code, e.message);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  @override
  Future<void> deleteDriver(String companyId, String driverId) async {
    try {
      await _firestore
          .collection('companies')
          .doc(companyId)
          .collection('drivers')
          .doc(driverId)
          .update({
        'deletedAt': DateTime.now().toIso8601String(),
        'status': 'suspended',
      });
    } on FirebaseException catch (e) {
      throw ServerFailure.fromFirebaseException(e.code, e.message);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  @override
  Future<void> updateDriverStatus(
      String companyId, String driverId, String status) async {
    try {
      await _firestore
          .collection('companies')
          .doc(companyId)
          .collection('drivers')
          .doc(driverId)
          .update({
        'status': status,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } on FirebaseException catch (e) {
      throw ServerFailure.fromFirebaseException(e.code, e.message);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  @override
  Future<void> linkVehicle(
    String companyId,
    String driverId,
    String? vehicleId,
    String? vehicleLicensePlate,
  ) async {
    try {
      await _firestore
          .collection('companies')
          .doc(companyId)
          .collection('drivers')
          .doc(driverId)
          .update({
        'assignedVehicleId': vehicleId,
        'assignedVehicleLicensePlate': vehicleLicensePlate,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } on FirebaseException catch (e) {
      throw ServerFailure.fromFirebaseException(e.code, e.message);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }
}
