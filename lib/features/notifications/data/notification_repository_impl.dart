import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/errors/failure.dart';
import '../domain/notification_entity.dart';
import '../domain/notification_preferences_entity.dart';
import '../domain/notification_repository.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  final FirebaseFirestore _firestore;
  final Uuid _uuid;

  NotificationRepositoryImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _uuid = const Uuid();

  @override
  Stream<List<NotificationEntity>> watchNotifications(String companyId) {
    return _firestore
        .collection('companies')
        .doc(companyId)
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => NotificationEntity.fromMap(doc.data()))
          .toList();
    });
  }

  @override
  Future<List<NotificationEntity>> getNotifications(String companyId) async {
    try {
      final snapshot = await _firestore
          .collection('companies')
          .doc(companyId)
          .collection('notifications')
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => NotificationEntity.fromMap(doc.data()))
          .toList();
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  @override
  Future<NotificationEntity> createNotification(
      String companyId, NotificationEntity notification) async {
    try {
      final id = notification.id.isEmpty ? _uuid.v4() : notification.id;
      final newNotification = notification.copyWith(
        id: id,
        companyId: companyId,
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection('companies')
          .doc(companyId)
          .collection('notifications')
          .doc(id)
          .set(newNotification.toMap());

      return newNotification;
    } on FirebaseException catch (e) {
      throw ServerFailure.fromFirebaseException(e.code, e.message);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  @override
  Future<void> updateNotification(
      String companyId, NotificationEntity notification) async {
    try {
      await _firestore
          .collection('companies')
          .doc(companyId)
          .collection('notifications')
          .doc(notification.id)
          .update(notification.toMap());
    } on FirebaseException catch (e) {
      throw ServerFailure.fromFirebaseException(e.code, e.message);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  @override
  Future<void> markAllAsRead(String companyId) async {
    try {
      final batch = _firestore.batch();
      final snapshot = await _firestore
          .collection('companies')
          .doc(companyId)
          .collection('notifications')
          .where('isRead', isEqualTo: false)
          .get();

      for (final doc in snapshot.docs) {
        batch.update(doc.reference, {
          'isRead': true,
          'readAt': DateTime.now().toIso8601String(),
        });
      }

      await batch.commit();
    } on FirebaseException catch (e) {
      throw ServerFailure.fromFirebaseException(e.code, e.message);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  @override
  Future<void> deleteNotification(
      String companyId, String notificationId) async {
    try {
      await _firestore
          .collection('companies')
          .doc(companyId)
          .collection('notifications')
          .doc(notificationId)
          .delete();
    } on FirebaseException catch (e) {
      throw ServerFailure.fromFirebaseException(e.code, e.message);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  @override
  Stream<NotificationPreferencesEntity> watchPreferences(String companyId) {
    return _firestore
        .collection('companies')
        .doc(companyId)
        .collection('notification_settings')
        .doc('preferences')
        .snapshots()
        .map((doc) {
      if (!doc.exists || doc.data() == null) {
        return NotificationPreferencesEntity(
          companyId: companyId,
          enabledCategories: const [
            'vehicles',
            'drivers',
            'inventory',
            'trips',
            'billing',
            'finance',
            'general'
          ],
          quietHoursEnabled: false,
          quietHoursStart: '22:00',
          quietHoursEnd: '06:00',
          minPriorityFilter: 'low',
        );
      }
      return NotificationPreferencesEntity.fromMap(doc.data()!);
    });
  }

  @override
  Future<NotificationPreferencesEntity> getPreferences(String companyId) async {
    try {
      final doc = await _firestore
          .collection('companies')
          .doc(companyId)
          .collection('notification_settings')
          .doc('preferences')
          .get();

      if (!doc.exists || doc.data() == null) {
        return NotificationPreferencesEntity(
          companyId: companyId,
          enabledCategories: const [
            'vehicles',
            'drivers',
            'inventory',
            'trips',
            'billing',
            'finance',
            'general'
          ],
          quietHoursEnabled: false,
          quietHoursStart: '22:00',
          quietHoursEnd: '06:00',
          minPriorityFilter: 'low',
        );
      }
      return NotificationPreferencesEntity.fromMap(doc.data()!);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  @override
  Future<void> savePreferences(
      String companyId, NotificationPreferencesEntity preferences) async {
    try {
      await _firestore
          .collection('companies')
          .doc(companyId)
          .collection('notification_settings')
          .doc('preferences')
          .set(preferences.toMap());
    } on FirebaseException catch (e) {
      throw ServerFailure.fromFirebaseException(e.code, e.message);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }
}
