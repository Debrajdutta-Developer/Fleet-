import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/errors/failure.dart';
import '../domain/route_entity.dart';
import '../domain/dispatch_entity.dart';
import '../domain/dispatch_repository.dart';

class DispatchRepositoryImpl implements DispatchRepository {
  final FirebaseFirestore _firestore;
  final Uuid _uuid;

  DispatchRepositoryImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _uuid = const Uuid();

  // --- Routes ---

  @override
  Stream<List<RouteEntity>> watchRoutes(String companyId) {
    return _firestore
        .collection('companies')
        .doc(companyId)
        .collection('routes')
        .where('deletedAt', isNull: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => RouteEntity.fromMap(doc.data()))
          .toList();
    });
  }

  @override
  Future<List<RouteEntity>> getRoutes(String companyId) async {
    try {
      final snapshot = await _firestore
          .collection('companies')
          .doc(companyId)
          .collection('routes')
          .where('deletedAt', isNull: true)
          .get();

      return snapshot.docs
          .map((doc) => RouteEntity.fromMap(doc.data()))
          .toList();
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  @override
  Future<RouteEntity> createRoute(String companyId, RouteEntity route) async {
    try {
      final id = route.id.isEmpty ? _uuid.v4() : route.id;
      final newRoute = route.copyWith(
        id: id,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection('companies')
          .doc(companyId)
          .collection('routes')
          .doc(id)
          .set(newRoute.toMap());

      return newRoute;
    } on FirebaseException catch (e) {
      throw ServerFailure.fromFirebaseException(e.code, e.message);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  @override
  Future<void> updateRoute(String companyId, RouteEntity route) async {
    try {
      final updatedRoute = route.copyWith(updatedAt: DateTime.now());
      await _firestore
          .collection('companies')
          .doc(companyId)
          .collection('routes')
          .doc(route.id)
          .update(updatedRoute.toMap());
    } on FirebaseException catch (e) {
      throw ServerFailure.fromFirebaseException(e.code, e.message);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  @override
  Future<void> deleteRoute(String companyId, String routeId) async {
    try {
      await _firestore
          .collection('companies')
          .doc(companyId)
          .collection('routes')
          .doc(routeId)
          .update({
        'deletedAt': DateTime.now().toIso8601String(),
      });
    } on FirebaseException catch (e) {
      throw ServerFailure.fromFirebaseException(e.code, e.message);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  // --- Dispatches ---

  @override
  Stream<List<DispatchEntity>> watchDispatches(String companyId) {
    return _firestore
        .collection('companies')
        .doc(companyId)
        .collection('dispatches')
        .where('deletedAt', isNull: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => DispatchEntity.fromMap(doc.data()))
          .toList();
    });
  }

  @override
  Future<List<DispatchEntity>> getDispatches(String companyId) async {
    try {
      final snapshot = await _firestore
          .collection('companies')
          .doc(companyId)
          .collection('dispatches')
          .where('deletedAt', isNull: true)
          .get();

      return snapshot.docs
          .map((doc) => DispatchEntity.fromMap(doc.data()))
          .toList();
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  @override
  Future<DispatchEntity?> getDispatchById(String companyId, String id) async {
    try {
      final doc = await _firestore
          .collection('companies')
          .doc(companyId)
          .collection('dispatches')
          .doc(id)
          .get();

      if (!doc.exists) return null;
      final data = doc.data();
      if (data == null || data['deletedAt'] != null) return null;
      return DispatchEntity.fromMap(data);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  @override
  Future<DispatchEntity> createDispatch(
      String companyId, DispatchEntity dispatch) async {
    try {
      final id = dispatch.id.isEmpty ? _uuid.v4() : dispatch.id;
      final newDispatch = dispatch.copyWith(
        id: id,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection('companies')
          .doc(companyId)
          .collection('dispatches')
          .doc(id)
          .set(newDispatch.toMap());

      return newDispatch;
    } on FirebaseException catch (e) {
      throw ServerFailure.fromFirebaseException(e.code, e.message);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  @override
  Future<void> updateDispatch(String companyId, DispatchEntity dispatch) async {
    try {
      final updatedDispatch = dispatch.copyWith(updatedAt: DateTime.now());
      await _firestore
          .collection('companies')
          .doc(companyId)
          .collection('dispatches')
          .doc(dispatch.id)
          .update(updatedDispatch.toMap());
    } on FirebaseException catch (e) {
      throw ServerFailure.fromFirebaseException(e.code, e.message);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  @override
  Future<void> updateDispatchStatus(
      String companyId, String dispatchId, String status) async {
    try {
      await _firestore
          .collection('companies')
          .doc(companyId)
          .collection('dispatches')
          .doc(dispatchId)
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
  Future<void> deleteDispatch(String companyId, String id) async {
    try {
      await _firestore
          .collection('companies')
          .doc(companyId)
          .collection('dispatches')
          .doc(id)
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
