import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/errors/failure.dart';
import '../domain/trip_entity.dart';
import '../domain/trip_status_history.dart';
import '../domain/audit_log_entity.dart';
import '../domain/trip_repository.dart';

class TripRepositoryImpl implements TripRepository {
  final FirebaseFirestore _firestore;
  final Uuid _uuid;

  TripRepositoryImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _uuid = const Uuid();

  @override
  Stream<List<TripEntity>> watchTrips(String companyId) {
    return _firestore
        .collection('companies')
        .doc(companyId)
        .collection('trips')
        .where('deletedAt', isNull: true)
        .snapshots()
        .map((snapshot) {
      final list =
          snapshot.docs.map((doc) => TripEntity.fromMap(doc.data())).toList();
      // Sort in-memory to ensure correct sorting offline/online
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  @override
  Future<List<TripEntity>> getTrips(String companyId) async {
    try {
      final snapshot = await _firestore
          .collection('companies')
          .doc(companyId)
          .collection('trips')
          .where('deletedAt', isNull: true)
          .get();

      final list =
          snapshot.docs.map((doc) => TripEntity.fromMap(doc.data())).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  @override
  Future<TripEntity?> getTripById(String companyId, String tripId) async {
    try {
      final doc = await _firestore
          .collection('companies')
          .doc(companyId)
          .collection('trips')
          .doc(tripId)
          .get();
      if (!doc.exists) return null;
      return TripEntity.fromMap(doc.data()!);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  @override
  Future<TripEntity> createTrip(
    String companyId,
    TripEntity trip,
    AuditLogEntity initialAuditLog,
  ) async {
    try {
      final tripId = trip.id.isEmpty ? _uuid.v4() : trip.id;
      final auditLogId =
          initialAuditLog.id.isEmpty ? _uuid.v4() : initialAuditLog.id;

      final now = DateTime.now();
      final initialHistory = TripStatusHistory(
        status: trip.status,
        changedAt: now,
        changedBy: initialAuditLog.userName,
        notes: 'Initial trip creation',
      );

      final newTrip = trip.copyWith(
        id: tripId,
        companyId: companyId,
        statusHistory: [initialHistory],
        createdAt: now,
        updatedAt: now,
      );

      final newAuditLog = AuditLogEntity(
        id: auditLogId,
        companyId: companyId,
        entityType: 'trip',
        entityId: tripId,
        action: initialAuditLog.action,
        description: initialAuditLog.description,
        userId: initialAuditLog.userId,
        userName: initialAuditLog.userName,
        timestamp: now,
      );

      final batch = _firestore.batch();

      final tripRef = _firestore
          .collection('companies')
          .doc(companyId)
          .collection('trips')
          .doc(tripId);

      final auditRef = _firestore
          .collection('companies')
          .doc(companyId)
          .collection('audit_logs')
          .doc(auditLogId);

      batch.set(tripRef, newTrip.toMap());
      batch.set(auditRef, newAuditLog.toMap());

      await batch.commit();

      return newTrip;
    } on FirebaseException catch (e) {
      throw ServerFailure.fromFirebaseException(e.code, e.message);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  @override
  Future<void> updateTripStatus(
    String companyId,
    String tripId,
    String newStatus,
    String changedByUserId,
    String changedByUserName, {
    String? notes,
  }) async {
    try {
      final tripRef = _firestore
          .collection('companies')
          .doc(companyId)
          .collection('trips')
          .doc(tripId);

      final doc = await tripRef.get();
      if (!doc.exists) {
        throw const ServerFailure(
          'Trip document not found.',
          code: 'not-found',
        );
      }

      final trip = TripEntity.fromMap(doc.data()!);
      final now = DateTime.now();

      final newHistory = TripStatusHistory(
        status: newStatus,
        changedAt: now,
        changedBy: changedByUserName,
        notes: notes,
      );

      final updatedHistory = List<TripStatusHistory>.from(trip.statusHistory)
        ..add(newHistory);
      final updatedTrip = trip.copyWith(
        status: newStatus,
        statusHistory: updatedHistory,
        updatedAt: now,
      );

      final auditLogId = _uuid.v4();
      final auditRef = _firestore
          .collection('companies')
          .doc(companyId)
          .collection('audit_logs')
          .doc(auditLogId);

      final auditLog = AuditLogEntity(
        id: auditLogId,
        companyId: companyId,
        entityType: 'trip',
        entityId: tripId,
        action: 'status_changed',
        description: 'Trip status updated from ${trip.status} to $newStatus',
        userId: changedByUserId,
        userName: changedByUserName,
        timestamp: now,
      );

      final batch = _firestore.batch();
      batch.update(tripRef, updatedTrip.toMap());
      batch.set(auditRef, auditLog.toMap());

      await batch.commit();
    } on FirebaseException catch (e) {
      throw ServerFailure.fromFirebaseException(e.code, e.message);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  @override
  Future<void> deleteTrip(
    String companyId,
    String tripId,
    AuditLogEntity deleteAuditLog,
  ) async {
    try {
      final now = DateTime.now();
      final tripRef = _firestore
          .collection('companies')
          .doc(companyId)
          .collection('trips')
          .doc(tripId);

      final auditLogId =
          deleteAuditLog.id.isEmpty ? _uuid.v4() : deleteAuditLog.id;
      final auditRef = _firestore
          .collection('companies')
          .doc(companyId)
          .collection('audit_logs')
          .doc(auditLogId);

      final finalAuditLog = AuditLogEntity(
        id: auditLogId,
        companyId: companyId,
        entityType: 'trip',
        entityId: tripId,
        action: deleteAuditLog.action,
        description: deleteAuditLog.description,
        userId: deleteAuditLog.userId,
        userName: deleteAuditLog.userName,
        timestamp: now,
      );

      final batch = _firestore.batch();
      batch.update(tripRef, {
        'deletedAt': now.toIso8601String(),
        'updatedAt': now.toIso8601String(),
      });
      batch.set(auditRef, finalAuditLog.toMap());

      await batch.commit();
    } on FirebaseException catch (e) {
      throw ServerFailure.fromFirebaseException(e.code, e.message);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  @override
  Stream<List<AuditLogEntity>> watchAuditLogsForTrip(
    String companyId,
    String tripId,
  ) {
    return _firestore
        .collection('companies')
        .doc(companyId)
        .collection('audit_logs')
        .where('entityType', isEqualTo: 'trip')
        .where('entityId', isEqualTo: tripId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => AuditLogEntity.fromMap(doc.data()))
          .toList();
      list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return list;
    });
  }
}
