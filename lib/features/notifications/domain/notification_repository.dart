import 'notification_entity.dart';
import 'notification_preferences_entity.dart';

abstract class NotificationRepository {
  Stream<List<NotificationEntity>> watchNotifications(String companyId);
  Future<List<NotificationEntity>> getNotifications(String companyId);
  Future<NotificationEntity> createNotification(
      String companyId, NotificationEntity notification);
  Future<void> updateNotification(
      String companyId, NotificationEntity notification);
  Future<void> markAllAsRead(String companyId);
  Future<void> deleteNotification(String companyId, String notificationId);

  // Preferences
  Stream<NotificationPreferencesEntity> watchPreferences(String companyId);
  Future<NotificationPreferencesEntity> getPreferences(String companyId);
  Future<void> savePreferences(
      String companyId, NotificationPreferencesEntity preferences);
}
